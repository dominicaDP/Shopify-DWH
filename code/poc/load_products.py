"""
stg_products loader (Phase 2.3) — full load.

The smallest of the four POC tables, so it's the first end-to-end proof that the
Shopify client + Exasol loader round-trip works on real data. Full load only:
truncate stg_products and reload the whole catalogue each run.

Run:
    python load_products.py
"""

import logging
from datetime import datetime, timezone

import pandas as pd

import exasol_loader as ex
from shopify_client import ShopifyClient

log = logging.getLogger("load_products")

SCHEMA, TABLE = "SHOPIFY_STG", "stg_products"

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
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    with ShopifyClient.from_env() as client:
        df = extract(client)
    log.info("extracted %d products from Shopify", len(df))

    conn = ex.connect()
    try:
        loaded = ex.load_full(conn, SCHEMA, TABLE, df)
        total = ex.count(conn, SCHEMA, TABLE)
        sample = conn.execute(
            f"SELECT id, title, status, vendor FROM {SCHEMA}.{TABLE} "
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
