"""
stg_order_transactions loader — payments/refunds off Order.transactions.
Scope: read_orders.  Grain: one row per transaction.  Merge key: id.

Order.transactions is a plain list (not a connection). Loads into
<stg_schema>.stg_order_transactions.

Run (from code/etl/):
    python -m shopify_dwh.loaders.transactions [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_order_transactions"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        transactions(first: 50) {
          id
          kind
          status
          gateway
          amountSet { shopMoney { amount currencyCode } }
          createdAt
          processedAt
          errorCode
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "processed_at", "extracted_at"]


def extract_rows(order: dict, run_ts: datetime) -> list[dict]:
    rows = []
    for t in order.get("transactions") or []:
        amount = t.get("amountSet") or {}
        rows.append({
            "id": t["id"],
            "order_id": order["id"],
            "kind": t.get("kind"),
            "status": t.get("status"),
            "gateway": t.get("gateway"),
            "amount": src.money(t.get("amountSet")),
            "currency_code": (amount.get("shopMoney") or {}).get("currencyCode"),
            "created_at": t.get("createdAt"),
            "processed_at": t.get("processedAt"),
            "error_code": t.get("errorCode"),
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
