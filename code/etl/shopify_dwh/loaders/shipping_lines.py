"""
stg_order_shipping_lines loader — off Order.shippingLines.
Scope: read_orders.  Grain: one row per shipping line.  Merge key: id.

Loads into <stg_schema>.stg_order_shipping_lines. Note `source` is a reserved-word
watch column (see ddl/README.md) — fine as a Python dict key, only relevant to DDL.

Run (from code/etl/):
    python -m shopify_dwh.loaders.shipping_lines [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_order_shipping_lines"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        shippingLines(first: 10) {
          edges {
            node {
              id
              title
              code
              source
              carrierIdentifier
              originalPriceSet   { shopMoney { amount } }
              discountedPriceSet { shopMoney { amount } }
            }
          }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""


def extract_rows(order: dict, run_ts: datetime) -> list[dict]:
    rows = []
    for sl in src.nodes(order.get("shippingLines")):
        rows.append({
            "id": sl["id"],
            "order_id": order["id"],
            "title": sl.get("title"),
            "code": sl.get("code"),
            "source": sl.get("source"),
            "original_price": src.money(sl.get("originalPriceSet")),
            "discounted_price": src.money(sl.get("discountedPriceSet")),
            "carrier_identifier": sl.get("carrierIdentifier"),
            "extracted_at": run_ts,
        })
    return rows


def main() -> int:
    return src.run_child_loader(
        table=TABLE, query=QUERY, extract_rows=extract_rows,
        key_columns=["id"], page_size=100,
    )


if __name__ == "__main__":
    raise SystemExit(main())
