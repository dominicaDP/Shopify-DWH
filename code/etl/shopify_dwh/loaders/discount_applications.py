"""
stg_order_discount_applications loader — off Order.discountApplications.
Scope: read_orders.  Grain: one row per discount application.
Merge key: (order_id, line_number).

DiscountApplication is an interface; the concrete type (__typename) decides which
of code/title/description is present, so the query uses inline fragments. `value`
is a union (MoneyV2 | PricingPercentageValue). No stable id -> line_number is the
1-based index within the connection. Loads into
<stg_schema>.stg_order_discount_applications.

Verify at first run: the inline-fragment field names against the live API version.

Run (from code/etl/):
    python -m shopify_dwh.loaders.discount_applications [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_order_discount_applications"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        discountApplications(first: 20) {
          edges {
            node {
              __typename
              allocationMethod
              targetType
              value {
                __typename
                ... on MoneyV2 { amount }
                ... on PricingPercentageValue { percentage }
              }
              ... on DiscountCodeApplication { code }
              ... on ManualDiscountApplication { title description }
              ... on AutomaticDiscountApplication { title }
              ... on ScriptDiscountApplication { title }
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
    for i, da in enumerate(src.nodes(order.get("discountApplications")), start=1):
        value = da.get("value") or {}
        rows.append({
            "order_id": order["id"],
            "line_number": i,
            "discount_type": da.get("__typename"),
            "code": da.get("code"),
            "title": da.get("title"),
            "description": da.get("description"),
            "value_type": value.get("__typename"),
            "value_amount": value.get("amount"),
            "value_percentage": value.get("percentage"),
            "target_type": da.get("targetType"),
            "allocation_method": da.get("allocationMethod"),
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
