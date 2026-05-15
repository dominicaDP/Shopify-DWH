"""
Phase 0 / Stream C gate test: fetch shop name via GraphQL.

If this prints the shop name, the Shopify side of Phase 0 is done.

Run:
    python shopify_hello.py
"""

import os
import sys
from pathlib import Path

import httpx
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

SHOP_DOMAIN = os.environ["SHOPIFY_SHOP_DOMAIN"]
API_VERSION = os.environ["SHOPIFY_API_VERSION"]
TOKEN = os.environ["SHOPIFY_ACCESS_TOKEN"]

if not TOKEN:
    print("SHOPIFY_ACCESS_TOKEN is empty. Run oauth_install.py first.", file=sys.stderr)
    sys.exit(1)

URL = f"https://{SHOP_DOMAIN}/admin/api/{API_VERSION}/graphql.json"

QUERY = """
{
  shop {
    name
    email
    myshopifyDomain
    primaryDomain { url }
    currencyCode
    ianaTimezone
  }
}
"""


def main() -> int:
    resp = httpx.post(
        URL,
        json={"query": QUERY},
        headers={
            "X-Shopify-Access-Token": TOKEN,
            "Content-Type": "application/json",
        },
        timeout=30.0,
    )
    resp.raise_for_status()
    data = resp.json()

    if "errors" in data:
        print("GraphQL errors:", data["errors"], file=sys.stderr)
        return 1

    shop = data["data"]["shop"]
    print(f"\nConnected to Shopify successfully:")
    print(f"  Name:       {shop['name']}")
    print(f"  Domain:     {shop['myshopifyDomain']}")
    print(f"  Primary:    {shop['primaryDomain']['url']}")
    print(f"  Email:      {shop['email']}")
    print(f"  Currency:   {shop['currencyCode']}")
    print(f"  Timezone:   {shop['ianaTimezone']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
