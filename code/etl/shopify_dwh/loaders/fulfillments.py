"""
stg_fulfillments loader — off Order.fulfillments.
Scope: read_orders.  Grain: one row per fulfillment (shipment).  Merge key: id.

Order.fulfillments is a plain list. trackingInfo is itself a list — we take the
first entry. Loads into <stg_schema>.stg_fulfillments.

Verify at first run (fields that vary by API version / couldn't be tested without
the live API): `location { id }`, `service { serviceName }`, and the
`trackingInfo(first: 1)` shape. If any errors, drop that selection and NULL the
column (POC precedent for API-removed fields).

Run (from code/etl/):
    python -m shopify_dwh.loaders.fulfillments [full|incremental]
"""

from __future__ import annotations

from datetime import datetime

from shopify_dwh.loaders import _orders_source as src

TABLE = "stg_fulfillments"

QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        fulfillments(first: 20) {
          id
          status
          displayStatus
          totalQuantity
          createdAt
          updatedAt
          location { id }
          service { serviceName }
          trackingInfo(first: 1) { number company url }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "updated_at", "extracted_at"]


def extract_rows(order: dict, run_ts: datetime) -> list[dict]:
    rows = []
    for f in order.get("fulfillments") or []:
        tracking = (f.get("trackingInfo") or [{}])
        track0 = tracking[0] if tracking else {}
        rows.append({
            "id": f["id"],
            "order_id": order["id"],
            "status": f.get("status"),
            "created_at": f.get("createdAt"),
            "updated_at": f.get("updatedAt"),
            "tracking_number": track0.get("number"),
            "tracking_company": track0.get("company"),
            "tracking_url": track0.get("url"),
            "location_id": (f.get("location") or {}).get("id"),
            "service": (f.get("service") or {}).get("serviceName"),
            "shipment_status": f.get("displayStatus"),
            "total_quantity": f.get("totalQuantity"),
            "extracted_at": run_ts,
        })
    return rows


def main() -> int:
    return src.run_child_loader(
        table=TABLE, query=QUERY, extract_rows=extract_rows,
        key_columns=["id"], page_size=50, timestamp_cols=TIMESTAMP_COLS,
    )


if __name__ == "__main__":
    raise SystemExit(main())
