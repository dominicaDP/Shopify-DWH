# Notes

**Project:** Shopify DWH Research
**Last Updated:** 2026-02-03

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

#### Inventory Domain Decision (2026-01-30)

**Decision:** Option C - Minimal approach

**Implemented now:**
```
dim_location
├── location_key (PK)
├── location_id
├── name
├── address1, address2, city, province, country
├── is_active
├── fulfills_online_orders
├── _loaded_at
```

**Backlogged for future:**
```
fact_inventory_snapshot (per item per location per day)
├── snapshot_key (PK)
├── product_key (FK)
├── location_key (FK)
├── snapshot_date_key (FK)
├── quantity_available
├── quantity_on_hand
├── quantity_committed
├── quantity_incoming
├── quantity_reserved
├── _loaded_at
```

**Rationale:**
- dim_location is low-cost, enables future fulfillment/inventory analytics
- fact_inventory_snapshot requires daily ETL and storage growth
- No clear use case yet - add when specific need emerges

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

**Schema Enhancements (2026-01-30):**

All potential additions implemented:

| Field | Source | Status |
|-------|--------|--------|
| discount_id | DiscountCodeNode.id | ✓ Added |
| title | codeDiscount.title | ✓ Added |
| status | codeDiscount.status | ✓ Added |
| starts_at | codeDiscount.startsAt | ✓ Added |
| ends_at | codeDiscount.endsAt | ✓ Added |
| usage_limit | codeDiscount.usageLimit | ✓ Added |
| usage_count | asyncUsageCount | ✓ Added |
| applies_once_per_customer | codeDiscount.appliesOncePerCustomer | ✓ Added |
| created_at | codeDiscount.createdAt | ✓ Added |

**Analytics Now Enabled:**
- Redemption rate: `usage_count / usage_limit`
- Active campaigns: `status = 'ACTIVE'`
- Discount inventory: `usage_limit - usage_count`
- Campaign performance by period

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
- ~~Orders (redemptions)~~ ✅ Done
- ~~Customers (end consumers)~~ ✅ Done
- ~~Fulfillment~~ ✅ Done
- Metafields (custom data?) - Deferred to Layer 2

### 2026-01-30 - Orders API Research

**Source:** Shopify GraphQL Admin API - Order, LineItem, Refund

#### Order Object - Key Fields

**Identity:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `id` | ID | → order_id |
| `name` | String | → order_name (e.g., "#1001") |
| `confirmationNumber` | String | *Consider adding* |

**Financial (MoneyBag - has shopMoney + presentmentMoney):**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `subtotalPriceSet` | MoneyBag | → subtotal (use shopMoney.amount) |
| `totalDiscountsSet` | MoneyBag | → total_discount |
| `totalTaxSet` | MoneyBag | → total_tax |
| `totalShippingPriceSet` | MoneyBag | → shipping_amount |
| `totalPriceSet` | MoneyBag | → total_price |
| `totalRefundedSet` | MoneyBag | → total_refunded |
| `netPaymentSet` | MoneyBag | → net_payment |
| `currencyCode` | CurrencyCode | *Consider adding* |

**Status:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `displayFinancialStatus` | String | → dim_order.financial_status |
| `displayFulfillmentStatus` | String | → fulfillment_status + is_fulfilled flags |
| `cancelledAt` | DateTime | → is_cancelled (NOT NULL check) |
| `cancelReason` | String | → dim_order.cancel_reason |
| `test` | Boolean | *Consider adding* (filter test orders) |

**Timestamps:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `createdAt` | DateTime | → order_date_key derivation |
| `processedAt` | DateTime | → dim_order.processed_at |
| `closedAt` | DateTime | → dim_order.closed_at |
| `cancelledAt` | DateTime | → dim_order.cancelled_at |

**Relationships:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `customer` | Customer | → customer_key (via customer.id) |
| `shippingAddress` | MailingAddress | → ship_address_key |
| `billingAddress` | MailingAddress | → bill_address_key |
| `lineItems` | LineItemConnection | → fact_order_line_item |
| `discountApplications` | DiscountApplicationConnection | → discount_key derivation |
| `refunds` | RefundConnection | → total_refunded, is_refunded |

#### LineItem Object - Key Fields

**Identity:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `id` | ID | → line_item_id |
| `sku` | String | → sku |
| `name` | String | Full product + variant name |
| `title` | String | Product title |
| `variantTitle` | String | Variant title |

**Quantities:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `quantity` | Int | → quantity |
| `currentQuantity` | Int | Current after refunds |
| `unfulfilledQuantity` | Int | For is_fulfilled derivation |
| `refundableQuantity` | Int | For is_refunded derivation |

**Pricing (MoneyBag):**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `originalUnitPriceSet` | MoneyBag | → unit_price |
| `originalTotalSet` | MoneyBag | → line_subtotal |
| `discountedTotalSet` | MoneyBag | → line_total |
| `totalDiscountSet` | MoneyBag | → line_discount_amount |

**Tax:**
| API Field | Type | Notes |
|-----------|------|-------|
| `taxable` | Boolean | → is_taxable |
| `taxLines` | [TaxLine] | Need to SUM for line_tax_amount |

**Flags:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `isGiftCard` | Boolean | → is_gift_card |
| `requiresShipping` | Boolean | Physical product flag |

