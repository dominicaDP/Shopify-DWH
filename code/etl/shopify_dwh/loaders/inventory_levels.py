"""
stg_inventory_levels loader — daily stock snapshot.   Scope: read_inventory.
Grain: one row per (inventory_item, location, snapshot_date).

Unlike the other STG tables there is no top-level "all inventory levels" query, so we
walk inventoryItems -> each item's inventoryLevels (one per stocking location) ->
the per-state quantities. Each run stamps today's date and idempotently MERGEs on
(inventory_item_id, location_id, snapshot_date).

PRODUCTISATION NOTE — why snapshot, and why one code path:
  The snapshot model is the productizable superset, so "current stock" vs "stock
  history" is a *deployment* choice, not a code fork:
    - run daily            -> accumulates history (sell-through / stock trends)
    - run once / retention=1 -> effectively current-state only (query MAX(snapshot_date))
  This whole module sits behind the `features.include_inventory_levels` flag in
  deployment_config.yaml (default off), and history depth is governed by the
  `retention` config — see productization-strategy.md. The loader just takes a clean
  snapshot; cadence (scheduling, Phase E) and retention (config) do the rest.

Verify at first run: the `quantities(names: [...])` set a given store actually
exposes (names beyond available/on_hand are not guaranteed) and InventoryLevel
field shapes. Missing names simply come back absent -> NULL column.

Run (from code/etl/):
    python -m shopify_dwh.loaders.inventory_levels
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_inventory_levels")

TABLE = "stg_inventory_levels"
KEY_COLUMNS = ["inventory_item_id", "location_id", "snapshot_date"]

# The inventory quantity states the design tracks. Shopify returns a name/quantity
# pair per requested name; unknown/unstocked names come back absent.
QUANTITY_NAMES = ["available", "on_hand", "committed", "incoming", "reserved"]

# inventoryLevels(first:) is bounded by the number of stocking locations per item —
# a small handful — so a modest inner cap won't truncate. The OUTER inventoryItems
# connection is what paginates (one page of items at a time).
LEVELS_PER_ITEM = 20

INVENTORY_QUERY = """
query($pageSize: Int!, $cursor: String) {
  inventoryItems(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        inventoryLevels(first: 20) {
          edges {
            node {
              updatedAt
              location { id }
              quantities(names: ["available","on_hand","committed","incoming","reserved"]) {
                name
                quantity
              }
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

TIMESTAMP_COLS = ["updated_at", "extracted_at"]


def _quantities(qlist: list | None) -> dict:
    """Pivot the [{name, quantity}] list into a name -> quantity dict."""
    return {q["name"]: q.get("quantity") for q in (qlist or [])}


def extract(client: ShopifyClient) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    snapshot_date = run_ts.date()
    rows = []
    items_seen = 0
    truncated_items = 0
    for item in client.paginate(INVENTORY_QUERY, ["inventoryItems"], page_size=200):
        items_seen += 1
        levels = item.get("inventoryLevels") or {}
        for edge in levels.get("edges", []):
            lvl = edge["node"]
            q = _quantities(lvl.get("quantities"))
            rows.append({
                "inventory_item_id": item["id"],
                "location_id": (lvl.get("location") or {}).get("id"),
                "available": q.get("available"),
                "on_hand": q.get("on_hand"),
                "committed": q.get("committed"),
                "incoming": q.get("incoming"),
                "reserved": q.get("reserved"),
                "updated_at": lvl.get("updatedAt"),
                "snapshot_date": snapshot_date,
                "extracted_at": run_ts,
            })
        if (levels.get("pageInfo") or {}).get("hasNextPage"):
            truncated_items += 1
        if items_seen % 1000 == 0:
            log.info("  ...scanned %d items, %d levels", items_seen, len(rows))
    if truncated_items:
        log.warning("%d item(s) stock at >%d locations — levels truncated",
                    truncated_items, LEVELS_PER_ITEM)
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
    log.info("extracted %d inventory levels from Shopify", len(df))

    conn = ex.connect(settings)
    try:
        # MERGE (not truncate): idempotent for same-day re-runs, preserves prior
        # days' snapshots so history accumulates across daily runs.
        merged = ex.merge_upsert(conn, schema, TABLE, df, KEY_COLUMNS)
        stats = conn.execute(
            f"""SELECT COUNT(*), COUNT(DISTINCT snapshot_date),
                       MAX(snapshot_date), COUNT(DISTINCT inventory_item_id),
                       COUNT(DISTINCT location_id)
                FROM {schema}.{TABLE}"""
        ).fetchone()
    finally:
        conn.close()

    print(f"\nSnapshot merged {merged} levels; {TABLE} now holds {stats[0]} rows.")
    print(f"Snapshots held    -> {stats[1]} day(s), latest {stats[2]}")
    print(f"Coverage          -> {stats[3]} items across {stats[4]} location(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
