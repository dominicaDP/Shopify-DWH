"""
stg_orders loader — header level only (line items load separately).

Two modes:
  full        — TRUNCATE + reload every order the scope permits
  incremental — fetch only orders with updatedAt >= the stored watermark, then
                MERGE on id so a re-run never duplicates

Production note vs the POC: with `read_customers` granted we now populate
`customer_id` from `customer { id }` (the POC NULLed it for lack of the scope).
`read_all_orders` lifts the 60-day window so a first full run backfills all history.
`landing_site` / `referring_site` / `checkout_id` stay NULL — those were removed
from the Order object in the 2026-04 API (use customerJourneySummary), not a scope
issue. Loads into <stg_schema>.stg_orders.

Run (from code/etl/):
    python -m shopify_dwh.loaders.orders            # auto: full if empty, else incremental
    python -m shopify_dwh.loaders.orders full
    python -m shopify_dwh.loaders.orders incremental
"""

from __future__ import annotations

import json
import logging
import sys
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_orders")

TABLE = "stg_orders"

ORDERS_QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        name
        email
        createdAt
        processedAt
        updatedAt
        cancelledAt
        closedAt
        cancelReason
        currencyCode
        subtotalPriceSet      { shopMoney { amount } }
        totalDiscountsSet     { shopMoney { amount } }
        totalTaxSet           { shopMoney { amount } }
        totalShippingPriceSet { shopMoney { amount } }
        totalPriceSet         { shopMoney { amount } }
        totalRefundedSet      { shopMoney { amount } }
        displayFinancialStatus
        displayFulfillmentStatus
        customer { id }
        shippingAddress { address1 address2 city province provinceCode countryCodeV2 country zip company name phone }
        billingAddress  { address1 address2 city province provinceCode countryCodeV2 country zip company name phone }
        tags
        note
        sourceName
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = [
    "created_at", "processed_at", "updated_at",
    "cancelled_at", "closed_at", "extracted_at",
]


def _money(money_set: dict | None):
    return (money_set or {}).get("shopMoney", {}).get("amount")


def _addr_json(addr: dict | None):
    return json.dumps(addr, ensure_ascii=False) if addr else None


def _to_row(node: dict, run_ts: datetime) -> dict:
    tags = node.get("tags") or []
    return {
        "id": node["id"],
        "name": node.get("name"),
        "email": node.get("email"),
        "created_at": node["createdAt"],
        "processed_at": node.get("processedAt"),
        "updated_at": node.get("updatedAt"),
        "cancelled_at": node.get("cancelledAt"),
        "closed_at": node.get("closedAt"),
        "cancel_reason": node.get("cancelReason"),
        "currency_code": node.get("currencyCode"),
        "subtotal_price": _money(node.get("subtotalPriceSet")),
        "total_discounts": _money(node.get("totalDiscountsSet")),
        "total_tax": _money(node.get("totalTaxSet")),
        "total_shipping": _money(node.get("totalShippingPriceSet")),
        "total_price": _money(node.get("totalPriceSet")),
        "total_refunded": _money(node.get("totalRefundedSet")),
        "financial_status": node.get("displayFinancialStatus"),
        "fulfillment_status": node.get("displayFulfillmentStatus"),
        "customer_id": (node.get("customer") or {}).get("id"),  # needs read_customers
        "shipping_address_json": _addr_json(node.get("shippingAddress")),
        "billing_address_json": _addr_json(node.get("billingAddress")),
        "tags": ",".join(tags) if tags else None,
        "note": node.get("note"),
        "source_name": node.get("sourceName"),
        "landing_site": None,    # removed in 2026-04 API (see module docstring)
        "referring_site": None,  # removed in 2026-04 API
        "checkout_id": None,     # removed in 2026-04 API
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient, query_filter: str | None = None) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = []
    for n in client.paginate(ORDERS_QUERY, ["orders"], variables={"query": query_filter}):
        rows.append(_to_row(n, run_ts))
        if len(rows) % 1000 == 0:
            log.info("  ...%d orders so far", len(rows))
    df = pd.DataFrame(rows)
    if len(df):
        ex.to_naive_utc(df, TIMESTAMP_COLS)
    return df


def _print_summary(conn, schema: str, loaded: int, mode: str) -> None:
    stats = conn.execute(
        f"""SELECT COUNT(*), COUNT(email), COUNT(customer_id), COUNT(shipping_address_json),
                   MIN(created_at), MAX(created_at), SUM(total_price)
            FROM {schema}.{TABLE}"""
    ).fetchone()
    dupes = conn.execute(
        f"SELECT COUNT(*) FROM (SELECT id FROM {schema}.{TABLE} GROUP BY id HAVING COUNT(*) > 1)"
    ).fetchone()[0]
    print(f"\n[{mode}] processed {loaded} orders; {TABLE} now holds {stats[0]} rows.")
    print(f"Completeness      -> email: {stats[1]}/{stats[0]}, customer_id: {stats[2]}/{stats[0]}, "
          f"shipping_addr: {stats[3]}/{stats[0]}")
    print(f"Date range        -> {stats[4]}  ..  {stats[5]}")
    print(f"Sum(total_price)  -> {stats[6]}")
    print(f"Duplicate ids     -> {dupes}  ({'OK' if dupes == 0 else 'FAIL — not idempotent'})")


def run_full(conn, client, schema: str) -> int:
    df = extract(client)
    log.info("extracted %d orders (full)", len(df))
    return ex.load_full(conn, schema, TABLE, df)


def run_incremental(conn, client, schema: str) -> int:
    watermark = conn.execute(f"SELECT MAX(updated_at) FROM {schema}.{TABLE}").fetchone()[0]
    if watermark is None:
        log.info("no watermark (table empty) — falling back to full load")
        return run_full(conn, client, schema)
    # Exasol returns TIMESTAMP as a string; normalise then format for Shopify.
    # >= the watermark so the boundary order is re-fetched and merged idempotently.
    filt = f"updated_at:>={pd.Timestamp(watermark).strftime('%Y-%m-%dT%H:%M:%SZ')}"
    log.info("incremental since watermark %s -> filter '%s'", watermark, filt)
    df = extract(client, query_filter=filt)
    log.info("extracted %d changed orders (incremental)", len(df))
    return ex.merge_upsert(conn, schema, TABLE, df, key_columns=["id"])


def main() -> int:
    settings = load_settings()
    configure_logging(settings)
    schema = settings.exasol.stg_schema
    mode = sys.argv[1].lower() if len(sys.argv) > 1 else "auto"

    conn = ex.connect(settings)
    try:
        if mode == "auto":
            mode = "incremental" if ex.count(conn, schema, TABLE) else "full"
        with ShopifyClient.from_settings(settings) as client:
            if mode == "full":
                loaded = run_full(conn, client, schema)
            elif mode == "incremental":
                loaded = run_incremental(conn, client, schema)
            else:
                print(f"unknown mode: {mode!r} (use full | incremental)", file=sys.stderr)
                return 2
        _print_summary(conn, schema, loaded, mode)
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
