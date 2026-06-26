"""
stg_refund_line_items loader — off Order.refunds.refundLineItems.
Scope: read_orders.  Grain: one row per refunded line item.
Merge key: (refund_id, line_item_id).

Doubly nested (orders -> refunds -> refundLineItems connection), so the orders page
size is kept small. Loads into <stg_schema>.stg_refund_line_items.

Run (from code/etl/):
    python -m shopify_dwh.loaders.refund_line_items [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_refund_line_items"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        refunds(first: 30) {
          id
          refundLineItems(first: 100) {
            edges {
              node {
                quantity
                restockType
                lineItem { id }
                location { id }
                subtotalSet { shopMoney { amount } }
                totalTaxSet { shopMoney { amount } }
              }
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
    for r in order.get("refunds") or []:
        for rli in src.nodes(r.get("refundLineItems")):
            rows.append({
                "refund_id": r["id"],
                "line_item_id": (rli.get("lineItem") or {}).get("id"),
                "quantity": rli.get("quantity"),
                "restock_type": rli.get("restockType"),
                "location_id": (rli.get("location") or {}).get("id"),
                "subtotal_amount": src.money(rli.get("subtotalSet")),
                "total_tax_amount": src.money(rli.get("totalTaxSet")),
                "extracted_at": run_ts,
            })
    return rows


def main() -> int:
    return src.run_child_loader(
        table=TABLE, query=QUERY, extract_rows=extract_rows,
        key_columns=["refund_id", "line_item_id"], page_size=25,
    )


if __name__ == "__main__":
    raise SystemExit(main())
