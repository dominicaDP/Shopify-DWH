"""
stg_abandoned_checkouts loader — full load.
Grain: one row per abandoned checkout.

Full reload each run: a checkout that gets completed drops off the abandoned list,
so truncate-and-reload keeps the table in sync with "currently abandoned"
(truly abandoned = completed_at IS NULL). Loads into
<stg_schema>.stg_abandoned_checkouts.

Scope: the `abandonedCheckouts` query is expected to read under read_orders —
confirm at first run; if it errors on access, read_checkouts may be required (it is
NOT in the decided scope set, so that would be a scope decision like discount_codes).

Verify at first run: email/phone are NOT read here — recent AbandonedCheckout exposes
contact via `customer`, not as top-level fields, so those two columns are left NULL
and should be filled by joining dim_customer in the DWH. currency comes off
totalPriceSet.shopMoney.currencyCode.

Run (from code/etl/):
    python -m shopify_dwh.loaders.abandoned_checkouts
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_abandoned_checkouts")

TABLE = "stg_abandoned_checkouts"

ABANDONED_QUERY = """
query($pageSize: Int!, $cursor: String) {
  abandonedCheckouts(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        createdAt
        updatedAt
        completedAt
        abandonedCheckoutUrl
        customer { id }
        subtotalPriceSet { shopMoney { amount } }
        totalTaxSet      { shopMoney { amount } }
        totalPriceSet    { shopMoney { amount currencyCode } }
        shippingAddress { address1 address2 city province provinceCode countryCodeV2 country zip company name phone }
        lineItems(first: 100) {
          edges { node { title quantity } }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "updated_at", "completed_at", "extracted_at"]


def _money(money_set: dict | None):
    return (money_set or {}).get("shopMoney", {}).get("amount")


def _to_row(node: dict, run_ts: datetime) -> dict:
    total_set = (node.get("totalPriceSet") or {}).get("shopMoney") or {}
    line_nodes = [e["node"] for e in (node.get("lineItems") or {}).get("edges", [])]
    address = node.get("shippingAddress")
    return {
        "id": node["id"],
        "created_at": node.get("createdAt"),
        "updated_at": node.get("updatedAt"),
        "completed_at": node.get("completedAt"),
        "customer_id": (node.get("customer") or {}).get("id"),
        "email": None,   # not a top-level field on AbandonedCheckout (see docstring)
        "phone": None,
        "subtotal_price": _money(node.get("subtotalPriceSet")),
        "total_tax": _money(node.get("totalTaxSet")),
        "total_price": _money(node.get("totalPriceSet")),
        "currency_code": total_set.get("currencyCode"),
        "abandoned_checkout_url": node.get("abandonedCheckoutUrl"),
        "line_items_count": len(line_nodes),
        "line_items_json": json.dumps(line_nodes, ensure_ascii=False) if line_nodes else None,
        "shipping_address_json": json.dumps(address, ensure_ascii=False) if address else None,
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = [_to_row(n, run_ts) for n in client.paginate(ABANDONED_QUERY, ["abandonedCheckouts"])]
    df = pd.DataFrame(rows)
    if len(df):
        ex.to_naive_utc(df, TIMESTAMP_COLS)
    return df


def main() -> int:
    settings = load_settings()
    configure_logging(settings)
    schema = settings.exasol.stg_schema

    with ShopifyClient.from_settings(settings) as client:
        df = extract(client)
    log.info("extracted %d abandoned checkouts from Shopify", len(df))

    conn = ex.connect(settings)
    try:
        loaded = ex.load_full(conn, schema, TABLE, df)
        stats = conn.execute(
            f"""SELECT COUNT(*), COUNT(completed_at), COUNT(customer_id), SUM(total_price)
                FROM {schema}.{TABLE}"""
        ).fetchone()
    finally:
        conn.close()

    print(f"\nLoaded {loaded} abandoned checkouts; {TABLE} now holds {stats[0]} rows.")
    print(f"Completed (recovered) -> {stats[1]}/{stats[0]}, with customer: {stats[2]}/{stats[0]}")
    print(f"Total cart value      -> {stats[3]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
