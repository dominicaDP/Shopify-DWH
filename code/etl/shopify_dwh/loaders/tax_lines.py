"""
stg_order_tax_lines loader — off Order.taxLines.
Scope: read_orders.  Grain: one row per tax line.  Merge key: (order_id, line_number).

Order.taxLines is a plain list with no stable id, so line_number is the 1-based
array index. Loads into <stg_schema>.stg_order_tax_lines.

Run (from code/etl/):
    python -m shopify_dwh.loaders.tax_lines [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_order_tax_lines"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        taxLines {
          title
          rate
          priceSet { shopMoney { amount } }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""


def extract_rows(order: dict, run_ts: datetime) -> list[dict]:
    rows = []
    for i, tax in enumerate(order.get("taxLines") or [], start=1):
        rows.append({
            "order_id": order["id"],
            "line_number": i,
            "title": tax.get("title"),
            "rate": tax.get("rate"),
            "price": src.money(tax.get("priceSet")),
            "extracted_at": run_ts,
        })
    return rows


def main() -> int:
    return src.run_child_loader(
        table=TABLE, query=QUERY, extract_rows=extract_rows,
        key_columns=["order_id", "line_number"], page_size=100,
    )


if __name__ == "__main__":
    raise SystemExit(main())
