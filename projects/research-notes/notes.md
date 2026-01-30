# Notes

**Project:** Shopify DWH Research
**Last Updated:** 2026-01-30

---

## Research Log

### 2026-01-29 - Project Setup & Business Context

**Topic:** Dress Your Tech Business Model

**Key Understanding:**
- B2B2C model, NOT traditional ecommerce
- Primary revenue: voucher-based value-added products
- Corporate clients (e.g., telecoms) attach vouchers to their products
- End consumers redeem vouchers on Dress Your Tech
- Gamatek handles fulfillment

**Data Flow:**
```
Corporate Client → Issues Voucher → Consumer → Redeems on DYT → Order → Gamatek Fulfills
```

**Implications for DWH:**
- Need to track voucher issuance (from where?)
- Track redemption (Shopify orders with discount codes?)
- Attribution back to corporate clients
- Standard ecommerce metrics (AOV, conversion) less relevant

**Open Questions:**
- How are vouchers issued and tracked?
- What data comes from Shopify vs. other systems?
- How to identify which corporate client a redemption belongs to?

---

### 2026-01-29 - Second Brain Setup

**Topic:** Knowledge Management System

**What I learned:**
- Three-layer architecture: Commands → Skills → Memory
- Progressive disclosure pattern for managing complexity
- Pattern confidence levels (LOW → MEDIUM → HIGH)

**Key Commands:**
- `/overview` - Daily dashboard
- `/switch [project]` - Context switching
- `/learn` - Extract patterns from work
- `/recall [topic]` - Search memory
- `/grow` - Brain health metrics

---

### 2026-01-29 - Competitive Landscape Research

**Topic:** Shopify Analytics & DWH Market

#### Market Segments

| Layer | What It Does | Examples |
|-------|--------------|----------|
| ETL/ELT Tools | Move data from Shopify → Warehouse | Fivetran, Airbyte, Stitch, Skyvia |
| Pre-built Data Models | Transform raw data into analytics-ready schema | Fivetran dbt packages, dlt-hub |
| Analytics Platforms | End-user dashboards and reporting | Triple Whale, Polar Analytics, Lifetimely |

#### ETL/ELT Tools

| Tool | Type | Pricing | Notes |
|------|------|---------|-------|
| Fivetran | Managed SaaS | Free tier (500k rows), Enterprise $10k+/mo | Market leader. 2025 pricing changes increased costs 40-70%. |
| Airbyte | Open-source + Cloud | Self-hosted free, Cloud ~$2.50/credit | 550+ connectors. More technical effort required. |
| Stitch | Managed SaaS | Volume-based | Owned by Talend. High-speed processing. |
| Panoply | ETL + Warehouse | SaaS pricing | Includes built-in warehouse. |
| Skyvia | Cloud platform | Tiered | Supports reverse ETL. |

#### Pre-built Data Models (dbt)

| Source | What It Provides |
|--------|------------------|
| Fivetran Shopify dbt | Source models, transform models, `shopify__line_item_enhanced` fact table |
| Fivetran Holistic | Combines Shopify with Klaviyo for marketing attribution |
| dlt-hub Shopify dbt | Staging + mart models (dimensions/facts) |

**Key insight:** Fivetran's model uses denormalized `line_item_enhanced` - similar to our approach.

#### Analytics Platforms

| Platform | Focus | Pricing | Target |
|----------|-------|---------|--------|
| Triple Whale | Attribution, first-party pixel, LTV | ~$429/mo for $1M GMV | DTC brands, agencies |
| Polar Analytics | BI tool, custom metrics | ~$720/mo+ | Data-savvy teams |
| Lifetimely | Customer LTV, cohort analysis | Lower tier | Retention-focused |
| BeProfit | Profit tracking | Budget-friendly | Small merchants |

#### Gap Analysis

| Gap | Opportunity |
|-----|-------------|
| Exasol not supported | Most tools target Snowflake/BigQuery/Redshift. Exasol = differentiation. |
| Expensive at scale | Fivetran pricing jumps significantly. Lower-cost alternative could win mid-market. |
| Generic, not customizable | Pre-built models are opinionated. Modular, extensible base appeals to technical teams. |
| No B2B2C focus | All solutions assume B2C. Voucher/corporate attribution unaddressed. |
| Bundled solutions | ETL, models, warehouse often sold separately. All-in-one could simplify. |

