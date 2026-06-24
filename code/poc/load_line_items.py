"""
stg_order_line_items loader (Phase 2.8).

Line items are children of orders, so they're extracted from the orders query's
nested lineItems connection. Confirms the loader pattern generalises from a flat
table to a nested one. This is the revenue-bearing table for the POC metric.

Modes mirror load_orders:
  full        — re-pull every order's lines, TRUNCATE + reload
  incremental — pull lines only for orders changed since stg_orders' watermark,
                MERGE on line id (idempotent)

Inner connection is fetched at lineItems(first: 100); an order with more than 100
lines would be truncated. We log a warning if that ever happens (rare for DYT).

Run:
    python load_line_items.py            # auto: full if empty, else incremental
    python load_line_items.py full
    python load_line_items.py incremental
"""

import logging
import sys
from datetime import datetime, timezone

import pandas as pd

import exasol_loader as ex
from shopify_client import ShopifyClient

log = logging.getLogger("load_line_items")

SCHEMA, TABLE = "SHOPIFY_STG", "stg_order_line_items"
ORDERS_TABLE = "stg_orders"  # watermark source for incremental
ORDERS_PAGE_SIZE = 50        # smaller: each order also pulls up to 100 line nodes
LINE_ITEMS_PER_ORDER = 100

ORDER_LINES_QUERY = """
query($pageSize: Int!, $cursor: String, $query: String) {
  orders(first: $pageSize, after: $cursor, sortKey: UPDATED_AT, query: $query) {
    edges {
      node {
        id
        lineItems(first: 100) {
          edges {
            node {
              id
              title
              variantTitle
              sku
              quantity
              currentQuantity
              unfulfilledQuantity
              fulfillableQuantity
              isGiftCard
              taxable
              requiresShipping
              variant { id product { id } }
              originalUnitPriceSet { shopMoney { amount } }
              originalTotalSet     { shopMoney { amount } }
              totalDiscountSet     { shopMoney { amount } }
              discountedTotalSet   { shopMoney { amount } }
            }
          }
          pageInfo { hasNextPage }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""


def _money(money_set: dict | None):
    return (money_set or {}).get("shopMoney", {}).get("amount")


def _line_row(ln: dict, order_id: str, run_ts: datetime) -> dict:
    variant = ln.get("variant") or {}
    product = variant.get("product") or {}
    return {
        "id": ln["id"],
        "order_id": order_id,
        "variant_id": variant.get("id"),
        "product_id": product.get("id"),
        "title": ln.get("title"),
        "variant_title": ln.get("variantTitle"),
        "sku": ln.get("sku"),
        "quantity": ln.get("quantity"),
        "current_quantity": ln.get("currentQuantity"),
        "unfulfilled_quantity": ln.get("unfulfilledQuantity"),
        "unit_price": _money(ln.get("originalUnitPriceSet")),
        "total_price": _money(ln.get("originalTotalSet")),
        "total_discount": _money(ln.get("totalDiscountSet")),
        "discounted_total": _money(ln.get("discountedTotalSet")),
        "is_gift_card": ln.get("isGiftCard"),
        "taxable": ln.get("taxable"),
        "requires_shipping": ln.get("requiresShipping"),
        "fulfillable_quantity": ln.get("fulfillableQuantity"),
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient, query_filter: str | None = None) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = []
    truncated_orders = 0
    orders_seen = 0
    for order in client.paginate(
        ORDER_LINES_QUERY, ["orders"], variables={"query": query_filter},
        page_size=ORDERS_PAGE_SIZE,
    ):
        orders_seen += 1
        line_conn = order.get("lineItems") or {}
        for edge in line_conn.get("edges", []):
            rows.append(_line_row(edge["node"], order["id"], run_ts))
        if (line_conn.get("pageInfo") or {}).get("hasNextPage"):
            truncated_orders += 1
        if orders_seen % 1000 == 0:
            log.info("  ...scanned %d orders, %d lines", orders_seen, len(rows))
    if truncated_orders:
        log.warning("%d order(s) had >%d line items — lines truncated",
                    truncated_orders, LINE_ITEMS_PER_ORDER)
    df = pd.DataFrame(rows)
    if len(df):
        ex.to_naive_utc(df, ["extracted_at"])
    return df


def _print_summary(conn, processed: int, mode: str) -> None:
    stats = conn.execute(
        f"""SELECT COUNT(*), COUNT(DISTINCT order_id), COUNT(DISTINCT product_id),
                   SUM(quantity), SUM(discounted_total)
            FROM {SCHEMA}.{TABLE}"""
    ).fetchone()
    dupes = conn.execute(
        f"SELECT COUNT(*) FROM (SELECT id FROM {SCHEMA}.{TABLE} GROUP BY id HAVING COUNT(*) > 1)"
    ).fetchone()[0]
    print(f"\n[{mode}] processed {processed} lines; {TABLE} now holds {stats[0]} rows.")
    print(f"Distinct orders   -> {stats[1]}")
    print(f"Distinct products -> {stats[2]}")
    print(f"Sum(quantity)     -> {stats[3]}")
    print(f"Sum(discounted)   -> {stats[4]}")
    print(f"Duplicate ids     -> {dupes}  ({'OK' if dupes == 0 else 'FAIL — not idempotent'})")


def run_full(conn, client) -> int:
    df = extract(client)
    log.info("extracted %d line items (full)", len(df))
    return ex.load_full(conn, SCHEMA, TABLE, df)


def run_incremental(conn, client) -> int:
    watermark = conn.execute(f"SELECT MAX(updated_at) FROM {SCHEMA}.{ORDERS_TABLE}").fetchone()[0]
    if watermark is None:
        log.info("no orders watermark — falling back to full load")
        return run_full(conn, client)
    filt = f"updated_at:>={pd.Timestamp(watermark).strftime('%Y-%m-%dT%H:%M:%SZ')}"
    log.info("incremental: lines for orders changed since %s", watermark)
    df = extract(client, query_filter=filt)
    log.info("extracted %d line items (incremental)", len(df))
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
                processed = run_full(conn, client)
            elif mode == "incremental":
                processed = run_incremental(conn, client)
            else:
                print(f"unknown mode: {mode!r} (use full | incremental)", file=sys.stderr)
                return 2
        _print_summary(conn, processed, mode)
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
