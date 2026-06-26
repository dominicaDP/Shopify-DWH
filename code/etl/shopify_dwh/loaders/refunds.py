"""
stg_refunds loader — off Order.refunds.
Scope: read_orders.  Grain: one row per refund.  Merge key: id.

Order.refunds is a plain list. Loads into <stg_schema>.stg_refunds.

Run (from code/etl/):
    python -m shopify_dwh.loaders.refunds [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_refunds"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        refunds(first: 30) {
          id
          createdAt
          note
          totalRefundedSet { shopMoney { amount } }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "extracted_at"]


def extract_rows(order: dict, run_ts: datetime) -> list[dict]:
    rows = []
    for r in order.get("refunds") or []:
        rows.append({
            "id": r["id"],
            "order_id": order["id"],
            "created_at": r.get("createdAt"),
            "note": r.get("note"),
            "total_refunded": src.money(r.get("totalRefundedSet")),
            "extracted_at": run_ts,
        })
    return rows


def main() -> int:
    return src.run_child_loader(
        table=TABLE, query=QUERY, extract_rows=extract_rows,
        key_columns=["id"], page_size=100, timestamp_cols=TIMESTAMP_COLS,
    )


if __name__ == "__main__":
    raise SystemExit(main())
