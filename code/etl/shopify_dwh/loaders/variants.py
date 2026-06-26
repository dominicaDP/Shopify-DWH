"""
stg_product_variants loader — full load.

Maps the top-level productVariants connection to <stg_schema>.stg_product_variants.
weight/cost live under inventoryItem (2026-04 API); unitCost needs read_inventory,
which the production scope set grants, so cost should now populate fully (the POC
ran without read_inventory and saw cost only partially filled).

Run (from code/etl/):
    python -m shopify_dwh.loaders.variants
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_variants")

TABLE = "stg_product_variants"

VARIANTS_QUERY = """
query($pageSize: Int!, $cursor: String) {
  productVariants(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        title
        sku
        barcode
        price
        compareAtPrice
        taxable
        createdAt
        updatedAt
        product { id }
        selectedOptions { name value }
        inventoryItem {
          id
          requiresShipping
          unitCost { amount }
          measurement { weight { value unit } }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "updated_at", "extracted_at"]


def _opt(options: list, idx: int):
    return options[idx]["value"] if options and len(options) > idx else None


def _to_row(node: dict, run_ts: datetime) -> dict:
    options = node.get("selectedOptions") or []
    inv = node.get("inventoryItem") or {}
    unit_cost = (inv.get("unitCost") or {}).get("amount")
    weight_obj = ((inv.get("measurement") or {}).get("weight")) or {}
    return {
        "id": node["id"],
        "product_id": (node.get("product") or {}).get("id"),
        "title": node["title"],
        "sku": node.get("sku"),
        "barcode": node.get("barcode"),
        "price": node.get("price"),
        "compare_at_price": node.get("compareAtPrice"),
        "cost": unit_cost,
        "taxable": node.get("taxable"),
        "requires_shipping": inv.get("requiresShipping"),
        "weight": weight_obj.get("value"),
        "weight_unit": weight_obj.get("unit"),
        "option1": _opt(options, 0),
        "option2": _opt(options, 1),
        "option3": _opt(options, 2),
        "inventory_item_id": inv.get("id"),
        "created_at": node["createdAt"],
        "updated_at": node["updatedAt"],
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = [_to_row(n, run_ts) for n in client.paginate(VARIANTS_QUERY, ["productVariants"])]
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
    log.info("extracted %d variants from Shopify", len(df))

    conn = ex.connect(settings)
    try:
        loaded = ex.load_full(conn, schema, TABLE, df)
        total = ex.count(conn, schema, TABLE)
        # how complete is each inventory-scoped field?
        filled = conn.execute(
            f"""SELECT
                  COUNT(cost)              AS cost_filled,
                  COUNT(weight)            AS weight_filled,
                  COUNT(requires_shipping) AS reqship_filled,
                  COUNT(*)                 AS total
                FROM {schema}.{TABLE}"""
        ).fetchone()
    finally:
        conn.close()

    print(f"\nLoaded {loaded} variants; {TABLE} now holds {total} rows.")
    print(f"Field completeness — cost: {filled[0]}/{filled[3]}, "
          f"weight: {filled[1]}/{filled[3]}, requires_shipping: {filled[2]}/{filled[3]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
