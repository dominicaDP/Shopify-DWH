"""
Shopify Admin GraphQL client wrapper for the POC (Phase 2.1).

One place to handle the things every loader needs:
  - auth (token header) and the versioned GraphQL endpoint
  - retries on transient network / 5xx / 429 failures (exponential backoff)
  - Shopify's cost-based rate limiting (leaky-bucket): read throttleStatus from
    each response, wait proactively when the bucket runs low, and back off-and-retry
    on an explicit THROTTLED error
  - cursor pagination over a GraphQL connection (edges/pageInfo)

Shopify's GraphQL rate limit is a points bucket, not a request count. Each query
has a cost; the response carries `extensions.cost.throttleStatus`
(maximumAvailable / currentlyAvailable / restoreRate points-per-second). We keep
the bucket healthy rather than sprinting into a 429.

Usage:
    with ShopifyClient.from_env() as client:
        for product in client.paginate(PRODUCTS_QUERY, ["products"], page_size=250):
            ...

Run directly for a Phase 2.1 self-test (paginates a few products):
    python shopify_client.py
"""

import logging
import os
import time
from pathlib import Path
from typing import Any, Iterator, Optional

import httpx
from dotenv import load_dotenv

log = logging.getLogger("shopify")


class ShopifyError(Exception):
    """Base class for client errors."""


class ShopifyGraphQLError(ShopifyError):
    """A non-retryable GraphQL error (bad query, missing field, denied access)."""

    def __init__(self, errors: Any):
        self.errors = errors
        super().__init__(f"GraphQL error(s): {errors}")


