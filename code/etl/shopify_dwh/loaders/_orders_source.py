"""
Shared plumbing for the STG tables that hang off the orders query.

Eight staging tables are children of Order — transactions, tax_lines,
discount_applications, shipping_lines, fulfillments, fulfillment_line_items,
refunds, refund_line_items. They all share one shape: paginate orders (full, or
incremental by the stg_orders updated_at watermark), pull one nested collection per
order, and write idempotently. This module owns that plumbing; each child loader
supplies only:

  - `query`: a full orders query whose node selects `id` plus the nested fields it
    needs, and whose `orders(...)` block carries `(first: $pageSize, after: $cursor,
    sortKey: UPDATED_AT, query: $query)` + `pageInfo { hasNextPage endCursor }`.
  - `extract_rows(order_node, run_ts) -> list[dict]`: 0+ child rows for one order.
  - `key_columns`: the merge key (so re-running a window never duplicates).

Idempotency note: incremental uses MERGE on key_columns. For child rows with stable
Shopify ids (transactions, shipping_lines, fulfillments, refunds) and for the
parent-child composites (fulfillment/refund line items) that's exact. tax_lines and
discount_applications are keyed by (order_id, line_number=array index): safe in
practice because an order's tax/discount lines are fixed at creation and don't
change on later updates (which is what triggers an incremental re-pull). If that
assumption ever breaks, switch those two to delete-by-order-then-insert.
"""

from __future__ import annotations

import logging
import sys
from datetime import datetime, timezone
from typing import Callable, Sequence

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("orders_source")

ORDERS_WATERMARK_TABLE = "stg_orders"

RowExtractor = Callable[[dict, datetime], list[dict]]


def money(money_set: dict | None):
    """shopMoney amount out of a *Set field, or None."""
    return (money_set or {}).get("shopMoney", {}).get("amount")


def nodes(connection: dict | None) -> list[dict]:
    """Yield node dicts from a GraphQL connection ({edges:[{node:..}]}) -> list."""
    return [e["node"] for e in (connection or {}).get("edges", [])]


def _extract(client, query, extract_rows, page_size, query_filter, timestamp_cols):
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows: list[dict] = []
    orders_seen = 0
    for order in client.paginate(
        query, ["orders"], variables={"query": query_filter}, page_size=page_size
    ):
        orders_seen += 1
        rows.extend(extract_rows(order, run_ts))
        if orders_seen % 1000 == 0:
            log.info("  ...scanned %d orders, %d rows", orders_seen, len(rows))
    df = pd.DataFrame(rows)
    if len(df):
        ex.to_naive_utc(df, list(timestamp_cols))
    return df


def _summary(conn, schema, table, processed, mode, key_columns):
    key_list = ", ".join(key_columns)
    total = ex.count(conn, schema, table)
    dupes = conn.execute(
        f"SELECT COUNT(*) FROM (SELECT {key_list} FROM {schema}.{table} "
        f"GROUP BY {key_list} HAVING COUNT(*) > 1)"
    ).fetchone()[0]
    print(f"\n[{mode}] processed {processed} rows; {table} now holds {total} rows.")
    print(f"Duplicate keys ({key_list}) -> {dupes}  "
          f"({'OK' if dupes == 0 else 'FAIL — not idempotent'})")


def run_child_loader(
    *,
    table: str,
    query: str,
    extract_rows: RowExtractor,
    key_columns: Sequence[str],
    page_size: int = 100,
    timestamp_cols: Sequence[str] = ("extracted_at",),
) -> int:
    """Full/incremental dispatch for an order-child STG table. Returns an exit code.

    Modes (argv[1]): full | incremental | auto (default: full if empty else incremental).
    """
    settings = load_settings()
    configure_logging(settings)
    schema = settings.exasol.stg_schema
    mode = sys.argv[1].lower() if len(sys.argv) > 1 else "auto"

    conn = ex.connect(settings)
    try:
        if mode == "auto":
            mode = "incremental" if ex.count(conn, schema, table) else "full"

        with ShopifyClient.from_settings(settings) as client:
            if mode == "full":
                df = _extract(client, query, extract_rows, page_size, None, timestamp_cols)
                processed = ex.load_full(conn, schema, table, df)
            elif mode == "incremental":
                wm = conn.execute(
                    f"SELECT MAX(updated_at) FROM {schema}.{ORDERS_WATERMARK_TABLE}"
                ).fetchone()[0]
                if wm is None:
                    log.info("no orders watermark — falling back to full load")
                    df = _extract(client, query, extract_rows, page_size, None, timestamp_cols)
                    processed = ex.load_full(conn, schema, table, df)
                else:
                    filt = f"updated_at:>={pd.Timestamp(wm).strftime('%Y-%m-%dT%H:%M:%SZ')}"
                    log.info("incremental: %s for orders changed since %s", table, wm)
                    df = _extract(client, query, extract_rows, page_size, filt, timestamp_cols)
                    processed = ex.merge_upsert(conn, schema, table, df, key_columns)
            else:
                print(f"unknown mode: {mode!r} (use full | incremental)", file=sys.stderr)
                return 2

        _summary(conn, schema, table, processed, mode, key_columns)
    finally:
        conn.close()
    return 0
