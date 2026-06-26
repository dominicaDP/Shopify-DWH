"""
stg_customers loader — full load.   Scope: read_customers.

Customers are a dimension source: truncate and reload each run so the rolling
aggregates Shopify maintains (numberOfOrders, amountSpent) stay current. Volume is
small for DYT; revisit incremental-by-updatedAt only if it ever isn't.

API shape (2026-04): email/phone/marketing consent moved off the Customer object
onto defaultEmailAddress / defaultPhoneNumber (the bare email/phone/
emailMarketingConsent fields are deprecated). We read the new objects. Loads into
<stg_schema>.stg_customers.

Run (from code/etl/):
    python -m shopify_dwh.loaders.customers
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_customers")

TABLE = "stg_customers"

CUSTOMERS_QUERY = """
query($pageSize: Int!, $cursor: String) {
  customers(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        firstName
        lastName
        defaultEmailAddress { emailAddress marketingState }
        defaultPhoneNumber  { phoneNumber marketingState }
        createdAt
        updatedAt
        numberOfOrders
        amountSpent { amount }
        defaultAddress { address1 address2 city province provinceCode countryCodeV2 country zip company name phone }
        tags
        note
        taxExempt
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "updated_at", "extracted_at"]


def _int(value):
    """numberOfOrders comes back as a string (UnsignedInt64) — coerce to int."""
    try:
        return int(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _to_row(node: dict, run_ts: datetime) -> dict:
    tags = node.get("tags") or []
    email_obj = node.get("defaultEmailAddress") or {}
    phone_obj = node.get("defaultPhoneNumber") or {}
    address = node.get("defaultAddress")
    return {
        "id": node["id"],
        "email": email_obj.get("emailAddress"),
        "phone": phone_obj.get("phoneNumber"),
        "first_name": node.get("firstName"),
        "last_name": node.get("lastName"),
        "email_marketing_state": email_obj.get("marketingState"),
        "sms_marketing_state": phone_obj.get("marketingState"),
        "created_at": node.get("createdAt"),
        "updated_at": node.get("updatedAt"),
        "number_of_orders": _int(node.get("numberOfOrders")),
        "amount_spent": (node.get("amountSpent") or {}).get("amount"),
        "default_address_json": json.dumps(address, ensure_ascii=False) if address else None,
        "tags": ",".join(tags) if tags else None,
        "note": node.get("note"),
        "tax_exempt": node.get("taxExempt"),
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = []
    for n in client.paginate(CUSTOMERS_QUERY, ["customers"]):
        rows.append(_to_row(n, run_ts))
        if len(rows) % 1000 == 0:
            log.info("  ...%d customers so far", len(rows))
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
    log.info("extracted %d customers from Shopify", len(df))

    conn = ex.connect(settings)
    try:
        loaded = ex.load_full(conn, schema, TABLE, df)
        stats = conn.execute(
            f"""SELECT COUNT(*), COUNT(email), COUNT(phone), COUNT(tags),
                       SUM(number_of_orders), SUM(amount_spent)
                FROM {schema}.{TABLE}"""
        ).fetchone()
    finally:
        conn.close()

    print(f"\nLoaded {loaded} customers; {TABLE} now holds {stats[0]} rows.")
    print(f"Completeness  -> email: {stats[1]}/{stats[0]}, phone: {stats[2]}/{stats[0]}, "
          f"tagged: {stats[3]}/{stats[0]}")
    print(f"Totals        -> orders: {stats[4]}, lifetime spend: {stats[5]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