#### Recommended Positioning

1. **Exasol-native** - First Shopify DWH optimized for Exasol (genuine differentiation)
2. **Generic base** - Productizable foundation (what we're building)
3. **B2B2C/voucher module** - DYT-specific layer proves extensibility
4. **Price below Fivetran + analytics bundles** - Mid-market appeal

#### Sources

- https://www.fivetran.com/connectors/shopify
- https://airbyte.com/top-etl-tools-for-sources/shopify
- https://fivetran.com/docs/transformations/data-models/shopify-data-model
- https://github.com/dlt-hub/dlt-dbt-shopify
- https://www.polaranalytics.com/compare/triplewhale-alternative-for-shopify
- https://reportgenix.com/top-10-shopify-analytics-apps/

---

## Shopify Data Notes

### 2026-01-29 - Product API Research

**Source:** Shopify REST Admin API - Product Resource

#### Product Entity Structure

| Field | Type | DWH Mapping |
|-------|------|-------------|
| `id` | integer (int64) | → product_id |
| `title` | string | → title |
| `handle` | string | *Consider adding* |
| `body_html` | string | Out of scope |
| `vendor` | string | → vendor |
| `product_type` | string | → product_type |
| `status` | string | → status (active/archived/draft) |
| `created_at` | datetime | → created_at |
| `updated_at` | datetime | *Consider adding* |
| `published_at` | datetime | Out of scope |
| `tags` | string (comma-sep) | → tags |

#### Variant Entity Structure (nested under Product)

| Field | Type | DWH Mapping |
|-------|------|-------------|
| `id` | integer | → variant_id |
| `product_id` | integer | → product_id |
| `title` | string | → variant_title |
| `price` | string (numeric) | → price |
| `sku` | string | → sku |
| `option1/2/3` | string | *Consider adding* |
| `taxable` | boolean | → taxable |
| `requires_shipping` | boolean | → requires_shipping |
| `weight` | decimal | → weight |
| `weight_unit` | string | → weight_unit |
| `compare_at_price` | string/null | → compare_at_price |
| `barcode` | string | *Consider adding* |
| `inventory_quantity` | integer | Separate inventory fact |
| `grams` | integer | Redundant (use weight) |

#### Cost Field Note

**Important:** `cost` is NOT in the Product API.

Cost comes from the **InventoryItem** resource:
```
Variant.inventory_item_id → InventoryItem.cost
```

Need separate API call to fetch cost data. Consider:
- Joining during ETL
- Separate dim_inventory_item
- Nullable cost in dim_product (populated from InventoryItem)

#### Schema Validation

**Current dim_product coverage:** ✅ Good
- All critical fields mapped
- Grain correct (variant level)

**Potential additions:**
| Field | Priority | Status |
|-------|----------|--------|
| `handle` | LOW | Deferred - rarely needed for analytics |
| `barcode` | MEDIUM | ✅ Added to schema |
| `option1/2/3` | MEDIUM | ✅ Added to schema |
| `updated_at` | LOW | Deferred - ETL metadata sufficient |

#### API Migration Alert

⚠️ **REST API Deprecation:**
- REST Product API is **legacy** as of October 1, 2024
- GraphQL Admin API **required** for new apps from April 1, 2025
- Recommendation: Build ETL against GraphQL from the start

### 2026-01-30 - InventoryItem API Research

**Source:** Shopify GraphQL Admin API - InventoryItem, InventoryLevel, InventoryQuantity

#### InventoryItem Object

| Field | Type | DWH Relevance |
|-------|------|---------------|
| `id` | ID | → inventory_item_id |
| `unitCost` | MoneyV2 | → cost (amount + currencyCode) ⭐ |
| `sku` | String | Duplicate of variant.sku |
| `tracked` | Boolean | Whether inventory is tracked |
| `requiresShipping` | Boolean | Physical product flag |
| `countryCodeOfOrigin` | String | For customs/international |
| `harmonizedSystemCode` | String | HS tariff code |
| `provinceCodeOfOrigin` | String | Origin province |
| `measurement` | Object | Weight/dimensions |
| `createdAt` / `updatedAt` | DateTime | Timestamps |

**Access:** `ProductVariant.inventoryItem`
**Scope Required:** `read_inventory` or `read_products`

#### MoneyV2 Type (for unitCost)

```graphql
unitCost {
  amount    # Decimal string, e.g., "12.99"
  currencyCode  # ISO currency, e.g., "USD"
}
```

#### InventoryLevel Object

**Grain:** One row per InventoryItem per Location

| Field | Type | Notes |
|-------|------|-------|
| `id` | ID | PK |
| `item` | InventoryItem | Parent item |
| `location` | Location | Stock location |
| `quantities` | [InventoryQuantity] | Stock by state |
| `createdAt` / `updatedAt` | DateTime | Timestamps |

#### InventoryQuantity Object

Normalized structure for quantity states:

| Field | Type | Notes |
|-------|------|-------|
| `name` | String | State name (available, on_hand, committed, incoming, reserved, etc.) |
| `quantity` | Int | Quantity in that state |

**Example states:** available, on_hand, committed, incoming, reserved, damaged, quality_control, safety_stock

#### Query Paths

**For Cost Data:**
```graphql
query {
  products(first: 50) {
    edges {
      node {
        variants(first: 100) {
          edges {
            node {
              id
              sku
              inventoryItem {
                unitCost {
                  amount
                  currencyCode
                }
              }
            }
          }
        }
      }
    }
  }
}
```

**For Inventory Levels:**
```graphql
query {
  inventoryItems(first: 50) {
    edges {
      node {
        id
        sku
        inventoryLevels(first: 10) {
          edges {
            node {
              location { name }
              quantities(names: ["available", "on_hand", "committed"]) {
                name
                quantity
              }
            }
          }
        }
      }
    }
  }
}
```

#### Bulk Operations

For large data extraction:
- Use `bulkOperationRunQuery` mutation
- Output: JSONL format
- Results available for 7 days
- Limit: 1 bulk query + 1 bulk mutation per shop concurrently
- Max 5 connections, depth of 2

#### ETL Implications

| Consideration | Decision |
|---------------|----------|
| Cost extraction | Join via `ProductVariant.inventoryItem.unitCost` during ETL |
| Multi-currency | Store both amount and currencyCode (may need conversion) |
| Multi-location | If needed: add dim_location + fact_inventory_level |
| Current schema | `dim_product.cost` is nullable - populate from InventoryItem |

#### Schema Impact

**dim_product** (no changes needed):
- `cost` field already exists as DECIMAL(18,2) nullable
- ETL will join Product → Variant → InventoryItem to populate

**Future consideration - Inventory domain:**
```
dim_location (if multi-location)
├── location_key
├── location_id
├── name
├── address fields...

fact_inventory_level (per item per location per snapshot)
├── inventory_level_key
├── product_key (FK)
├── location_key (FK)
├── snapshot_date_key (FK)
├── quantity_available
├── quantity_on_hand
├── quantity_committed
├── quantity_incoming
```

---

### 2026-01-30 - Discount/Voucher API Research

**Source:** Shopify GraphQL Admin API - Discounts, DiscountCode*, DiscountApplication

#### Discount System Overview

Shopify has two discount mechanisms:
1. **Code Discounts** - Customer enters a code at checkout
2. **Automatic Discounts** - Applied automatically when conditions met

**Discount Classes:**
| Class | Applies To |
|-------|------------|
| Product | Specific items (cart operations) |
| Order | Entire purchase amount |
| Shipping | Delivery costs |

#### Discount Code Types

| Type | Description | Key Fields |
|------|-------------|------------|
| **DiscountCodeBasic** | Fixed amount or percentage off | title, codes, customerGets, usageLimit |
| **DiscountCodeBxgy** | Buy X Get Y promotions | customerBuys, customerGets, usesPerOrderLimit |
| **DiscountCodeFreeShipping** | Waive shipping costs | maximumShippingPrice, destinationSelection |
| **DiscountCodeApp** | Custom app-defined discounts | App-specific |

#### Key Objects

**DiscountCodeNode** (Container)
```graphql
query {
  codeDiscountNodes(first: 50) {
    nodes {
      id
      codeDiscount {
        ... on DiscountCodeBasic {
          title
          status
          startsAt
          endsAt
          usageLimit
          asyncUsageCount
          appliesOncePerCustomer
          codes(first: 10) {
            nodes {
              code
              id
              asyncUsageCount
            }
          }
          customerGets {
            value {
              ... on MoneyV2 { amount, currencyCode }
              ... on PricingPercentageValue { percentage }
            }
          }
        }
      }
    }
  }
}
```

**DiscountRedeemCode** (Individual Codes)
| Field | Type | Description |
|-------|------|-------------|
| `id` | ID | Unique identifier |
| `code` | String | The code customers enter (e.g., "SUMMER20") |
| `asyncUsageCount` | Int! | Redemption count (updated asynchronously) |
| `createdBy` | App/User | Who created the code |

**PricingValue** (Union Type)
- `MoneyV2` - Fixed amount { amount, currencyCode }
- `PricingPercentageValue` - Percentage { percentage }

#### Discounts on Orders

**Order-Level Fields:**
| Field | Description |
|-------|-------------|
| `discountCodes` | Array of codes applied |
| `discountApplications` | How discounts were applied |
| `totalDiscountsSet` | Total discount amount (MoneyBag) |

**DiscountApplication Interface:**
| Field | Description |
|-------|-------------|
| `allocationMethod` | How discount distributes (ACROSS, EACH, ONE) |
| `targetSelection` | Which items (ALL, ENTITLED, EXPLICIT) |
| `targetType` | LINE_ITEM or SHIPPING_LINE |
| `value` | PricingValue (amount or percentage) |

**Implementing Types:**
- `DiscountCodeApplication` - Code-based (has `code` field)
- `AutomaticDiscountApplication` - Auto-applied
- `ManualDiscountApplication` - Staff-applied
- `ScriptDiscountApplication` - Shopify Scripts

#### Discounts on Line Items

**LineItem Fields:**
| Field | Description |
|-------|-------------|
| `discountAllocations` | Allocated discount amounts |
| `originalTotalSet` | Price before discounts |
| `discountedTotalSet` | Price after discounts |
| `totalDiscountSet` | Computed discount amount |

#### Query Example - Orders with Discount Details

```graphql
query {
  orders(first: 50) {
    nodes {
      id
      name
      discountCodes
      totalDiscountsSet {
        shopMoney { amount, currencyCode }
      }
      discountApplications(first: 5) {
        nodes {
          ... on DiscountCodeApplication {
            code
            allocationMethod
            targetType
            value {
              ... on MoneyV2 { amount, currencyCode }
              ... on PricingPercentageValue { percentage }
            }
          }
        }
      }
      lineItems(first: 50) {
        nodes {
          title
          originalTotalSet { shopMoney { amount } }
          discountedTotalSet { shopMoney { amount } }
          totalDiscountSet { shopMoney { amount } }
        }
      }
    }
  }
}
```

#### DWH Schema Implications

**Current dim_discount Assessment:**
| Current Field | API Source | Status |
|---------------|------------|--------|
| discount_key | Generated | ✓ |
| discount_code | DiscountRedeemCode.code | ✓ |
| discount_type | DiscountCodeBasic/Bxgy/FreeShipping | ✓ |
| value | customerGets.value.amount or percentage | ✓ |
| value_type | MoneyV2 vs PricingPercentageValue | ✓ |
| target_type | DiscountApplication.targetType | ✓ |
| allocation_method | DiscountApplication.allocationMethod | ✓ |

**Potential Additions:**
| Field | Source | Priority |
|-------|--------|----------|
| title | DiscountCodeBasic.title | MEDIUM |
| starts_at | DiscountCodeBasic.startsAt | LOW |
| ends_at | DiscountCodeBasic.endsAt | LOW |
| usage_limit | DiscountCodeBasic.usageLimit | MEDIUM |
| usage_count | asyncUsageCount | HIGH (for redemption tracking) |
| applies_once_per_customer | Boolean | LOW |

**B2B2C Voucher Considerations:**
- Shopify discount codes = your vouchers
- `asyncUsageCount` tracks redemptions
- Corporate client attribution NOT in Shopify (confirmed out of scope for Layer 1)
- Layer 2 will need external data source for client attribution

#### Required Scopes

- `read_discounts` - Query discount codes
- `write_discounts` - Create/modify discounts (if needed)

#### Sources

- [DiscountCodeBasic](https://shopify.dev/docs/api/admin-graphql/latest/objects/DiscountCodeBasic)
- [DiscountRedeemCode](https://shopify.dev/docs/api/admin-graphql/latest/objects/discountredeemcode)
- [Order Query](https://shopify.dev/docs/api/admin-graphql/latest/queries/order)
- [Discounts Overview](https://shopify.dev/docs/apps/build/discounts)

---

### Key Entities to Research
- ~~Products (mobile accessories)~~ ✅ Done
- ~~InventoryItem (for cost data)~~ ✅ Done
- ~~Discount Codes (vouchers)~~ ✅ Done
- Orders (redemptions)
- Customers (end consumers)
- Metafields (custom data?)

### API Considerations
- ~~REST API vs GraphQL~~ → **Use GraphQL** (REST being deprecated)
- Rate limits
- Historical data access

---

### 2026-01-30 - ETL Tooling Evaluation

**Goal:** Custom-built ETL running on Linux (same machine as Exasol) with configurable scheduling.

#### Decision: Custom Python ETL

**Rationale for rejecting off-the-shelf solutions:**
| Solution | Issue |
|----------|-------|
| Fivetran | Cost prohibitive (~$10k+/mo at scale), pricing increased 40-70% in 2025 |
| Airbyte Cloud | Still significant cost, adds external dependency |
| Airbyte Self-Hosted | Heavy infrastructure (Docker/K8s), overkill for single source |

**Custom approach benefits:**
- Full control over logic and scheduling
- Runs on existing infrastructure (Exasol Linux box)
- No ongoing licensing costs
- Can optimize for Exasol-specific bulk loading
- Productizable as part of the DWH offering

---

#### Recommended Tech Stack

| Component | Technology | Notes |
|-----------|------------|-------|
| **Language** | Python 3.10+ | Required for PyExasol 2.0 |
| **Shopify Client** | `shopify_python_api` or custom GraphQL | Official library supports GraphQL |
| **Exasol Driver** | `pyexasol` 2.0 | Fast bulk loading, pandas integration |
| **Scheduler** | systemd timers (preferred) or cron | See comparison below |
| **Config** | YAML or environment files | Store credentials securely |
| **Logging** | Python `logging` + journald | Structured logs for debugging |

---

#### Shopify Data Extraction

**Two approaches:**

| Approach | Use Case | API |
|----------|----------|-----|
| **Bulk Operations** | Full loads, large datasets | `bulkOperationRunQuery` mutation |
| **Standard Queries** | Incremental loads, small updates | Paginated GraphQL queries |

**Bulk Operations Details:**
- Async processing - submit query, poll for completion, download JSONL
- Up to 5 concurrent bulk operations per shop (API 2026-01+)
- Results available for 7 days
- Must complete within 10 days
- Constraints: max 5 connections, 2 levels of nesting

**Bulk Query Workflow:**
```
1. Submit bulkOperationRunQuery mutation
2. Poll currentBulkOperation for status (or use webhook)
3. When status = COMPLETED, download JSONL from url field
4. Parse JSONL (line by line, memory efficient)
5. Load into Exasol staging tables
6. Transform to star schema
```

**Example Bulk Query (Products with Variants):**
```graphql
mutation {
  bulkOperationRunQuery(
    query: """
    {
      products {
        edges {
          node {
            id
            title
            productType
            vendor
            status
            createdAt
            variants {
              edges {
                node {
                  id
                  sku
                  price
                  inventoryItem {
                    unitCost { amount currencyCode }
                  }
                }
              }
            }
          }
        }
      }
    }
    """
  ) {
    bulkOperation {
      id
      status
    }
    userErrors { field message }
  }
}
```

**Incremental Load Strategy:**
- Use `updated_at` filter for changed records
- Store last sync timestamp in state file or Exasol table
- Orders: `orders(query: "updated_at:>'2026-01-29T00:00:00Z'")`

---

#### Exasol Loading with PyExasol

**Key Features:**
- HTTP transport with compression (fast bulk loading)
- Parallel data streams (multiple CPU cores)
- Native pandas/polars integration
- Significant performance over ODBC

**Bulk Load Pattern:**
```python
import pyexasol
import pandas as pd

conn = pyexasol.connect(
    dsn='exasol-host:8563',
    user='etl_user',
    password='...',
    schema='SHOPIFY_STG'
)

# Load DataFrame to Exasol
df = pd.read_json('products.jsonl', lines=True)
conn.import_from_pandas(df, 'STG_PRODUCTS')

# Or use IMPORT for large files
conn.execute("""
    IMPORT INTO STG_PRODUCTS
    FROM LOCAL CSV FILE '/path/to/data.csv'
    COLUMN SEPARATOR = ','
    SKIP = 1
""")
```

**Recommended Schema Pattern:**
```
SHOPIFY_STG (staging)
├── stg_products
├── stg_orders
├── stg_customers
├── stg_discounts
└── _etl_state (last sync timestamps)

SHOPIFY_DWH (star schema)
├── fact_order_line_item
├── fact_order_header
├── dim_product
├── dim_customer
├── dim_date
├── dim_geography
├── dim_order
└── dim_discount
```

---

#### Scheduling: systemd Timers vs Cron

| Feature | systemd Timers | Cron |
|---------|----------------|------|
| Single instance guarantee | ✓ (built-in) | ✗ (needs flock) |
| Missed run catch-up | ✓ (Persistent=true) | ✗ (skips) |
| Resource limits | ✓ (CPUQuota, MemoryLimit) | ✗ |
| Logging | ✓ (journald integration) | ✗ (email/file) |
| Environment handling | ✓ (EnvironmentFile) | Limited |
| Dependencies | ✓ (After=, Requires=) | ✗ |
| Setup complexity | Medium (2 files) | Low (1 line) |

**Recommendation: systemd timers** for production

**Example systemd Setup:**

`/etc/systemd/system/shopify-etl.service`:
```ini
[Unit]
Description=Shopify ETL to Exasol
After=network.target

[Service]
Type=oneshot
User=etl
WorkingDirectory=/opt/shopify-etl
ExecStart=/opt/shopify-etl/venv/bin/python main.py
EnvironmentFile=/opt/shopify-etl/.env
StandardOutput=journal
StandardError=journal

# Resource limits
MemoryMax=2G
CPUQuota=80%
```

`/etc/systemd/system/shopify-etl.timer`:
```ini
[Unit]
Description=Run Shopify ETL every 6 hours

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

**Enable:**
```bash
systemctl daemon-reload
systemctl enable shopify-etl.timer
systemctl start shopify-etl.timer
systemctl list-timers  # verify
```

---

#### ETL Job Types

| Job | Frequency | Approach | Notes |
|-----|-----------|----------|-------|
| **Full Product Sync** | Daily (overnight) | Bulk operation | All products + variants |
| **Incremental Orders** | Every 6 hours | Filtered query | updated_at > last_sync |
| **Incremental Customers** | Every 6 hours | Filtered query | updated_at > last_sync |
| **Discount Codes** | Daily | Standard query | Usually small volume |
| **Inventory Levels** | Hourly (optional) | Standard query | If tracking stock |

---

#### Error Handling & Monitoring

**Retry Strategy:**
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, max=60))
def run_bulk_operation(query):
    # ... submit and poll
```

**State Management:**
```sql
-- Track sync state in Exasol
CREATE TABLE _etl_state (
    entity VARCHAR(50) PRIMARY KEY,
    last_sync_at TIMESTAMP,
    last_run_status VARCHAR(20),
    records_processed INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Monitoring Options:**
- systemd `OnFailure=` trigger for alerts
- Log shipping to centralized logging
- Simple health check endpoint
- Email/Slack notification on failure

---

#### Project Structure

```
/opt/shopify-etl/
├── main.py                    # Entry point
├── config.yaml                # Non-sensitive config
├── .env                       # Credentials (gitignored)
├── requirements.txt
├── venv/
├── src/
│   ├── __init__.py
│   ├── shopify_client.py      # GraphQL client wrapper
│   ├── exasol_loader.py       # PyExasol wrapper
│   ├── transformers/          # Staging → DWH transforms
│   │   ├── products.py
│   │   ├── orders.py
│   │   └── customers.py
│   ├── jobs/                  # Scheduled job definitions
│   │   ├── full_product_sync.py
│   │   ├── incremental_orders.py
│   │   └── ...
│   └── utils/
│       ├── logging.py
│       └── state.py
├── sql/                       # DDL and transform SQL
│   ├── staging/
│   └── dwh/
└── tests/
```

---

#### Cost Comparison

| Approach | Monthly Cost | Notes |
|----------|--------------|-------|
| Fivetran | $500-$10,000+ | Row-based pricing, scales with volume |
| Airbyte Cloud | $300-$2,000+ | Credit-based |
| Airbyte Self-Hosted | $0 (infra only) | Needs Docker/K8s, maintenance overhead |
| **Custom Python** | **$0** | Runs on existing Exasol box |

**Break-even:** Custom pays off immediately for your scale (2-4k orders/month)

---

#### Implementation Phases

**Phase 1: Foundation**
- [ ] Set up project structure
- [ ] Implement Shopify GraphQL client
- [ ] Implement PyExasol loader
- [ ] Create staging tables in Exasol
- [ ] Full product sync job

**Phase 2: Core ETL**
- [ ] Orders extraction (bulk + incremental)
- [ ] Customers extraction
- [ ] Discount codes extraction
- [ ] Staging → DWH transforms

**Phase 3: Production**
- [ ] systemd timer setup
- [ ] Error handling & retries
- [ ] Monitoring & alerting
- [ ] Documentation

**Phase 4: Optimization**
- [ ] Inventory levels (if needed)
- [ ] Performance tuning
- [ ] Parallel loading

---

#### Required Shopify Scopes

```
read_products
read_orders
read_customers
read_discounts
read_inventory (if tracking stock)
```

---

#### Sources

- [Shopify Bulk Operations Guide](https://shopify.dev/docs/api/usage/bulk-operations/queries)
- [PyExasol GitHub](https://github.com/exasol/pyexasol)
- [Shopify Python API](https://github.com/Shopify/shopify_python_api)
- [systemd Timers vs Cron](https://opensource.com/article/20/7/systemd-timers)

---

## Code Snippets

<!-- Add useful code snippets here with context -->

### Template
```
### [Snippet Name]

**Language:**
**Use Case:**
**Source:**

\```[language]
// code
\```

**Notes:**
```

---

## Research Topics

### Active
- [ ] Voucher/discount code tracking in Shopify
- [ ] Exasol-specific optimizations

### Completed
- [x] Initial system setup
- [x] Business context documentation
- [x] Data modeling approach (star schema selected)
- [x] Shopify Orders data model mapping
- [x] DWH schema design (facts + dimensions)
- [x] Competitive landscape research

### Future
- [ ] ETL tool evaluation (Airbyte vs custom)
- [ ] BI platform selection
- [ ] Data quality monitoring

---

## Ideas & Future Improvements

- [ ] Create Shopify API query templates
- [ ] Build voucher lifecycle tracking dashboard
- [ ] Develop corporate client attribution logic

---

## External References

- **Shopify API Docs:** https://shopify.dev/docs/api
- **Shopify Admin API:** https://shopify.dev/docs/api/admin
- **Second Brain system:** See CLAUDE.md

---

## Quick Capture

<!-- Use this section for quick notes during research sessions -->
<!-- Move organized content to appropriate sections above -->