**Product Relationship:**
| API Field | Type | Notes |
|-----------|------|-------|
| `variant` | ProductVariant | → product_key (via variant.id) |
| `product` | Product | Alternative path |

#### MoneyBag Structure

Every `*Set` financial field returns MoneyBag:
```graphql
totalPriceSet {
  shopMoney {
    amount       # Decimal string in shop's currency
    currencyCode # e.g., "ZAR"
  }
  presentmentMoney {
    amount       # Decimal string in customer's currency
    currencyCode # e.g., "USD"
  }
}
```

**Decision:** Use `shopMoney` for DWH (merchant's base currency, consistent for reporting)

#### Schema Validation Results

**fact_order_line_item:**
| Our Field | API Source | Status |
|-----------|------------|--------|
| line_item_key | Generated | ✓ OK |
| order_key | Generated | ✓ OK |
| product_key | variant.id lookup | ✓ OK |
| customer_key | order.customer.id | ✓ OK |
| order_date_key | order.createdAt | ✓ OK |
| ship_address_key | order.shippingAddress | ✓ OK |
| discount_key | discountApplications | ✓ OK |
| order_id | order.id | ✓ OK |
| order_name | order.name | ✓ OK |
| line_item_id | lineItem.id | ✓ OK |
| sku | lineItem.sku | ✓ OK |
| quantity | lineItem.quantity | ✓ OK |
| unit_price | originalUnitPriceSet.shopMoney.amount | ✓ OK |
| line_subtotal | originalTotalSet.shopMoney.amount | ✓ OK |
| line_discount_amount | totalDiscountSet.shopMoney.amount | ✓ OK |
| line_tax_amount | SUM(taxLines.priceSet) | ⚠️ Aggregate needed |
| line_total | discountedTotalSet.shopMoney.amount | ✓ OK |
| is_gift_card | isGiftCard | ✓ OK |
| is_taxable | taxable | ✓ OK |
| is_fulfilled | unfulfilledQuantity == 0 | ⚠️ Derived |
| is_refunded | currentQuantity < quantity | ⚠️ Derived |

**fact_order_header:**
| Our Field | API Source | Status |
|-----------|------------|--------|
| subtotal | subtotalPriceSet.shopMoney.amount | ✓ OK |
| total_discount | totalDiscountsSet.shopMoney.amount | ✓ OK |
| total_tax | totalTaxSet.shopMoney.amount | ✓ OK |
| shipping_amount | totalShippingPriceSet.shopMoney.amount | ✓ OK |
| total_price | totalPriceSet.shopMoney.amount | ✓ OK |
| total_refunded | totalRefundedSet.shopMoney.amount | ✓ OK |
| net_payment | netPaymentSet.shopMoney.amount | ✓ OK |
| is_cancelled | cancelledAt IS NOT NULL | ✓ OK |
| is_fulfilled | displayFulfillmentStatus == 'FULFILLED' | ✓ OK |
| is_partially_fulfilled | displayFulfillmentStatus == 'PARTIALLY_FULFILLED' | ✓ OK |

#### Potential Schema Enhancements

**fact_order_header additions:**
| Field | Source | Priority | Rationale |
|-------|--------|----------|-----------|
| `currency_code` | currencyCode | MEDIUM | Multi-currency reporting |
| `is_test_order` | test | LOW | Filter test data |

**dim_order additions:**
| Field | Source | Priority | Rationale |
|-------|--------|----------|-----------|
| `confirmation_number` | confirmationNumber | LOW | Customer service lookup |

#### ETL Query Example

```graphql
query BulkOrdersExport {
  orders {
    edges {
      node {
        id
        name
        createdAt
        processedAt
        cancelledAt
        cancelReason
        displayFinancialStatus
        displayFulfillmentStatus
        currencyCode
        test

        # Financial totals
        subtotalPriceSet { shopMoney { amount currencyCode } }
        totalDiscountsSet { shopMoney { amount currencyCode } }
        totalTaxSet { shopMoney { amount currencyCode } }
        totalShippingPriceSet { shopMoney { amount currencyCode } }
        totalPriceSet { shopMoney { amount currencyCode } }
        totalRefundedSet { shopMoney { amount currencyCode } }
        netPaymentSet { shopMoney { amount currencyCode } }

        # Customer
        customer { id }

        # Addresses
        shippingAddress {
          city
          province
          provinceCode
          country
          countryCodeV2
          zip
          latitude
          longitude
        }
        billingAddress {
          city
          province
          provinceCode
          country
          countryCodeV2
          zip
        }

        # Discount codes
        discountCodes
        discountApplications(first: 10) {
          edges {
            node {
              ... on DiscountCodeApplication {
                code
                allocationMethod
                targetType
                value {
                  ... on MoneyV2 { amount currencyCode }
                  ... on PricingPercentageValue { percentage }
                }
              }
            }
          }
        }

        # Line items
        lineItems(first: 100) {
          edges {
            node {
              id
              sku
              quantity
              currentQuantity
              unfulfilledQuantity
              isGiftCard
              taxable

              variant { id }

              originalUnitPriceSet { shopMoney { amount } }
              originalTotalSet { shopMoney { amount } }
              discountedTotalSet { shopMoney { amount } }
              totalDiscountSet { shopMoney { amount } }

              taxLines {
                priceSet { shopMoney { amount } }
              }
            }
          }
        }
      }
    }
  }
}
```

#### Deprecated Fields to Avoid

Use `*Set` variants instead of deprecated scalar fields:
- ❌ `subtotalPrice` → ✓ `subtotalPriceSet`
- ❌ `totalPrice` → ✓ `totalPriceSet`
- ❌ `totalDiscounts` → ✓ `totalDiscountsSet`
- ❌ `totalTax` → ✓ `totalTaxSet`
- ❌ `totalRefunded` → ✓ `totalRefundedSet`
- ❌ `cartDiscountAmount` → ✓ `cartDiscountAmountSet`

#### Required Scopes

```
read_orders  # Primary scope needed
```

#### Query Filters for Incremental Loads

```graphql
# Orders updated since last sync
orders(query: "updated_at:>'2026-01-29T00:00:00Z'")

# Filter by financial status
orders(query: "financial_status:paid")

# Filter by fulfillment status
orders(query: "fulfillment_status:shipped")
```

---

### 2026-01-30 - Customers API Research

**Source:** Shopify GraphQL Admin API - Customer, CustomerEmailAddress, MailingAddress

#### Customer Object - Key Fields

**Identity:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `id` | ID | → customer_id |
| `firstName` | String | → first_name |
| `lastName` | String | → last_name |
| `displayName` | String | *Consider adding* (derived: first + last) |

**Contact (New Pattern - Deprecated scalars):**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `defaultEmailAddress` | CustomerEmailAddress | → email (use .emailAddress) |
| `defaultPhoneNumber` | CustomerPhoneNumber | → phone (use .phoneNumber) |
| ~~`email`~~ | ~~String~~ | ❌ DEPRECATED |
| ~~`phone`~~ | ~~String~~ | ❌ DEPRECATED |

**Aggregates:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `amountSpent` | MoneyV2 | → total_spent (.amount) |
| `numberOfOrders` | Int | → order_count |

**Marketing Consent (New Pattern):**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `defaultEmailAddress.marketingState` | CustomerEmailAddressMarketingState | → accepts_marketing |
| `defaultEmailAddress.marketingOptInLevel` | CustomerMarketingOptInLevel | *Consider adding* |
| ~~`emailMarketingConsent`~~ | ~~CustomerEmailMarketingConsentState~~ | ❌ DEPRECATED |
| ~~`smsMarketingConsent`~~ | ~~CustomerSmsMarketingConsentState~~ | ❌ DEPRECATED |

**Marketing State Values:**
- `NOT_SUBSCRIBED` - Not subscribed
- `PENDING` - Pending confirmation
- `SUBSCRIBED` - Opted in
- `UNSUBSCRIBED` - Opted out
- `REDACTED` - Data redacted
- `INVALID` - Invalid email

**Marketing Opt-In Levels:**
- `SINGLE_OPT_IN` - Subscribed without confirmation
- `CONFIRMED_OPT_IN` - Double opt-in confirmed
- `UNKNOWN` - Unknown

**Metadata:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `tags` | [String] | → tags (join with comma) |
| `note` | String | *Consider adding* |
| `createdAt` | DateTime | → created_at |
| `updatedAt` | DateTime | *Consider adding* (for SCD tracking) |

**Default Address:**
| API Field | Type | DWH Mapping |
|-----------|------|-------------|
| `defaultAddress.country` | String | → default_country |
| `defaultAddress.province` | String | → default_province |
| `defaultAddress.city` | String | *Available but not mapped* |
| ~~`addresses`~~ | ~~MailingAddressConnection~~ | ❌ DEPRECATED |

#### CustomerEmailAddress Object

| Field | Type | Description |
|-------|------|-------------|
| `emailAddress` | String | The actual email address |
| `marketingState` | CustomerEmailAddressMarketingState | Current marketing consent |
| `marketingOptInLevel` | CustomerMarketingOptInLevel | How consent was obtained |
| `marketingUnsubscribeUrl` | URL | Unsubscribe link |
| `openTrackingLevel` | CustomerEmailAddressOpenTrackingLevel | Email open tracking |
| `validFormat` | Boolean | Whether format is valid |

#### Schema Validation Results

**dim_customer:**
| Our Field | API Source | Status |
|-----------|------------|--------|
| customer_key | Generated | ✓ OK |
| customer_id | id | ✓ OK |
| email | defaultEmailAddress.emailAddress | ⚠️ Use new field |
| first_name | firstName | ✓ OK |
| last_name | lastName | ✓ OK |
| phone | defaultPhoneNumber.phoneNumber | ⚠️ Use new field |
| accepts_marketing | defaultEmailAddress.marketingState | ⚠️ Derive from enum |
| created_at | createdAt | ✓ OK |
| order_count | numberOfOrders | ✓ OK |
| total_spent | amountSpent.amount | ✓ OK (MoneyV2) |
| default_country | defaultAddress.country | ✓ OK |
| default_province | defaultAddress.province | ✓ OK |
| tags | tags (array → comma string) | ✓ OK |

**ETL Notes:**
- `accepts_marketing` = TRUE when `marketingState` IN ('SUBSCRIBED', 'PENDING')
- `tags` array must be joined with commas for VARCHAR storage
- `amountSpent` is MoneyV2 type - use `.amount` field

#### Potential Schema Additions

| Field | Source | Priority | Rationale |
|-------|--------|----------|-----------|
| `note` | note | LOW | Customer notes (internal use) |
| `updated_at` | updatedAt | LOW | Track last change timestamp |
| `marketing_opt_in_level` | defaultEmailAddress.marketingOptInLevel | LOW | Distinguish single vs double opt-in |

**Recommendation:** Current schema is sufficient for generic layer. Add note/updated_at if specific use cases emerge.

#### ETL Query Example

```graphql
query BulkCustomersExport {
  customers {
    edges {
      node {
        id
        firstName
        lastName
        createdAt
        updatedAt
        tags
        note

        # Contact (using new objects)
        defaultEmailAddress {
          emailAddress
          marketingState
          marketingOptInLevel
        }
        defaultPhoneNumber {
          phoneNumber
        }

        # Aggregates
        amountSpent { amount currencyCode }
        numberOfOrders

        # Default address
        defaultAddress {
          country
          countryCodeV2
          province
          provinceCode
          city
        }
      }
    }
  }
}
```

#### Deprecated Fields to Avoid

Use new object patterns instead of deprecated scalar fields:
- ❌ `email` → ✓ `defaultEmailAddress.emailAddress`
- ❌ `phone` → ✓ `defaultPhoneNumber.phoneNumber`
- ❌ `emailMarketingConsent` → ✓ `defaultEmailAddress.marketingState`
- ❌ `smsMarketingConsent` → ✓ `defaultPhoneNumber.marketingState`
- ❌ `addresses` → ✓ `defaultAddress` (single address)

#### Required Scopes

```
read_customers  # Primary scope needed
```

#### Query Filters for Incremental Loads

```graphql
# Customers updated since last sync
customers(query: "updated_at:>'2026-01-29T00:00:00Z'")

# Filter by country
customers(query: "country:ZA")

# Filter by tag
customers(query: "tag:vip")

# Filter by orders
customers(query: "orders_count:>5")
```

---

### 2026-01-30 - Fulfillment API Research

**Source:** Shopify GraphQL Admin API - Fulfillment, FulfillmentOrder, FulfillmentLineItem, DeliveryMethod

#### Fulfillment Object Hierarchy

```
Order
  └→ fulfillmentOrders (FulfillmentOrder[])
       ├→ deliveryMethod (DeliveryMethod)
       ├→ destination (address)
       ├→ status (FulfillmentOrderStatus)
       └→ fulfillments (Fulfillment[])
            ├→ status (FulfillmentStatus)
            ├→ trackingInfo (FulfillmentTrackingInfo)
            ├→ location (Location)
            └→ fulfillmentLineItems (FulfillmentLineItem[])
                 ├→ lineItem (LineItem reference)
                 └→ quantity (fulfilled)
```

**Key Concept:**
- **FulfillmentOrder** = What SHOULD be shipped (grouped by location)
- **Fulfillment** = What WAS shipped (actual shipment record)

#### FulfillmentOrder Object

**Grain:** Groups items to be fulfilled from same location

| Field | Type | Description |
|-------|------|-------------|
| `id` | ID | Unique identifier |
| `status` | FulfillmentOrderStatus | Current workflow state |
| `assignedLocation` | Location | Fulfillment location |
| `deliveryMethod` | DeliveryMethod | How it will be delivered |
| `destination` | FulfillmentOrderDestination | Ship-to address |
| `fulfillAt` | DateTime | Scheduled fulfillment time |
| `order` | Order | Parent order |
| `lineItems` | FulfillmentOrderLineItem[] | Items to fulfill |
| `fulfillments` | Fulfillment[] | Completed shipments |
| `createdAt` / `updatedAt` | DateTime | Timestamps |

**FulfillmentOrderStatus Enum:**
| Value | Description |
|-------|-------------|
| `OPEN` | Ready for processing |
| `IN_PROGRESS` | Currently being processed |
| `SCHEDULED` | Scheduled for future fulfillment |
| `ON_HOLD` | Temporarily held |
| `INCOMPLETE` | Partially complete |
| `CLOSED` | Completed |
| `CANCELLED` | Cancelled |

#### Fulfillment Object

**Grain:** One row per shipment (can have multiple per order)

| Field | Type | Description |
|-------|------|-------------|
| `id` | ID | Unique identifier |
| `name` | String | Fulfillment name (e.g., "#1001-F1") |
| `status` | FulfillmentStatus | Shipment status |
| `trackingInfo` | FulfillmentTrackingInfo[] | Carrier & tracking |
| `location` | Location | Ship-from location |
| `totalQuantity` | Int | Total units shipped |
| `fulfillmentLineItems` | FulfillmentLineItem[] | Items in shipment |
| `createdAt` | DateTime | When created |
| `inTransitAt` | DateTime | When shipped |
| `deliveredAt` | DateTime | When delivered |
| `estimatedDeliveryAt` | DateTime | Expected delivery |

**FulfillmentStatus Enum:**
| Value | Description |
|-------|-------------|
| `SUCCESS` | Completed successfully |
| `CANCELLED` | Cancelled |
| `ERROR` | Error condition |
| `FAILURE` | Failed to complete |
| ~~`OPEN`~~ | ❌ Deprecated |
| ~~`PENDING`~~ | ❌ Deprecated |

#### FulfillmentTrackingInfo Object

| Field | Type | Description |
|-------|------|-------------|
| `company` | String | Carrier name (e.g., "DHL", "Aramex") |
| `number` | String | Tracking number |
| `url` | URL | Tracking URL |

#### FulfillmentLineItem Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | ID | Unique identifier |
| `lineItem` | LineItem | Reference to order line item |
| `quantity` | Int | Units fulfilled |
| `originalTotalSet` | MoneyBag | Pre-discount value |
| `discountedTotalSet` | MoneyBag | Post-discount value |

#### DeliveryMethod Object

| Field | Type | Description |
|-------|------|-------------|
| `methodType` | DeliveryMethodType | Delivery category |
| `presentedName` | String | Name shown to customer |
| `serviceCode` | String | Service identifier |
| `minDeliveryDateTime` | DateTime | Earliest delivery |
| `maxDeliveryDateTime` | DateTime | Latest delivery |

**DeliveryMethodType Enum:**
| Value | Description |
|-------|-------------|
| `SHIPPING` | Standard shipping |
| `LOCAL` | Local delivery |
| `PICK_UP` | Customer pickup |
| `PICKUP_POINT` | Designated pickup location |
| `RETAIL` | Retail store delivery |
| `NONE` | No delivery method |

#### DWH Design Options

**Option A: Simple (Current Approach)**
Track fulfillment at order/line item level:
- `fact_order_line_item.is_fulfilled` (derived from unfulfilledQuantity == 0)
- `fact_order_header.is_fulfilled`, `is_partially_fulfilled`
- `dim_order.fulfillment_status`

**Pros:** Simple, covers 80% of analytics needs
**Cons:** No shipment-level tracking, no carrier analytics

**Option B: Fulfillment Fact Table**
Add `fact_fulfillment` for shipment-level analysis:

```
fact_fulfillment
├── fulfillment_key (PK)
├── order_key (FK)
├── fulfillment_id
├── fulfillment_name
├── location_key (FK → dim_location)
├── carrier_name
├── tracking_number
├── delivery_method_type
├── status
├── total_quantity
├── created_at
├── shipped_at (inTransitAt)
├── delivered_at
├── estimated_delivery_at
├── _loaded_at
```

**Pros:** Full shipment analytics, carrier performance, delivery times
**Cons:** More complexity, requires dim_location

**Option C: Fulfillment Line Item Grain**
Add `fact_fulfillment_line_item` for item-level shipment tracking:

```
fact_fulfillment_line_item
├── fulfillment_line_key (PK)
├── fulfillment_key (FK)
├── line_item_key (FK)
├── quantity_fulfilled
├── _loaded_at
```

**Pros:** Full traceability, partial fulfillment tracking
**Cons:** Most complex, may be overkill

#### Recommendation for Generic Layer

**Start with Option A** (current approach):
- Fulfillment flags already exist in schema
- Sufficient for "was it shipped?" analysis
- Most Shopify stores don't need shipment-level analytics

**Backlog Option B** for future:
- Add when carrier performance analysis needed
- Add when multi-location fulfillment tracking needed
- Would require dim_location (already designed for inventory)

#### ETL Query Example

```graphql
query OrderWithFulfillments {
  orders(first: 50) {
    edges {
      node {
        id
        name
        displayFulfillmentStatus

        fulfillmentOrders(first: 10) {
          edges {
            node {
              status
              assignedLocation { name }
              deliveryMethod {
                methodType
                presentedName
              }

              fulfillments(first: 5) {
                edges {
                  node {
                    id
                    name
                    status
                    totalQuantity
                    createdAt
                    inTransitAt
                    deliveredAt

                    trackingInfo(first: 3) {
                      company
                      number
                      url
                    }

                    fulfillmentLineItems(first: 50) {
                      edges {
                        node {
                          quantity
                          lineItem { id sku }
                        }
                      }
                    }
                  }
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

#### Required Scopes

```
read_orders                              # Basic access
read_assigned_fulfillment_orders         # If using fulfillment services
read_merchant_managed_fulfillment_orders # For merchant-managed
read_third_party_fulfillment_orders      # For 3PL integrations
```

#### Gamatek Integration Notes (DYT Layer 2)

For DYT-specific fulfillment tracking with Gamatek:
- Standard Fulfillment object captures shipment data
- `trackingInfo` captures carrier/tracking from Gamatek
- May need custom fields via metafields for Gamatek-specific data
- Consider: Gamatek order ID, warehouse location, special handling notes

---

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

### 2026-01-30 - Multi-Currency Handling Decision

**Decision:** Option B - Store currency code, use shopMoney amounts

#### Implementation

**Financial Amounts:**
- All amounts use `shopMoney.amount` from MoneyBag fields
- Stored in DECIMAL(18,2) columns
- Consistent currency for all calculations

**Currency Tracking:**
- `dim_order.currency` stores the order's currency code (e.g., "ZAR", "USD")
- Already exists in schema - just ensure ETL populates from `Order.currencyCode`
- No currency fields needed on fact tables (join to dim_order)

**Multi-Currency Shop Handling:**
```sql
-- Filter to specific currency
SELECT SUM(total_price)
FROM fact_order_header foh
JOIN dim_order do ON foh.order_key = do.order_key
WHERE do.currency = 'ZAR';

-- Group by currency for multi-currency analysis
SELECT do.currency, SUM(foh.total_price)
FROM fact_order_header foh
JOIN dim_order do ON foh.order_key = do.order_key
GROUP BY do.currency;
```

#### What's NOT Implemented (Backlogged)

| Feature | Reason |
|---------|--------|
| presentmentMoney storage | Rarely needed, doubles financial columns |
| dim_exchange_rate | Requires external rate source |
| Normalized currency conversion | Significant complexity |

**Upgrade Path:**
If dual-currency or conversion needed later:
1. Add `*_presentment` columns to fact tables
2. Add `currency_code_presentment` to dim_order
3. Or: Add dim_exchange_rate for conversion

---

### 2026-02-03 - Market Perception of Shopify Native Reporting

**Topic:** Market validation for Shopify DWH/analytics solutions

**Key Finding:** Strong market demand exists beyond our specific voucher tracking use case. The base product has significant market potential.

---

#### Pain Points with Shopify Native Analytics

**1. Data Delays & Accuracy**
- Batch processing: 1-3 hours normally, up to 24+ hours during high traffic (BFCM, viral launches)
- Merchants report discrepancies: "100 orders in Shopify while payment processor shows 120"
- Attribution confusion: "Facebook claiming $10,000 in sales while Shopify attributes to 'Direct traffic'"

**2. Plan-Gated Features**
- Advanced reports only on higher Shopify plans
- Expert quote: *"If you are running your business purely on Shopify's default analytics, you are only seeing half the picture."*
- Even Advanced/Plus stores have limitations on custom reports

**3. Scaling Problems**
- At $10K/month: 5% discrepancy = annoying
- At $100K/month: 5% discrepancy = $5,000 mystery revenue affecting strategy
- Fundamental limitations become critical as stores grow

**4. Missing Capabilities**
- No bounce rate, time on page, scroll depth
- No raw data export (API only, with limitations)
- Only ~13 months of historical data retention
- Isolated from paid media, CRM, ERP, marketplace systems
- Multi-store rollups and unified customer views require external tools

**5. Integration Challenges**
- Google Analytics requires complex manual setup for Shopify eCommerce tracking
- Discrepancies between Shopify Analytics and third-party tracking common
- Most marketplace apps "beautify data" but don't provide actionable insights

---

#### Market Size & Validation

**E-commerce Analytics Software Market:**
| Metric | Value | Source |
|--------|-------|--------|
| Market Size (2023) | $16.8B | Verified Market Reports |
| Projected Size (2030) | $37.5B | Verified Market Reports |
| CAGR | 12.5% | |

**Broader E-commerce Analytics Market:**
| Metric | Value | Source |
|--------|-------|--------|
| Market Size (2025) | $29B | Knowledge Sourcing |
| Projected Size (2030) | $60B | Knowledge Sourcing |
| CAGR | 15.66% | |

**Shopify Addressable Market:**
| Metric | Value |
|--------|-------|
| Active Shopify websites globally | 4.82 million |
| US Shopify stores | 2.67 million |
| US ecommerce using Shopify | 30% |
| Merchant-generated revenue | $1.4T+ |
| Shopify platform revenue (2024) | $6B+ |

---

#### Competitor Traction (Market Proof)

**Triple Whale:**
- Raised $27.7M (NFX, Elephant VC, Shaan Puri)
- Serves 50,000+ brands
- Investor quote: "one of the fastest-growing and most exciting companies I've ever worked with"
- Pricing: ~$429/month for $1M GMV brands, scaling steeply

**Polar Analytics:**
- Pricing: ~$720/month, scaling with volume
- AI-powered analyst feature ("Ask Polar")
- Customer testimonials citing "+20% growth"

**Market Signal:** Premium pricing ($400-700+/month) proves willingness to pay for better analytics.

---

#### What Third-Party Tools Solve

| Gap | Native Shopify | Third-Party Value |
|-----|----------------|-------------------|
| LTV Analysis | Superficial | Cohort-based, channel-attributed, accounting for acquisition costs |
| Marketing Attribution | "Direct traffic" catch-all | Multi-touch, cross-channel |
| Predictive Analytics | None | Churn prediction, ML-based forecasting |
| Team Collaboration | Manual dashboard checks | Automated report distribution |
| Custom Reporting | Plan-restricted | Flexible, unlimited |
| Historical Data | ~13 months | Unlimited (warehouse-based) |

**ROI Example:** Automated report distribution for 5-person team eliminates 75 minutes daily dashboard checking. At $50/hour = $27,350 annually saved.

---

#### Strategic Implications for Our DWH

**Dual Market Opportunity:**

1. **Specific Use Case (DYT/B2B2C)**
   - Voucher redemption tracking
   - Corporate client attribution
   - B2B2C metrics not covered by any existing tool

2. **Generic Base Product**
   - Shopify → Exasol data warehouse
   - First Exasol-native Shopify solution (differentiation)
   - Custom SQL access to raw data
   - Lower price point than Triple Whale/Polar ($400-700/mo)
   - Mid-market appeal (price-sensitive but data-hungry merchants)

**Positioning Strategy:**
| Layer | Description | Market |
|-------|-------------|--------|
| Layer 1 (Generic) | Shopify DWH for Exasol | Any Shopify merchant needing data warehouse |
| Layer 2 (DYT-specific) | Voucher/B2B2C module | DYT internal + similar B2B2C businesses |

**Key Differentiators:**
1. **Exasol-native** - No existing competitors
2. **Raw data access** - Full SQL, not pre-built dashboards
3. **Price competitiveness** - Below $400/mo SaaS tools
4. **B2B2C capability** - Unique extension for voucher models

---

#### Sources

- [ReportGenix - Shopify Analytics Issues 2025](https://reportgenix.com/shopify-analytics-issues-2025/)
- [Putler - Issues Shopify Stores Face](https://www.putler.com/issues-shopify-stores/)
- [Plausible - Shopify Analytics](https://plausible.io/blog/shopify-analytics)
- [Conjura - Triple Whale Alternatives 2025](https://www.conjura.com/blog/triple-whale-alternatives-2025/)
- [CB Insights - Triple Whale Competitors](https://www.cbinsights.com/research/triple-whale-competitors-daasity-peel-insights-polar-analytics-wicked-reports/)
- [PRNewswire - Triple Whale Raises $27.7M](https://www.prnewswire.com/news-releases/triple-whale-raises-27-7m-to-develop-default-ecommerce-operating-system-for-shopify-brands-301510122.html)
- [Verified Market Reports - E-commerce Analytics Software](https://www.verifiedmarketreports.com/product/e-commerce-analytics-software-market/)
- [Knowledge Sourcing - E-commerce Analytics Market](https://www.knowledge-sourcing.com/report/global-e-commerce-analytics-market)
- [Omnisend - Shopify Statistics 2026](https://www.omnisend.com/blog/shopify-statistics/)
- [Improvado - Shopify Dashboard Guide](https://improvado.io/blog/shopify-dashboard)

---

### 2026-02-03 - Exasol Personal Edition (Game-Changer for Productization)

**Topic:** New Exasol Personal edition and its impact on go-to-market strategy

**Key Finding:** Exasol Personal dramatically lowers the barrier to entry for a Shopify DWH product. Users only pay for AWS infrastructure (~$20/mo), not Exasol licensing.

---

#### What is Exasol Personal?

Released late 2025/early 2026, designed for individuals, developers, and data scientists.

**Core Value Proposition:**
- **100% free** Exasol software for single-user/personal use
- **No feature limits** - All enterprise features included
- **No artificial caps** - Unlimited data, unlimited nodes, unlimited memory
- **Bring Your Own Cloud** - Currently AWS; Azure and GCP coming soon

**Deployment:**
- Uses **Exasol Launcher** CLI tool (runs on Linux, Mac, Windows)
- Deploys to Intel-based EC2 instances in user's own AWS account
- Can spin up distributed clusters in minutes

---

#### Cost Structure

| Component | Cost | Notes |
|-----------|------|-------|
| Exasol Software | **$0** | Free for personal use |
| AWS EC2 (t3.small) | ~$15/mo | On-demand pricing |
| AWS EBS (30GB) | ~$2/mo | Storage volume |
| AWS S3 (50GB) | ~$1/mo | Optional object storage |
| Data Transfer | Free (100GB) | AWS free tier |
| **Total** | **~$20/mo** | Basic setup |

**Comparison to competitors:**
| Solution | Monthly Cost |
|----------|--------------|
| Triple Whale | $429+ |
| Polar Analytics | $720+ |
| **Exasol Personal + our ETL** | **~$20-50** |

---

#### Features Included (No Gating)

- Full SQL analytics at any scale
- Distributed computing across nodes
- Native UDF support (Python, R, Java, Lua)
- GPU acceleration (7x speedup for AI/ML)
- 30+ SQL dialect compatibility
- Native dbt integration
- Model Context Protocol support (AI-ready)

---

#### Strategic Implications for Shopify DWH Product

**Before Exasol Personal:**
- Target market limited to enterprises with Exasol licenses
- High barrier to entry
- Complex sales cycle

**After Exasol Personal (IF licensing permits):**
- **Individual merchants** can self-serve
- **Developers/agencies** can prototype and demo freely
- **Small teams** would need commercial Exasol license

**Go-to-Market Options (Pending License Clarification):**

| Tier | Target | Offering | Exasol License | Price Point |
|------|--------|----------|----------------|-------------|
| **Dev/Eval** | Developers, prototyping | Open-source ETL + docs | Personal (free) | Free |
| **Solo Merchant** | Single-user businesses | ETL + dashboards | Personal (if permitted) OR commercial | $49-99/mo + AWS |
| **Team** | Multi-user businesses | Full DWH + support | Commercial license required | $299+/mo |
| **Enterprise** | Large/multi-store | Custom + SLA | Commercial license | Custom |

**Key Insight:** Exasol Personal is valuable for **development, demos, and possibly solo merchants**, but team/commercial scenarios likely require commercial Exasol licensing.

**Alternative Strategies if Personal License Too Restrictive:**

1. **Partner with Exasol** - Explore reseller/OEM arrangements
2. **Exasol SaaS** - Use managed Exasol (different pricing model)
3. **Alternative DB** - Consider DuckDB, ClickHouse, or PostgreSQL for lower tiers
4. **Hybrid** - Personal for dev/solo, Commercial for teams

---

#### Product Architecture Options

**Option A: Open-Source ETL + Premium Dashboards**
```
Free tier:
- Open-source Shopify → Exasol ETL
- Self-hosted on Exasol Personal
- Community support

Paid tier:
- Pre-built BI dashboards
- Managed ETL service
- Priority support
```

**Option B: Managed Service on Customer's AWS**
```
- We deploy and manage Exasol Personal in customer's AWS
- They own the infrastructure
- We provide ETL, transforms, dashboards
- Fixed monthly fee
```

**Option C: Hybrid**
```
- Self-service for technical users
- Managed service for non-technical merchants
- Enterprise for complex requirements
```

---

#### ⚠️ Licensing Considerations (CRITICAL - Requires Clarification)

**What Exasol States:**
- "Free for personal use at any scale"
- "You can use it at home, at your studies or **at work**"
- "Single-user edition" - limited to one user
- "Intended for personal use and evaluation"

**Ambiguous Areas:**
| Question | Status |
|----------|--------|
| Can a single person use it for their employer's business analytics? | Unclear - "at work" suggests yes |
| Can it power a commercial SaaS product? | Likely NO - "personal use" implies individual benefit |
| Can customers use it to run their own Shopify analytics? | Possibly - if single user running their own business analytics |
| Can we resell/bundle it? | Almost certainly NO |

**Key Restriction:**
- Single-user only - no team access without upgrade
- This inherently limits commercial deployment scenarios

**Before Productizing - MUST:**
1. Review full EULA at [Exasol Terms & Conditions](https://www.exasol.com/terms-and-conditions/)
2. Contact Exasol directly to clarify:
   - Can a merchant use Personal edition for their own business analytics?
   - What are the upgrade triggers/pricing?
   - Partner/reseller program options?

**STATUS: PARKED** - Dominic has strong Exasol connections; will clarify directly.

**Likely Scenarios:**

| Use Case | Likely Permitted? | Notes |
|----------|-------------------|-------|
| Developer building/testing ETL | ✅ Yes | Evaluation/development use |
| Solo merchant running own analytics | ⚠️ Maybe | "At work" + single-user fits |
| Team accessing shared dashboards | ❌ No | Violates single-user |
| SaaS product powered by Personal | ❌ No | Commercial service, not personal |
| Consulting engagement (your AWS) | ⚠️ Maybe | Depends on EULA interpretation |

---

#### Technical Considerations

**Exasol Personal Constraints:**
- Single-user license (not for teams without upgrade)
- Bring Your Own AWS (customer manages account)
- Intel-based EC2 only (currently)

**ETL Deployment:**
- Can run on same EC2 as Exasol or separate
- systemd timers for scheduling (already designed)
- PyExasol for fast bulk loading (already selected)

**Scaling Path:**
- Start with Exasol Personal (free)
- Upgrade to Exasol Cloud or Enterprise when needed
- Our ETL/transforms work identically

---

#### Sources

- [Exasol Blog - Introducing Exasol Personal](https://www.exasol.com/blog/introducing-exasol-personal/)
- [Exasol Blog - 8 Release 2025.2](https://www.exasol.com/blog/exasol-8-release-2025-2/)
- [Exasol Docs - Editions Overview](https://docs.exasol.com/db/latest/get_started/exasol_editions.htm)
- [Exasol Docs - AWS Deployment](https://docs.exasol.com/db/latest/get_started/cloud_platforms/aws.htm)

---

## Research Topics

### Active
- [ ] dim_time consideration (time-of-day analysis)
- [ ] View layer for calculated measures
- [ ] **PARKED:** Clarify Exasol Personal license terms for commercial use scenarios
  - Dominic to discuss directly with Exasol contacts
  - Key questions: solo merchant use, partner/reseller options, upgrade pricing

### Completed
- [x] Initial system setup
- [x] Business context documentation
- [x] Data modeling approach (star schema selected)
- [x] Shopify Orders data model mapping
- [x] DWH schema design (facts + dimensions)
- [x] Competitive landscape research
- [x] Products API research
- [x] InventoryItem API research
- [x] Discount/Voucher API research
- [x] Orders API research & schema validation
- [x] Customers API research & schema validation
- [x] Fulfillment API research
- [x] Inventory domain decision (dim_location added)
- [x] Exasol-specific optimizations
- [x] ETL tool evaluation (Custom Python + PyExasol)
- [x] Multi-currency handling (Option B - currency in dim_order)
- [x] Market perception research - Shopify native reporting pain points
- [x] Exasol Personal edition research - game-changer for pricing strategy

### Future / Layer 2
- [ ] Metafields (custom data for DYT)
- [ ] BI platform selection
- [ ] Data quality monitoring

---

## Ideas & Future Improvements

- [ ] Create Shopify API query templates
- [ ] Build voucher lifecycle tracking dashboard
- [ ] Develop corporate client attribution logic
- [ ] **Productization opportunity:** Generic Shopify-to-Exasol DWH as standalone product
  - Market validated: $16B+ market, 12.5% CAGR
  - Competitors pricing $400-700/mo (Triple Whale, Polar)
  - Exasol Personal may enable lower price point for solo users (~$20-50/mo)
  - ⚠️ **Licensing caveat:** Must clarify if Personal license permits commercial use
  - Consider: open-source ETL (free) + premium dashboards/support (paid tiers)
  - Alternative: Partner with Exasol or consider hybrid DB strategy for different tiers

---

## External References

- **Shopify API Docs:** https://shopify.dev/docs/api
- **Shopify Admin API:** https://shopify.dev/docs/api/admin
- **Second Brain system:** See CLAUDE.md

---

## Quick Capture

<!-- Use this section for quick notes during research sessions -->
<!-- Move organized content to appropriate sections above -->
