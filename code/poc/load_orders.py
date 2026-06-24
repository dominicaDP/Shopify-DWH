"""
stg_orders loader (Phase 2.5) — full load, header level only.

Bigger table, harder pagination. Line items are loaded separately (Phase 2.8),
so this query stays at order-header grain to keep query cost low.

Known API-version caveats (2026-04) handled here:
  - landing_site / referring_site / checkout_id: these Order fields were removed in
    favour of customerJourneySummary. Not needed for the POC revenue metric, so we
    NULL them and move on (documented as a finding).
  - email + addresses are protected customer data; we attempt them (owner custom app
    with read_orders) and learn from the run.

Two modes:
  full        — TRUNCATE + reload every order the scope permits (default first run)
  incremental — fetch only orders with updatedAt >= the stored watermark, then
                MERGE on id so a re-run never duplicates (Phase 2.6 / 2.7)

Run:
    python load_orders.py            # auto: full if table empty, else incremental
    python load_orders.py full
    python load_orders.py incremental
"""

import json
import logging
import sys
from datetime import datetime, timezone

import pandas as pd

import exasol_loader as ex
from shopify_client import ShopifyClient

log = logging.getLogger("load_orders")

SCHEMA, TABLE = "SHOPIFY_STG", "stg_orders"

ORDERS_QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        name
        email
        createdAt
        processedAt
        updatedAt
        cancelledAt
        closedAt
        cancelReason
        currencyCode
        subtotalPriceSet      { shopMoney { amount } }
        totalDiscountsSet     { shopMoney { amount } }
        totalTaxSet           { shopMoney { amount } }
        totalShippingPriceSet { shopMoney { amount } }
        totalPriceSet         { shopMoney { amount } }
        totalRefundedSet      { shopMoney { amount } }
        displayFinancialStatus
        displayFulfillmentStatus
        shippingAddress { address1 address2 city province provinceCode countryCodeV2 country zip company name phone }
        billingAddress  { address1 address2 city province provinceCode countryCodeV2 country zip company name phone }
        tags
        note
        sourceName
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = [
    "created_at", "processed_at", "updated_at",
    "cancelled_at", "closed_at", "extracted_at",
]


def _money(money_set: dict | None):
    return (money_set or {}).get("shopMoney", {}).get("amount")


def _addr_json(addr: dict | None):
    return json.dumps(addr, ensure_ascii=False) if addr else None


def _to_row(node: dict, run_ts: datetime) -> dict:
    tags = node.get("tags") or []
    return {
        "id": node["id"],
        "name": node.get("name"),
        "email": node.get("email"),
        "created_at": node["createdAt"],
        "processed_at": node.get("processedAt"),
        "updated_at": node.get("updatedAt"),
        "cancelled_at": node.get("cancelledAt"),
        "closed_at": node.get("closedAt"),
        "cancel_reason": node.get("cancelReason"),
        "currency_code": node.get("currencyCode"),
        "subtotal_price": _money(node.get("subtotalPriceSet")),
        "total_discounts": _money(node.get("totalDiscountsSet")),
        "total_tax": _money(node.get("totalTaxSet")),
        "total_shipping": _money(node.get("totalShippingPriceSet")),
        "total_price": _money(node.get("totalPriceSet")),
        "total_refunded": _money(node.get("totalRefundedSet")),
        "financial_status": node.get("displayFinancialStatus"),
        "fulfillment_status": node.get("displayFulfillmentStatus"),
        "customer_id": None,  # customer{} needs read_customers scope (not granted)
        "shipping_address_json": _addr_json(node.get("shippingAddress")),
        "billing_address_json": _addr_json(node.get("billingAddress")),
        "tags": ",".join(tags) if tags else None,
        "note": node.get("note"),
        "source_name": node.get("sourceName"),
        "landing_site": None,    # removed in 2026-04 API (see module docstring)
        "referring_site": None,  # removed in 2026-04 API
        "checkout_id": None,     # removed in 2026-04 API
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient, query_filter: str | None = None) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = []
    for n in client.paginate(ORDERS_QUERY, ["orders"], variables={"query": query_filter}):
        rows.append(_to_row(n, run_ts))
        if len(rows) % 1000 == 0:
            log.info("  ...%d orders so far", len(rows))
    df = pd.DataFrame(rows)
    if len(df):
        ex.to_naive_utc(df, TIMESTAMP_COLS)
    return df


def _print_summary(conn, loaded: int, mode: str) -> None:
    stats = conn.execute(
        f"""SELECT COUNT(*), COUNT(email), COUNT(shipping_address_json),
                   MIN(created_at), MAX(created_at), SUM(total_price)
            FROM {SCHEMA}.{TABLE}"""
    ).fetchone()
    dupes = conn.execute(
        f"SELECT COUNT(*) FROM (SELECT id FROM {SCHEMA}.{TABLE} GROUP BY id HAVING COUNT(*) > 1)"
    ).fetchone()[0]
    print(f"\n[{mode}] processed {loaded} orders; {TABLE} now holds {stats[0]} rows.")
    print(f"PII completeness  -> email: {stats[1]}/{stats[0]}, shipping_addr: {stats[2]}/{stats[0]}")
    print(f"Date range        -> {stats[3]}  ..  {stats[4]}")
    print(f"Sum(total_price)  -> {stats[5]}")
    print(f"Duplicate ids     -> {dupes}  ({'OK' if dupes == 0 else 'FAIL — not idempotent'})")


def run_full(conn, client) -> int:
    df = extract(client)
    log.info("extracted %d orders (full)", len(df))
    return ex.load_full(conn, SCHEMA, TABLE, df)


def run_incremental(conn, client) -> int:
    watermark = conn.execute(f"SELECT MAX(updated_at) FROM {SCHEMA}.{TABLE}").fetchone()[0]
    if watermark is None:
        log.info("no watermark (table empty) — falling back to full load")
        return run_full(conn, client)
    # Exasol returns TIMESTAMP as a string; normalise then format for Shopify.
    # Shopify expects ISO-8601; >= the watermark so the boundary order is re-fetched
    # and merged idempotently rather than skipped.
    filt = f"updated_at:>={pd.Timestamp(watermark).strftime('%Y-%m-%dT%H:%M:%SZ')}"
    log.info("incremental since watermark %s -> filter '%s'", watermark, filt)
    df = extract(client, query_filter=filt)
    log.info("extracted %d changed orders (incremental)", len(df))
    return ex.merge_upsert(conn, SCHEMA, TABLE, df, key_columns=["id"])


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    mode = sys.argv[1].lower() if len(sys.argv) > 1 else "auto"

    conn = ex.connect()
    try:
        if mode == "auto":
            mode = "incremental" if ex.count(conn, SCHEMA, TABLE) else "full"
        with ShopifyClient.from_env() as client:
            if mode == "full":
                loaded = run_full(conn, client)
            elif mode == "incremental":
                loaded = run_incremental(conn, client)
            else:
                print(f"unknown mode: {mode!r} (use full | incremental)", file=sys.stderr)
                return 2
        _print_summary(conn, loaded, mode)
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
