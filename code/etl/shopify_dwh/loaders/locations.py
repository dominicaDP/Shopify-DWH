"""
stg_locations loader — full load.

A small dimension (a handful of fulfillment/store locations): truncate and reload
each run. Mirrors the products loader. Loads into <stg_schema>.stg_locations.

Scope note: the `locations` query is generally readable alongside read_orders /
read_inventory; if it returns an access error, the dedicated `read_locations`
scope is needed (add it the same way as the other scopes — see build-plan).

Run (from code/etl/):
    python -m shopify_dwh.loaders.locations
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import pandas as pd

from shopify_dwh import exasol_loader as ex
from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.shopify_client import ShopifyClient

log = logging.getLogger("load_locations")

TABLE = "stg_locations"

LOCATIONS_QUERY = """
query($pageSize: Int!, $cursor: String) {
  locations(first: $pageSize, after: $cursor) {
    edges {
      node {
        id
        name
        isActive
        fulfillsOnlineOrders
        address {
          address1
          address2
          city
          province
          provinceCode
          country
          countryCode
          zip
          phone
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""


def _to_row(node: dict, run_ts: datetime) -> dict:
    addr = node.get("address") or {}
    return {
        "id": node["id"],
        "name": node.get("name"),
        "address1": addr.get("address1"),
        "address2": addr.get("address2"),
        "city": addr.get("city"),
        "province": addr.get("province"),
        "province_code": addr.get("provinceCode"),
        "country": addr.get("country"),
        "country_code": addr.get("countryCode"),
        "zip": addr.get("zip"),
        "phone": addr.get("phone"),
        "is_active": node.get("isActive"),
        "fulfills_online_orders": node.get("fulfillsOnlineOrders"),
        "extracted_at": run_ts,
    }


def extract(client: ShopifyClient) -> pd.DataFrame:
    run_ts = datetime.now(timezone.utc).replace(tzinfo=None)
    rows = [_to_row(n, run_ts) for n in client.paginate(LOCATIONS_QUERY, ["locations"])]
    df = pd.DataFrame(rows)
    if len(df):
        ex.to_naive_utc(df, ["extracted_at"])
    return df


def main() -> int:
    settings = load_settings()
    configure_logging(settings)
    schema = settings.exasol.stg_schema

    with ShopifyClient.from_settings(settings) as client:
        df = extract(client)
    log.info("extracted %d locations from Shopify", len(df))

    conn = ex.connect(settings)
    try:
        loaded = ex.load_full(conn, schema, TABLE, df)
        total = ex.count(conn, schema, TABLE)
        sample = conn.execute(
            f"SELECT name, city, country_code, is_active FROM {schema}.{TABLE} ORDER BY name"
        ).fetchall()
    finally:
        conn.close()

    print(f"\nLoaded {loaded} locations; {TABLE} now holds {total} rows.")
    for row in sample:
        print(f"  {row[0]} — {row[1]}, {row[2]}  (active={row[3]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
