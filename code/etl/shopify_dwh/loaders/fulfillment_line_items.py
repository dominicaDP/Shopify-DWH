"""
stg_fulfillment_line_items loader — off Order.fulfillments.fulfillmentLineItems.
Scope: read_orders.  Grain: one row per fulfilled line item.
Merge key: (fulfillment_id, line_item_id).

Doubly nested (orders -> fulfillments -> fulfillmentLineItems connection), so the
orders page size is kept small. Loads into <stg_schema>.stg_fulfillment_line_items.

Verify at first run: the money field name — schema-layered.md maps discounted_total
to `discountedTotalPriceSet`, but the live FulfillmentLineItem field is most likely
`discountedTotalSet`. We read `discountedTotalSet` and fall back to None; confirm and
align the design doc once the API confirms it.

Run (from code/etl/):
    python -m shopify_dwh.loaders.fulfillment_line_items [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_fulfillment_line_items"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        fulfillments(first: 20) {
          id
          fulfillmentLineItems(first: 100) {
            edges {
              node {
                lineItem { id }
                quantity
                originalTotalSet   { shopMoney { amount } }
                discountedTotalSet { shopMoney { amount } }
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
    for f in order.get("fulfillments") or []:
        for fli in src.nodes(f.get("fulfillmentLineItems")):
            rows.append({
                "fulfillment_id": f["id"],
                "line_item_id": (fli.get("lineItem") or {}).get("id"),
                "quantity": fli.get("quantity"),
                "original_total": src.money(fli.get("originalTotalSet")),
                "discounted_total": src.money(fli.get("discountedTotalSet")),
                "extracted_at": run_ts,
            })
    return rows


def main() -> int:
    return src.run_child_loader(
        table=TABLE, query=QUERY, extract_rows=extract_rows,
        key_columns=["fulfillment_id", "line_item_id"], page_size=25,
    )


if __name__ == "__main__":
    raise SystemExit(main())
