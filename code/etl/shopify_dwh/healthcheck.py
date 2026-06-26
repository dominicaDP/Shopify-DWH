"""
Gate A health check — the two-sided smoke test for the production scaffold.

Confirms the shared modules can reach BOTH ends of the pipeline against the real
hosts:
  - Exasol: SELECT 1 + report the DB version (and confirm the two target schemas
    are visible, if they exist yet)
  - Shopify: fetch the shop identity via GraphQL and echo the bucket status

This is what "Gate A passes" means in build-plan.md. It needs the external
prerequisites done first: a reachable Exasol with the ETL user/credentials, and a
Shopify token with the production scopes.

Run (from code/etl/):
    python -m shopify_dwh.healthcheck
"""

from __future__ import annotations

import sys

from shopify_dwh.config import configure_logging, load_settings
from shopify_dwh.exasol_loader import connect
from shopify_dwh.shopify_client import ShopifyClient, ShopifyError

_SHOP_QUERY = """
{
  shop {
    name
    myshopifyDomain
    primaryDomain { url }
    currencyCode
    ianaTimezone
  }
}
"""


def check_exasol(settings) -> bool:
    print("Exasol")
    print("------")
    try:
        conn = connect(settings)
    except Exception as e:
        print(f"  FAIL  could not connect: {type(e).__name__}: {e}")
        return False
    try:
        one = conn.execute("SELECT 1").fetchone()[0]
        version = conn.execute(
            "SELECT PARAM_VALUE FROM EXA_METADATA "
            "WHERE PARAM_NAME = 'databaseProductVersion'"
        ).fetchone()[0]
        schemas = [
            r[0]
            for r in conn.execute(
                "SELECT SCHEMA_NAME FROM SYS.EXA_SCHEMAS "
                "WHERE SCHEMA_NAME IN ({stg}, {dwh})",
                {
                    "stg": settings.exasol.stg_schema.upper(),
                    "dwh": settings.exasol.dwh_schema.upper(),
                },
            ).fetchall()
        ]
        print(f"  OK    SELECT 1 = {one}")
        print(f"  OK    DB version: {version}")
        print(f"  user: {settings.exasol.user} @ {settings.exasol.dsn}")
        present = ", ".join(schemas) if schemas else "(neither yet — expected pre-Phase B)"
        print(f"  target schemas present: {present}")
        return True
    except Exception as e:
        print(f"  FAIL  query failed: {type(e).__name__}: {e}")
        return False
    finally:
        conn.close()


def check_shopify(settings) -> bool:
    print("\nShopify")
    print("-------")
    try:
        with ShopifyClient.from_settings(settings) as client:
            shop = client.execute(_SHOP_QUERY)["shop"]
            print(f"  OK    {shop['name']} ({shop['myshopifyDomain']})")
            print(f"  primary domain: {shop['primaryDomain']['url']}")
            print(f"  currency: {shop['currencyCode']}   tz: {shop['ianaTimezone']}")
            print(f"  scopes configured: {settings.shopify.scopes or '(none set)'}")
            if client._throttle:
                t = client._throttle
                print(
                    f"  bucket: {t.get('currentlyAvailable')}/{t.get('maximumAvailable')} "
                    f"pts, restoring {t.get('restoreRate')}/s"
                )
        return True
    except ShopifyError as e:
        print(f"  FAIL  {e}")
        return False
    except Exception as e:
        print(f"  FAIL  {type(e).__name__}: {e}")
        return False


def main() -> int:
    settings = load_settings()
    configure_logging(settings)

    exa_ok = check_exasol(settings)
    shop_ok = check_shopify(settings)

    print("\n" + "=" * 40)
    if exa_ok and shop_ok:
        print("Gate A: GREEN — both ends reachable.")
        return 0
    print("Gate A: NOT green — see failures above.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