class ShopifyClient:
    # HTTP statuses worth retrying (transient server-side / rate limit).
    _RETRYABLE_STATUS = {429, 500, 502, 503, 504}

    def __init__(
        self,
        shop_domain: str,
        api_version: str,
        token: str,
        *,
        max_retries: int = 5,
        timeout: float = 30.0,
        points_buffer: int = 100,
        backoff_base: float = 1.0,
        backoff_cap: float = 60.0,
    ):
        if not token:
            raise ShopifyError("No access token. Run oauth_install.py first.")
        self.url = f"https://{shop_domain}/admin/api/{api_version}/graphql.json"
        self.max_retries = max_retries
        self.points_buffer = points_buffer
        self.backoff_base = backoff_base
        self.backoff_cap = backoff_cap
        self._client = httpx.Client(
            timeout=timeout,
            headers={
                "X-Shopify-Access-Token": token,
                "Content-Type": "application/json",
            },
        )
        self._throttle: Optional[dict] = None  # last seen throttleStatus

    @classmethod
    def from_env(cls, **kwargs) -> "ShopifyClient":
        load_dotenv(Path(__file__).parent / ".env")
        return cls(
            shop_domain=os.environ["SHOPIFY_SHOP_DOMAIN"],
            api_version=os.environ["SHOPIFY_API_VERSION"],
            token=os.environ.get("SHOPIFY_ACCESS_TOKEN", ""),
            **kwargs,
        )

    # -- lifecycle ----------------------------------------------------------

    def close(self) -> None:
        self._client.close()

    def __enter__(self) -> "ShopifyClient":
        return self

    def __exit__(self, *_exc) -> None:
        self.close()

    # -- core request -------------------------------------------------------

    def execute(self, query: str, variables: Optional[dict] = None) -> dict:
        """Run one GraphQL query, returning the `data` object.

        Retries transient failures and throttling; raises ShopifyGraphQLError on
        genuine query errors.
        """
        for attempt in range(self.max_retries + 1):
            try:
                resp = self._client.post(
                    self.url, json={"query": query, "variables": variables or {}}
                )
            except (httpx.TimeoutException, httpx.TransportError) as exc:
                self._sleep_backoff(attempt, why=f"network error: {exc!r}")
                continue

            if resp.status_code in self._RETRYABLE_STATUS:
                retry_after = self._retry_after_seconds(resp)
                self._sleep_backoff(
                    attempt, why=f"HTTP {resp.status_code}", override=retry_after
                )
                continue
            resp.raise_for_status()  # any other 4xx is a real bug — surface it

            payload = resp.json()
            self._record_throttle(payload)

            if payload.get("errors"):
                if self._is_throttled(payload["errors"]):
                    self._sleep_for_points(attempt)
                    continue
                raise ShopifyGraphQLError(payload["errors"])

            self._wait_if_bucket_low()
            return payload["data"]

        raise ShopifyError(f"Exceeded {self.max_retries} retries for query")

    # -- pagination ---------------------------------------------------------

    def paginate(
        self,
        query: str,
        connection_path: list[str],
        variables: Optional[dict] = None,
        page_size: int = 250,
    ) -> Iterator[dict]:
        """Yield every node from a cursor-paginated connection.

        The query must accept `$cursor: String` and `$pageSize: Int` variables and
        select `edges { node { ... } } pageInfo { hasNextPage endCursor }` on the
        connection. `connection_path` is the key path from `data` to that
        connection, e.g. ["products"] or ["orders"].
        """
        cursor: Optional[str] = None
        base_vars = dict(variables or {})
        page = 0
        while True:
            page += 1
            data = self.execute(
                query, {**base_vars, "cursor": cursor, "pageSize": page_size}
            )
            conn = data
            for key in connection_path:
                conn = conn[key]
            edges = conn["edges"]
            log.debug("page %d: %d nodes", page, len(edges))
            for edge in edges:
                yield edge["node"]
            page_info = conn["pageInfo"]
            if not page_info["hasNextPage"]:
                return
            cursor = page_info["endCursor"]

    # -- throttle / backoff helpers ----------------------------------------

    @staticmethod
    def _is_throttled(errors: list) -> bool:
        for err in errors:
            code = (err.get("extensions") or {}).get("code")
            if code == "THROTTLED" or "throttled" in err.get("message", "").lower():
                return True
        return False

    def _record_throttle(self, payload: dict) -> None:
        cost = (payload.get("extensions") or {}).get("cost")
        if cost and cost.get("throttleStatus"):
            self._throttle = cost["throttleStatus"]

    def _wait_if_bucket_low(self) -> None:
        """Proactively pause when remaining points dip below the buffer."""
        t = self._throttle
        if not t:
            return
        available = t.get("currentlyAvailable", 0)
        restore = t.get("restoreRate", 1) or 1
        if available < self.points_buffer:
            wait = (self.points_buffer - available) / restore
            log.info("bucket low (%s pts), waiting %.1fs to restore", available, wait)
            time.sleep(wait)

    def _sleep_for_points(self, attempt: int) -> None:
        """Wait after an explicit THROTTLED error, using throttleStatus if known."""
        t = self._throttle
        if t:
            restore = t.get("restoreRate", 1) or 1
            available = t.get("currentlyAvailable", 0)
            wait = max(1.0, (self.points_buffer - available) / restore)
            log.warning("throttled, waiting %.1fs for points to restore", wait)
            time.sleep(min(wait, self.backoff_cap))
        else:
            self._sleep_backoff(attempt, why="throttled (no cost info)")

    def _sleep_backoff(
        self, attempt: int, *, why: str, override: Optional[float] = None
    ) -> None:
        if attempt >= self.max_retries:
            return  # let the caller fall through to the final raise
        wait = override if override is not None else self.backoff_base * (2 ** attempt)
        wait = min(wait, self.backoff_cap)
        log.warning("retry %d/%d after %s — sleeping %.1fs",
                    attempt + 1, self.max_retries, why, wait)
        time.sleep(wait)

    @staticmethod
    def _retry_after_seconds(resp: httpx.Response) -> Optional[float]:
        value = resp.headers.get("Retry-After")
        if value is None:
            return None
        try:
            return float(value)
        except ValueError:
            return None


# ---------------------------------------------------------------------------
# Phase 2.1 self-test: prove auth + pagination + cost reporting work end to end.
# ---------------------------------------------------------------------------

_PRODUCTS_PROBE = """
query($pageSize: Int!, $cursor: String) {
  products(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        title
        status
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""


def _selftest() -> int:
    logging.basicConfig(
        level=logging.INFO, format="%(levelname)s %(name)s: %(message)s"
    )
    with ShopifyClient.from_env() as client:
        count = 0
        sample = []
        # Small page size on purpose, to exercise multi-page pagination.
        for node in client.paginate(_PRODUCTS_PROBE, ["products"], page_size=5):
            count += 1
            if len(sample) < 5:
                sample.append(node["title"])
            if count >= 12:  # don't walk the whole catalogue for a smoke test
                break
        print(f"\nPaginated {count} product(s). Sample titles:")
        for title in sample:
            print(f"  - {title}")
        if client._throttle:
            t = client._throttle
            print(
                f"\nLeaky bucket: {t.get('currentlyAvailable')}/{t.get('maximumAvailable')} "
                f"points available, restoring {t.get('restoreRate')}/s"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(_selftest())
