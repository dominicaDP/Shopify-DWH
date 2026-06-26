"""
stg_products loader — full load.

The smallest STG table: truncate and reload the whole catalogue each run. Ported
from the POC; the only changes are production wiring (config-driven schema +
connection). Loads into <stg_schema>.stg_products.

Run (from code/etl/):
    python -m shopify_dwh.loaders.products
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_products")

TABLE = "stg_products"

PRODUCTS_QUERY = """
query($pageSize: Int!, $cursor: String) {
  products(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        title
        handle
        description
        productType
        vendor
        status
        createdAt
        updatedAt
        publishedAt
        tags
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

TIMESTAMP_COLS = ["created_at", "updated_at", "published_at", "extracted_at"]


def _to_row(node: dict, run_ts: datetime) -> dict:
    tags = node.get("tags") or []
    return {
        "id": node["id"],
        "title": node["title"],
        "handle": node["handle"],
        "description": node["description"],
        "product_type": node["productType"],
        "vendor": node["vendor"],
        "status": node["status"],
        "created_at": node["createdAt"],
        "updated_at": node["updatedAt"],
        "published_at": node["publishedAt"],
        "tags": ",".join(tags) if tags else None,
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = [_to_row(n, run_ts) for n in client.paginate(PRODUCTS_QUERY, ["products"])]
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
    log.info("extracted %d products from Shopify", len(df))

    conn = ex.connect(settings)
    try:
        loaded = ex.load_full(conn, schema, TABLE, df)
        total = ex.count(conn, schema, TABLE)
        sample = conn.execute(
            f"SELECT id, title, status, vendor FROM {schema}.{TABLE} "
            f"ORDER BY created_at DESC LIMIT 5"
        ).fetchall()
    finally:
        conn.close()

    print(f"\nLoaded {loaded} products; {TABLE} now holds {total} rows.")
    print("Most recently created (sample):")
    for row in sample:
        print(f"  {row[0]}  [{row[2]}] {row[3]} — {row[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
