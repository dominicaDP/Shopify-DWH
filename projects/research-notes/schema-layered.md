# Shopify DWH - Layered Schema Design

**Version:** 1.0
**Last Updated:** 2026-01-30

This document defines the two-layer architecture: Staging (STG) mirrors Shopify, DWH is reporting-optimized.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Shopify GraphQL API                                            │
│  POST /admin/api/2024-01/graphql.json                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SHOPIFY_STG (Staging Schema)                                   │
│                                                                 │
│  • Raw data, mirrors Shopify API structure                      │
│  • Row-based, normalized (1 row per transaction, tax line, etc)│
│  • Field names match Shopify API (camelCase → snake_case)      │
│  • No business logic, no transformations                        │
│  • Transient - can be truncated after DWH load                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ Transform + Pivot + Denormalize
┌─────────────────────────────────────────────────────────────────┐
│  SHOPIFY_DWH (Data Warehouse Schema)                            │
│                                                                 │
│  • Reporting-optimized, columnar-friendly                       │
│  • Pivoted arrays → columns (payments, taxes, discounts)       │
│  • Denormalized dimension attributes on facts                   │
│  • User-friendly field names                                    │
│  • Business logic applied (derived flags, calculations)        │
│  • Permanent storage, historical                                │
└─────────────────────────────────────────────────────────────────┘
```

---

# STAGING SCHEMA (SHOPIFY_STG)

Mirrors Shopify API structure exactly. One table per API object.

---

## stg_orders

**Source:** `orders` query → `Order` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Shopify GID (raw) |
| name | name | VARCHAR(20) | Order number (#1001) |
| email | email | VARCHAR(255) | Customer email on order |
| created_at | createdAt | TIMESTAMP | Order creation time |
| processed_at | processedAt | TIMESTAMP | Payment processing time |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| cancelled_at | cancelledAt | TIMESTAMP | Cancellation time |
| closed_at | closedAt | TIMESTAMP | Order closed time |
| cancel_reason | cancelReason | VARCHAR(50) | Cancellation reason |
| currency_code | currencyCode | VARCHAR(5) | Shop currency |
| subtotal_price | subtotalPriceSet.shopMoney.amount | DECIMAL(18,2) | Subtotal |
| total_discounts | totalDiscountsSet.shopMoney.amount | DECIMAL(18,2) | Total discounts |
| total_tax | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | Total tax |
| total_shipping | totalShippingPriceSet.shopMoney.amount | DECIMAL(18,2) | Shipping cost |
| total_price | totalPriceSet.shopMoney.amount | DECIMAL(18,2) | Order total |
| total_refunded | totalRefundedSet.shopMoney.amount | DECIMAL(18,2) | Refunded amount |
| financial_status | displayFinancialStatus | VARCHAR(50) | Payment status |
| fulfillment_status | displayFulfillmentStatus | VARCHAR(50) | Fulfillment status |
| customer_id | customer.id | VARCHAR(50) | Customer GID |
| shipping_address_json | shippingAddress | TEXT | Full address JSON |
| billing_address_json | billingAddress | TEXT | Full address JSON |
| tags | tags | TEXT | Comma-separated tags |
| note | note | TEXT | Order notes |
| source_name | sourceName | VARCHAR(50) | Channel source (web, pos, mobile, etc.) |
| landing_site | landingSite | TEXT | First URL customer landed on |
| referring_site | referringSite | TEXT | Referring URL |
| checkout_id | checkoutId | VARCHAR(50) | Associated checkout GID |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_order_line_items

**Source:** `orders` query → `Order.lineItems` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Line item GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| variant_id | variant.id | VARCHAR(50) | Product variant GID |
| product_id | variant.product.id | VARCHAR(50) | Product GID |
| title | title | VARCHAR(255) | Product title at time of sale |
| variant_title | variantTitle | VARCHAR(255) | Variant title |
| sku | sku | VARCHAR(100) | SKU |
| quantity | quantity | INT | Quantity ordered |
| current_quantity | currentQuantity | INT | Current quantity (after refunds) |
| unfulfilled_quantity | unfulfilledQuantity | INT | Unfulfilled quantity |
| unit_price | originalUnitPriceSet.shopMoney.amount | DECIMAL(18,2) | Unit price |
| total_price | originalTotalSet.shopMoney.amount | DECIMAL(18,2) | Line subtotal |
| total_discount | totalDiscountSet.shopMoney.amount | DECIMAL(18,2) | Line discount |
| discounted_total | discountedTotalSet.shopMoney.amount | DECIMAL(18,2) | Final line total |
| is_gift_card | isGiftCard | BOOLEAN | Gift card flag |
| taxable | taxable | BOOLEAN | Taxable flag |
| requires_shipping | requiresShipping | BOOLEAN | Requires shipping |
| fulfillable_quantity | fulfillableQuantity | INT | Quantity that can be fulfilled |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_order_transactions

**Source:** `orders` query → `Order.transactions` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Transaction GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| kind | kind | VARCHAR(20) | SALE, REFUND, CAPTURE, etc. |
| status | status | VARCHAR(20) | SUCCESS, PENDING, FAILURE, ERROR |
| gateway | gateway | VARCHAR(100) | Payment gateway name |
| amount | amountSet.shopMoney.amount | DECIMAL(18,2) | Transaction amount |
| currency_code | amountSet.shopMoney.currencyCode | VARCHAR(5) | Currency |
| created_at | createdAt | TIMESTAMP | Transaction time |
| processed_at | processedAt | TIMESTAMP | Processing time |
| error_code | errorCode | VARCHAR(50) | Error code if failed |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_order_tax_lines

**Source:** `orders` query → `Order.taxLines` array

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| line_number | (array index) | INT | Position in array (1, 2, 3...) |
| title | title | VARCHAR(100) | Tax name |
| rate | rate | DECIMAL(10,6) | Tax rate (0.15 = 15%) |
| price | priceSet.shopMoney.amount | DECIMAL(18,2) | Tax amount |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_order_discount_applications

**Source:** `orders` query → `Order.discountApplications` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| line_number | (array index) | INT | Position in array |
| discount_type | __typename | VARCHAR(50) | DiscountCodeApplication, ManualDiscountApplication, etc. |
| code | code | VARCHAR(100) | Discount code (if code-based) |
| title | title | VARCHAR(255) | Discount title |
| description | description | TEXT | Description |
| value_type | value.__typename | VARCHAR(20) | MoneyV2 or PricingPercentageValue |
| value_amount | value.amount | DECIMAL(18,2) | Fixed amount (if applicable) |
| value_percentage | value.percentage | DECIMAL(5,2) | Percentage (if applicable) |
| target_type | targetType | VARCHAR(20) | LINE_ITEM or SHIPPING_LINE |
| allocation_method | allocationMethod | VARCHAR(20) | ACROSS, EACH, ONE |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_order_shipping_lines

**Source:** `orders` query → `Order.shippingLines` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Shipping line GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| title | title | VARCHAR(255) | Shipping method name |
| code | code | VARCHAR(100) | Shipping method code |
| source | source | VARCHAR(100) | Shipping rate source |
| original_price | originalPriceSet.shopMoney.amount | DECIMAL(18,2) | Original shipping price |
| discounted_price | discountedPriceSet.shopMoney.amount | DECIMAL(18,2) | After discounts |
| carrier_identifier | carrierIdentifier | VARCHAR(100) | Carrier ID |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_customers

**Source:** `customers` query → `Customer` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Customer GID |
| email | defaultEmailAddress.emailAddress | VARCHAR(255) | Primary email |
| phone | defaultPhoneNumber.phoneNumber | VARCHAR(50) | Primary phone |
| first_name | firstName | VARCHAR(100) | First name |
| last_name | lastName | VARCHAR(100) | Last name |
| email_marketing_state | defaultEmailAddress.marketingState | VARCHAR(20) | SUBSCRIBED, UNSUBSCRIBED, etc. |
| sms_marketing_state | defaultPhoneNumber.marketingState | VARCHAR(20) | SMS consent state |
| created_at | createdAt | TIMESTAMP | Account creation |
| updated_at | updatedAt | TIMESTAMP | Last update |
| number_of_orders | numberOfOrders | INT | Order count |
| amount_spent | amountSpent.amount | DECIMAL(18,2) | Lifetime spend |
| default_address_json | defaultAddress | TEXT | Default address JSON |
| tags | tags | TEXT | Comma-separated tags |
| note | note | TEXT | Customer notes |
| tax_exempt | taxExempt | BOOLEAN | Tax exempt flag |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_products

**Source:** `products` query → `Product` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Product GID |
| title | title | VARCHAR(255) | Product title |
| handle | handle | VARCHAR(255) | URL handle |
| description | description | TEXT | Description |
| product_type | productType | VARCHAR(255) | Product type/category |
| vendor | vendor | VARCHAR(255) | Vendor name |
| status | status | VARCHAR(20) | ACTIVE, DRAFT, ARCHIVED |
| created_at | createdAt | TIMESTAMP | Creation time |
| updated_at | updatedAt | TIMESTAMP | Last update |
| published_at | publishedAt | TIMESTAMP | Publication time |
| tags | tags | TEXT | Comma-separated tags |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_product_variants

**Source:** `productVariants` query → `ProductVariant` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Variant GID |
| product_id | product.id | VARCHAR(50) | Parent product GID |
| title | title | VARCHAR(255) | Variant title |
| sku | sku | VARCHAR(100) | SKU |
| barcode | barcode | VARCHAR(100) | Barcode |
| price | price | DECIMAL(18,2) | Current price |
| compare_at_price | compareAtPrice | DECIMAL(18,2) | Compare at price |
| cost | inventoryItem.unitCost.amount | DECIMAL(18,2) | Unit cost |
| taxable | taxable | BOOLEAN | Taxable flag |
| requires_shipping | requiresShipping | BOOLEAN | Physical product |
| weight | weight | DECIMAL(10,2) | Weight |
| weight_unit | weightUnit | VARCHAR(10) | g, kg, lb, oz |
| option1 | selectedOptions[0].value | VARCHAR(255) | First option value |
| option2 | selectedOptions[1].value | VARCHAR(255) | Second option value |
| option3 | selectedOptions[2].value | VARCHAR(255) | Third option value |
| inventory_item_id | inventoryItem.id | VARCHAR(50) | Inventory item GID |
| created_at | createdAt | TIMESTAMP | Creation time |
| updated_at | updatedAt | TIMESTAMP | Last update |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_discount_codes

**Source:** `codeDiscountNodes` query → `DiscountCodeNode` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Discount node GID |
| code | codeDiscount.codes.nodes[].code | VARCHAR(100) | The discount code |
| title | codeDiscount.title | VARCHAR(255) | Discount title |
| discount_type | codeDiscount.__typename | VARCHAR(50) | DiscountCodeBasic, etc. |
| status | codeDiscount.status | VARCHAR(20) | ACTIVE, EXPIRED, SCHEDULED |
| value_type | customerGets.value.__typename | VARCHAR(30) | MoneyV2 or PricingPercentageValue |
| value_amount | customerGets.value.amount | DECIMAL(18,2) | Fixed amount |
| value_percentage | customerGets.value.percentage | DECIMAL(5,2) | Percentage |
| starts_at | codeDiscount.startsAt | TIMESTAMP | Start date |
| ends_at | codeDiscount.endsAt | TIMESTAMP | End date |
| usage_limit | codeDiscount.usageLimit | INT | Total usage limit |
| usage_count | codes.nodes[].asyncUsageCount | INT | Current usage |
| applies_once_per_customer | codeDiscount.appliesOncePerCustomer | BOOLEAN | Per-customer limit |
| created_at | codeDiscount.createdAt | TIMESTAMP | Creation time |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_locations

**Source:** `locations` query → `Location` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Location GID |
| name | name | VARCHAR(255) | Location name |
| address1 | address.address1 | VARCHAR(255) | Street address |
| address2 | address.address2 | VARCHAR(255) | Address line 2 |
| city | address.city | VARCHAR(100) | City |
| province | address.province | VARCHAR(100) | Province/State |
| province_code | address.provinceCode | VARCHAR(10) | Province code |
| country | address.country | VARCHAR(100) | Country |
| country_code | address.countryCode | VARCHAR(5) | Country code |
| zip | address.zip | VARCHAR(20) | Postal code |
| phone | address.phone | VARCHAR(50) | Phone number |
| is_active | isActive | BOOLEAN | Active flag |
| fulfills_online_orders | fulfillsOnlineOrders | BOOLEAN | Fulfills online orders |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_fulfillments

**Source:** `orders` query → `Order.fulfillments` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Fulfillment GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| status | status | VARCHAR(20) | SUCCESS, PENDING, CANCELLED, ERROR, FAILURE |
| created_at | createdAt | TIMESTAMP | Fulfillment creation time |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| tracking_number | trackingInfo.number | VARCHAR(255) | Tracking number |
| tracking_company | trackingInfo.company | VARCHAR(100) | Carrier name |
| tracking_url | trackingInfo.url | TEXT | Tracking URL |
| location_id | location.id | VARCHAR(50) | Fulfillment location GID |
| service | service.serviceName | VARCHAR(100) | Shipping service name |
| shipment_status | displayStatus | VARCHAR(50) | LABEL_PRINTED, LABEL_PURCHASED, etc. |
| total_quantity | totalQuantity | INT | Total items fulfilled |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_fulfillment_line_items

**Source:** `orders` query → `Order.fulfillments.fulfillmentLineItems` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| fulfillment_id | (parent fulfillment) | VARCHAR(50) | Parent fulfillment GID |
| line_item_id | lineItem.id | VARCHAR(50) | Original line item GID |
| quantity | quantity | INT | Quantity fulfilled in this shipment |
| original_total | originalTotalSet.shopMoney.amount | DECIMAL(18,2) | Original total for fulfilled items |
| discounted_total | discountedTotalPriceSet.shopMoney.amount | DECIMAL(18,2) | Discounted total for fulfilled items |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_refunds

**Source:** `orders` query → `Order.refunds` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Refund GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| created_at | createdAt | TIMESTAMP | Refund creation time |
| note | note | TEXT | Refund note/reason |
| total_refunded | totalRefundedSet.shopMoney.amount | DECIMAL(18,2) | Total refund amount |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_refund_line_items

**Source:** `orders` query → `Order.refunds.refundLineItems` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| refund_id | (parent refund) | VARCHAR(50) | Parent refund GID |
| line_item_id | lineItem.id | VARCHAR(50) | Original line item GID |
| quantity | quantity | INT | Quantity refunded |
| restock_type | restockType | VARCHAR(20) | NO_RESTOCK, CANCEL, RETURN, LEGACY_RESTOCK |
| location_id | location.id | VARCHAR(50) | Restock location GID |
| subtotal_amount | subtotalSet.shopMoney.amount | DECIMAL(18,2) | Line item subtotal refunded |
| total_tax_amount | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | Tax amount refunded |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## stg_inventory_levels

**Source:** `inventoryLevels` query → `InventoryLevel` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| inventory_item_id | item.id | VARCHAR(50) | Inventory item GID |
| location_id | location.id | VARCHAR(50) | Location GID |
| available | quantities.available | INT | Available to sell |
| on_hand | quantities.on_hand | INT | Physically in stock |
| committed | quantities.committed | INT | Reserved for orders |
| incoming | quantities.incoming | INT | Expected from purchase orders |
| reserved | quantities.reserved | INT | Reserved for other reasons |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| snapshot_date | ETL | DATE | Snapshot date for historical tracking |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

**Note:** This table stores daily snapshots for inventory trend analysis.

---

## stg_abandoned_checkouts

**Source:** `abandonedCheckouts` query → `Checkout` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Checkout GID |
| created_at | createdAt | TIMESTAMP | Checkout creation time |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| completed_at | completedAt | TIMESTAMP | Completion time (NULL if abandoned) |
| customer_id | customer.id | VARCHAR(50) | Customer GID (if logged in) |
| email | email | VARCHAR(255) | Customer email |
| phone | phone | VARCHAR(50) | Customer phone |
| subtotal_price | subtotalPriceSet.shopMoney.amount | DECIMAL(18,2) | Subtotal |
| total_tax | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | Tax amount |
| total_price | totalPriceSet.shopMoney.amount | DECIMAL(18,2) | Total price |
| currency_code | currencyCode | VARCHAR(5) | Currency |
| abandoned_checkout_url | abandonedCheckoutUrl | TEXT | Recovery URL |
| line_items_count | lineItems.edges.length | INT | Number of line items |
| line_items_json | lineItems | TEXT | Line items JSON for analysis |
| shipping_address_json | shippingAddress | TEXT | Shipping address JSON |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

**Note:** Only checkouts where `completedAt IS NULL` are truly abandoned.

---

# DATA WAREHOUSE SCHEMA (SHOPIFY_DWH)

Reporting-optimized with pivoted arrays, denormalized attributes, and user-friendly names.

---

## dim_date

**Source:** Generated (not from Shopify)

| Column | Type | Description |
|--------|------|-------------|
| date_key | INT | Primary key (YYYYMMDD) |
| full_date | DATE | Actual date |
| year | INT | Year (2026) |
| quarter | INT | Quarter (1-4) |
| month | INT | Month (1-12) |
| month_name | VARCHAR(20) | January, February... |
| week_of_year | INT | Week number (1-53) |
| day_of_month | INT | Day (1-31) |
| day_of_week | INT | Day number (1=Monday) |
| day_name | VARCHAR(20) | Monday, Tuesday... |
| is_weekend | BOOLEAN | Saturday/Sunday |
| is_month_end | BOOLEAN | Last day of month |
| fiscal_year | INT | Fiscal year |
| fiscal_quarter | INT | Fiscal quarter |

---

## dim_time

**Source:** Generated (24 rows, one per hour)

| Column | Type | Description |
|--------|------|-------------|
| time_key | INT | Primary key (0-23) |
| hour_24 | INT | Hour in 24h format |
| hour_12 | INT | Hour in 12h format |
| am_pm | VARCHAR(2) | AM or PM |
| hour_label | VARCHAR(10) | "9:00 AM" |
| day_part | VARCHAR(15) | Morning, Afternoon, Evening, Night |
| is_business_hours | BOOLEAN | 9:00-17:00 |

---

## dim_customer

**Source:** stg_customers + aggregations from stg_orders

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| customer_key | BIGINT | IDENTITY | Surrogate key |
| customer_id | VARCHAR(50) | stg_customers.id → extract_id() | Shopify customer ID |
| email | VARCHAR(255) | stg_customers.email | Email address |
| first_name | VARCHAR(100) | stg_customers.first_name | First name |
| last_name | VARCHAR(100) | stg_customers.last_name | Last name |
| full_name | VARCHAR(200) | first_name + ' ' + last_name | Full name |
| phone | VARCHAR(50) | stg_customers.phone | Phone number |
| accepts_email_marketing | BOOLEAN | email_marketing_state IN ('SUBSCRIBED','PENDING') | Email opt-in |
| accepts_sms_marketing | BOOLEAN | sms_marketing_state IN ('SUBSCRIBED','PENDING') | SMS opt-in |
| customer_created_date | DATE | stg_customers.created_at | Account creation date |
| default_country | VARCHAR(100) | stg_customers.default_address_json → country | Default country |
| default_city | VARCHAR(100) | stg_customers.default_address_json → city | Default city |
| tags | VARCHAR(1000) | stg_customers.tags | Customer tags |
| is_tax_exempt | BOOLEAN | stg_customers.tax_exempt | Tax exempt flag |
| lifetime_order_count | INT | COUNT(stg_orders) | Total orders |
| lifetime_revenue | DECIMAL(18,2) | SUM(stg_orders.total_price) | Total spend |
| first_order_date | DATE | MIN(stg_orders.created_at) | First purchase |
| last_order_date | DATE | MAX(stg_orders.created_at) | Most recent purchase |
| average_order_value | DECIMAL(18,2) | lifetime_revenue / lifetime_order_count | AOV |
| days_since_last_order | INT | CURRENT_DATE - last_order_date | Recency |
| customer_segment | VARCHAR(20) | Business logic | New/Active/At-Risk/Lapsed |
| **RFM Segmentation** |
| rfm_recency_score | INT | Recency quintile (1-5) | 5 = most recent |
| rfm_frequency_score | INT | Frequency quintile (1-5) | 5 = most frequent |
| rfm_monetary_score | INT | Monetary quintile (1-5) | 5 = highest spend |
| rfm_combined_score | INT | R + F + M (3-15) | Overall RFM score |
| rfm_segment | VARCHAR(30) | RFM business logic | Champions, Loyal, At Risk, etc. |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

**RFM Segment Definitions:**
| Segment | R Score | F Score | M Score | Description |
|---------|---------|---------|---------|-------------|
| Champions | 5 | 5 | 5 | Best customers, recent high-value frequent buyers |
| Loyal | 4-5 | 4-5 | 3-5 | Consistent valuable customers |
| Potential Loyalists | 4-5 | 2-3 | 2-3 | Recent customers with growth potential |
| New Customers | 5 | 1 | 1-3 | Just acquired, opportunity to nurture |
| Promising | 3-4 | 1-2 | 1-2 | Recent but low engagement |
| Needs Attention | 3 | 3 | 3 | Average across all dimensions |
| About to Sleep | 2-3 | 2-3 | 2-3 | Declining engagement |
| At Risk | 1-2 | 4-5 | 4-5 | Were valuable, now inactive |
| Can't Lose | 1-2 | 4-5 | 5 | Highest value but churning |
| Hibernating | 1-2 | 1-2 | 1-2 | Low value, inactive |
| Lost | 1 | 1 | 1 | No recent activity, low historical value |

---

## dim_product

**Source:** stg_products + stg_product_variants

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| product_key | BIGINT | IDENTITY | Surrogate key |
| product_id | VARCHAR(50) | stg_products.id → extract_id() | Shopify product ID |
| variant_id | VARCHAR(50) | stg_product_variants.id → extract_id() | Shopify variant ID |
| sku | VARCHAR(100) | stg_product_variants.sku | SKU |
| barcode | VARCHAR(100) | stg_product_variants.barcode | Barcode/UPC |
| product_title | VARCHAR(255) | stg_products.title | Product name |
| variant_title | VARCHAR(255) | stg_product_variants.title | Variant name |
| full_title | VARCHAR(500) | product_title + ' - ' + variant_title | Combined title |
| product_type | VARCHAR(255) | stg_products.product_type | Category |
| vendor | VARCHAR(255) | stg_products.vendor | Vendor/Brand |
| option_1_value | VARCHAR(255) | stg_product_variants.option1 | Size, etc. |
| option_2_value | VARCHAR(255) | stg_product_variants.option2 | Color, etc. |
| option_3_value | VARCHAR(255) | stg_product_variants.option3 | Material, etc. |
| current_price | DECIMAL(18,2) | stg_product_variants.price | Current selling price |
| compare_at_price | DECIMAL(18,2) | stg_product_variants.compare_at_price | Original/compare price |
| unit_cost | DECIMAL(18,2) | stg_product_variants.cost | Cost of goods |
| is_on_sale | BOOLEAN | compare_at_price > price | On sale flag |
| discount_percentage | DECIMAL(5,2) | (compare_at_price - price) / compare_at_price * 100 | Sale discount % |
| is_taxable | BOOLEAN | stg_product_variants.taxable | Taxable flag |
| requires_shipping | BOOLEAN | stg_product_variants.requires_shipping | Physical product |
| weight_grams | DECIMAL(10,2) | Normalized to grams | Weight in grams |
| product_status | VARCHAR(20) | stg_products.status | ACTIVE/DRAFT/ARCHIVED |
| tags | VARCHAR(1000) | stg_products.tags | Product tags |
| product_created_date | DATE | stg_products.created_at | Product creation |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## dim_geography

**Source:** Unique addresses from stg_orders (shipping + billing)

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| geography_key | BIGINT | IDENTITY | Surrogate key |
| address_hash | VARCHAR(64) | hash_address() | Deduplication hash |
| city | VARCHAR(255) | address.city | City |
| province | VARCHAR(255) | address.province | State/Province |
| province_code | VARCHAR(10) | address.provinceCode | Province code |
| country | VARCHAR(100) | address.country | Country name |
| country_code | VARCHAR(5) | address.countryCodeV2 | ISO country code |
| postal_code | VARCHAR(20) | address.zip | Postal/ZIP code |
| region | VARCHAR(50) | Derived from country | Geographic region |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## dim_discount

**Source:** stg_discount_codes

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| discount_key | BIGINT | IDENTITY (0 = No Discount) | Surrogate key |
| discount_id | VARCHAR(50) | stg_discount_codes.id → extract_id() | Shopify discount ID |
| discount_code | VARCHAR(100) | stg_discount_codes.code | The code itself |
| discount_title | VARCHAR(255) | stg_discount_codes.title | Friendly name |
| discount_type | VARCHAR(50) | map_discount_type() | basic/bxgy/free_shipping/app |
| value_type | VARCHAR(20) | fixed_amount or percentage | Type of value |
| discount_value | DECIMAL(18,2) | Amount or percentage | Value |
| discount_status | VARCHAR(20) | stg_discount_codes.status | ACTIVE/EXPIRED/SCHEDULED |
| starts_at | DATE | stg_discount_codes.starts_at | Start date |
| ends_at | DATE | stg_discount_codes.ends_at | End date |
| usage_limit | INT | stg_discount_codes.usage_limit | Max uses |
| current_usage_count | INT | stg_discount_codes.usage_count | Times used |
| is_one_per_customer | BOOLEAN | stg_discount_codes.applies_once_per_customer | Limit flag |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## dim_location

**Source:** stg_locations

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| location_key | BIGINT | IDENTITY | Surrogate key |
| location_id | VARCHAR(50) | stg_locations.id → extract_id() | Shopify location ID |
| location_name | VARCHAR(255) | stg_locations.name | Location name |
| address | VARCHAR(500) | Concatenated address | Full address |
| city | VARCHAR(100) | stg_locations.city | City |
| province | VARCHAR(100) | stg_locations.province | Province |
| country | VARCHAR(100) | stg_locations.country | Country |
| country_code | VARCHAR(5) | stg_locations.country_code | Country code |
| is_active | BOOLEAN | stg_locations.is_active | Active flag |
| fulfills_online | BOOLEAN | stg_locations.fulfills_online_orders | Online fulfillment |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## fact_order

**Source:** stg_orders + pivoted data from stg_order_transactions, stg_order_tax_lines, stg_order_discount_applications, stg_order_shipping_lines

**Grain:** One row per order (header level with pivoted details)

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| order_key | BIGINT | IDENTITY | Surrogate key |
| order_date_key | INT | stg_orders.created_at → to_date_key() | FK to dim_date |
| order_time_key | INT | stg_orders.created_at → to_time_key() | FK to dim_time |
| customer_key | BIGINT | stg_orders.customer_id → lookup | FK to dim_customer |
| shipping_geography_key | BIGINT | shipping_address → lookup | FK to dim_geography |
| billing_geography_key | BIGINT | billing_address → lookup | FK to dim_geography |
| **Order Identifiers** |
| order_id | VARCHAR(50) | stg_orders.id → extract_id() | Shopify order ID |
| order_number | VARCHAR(20) | stg_orders.name | Display order # |
| order_email | VARCHAR(255) | stg_orders.email | Customer email |
| checkout_id | VARCHAR(50) | stg_orders.checkout_id → extract_id() | Associated checkout ID |
| **Channel & Attribution** |
| source_name | VARCHAR(50) | stg_orders.source_name | Channel (web, pos, mobile) |
| landing_site | TEXT | stg_orders.landing_site | First URL landed |
| referring_site | TEXT | stg_orders.referring_site | Referrer URL |
| **Timestamps** |
| order_created_at | TIMESTAMP | stg_orders.created_at | Order creation |
| order_processed_at | TIMESTAMP | stg_orders.processed_at | Payment processed |
| order_cancelled_at | TIMESTAMP | stg_orders.cancelled_at | Cancellation time |
| order_closed_at | TIMESTAMP | stg_orders.closed_at | Order closed |
| **Financial - Base** |
| subtotal_amount | DECIMAL(18,2) | stg_orders.subtotal_price | Subtotal |
| shipping_amount | DECIMAL(18,2) | stg_orders.total_shipping | Shipping cost |
| tax_amount | DECIMAL(18,2) | stg_orders.total_tax | Total tax |
| discount_amount | DECIMAL(18,2) | stg_orders.total_discounts | Total discounts |
| total_amount | DECIMAL(18,2) | stg_orders.total_price | Order total |
| refund_amount | DECIMAL(18,2) | stg_orders.total_refunded | Refunded amount |
| net_amount | DECIMAL(18,2) | total_amount - refund_amount | Net revenue |
| currency_code | VARCHAR(5) | stg_orders.currency_code | Currency |
| **Payments - Pivoted (up to 3)** |
| payment_1_gateway | VARCHAR(100) | stg_order_transactions[0].gateway | First payment method |
| payment_1_amount | DECIMAL(18,2) | stg_order_transactions[0].amount | First payment amount |
| payment_2_gateway | VARCHAR(100) | stg_order_transactions[1].gateway | Second payment method |
| payment_2_amount | DECIMAL(18,2) | stg_order_transactions[1].amount | Second payment amount |
| payment_3_gateway | VARCHAR(100) | stg_order_transactions[2].gateway | Third payment method |
| payment_3_amount | DECIMAL(18,2) | stg_order_transactions[2].amount | Third payment amount |
| total_payment_count | INT | COUNT(stg_order_transactions WHERE kind='SALE') | Number of payments |
| **Taxes - Pivoted (up to 2)** |
| tax_1_name | VARCHAR(100) | stg_order_tax_lines[0].title | First tax name |
| tax_1_rate | DECIMAL(5,4) | stg_order_tax_lines[0].rate | First tax rate |
| tax_1_amount | DECIMAL(18,2) | stg_order_tax_lines[0].price | First tax amount |
| tax_2_name | VARCHAR(100) | stg_order_tax_lines[1].title | Second tax name |
| tax_2_rate | DECIMAL(5,4) | stg_order_tax_lines[1].rate | Second tax rate |
| tax_2_amount | DECIMAL(18,2) | stg_order_tax_lines[1].price | Second tax amount |
| **Discounts - Pivoted (up to 2)** |
| discount_1_code | VARCHAR(100) | stg_order_discount_applications[0].code | First discount code |
| discount_1_type | VARCHAR(20) | stg_order_discount_applications[0].value_type | fixed/percentage |
| discount_1_amount | DECIMAL(18,2) | stg_order_discount_applications[0].value_amount | First discount value |
| discount_2_code | VARCHAR(100) | stg_order_discount_applications[1].code | Second discount code |
| discount_2_type | VARCHAR(20) | stg_order_discount_applications[1].value_type | fixed/percentage |
| discount_2_amount | DECIMAL(18,2) | stg_order_discount_applications[1].value_amount | Second discount value |
| primary_discount_key | BIGINT | First code → lookup | FK to dim_discount |
| **Shipping - Pivoted** |
| shipping_method | VARCHAR(255) | stg_order_shipping_lines[0].title | Shipping method |
| shipping_carrier | VARCHAR(100) | stg_order_shipping_lines[0].carrier_identifier | Carrier |
| **Status & Flags** |
| financial_status | VARCHAR(50) | stg_orders.financial_status | Payment status |
| fulfillment_status | VARCHAR(50) | stg_orders.fulfillment_status | Fulfillment status |
| cancel_reason | VARCHAR(50) | stg_orders.cancel_reason | Why cancelled |
| is_paid | BOOLEAN | financial_status IN ('PAID','PARTIALLY_REFUNDED') | Paid flag |
| is_fully_refunded | BOOLEAN | financial_status = 'REFUNDED' | Full refund flag |
| is_cancelled | BOOLEAN | cancelled_at IS NOT NULL | Cancelled flag |
| is_fulfilled | BOOLEAN | fulfillment_status = 'FULFILLED' | Fulfilled flag |
| has_discount | BOOLEAN | discount_amount > 0 | Discount applied flag |
| has_multiple_payments | BOOLEAN | total_payment_count > 1 | Multiple payments flag |
| **Counts** |
| line_item_count | INT | COUNT(stg_order_line_items) | Number of line items |
| total_quantity | INT | SUM(stg_order_line_items.quantity) | Total units |
| unique_product_count | INT | COUNT(DISTINCT product_id) | Unique products |
| **Denormalized Customer (for reporting)** |
| customer_email | VARCHAR(255) | dim_customer.email | Customer email |
| customer_name | VARCHAR(200) | dim_customer.full_name | Customer name |
| customer_segment | VARCHAR(20) | dim_customer.customer_segment | Customer segment |
| is_first_order | BOOLEAN | order = customer's first | First purchase flag |
| is_repeat_customer | BOOLEAN | customer_lifetime_order_count > 1 | Repeat buyer flag |
| **Denormalized Geography (for reporting)** |
| shipping_city | VARCHAR(255) | dim_geography.city | Ship to city |
| shipping_province | VARCHAR(255) | dim_geography.province | Ship to province |
| shipping_country | VARCHAR(100) | dim_geography.country | Ship to country |
| shipping_country_code | VARCHAR(5) | dim_geography.country_code | Ship to country code |
| **Tags & Notes** |
| tags | VARCHAR(1000) | stg_orders.tags | Order tags |
| notes | TEXT | stg_orders.note | Order notes |
| **ETL** |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## fact_order_line_item

**Source:** stg_order_line_items with denormalized attributes

**Grain:** One row per line item

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| line_item_key | BIGINT | IDENTITY | Surrogate key |
| order_key | BIGINT | FK lookup | FK to fact_order |
| order_date_key | INT | From parent order | FK to dim_date |
| order_time_key | INT | From parent order | FK to dim_time |
| product_key | BIGINT | variant_id → lookup | FK to dim_product |
| customer_key | BIGINT | From parent order | FK to dim_customer |
| **Line Item Identifiers** |
| line_item_id | VARCHAR(50) | stg_order_line_items.id → extract_id() | Shopify line item ID |
| order_id | VARCHAR(50) | stg_order_line_items.order_id → extract_id() | Shopify order ID |
| order_number | VARCHAR(20) | stg_orders.name | Display order # |
| **Product Details (Denormalized)** |
| sku | VARCHAR(100) | stg_order_line_items.sku | SKU |
| product_title | VARCHAR(255) | stg_order_line_items.title | Product title at sale |
| variant_title | VARCHAR(255) | stg_order_line_items.variant_title | Variant at sale |
| product_type | VARCHAR(255) | dim_product.product_type | Product category |
| vendor | VARCHAR(255) | dim_product.vendor | Vendor |
| **Quantities** |
| quantity_ordered | INT | stg_order_line_items.quantity | Originally ordered |
| quantity_fulfilled | INT | quantity - unfulfilled_quantity | Fulfilled |
| quantity_refunded | INT | quantity - current_quantity | Refunded |
| quantity_current | INT | stg_order_line_items.current_quantity | Current after refunds |
| **Financial** |
| unit_price | DECIMAL(18,2) | stg_order_line_items.unit_price | Price per unit |
| unit_cost | DECIMAL(18,2) | dim_product.unit_cost | Cost per unit |
| gross_amount | DECIMAL(18,2) | stg_order_line_items.total_price | Before discount |
| discount_amount | DECIMAL(18,2) | stg_order_line_items.total_discount | Line discount |
| net_amount | DECIMAL(18,2) | stg_order_line_items.discounted_total | After discount |
| gross_margin | DECIMAL(18,2) | net_amount - (unit_cost * quantity) | Margin $ |
| gross_margin_percent | DECIMAL(5,2) | gross_margin / net_amount * 100 | Margin % |
| **Flags** |
| is_gift_card | BOOLEAN | stg_order_line_items.is_gift_card | Gift card flag |
| is_taxable | BOOLEAN | stg_order_line_items.taxable | Taxable flag |
| is_fulfilled | BOOLEAN | unfulfilled_quantity = 0 | Fulfilled flag |
| is_partially_fulfilled | BOOLEAN | 0 < quantity_fulfilled < quantity | Partial flag |
| is_refunded | BOOLEAN | quantity_refunded > 0 | Refund flag |
| is_fully_refunded | BOOLEAN | current_quantity = 0 | Full refund flag |
| **Denormalized Order Attributes (for reporting)** |
| order_created_date | DATE | From fact_order | Order date |
| order_financial_status | VARCHAR(50) | From fact_order | Payment status |
| order_fulfillment_status | VARCHAR(50) | From fact_order | Fulfillment status |
| **Denormalized Customer (for reporting)** |
| customer_email | VARCHAR(255) | dim_customer.email | Customer email |
| customer_name | VARCHAR(200) | dim_customer.full_name | Customer name |
| **Denormalized Geography (for reporting)** |
| shipping_country | VARCHAR(100) | From fact_order | Ship to country |
| shipping_country_code | VARCHAR(5) | From fact_order | Ship to country code |
| **ETL** |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## fact_fulfillment

**Source:** stg_fulfillments + stg_fulfillment_line_items with denormalized attributes

**Grain:** One row per fulfillment (shipment level)

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| fulfillment_key | BIGINT | IDENTITY | Surrogate key |
| order_key | BIGINT | order_id → lookup | FK to fact_order |
| order_date_key | INT | From parent order | FK to dim_date |
| fulfillment_date_key | INT | stg_fulfillments.created_at → to_date_key() | FK to dim_date |
| fulfillment_time_key | INT | stg_fulfillments.created_at → to_time_key() | FK to dim_time |
| location_key | BIGINT | stg_fulfillments.location_id → lookup | FK to dim_location |
| customer_key | BIGINT | From parent order | FK to dim_customer |
| **Fulfillment Identifiers** |
| fulfillment_id | VARCHAR(50) | stg_fulfillments.id → extract_id() | Shopify fulfillment ID |
| order_id | VARCHAR(50) | stg_fulfillments.order_id → extract_id() | Shopify order ID |
| order_number | VARCHAR(20) | From fact_order | Display order # |
| **Timestamps** |
| order_created_at | TIMESTAMP | From fact_order | Order creation time |
| fulfillment_created_at | TIMESTAMP | stg_fulfillments.created_at | Fulfillment creation |
| fulfillment_updated_at | TIMESTAMP | stg_fulfillments.updated_at | Last update |
| **Timing Metrics** |
| fulfillment_time_hours | DECIMAL(10,2) | (fulfillment_created_at - order_created_at) / 3600 | Hours to fulfill |
| fulfillment_time_days | DECIMAL(10,2) | fulfillment_time_hours / 24 | Days to fulfill |
| **Tracking** |
| tracking_number | VARCHAR(255) | stg_fulfillments.tracking_number | Tracking number |
| tracking_company | VARCHAR(100) | stg_fulfillments.tracking_company | Carrier name |
| tracking_url | TEXT | stg_fulfillments.tracking_url | Tracking URL |
| shipping_service | VARCHAR(100) | stg_fulfillments.service | Shipping service |
| **Status** |
| fulfillment_status | VARCHAR(20) | stg_fulfillments.status | SUCCESS, PENDING, etc. |
| shipment_status | VARCHAR(50) | stg_fulfillments.shipment_status | LABEL_PRINTED, etc. |
| is_successful | BOOLEAN | status = 'SUCCESS' | Success flag |
| is_pending | BOOLEAN | status = 'PENDING' | Pending flag |
| **Quantities** |
| total_quantity | INT | stg_fulfillments.total_quantity | Items in shipment |
| line_item_count | INT | COUNT(stg_fulfillment_line_items) | Distinct line items |
| **Denormalized (for reporting)** |
| location_name | VARCHAR(255) | dim_location.location_name | Fulfillment location |
| customer_email | VARCHAR(255) | dim_customer.email | Customer email |
| customer_name | VARCHAR(200) | dim_customer.full_name | Customer name |
| shipping_country | VARCHAR(100) | From fact_order | Destination country |
| **Flags** |
| is_same_day | BOOLEAN | fulfillment_time_hours < 24 | Fulfilled same day |
| is_within_48h | BOOLEAN | fulfillment_time_hours <= 48 | Fulfilled within 48h |
| is_late | BOOLEAN | fulfillment_time_hours > 72 | Took more than 72h |
| **ETL** |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## fact_inventory_snapshot

**Source:** stg_inventory_levels with denormalized product attributes

**Grain:** One row per inventory item per location per snapshot date

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| inventory_snapshot_key | BIGINT | IDENTITY | Surrogate key |
| snapshot_date_key | INT | stg_inventory_levels.snapshot_date → to_date_key() | FK to dim_date |
| product_key | BIGINT | inventory_item_id → lookup | FK to dim_product |
| location_key | BIGINT | location_id → lookup | FK to dim_location |
| **Identifiers** |
| inventory_item_id | VARCHAR(50) | stg_inventory_levels.inventory_item_id → extract_id() | Inventory item ID |
| location_id | VARCHAR(50) | stg_inventory_levels.location_id → extract_id() | Location ID |
| snapshot_date | DATE | stg_inventory_levels.snapshot_date | Snapshot date |
| **Inventory Levels** |
| available_quantity | INT | stg_inventory_levels.available | Available to sell |
| on_hand_quantity | INT | stg_inventory_levels.on_hand | Physically in stock |
| committed_quantity | INT | stg_inventory_levels.committed | Reserved for orders |
| incoming_quantity | INT | stg_inventory_levels.incoming | Expected inventory |
| reserved_quantity | INT | stg_inventory_levels.reserved | Other reservations |
| **Calculated Inventory Metrics** |
| total_inventory | INT | on_hand + incoming | Total inventory position |
| sellable_inventory | INT | available | Truly available |
| **Valuation** |
| unit_cost | DECIMAL(18,2) | dim_product.unit_cost | Cost per unit |
| inventory_cost_value | DECIMAL(18,2) | on_hand_quantity * unit_cost | Inventory value at cost |
| unit_price | DECIMAL(18,2) | dim_product.current_price | Selling price per unit |
| inventory_retail_value | DECIMAL(18,2) | on_hand_quantity * unit_price | Inventory value at retail |
| **Denormalized Product (for reporting)** |
| sku | VARCHAR(100) | dim_product.sku | SKU |
| product_title | VARCHAR(255) | dim_product.product_title | Product name |
| variant_title | VARCHAR(255) | dim_product.variant_title | Variant name |
| product_type | VARCHAR(255) | dim_product.product_type | Category |
| vendor | VARCHAR(255) | dim_product.vendor | Vendor |
| **Denormalized Location (for reporting)** |
| location_name | VARCHAR(255) | dim_location.location_name | Location name |
| location_country | VARCHAR(100) | dim_location.country | Location country |
| **Flags** |
| is_out_of_stock | BOOLEAN | available_quantity = 0 | Out of stock flag |
| is_low_stock | BOOLEAN | available_quantity < threshold | Low stock warning |
| is_overstocked | BOOLEAN | available_quantity > high_threshold | Overstock flag |
| **ETL** |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

**Note:** Threshold values for low_stock and overstocked flags are configurable per product category.

---

## fact_refund

**Source:** stg_refunds + stg_refund_line_items with denormalized attributes

**Grain:** One row per refund

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| refund_key | BIGINT | IDENTITY | Surrogate key |
| order_key | BIGINT | order_id → lookup | FK to fact_order |
| order_date_key | INT | From parent order | FK to dim_date |
| refund_date_key | INT | stg_refunds.created_at → to_date_key() | FK to dim_date |
| customer_key | BIGINT | From parent order | FK to dim_customer |
| **Refund Identifiers** |
| refund_id | VARCHAR(50) | stg_refunds.id → extract_id() | Shopify refund ID |
| order_id | VARCHAR(50) | stg_refunds.order_id → extract_id() | Shopify order ID |
| order_number | VARCHAR(20) | From fact_order | Display order # |
| **Timestamps** |
| order_created_at | TIMESTAMP | From fact_order | Order creation |
| refund_created_at | TIMESTAMP | stg_refunds.created_at | Refund creation |
| **Timing Metrics** |
| days_to_refund | INT | DATE(refund_created_at) - DATE(order_created_at) | Days between order and refund |
| **Financial** |
| refund_amount | DECIMAL(18,2) | stg_refunds.total_refunded | Total refund amount |
| refund_subtotal | DECIMAL(18,2) | SUM(stg_refund_line_items.subtotal_amount) | Line items subtotal |
| refund_tax | DECIMAL(18,2) | SUM(stg_refund_line_items.total_tax_amount) | Tax refunded |
| original_order_total | DECIMAL(18,2) | From fact_order.total_amount | Original order value |
| refund_percentage | DECIMAL(5,2) | (refund_amount / original_order_total) * 100 | % of order refunded |
| **Items** |
| total_items_refunded | INT | SUM(stg_refund_line_items.quantity) | Units refunded |
| line_item_count | INT | COUNT(DISTINCT stg_refund_line_items.line_item_id) | Line items affected |
| **Restock Analysis** |
| items_restocked | INT | SUM where restock_type IN ('RETURN','CANCEL') | Units returned to inventory |
| items_not_restocked | INT | SUM where restock_type = 'NO_RESTOCK' | Units not restocked |
| **Reason** |
| refund_note | TEXT | stg_refunds.note | Refund reason/note |
| **Flags** |
| is_full_refund | BOOLEAN | refund_percentage >= 99 | Full refund flag |
| is_partial_refund | BOOLEAN | 0 < refund_percentage < 99 | Partial refund flag |
| has_restock | BOOLEAN | items_restocked > 0 | Inventory restocked |
| **Denormalized (for reporting)** |
| customer_email | VARCHAR(255) | dim_customer.email | Customer email |
| customer_name | VARCHAR(200) | dim_customer.full_name | Customer name |
| **ETL** |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

# DATA LINEAGE

## Lineage Diagram

```
SHOPIFY API                    STAGING (STG)                           DATA WAREHOUSE (DWH)
═══════════════════════════════════════════════════════════════════════════════════════════════

orders ──────────────────────► stg_orders ─────────────────┬──────────► fact_order
  │                                                        │              │
  ├── lineItems ─────────────► stg_order_line_items ───────┼──────────► fact_order_line_item
  │                                                        │
  ├── transactions ──────────► stg_order_transactions ─────┤ (pivot)
  │                                                        │
  ├── taxLines ──────────────► stg_order_tax_lines ────────┤ (pivot)
  │                                                        │
  ├── discountApplications ──► stg_order_discount_apps ────┤ (pivot)
  │                                                        │
  ├── shippingLines ─────────► stg_order_shipping_lines ───┘ (pivot)
  │
  ├── fulfillments ──────────► stg_fulfillments ───────────┬──────────► fact_fulfillment
  │       │                                                │
  │       └── lineItems ─────► stg_fulfillment_line_items ─┘
  │
  ├── refunds ───────────────► stg_refunds ────────────────┬──────────► fact_refund
  │       │                                                │
  │       └── refundLineItems► stg_refund_line_items ──────┘
  │
  └── shippingAddress ───────► (embedded in stg_orders) ───────────────► dim_geography
      billingAddress


customers ───────────────────► stg_customers ──────────────────────────► dim_customer
                                    │                                      │
                                    └── + aggregations from stg_orders ────┘
                                        + RFM scoring


productVariants ─────────────► stg_product_variants ───────┬───────────► dim_product
  │                                                        │
  └── product ───────────────► stg_products ───────────────┘


codeDiscountNodes ───────────► stg_discount_codes ─────────────────────► dim_discount


locations ───────────────────► stg_locations ──────────────────────────► dim_location


inventoryLevels ─────────────► stg_inventory_levels ───────────────────► fact_inventory_snapshot


abandonedCheckouts ──────────► stg_abandoned_checkouts ────────────────► (analytics/reporting)


(generated) ─────────────────────────────────────────────────────────────► dim_date
                                                                          dim_time
```

---

## Transformation Summary by Table

### fact_order

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_orders | Direct mapping | order_id, order_number, timestamps, amounts |
| stg_orders | extract_id() | order_id |
| stg_orders | to_date_key() | order_date_key |
| stg_orders | to_time_key() | order_time_key |
| stg_orders.customer_id | FK lookup | customer_key |
| stg_orders.shipping_address | hash_address() + lookup | shipping_geography_key |
| stg_order_transactions | PIVOT (row 1,2,3 → columns) | payment_1/2/3_gateway, payment_1/2/3_amount |
| stg_order_tax_lines | PIVOT (row 1,2 → columns) | tax_1/2_name, tax_1/2_rate, tax_1/2_amount |
| stg_order_discount_applications | PIVOT (row 1,2 → columns) | discount_1/2_code, discount_1/2_type, discount_1/2_amount |
| stg_order_shipping_lines | First row only | shipping_method, shipping_carrier |
| stg_order_line_items | COUNT, SUM | line_item_count, total_quantity |
| dim_customer | Denormalize | customer_email, customer_name, customer_segment |
| dim_geography | Denormalize | shipping_city, shipping_province, shipping_country |
| Derived | Business logic | is_paid, is_cancelled, is_fulfilled, has_discount, etc. |

### fact_order_line_item

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_order_line_items | Direct mapping | quantities, amounts |
| stg_order_line_items | extract_id() | line_item_id, order_id |
| stg_order_line_items.variant_id | FK lookup | product_key |
| fact_order | FK lookup | order_key, order_date_key, customer_key |
| dim_product | Denormalize | product_type, vendor, unit_cost |
| dim_customer | Denormalize | customer_email, customer_name |
| fact_order | Denormalize | order_created_date, shipping_country |
| Derived | Calculation | gross_margin, gross_margin_percent |
| Derived | Business logic | is_fulfilled, is_refunded flags |

### dim_customer

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_customers | Direct mapping | email, names, phone, tags |
| stg_customers | extract_id() | customer_id |
| stg_customers | map_marketing() | accepts_email_marketing, accepts_sms_marketing |
| stg_customers.default_address_json | JSON extract | default_country, default_city |
| stg_orders | COUNT | lifetime_order_count |
| stg_orders | SUM(total_price) | lifetime_revenue |
| stg_orders | MIN(created_at) | first_order_date |
| stg_orders | MAX(created_at) | last_order_date |
| Derived | Calculation | average_order_value, days_since_last_order |
| Derived | Business logic | customer_segment |

---

## Pivot Transformation Details

### Payments Pivot (stg_order_transactions → fact_order)

**Input (rows):**
```
order_id | transaction_id | kind | gateway          | amount
---------|----------------|------|------------------|--------
1001     | 5001           | SALE | shopify_payments | 150.00
1001     | 5002           | SALE | gift_card        | 50.00
```

**Transformation SQL:**
```sql
SELECT
    order_id,
    MAX(CASE WHEN rn = 1 THEN gateway END) AS payment_1_gateway,
    MAX(CASE WHEN rn = 1 THEN amount END) AS payment_1_amount,
    MAX(CASE WHEN rn = 2 THEN gateway END) AS payment_2_gateway,
    MAX(CASE WHEN rn = 2 THEN amount END) AS payment_2_amount,
    MAX(CASE WHEN rn = 3 THEN gateway END) AS payment_3_gateway,
    MAX(CASE WHEN rn = 3 THEN amount END) AS payment_3_amount,
    COUNT(*) AS total_payment_count
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY created_at) AS rn
    FROM stg_order_transactions
    WHERE kind = 'SALE' AND status = 'SUCCESS'
) t
GROUP BY order_id
```

**Output (columns):**
```
order_id | payment_1_gateway | payment_1_amount | payment_2_gateway | payment_2_amount | total_payment_count
---------|-------------------|------------------|-------------------|------------------|--------------------
1001     | shopify_payments  | 150.00           | gift_card         | 50.00            | 2
```

---

### Taxes Pivot (stg_order_tax_lines → fact_order)

**Input (rows):**
```
order_id | line_number | title | rate   | price
---------|-------------|-------|--------|------
1001     | 1           | VAT   | 0.1500 | 30.00
1001     | 2           | Levy  | 0.0100 | 2.00
```

**Output (columns):**
```
order_id | tax_1_name | tax_1_rate | tax_1_amount | tax_2_name | tax_2_rate | tax_2_amount
---------|------------|------------|--------------|------------|------------|-------------
1001     | VAT        | 0.1500     | 30.00        | Levy       | 0.0100     | 2.00
```

---

### Discounts Pivot (stg_order_discount_applications → fact_order)

**Input (rows):**
```
order_id | line_number | code      | value_type | value_amount | value_percentage
---------|-------------|-----------|------------|--------------|------------------
1001     | 1           | SAVE20    | percentage | NULL         | 20.00
1001     | 2           | FREESHIP  | fixed      | 50.00        | NULL
```

**Output (columns):**
```
order_id | discount_1_code | discount_1_type | discount_1_amount | discount_2_code | discount_2_type | discount_2_amount
---------|-----------------|-----------------|-------------------|-----------------|-----------------|-------------------
1001     | SAVE20          | percentage      | 20.00             | FREESHIP        | fixed           | 50.00
```

---

## Column Count Comparison

| Layer | Table | Columns | Notes |
|-------|-------|---------|-------|
| **STG** | stg_orders | ~29 | Raw order data + channel fields |
| **STG** | stg_order_transactions | ~12 | Row per payment |
| **STG** | stg_order_tax_lines | ~6 | Row per tax |
| **STG** | stg_order_discount_applications | ~12 | Row per discount |
| **STG** | stg_fulfillments | ~13 | Row per shipment |
| **STG** | stg_refunds | ~6 | Row per refund |
| **STG** | stg_inventory_levels | ~11 | Row per item×location |
| **DWH** | fact_order | ~75 | Pivoted + denormalized + channel |
| **STG** | stg_order_line_items | ~19 | Raw line items |
| **DWH** | fact_order_line_item | ~35 | + denormalized attributes |
| **DWH** | fact_fulfillment | ~30 | Fulfillment metrics |
| **DWH** | fact_refund | ~25 | Refund analytics |
| **DWH** | fact_inventory_snapshot | ~25 | Inventory tracking |

The DWH tables are wider (more columns) but with fewer joins required for reporting.

---

# METRICS LINEAGE

This section provides complete traceability from business metrics to their underlying data sources.

## Report Catalog by Business Function

### 1. Sales & Revenue Reports

| Report | Key Metrics | Primary DWH Table |
|--------|-------------|-------------------|
| Daily Sales Dashboard | Gross Revenue, Net Revenue, Order Count, AOV | fact_order |
| Revenue by Channel | Revenue by source_name | fact_order |
| Revenue by Geography | Revenue by country/region | fact_order + dim_geography |
| Sales Trend Analysis | Revenue over time, Growth rate | fact_order + dim_date |
| Product Sales Report | Revenue by product, Units sold | fact_order_line_item + dim_product |

### 2. Customer Analytics Reports

| Report | Key Metrics | Primary DWH Table |
|--------|-------------|-------------------|
| Customer Lifetime Value | CLV, Order Count, Total Spent | dim_customer |
| RFM Segmentation | RFM scores, Segment distribution | dim_customer |
| New vs Returning | First-time vs repeat revenue | fact_order (is_first_order) |
| Customer Cohort Analysis | Retention by cohort month | dim_customer + fact_order |
| At-Risk Customers | Days since last order, Segment | dim_customer |

### 3. Product Performance Reports

| Report | Key Metrics | Primary DWH Table |
|--------|-------------|-------------------|
| Product Revenue Report | Revenue, Units, Margin by product | fact_order_line_item |
| Inventory Status | Available, On-hand, Stock-outs | fact_inventory_snapshot |
| Sell-Through Analysis | Sell-through rate by product | fact_order_line_item + fact_inventory_snapshot |
| Product Return Analysis | Return rate by product | fact_refund + fact_order_line_item |
| Margin Analysis | Gross margin %, Top/bottom margin products | fact_order_line_item |

### 4. Marketing & Promotions Reports

| Report | Key Metrics | Primary DWH Table |
|--------|-------------|-------------------|
| Discount Performance | Usage rate, Revenue impact | fact_order + dim_discount |
| Code Redemption Report | Usage by code, Revenue per code | fact_order |
| Channel Attribution | Revenue by landing/referring site | fact_order |
| Marketing Spend ROI | ROAS (requires external data) | fact_order + external |

### 5. Operations & Fulfillment Reports

| Report | Key Metrics | Primary DWH Table |
|--------|-------------|-------------------|
| Fulfillment Performance | Fulfillment time, On-time rate | fact_fulfillment |
| Location Performance | Orders by location, Fulfillment speed | fact_fulfillment + dim_location |
| Shipping Analysis | Carrier distribution, Shipping costs | fact_order + fact_fulfillment |
| Refund Analysis | Refund rate, Refund reasons | fact_refund |
| Return Rate Report | Return % by product/category | fact_refund + dim_product |

### 6. Financial Reports

| Report | Key Metrics | Primary DWH Table |
|--------|-------------|-------------------|
| Gross Margin Report | COGS, Gross profit, Margin % | fact_order_line_item |
| Tax Summary | Tax collected by region | fact_order |
| Refund Summary | Total refunds, Refund % of revenue | fact_refund |
| Inventory Valuation | Inventory at cost/retail | fact_inventory_snapshot |

---

## Metric Definitions with Complete Lineage

### Sales & Revenue Metrics (8)

| # | Metric | Formula | DWH Source | STG Source | API Field |
|---|--------|---------|------------|------------|-----------|
| 1 | **Gross Revenue** | SUM(gross_amount) | fact_order_line_item.gross_amount | stg_order_line_items.total_price | lineItems.originalTotalSet.shopMoney.amount |
| 2 | **Net Revenue** | SUM(net_amount) | fact_order_line_item.net_amount | stg_order_line_items.discounted_total | lineItems.discountedTotalSet.shopMoney.amount |
| 3 | **Total Revenue (Order Level)** | SUM(total_amount) | fact_order.total_amount | stg_orders.total_price | orders.totalPriceSet.shopMoney.amount |
| 4 | **Average Order Value (AOV)** | SUM(total_amount) / COUNT(DISTINCT order_key) | fact_order.total_amount | stg_orders.total_price | orders.totalPriceSet.shopMoney.amount |
| 5 | **Order Count** | COUNT(DISTINCT order_key) | fact_order.order_key | stg_orders.id | orders.id |
| 6 | **Units Per Transaction (UPT)** | SUM(quantity_ordered) / COUNT(DISTINCT order_key) | fact_order_line_item.quantity_ordered | stg_order_line_items.quantity | lineItems.quantity |
| 7 | **Revenue by Channel** | SUM(total_amount) GROUP BY source_name | fact_order.total_amount, fact_order.source_name | stg_orders.total_price, stg_orders.source_name | orders.totalPriceSet, orders.sourceName |
| 8 | **Sales Growth Rate** | (Current Period - Prior Period) / Prior Period * 100 | fact_order.total_amount + dim_date | stg_orders.total_price, stg_orders.created_at | orders.totalPriceSet, orders.createdAt |

### Customer Analytics Metrics (11)

| # | Metric | Formula | DWH Source | STG Source | API Field |
|---|--------|---------|------------|------------|-----------|
| 9 | **Customer Lifetime Value (CLV)** | lifetime_revenue | dim_customer.lifetime_revenue | SUM(stg_orders.total_price) per customer | orders.totalPriceSet |
| 10 | **Lifetime Order Count** | lifetime_order_count | dim_customer.lifetime_order_count | COUNT(stg_orders) per customer | orders.id, orders.customer.id |
| 11 | **Average Order Value (Customer)** | average_order_value | dim_customer.average_order_value | Derived: lifetime_revenue / lifetime_order_count | Calculated |
| 12 | **Days Since Last Order** | days_since_last_order | dim_customer.days_since_last_order | CURRENT_DATE - MAX(stg_orders.created_at) | orders.createdAt |
| 13 | **First Order Date** | first_order_date | dim_customer.first_order_date | MIN(stg_orders.created_at) | orders.createdAt |
| 14 | **Customer Retention Rate** | Returning Customers / Starting Customers * 100 | dim_customer + fact_order | stg_customers, stg_orders | customers, orders |
| 15 | **Repeat Purchase Rate** | Customers with 2+ orders / Total Customers * 100 | dim_customer.lifetime_order_count | stg_customers, stg_orders | customers.numberOfOrders |
| 16 | **New Customer Revenue** | SUM(total_amount) WHERE is_first_order = TRUE | fact_order.total_amount, fact_order.is_first_order | stg_orders.total_price + derived | orders.totalPriceSet |
| 17 | **Returning Customer Revenue** | SUM(total_amount) WHERE is_first_order = FALSE | fact_order.total_amount, fact_order.is_first_order | stg_orders.total_price + derived | orders.totalPriceSet |
| 18 | **RFM Recency Score** | Quintile of days_since_last_order | dim_customer.rfm_recency_score | Derived from stg_orders.created_at | orders.createdAt |
| 19 | **RFM Segment** | Business logic on R/F/M scores | dim_customer.rfm_segment | Derived | Calculated |

### Product Performance Metrics (10)

| # | Metric | Formula | DWH Source | STG Source | API Field |
|---|--------|---------|------------|------------|-----------|
| 20 | **Units Sold** | SUM(quantity_ordered) | fact_order_line_item.quantity_ordered | stg_order_line_items.quantity | lineItems.quantity |
| 21 | **Product Revenue** | SUM(net_amount) GROUP BY product_key | fact_order_line_item.net_amount | stg_order_line_items.discounted_total | lineItems.discountedTotalSet |
| 22 | **Average Selling Price (ASP)** | SUM(net_amount) / SUM(quantity_ordered) | fact_order_line_item | stg_order_line_items | lineItems |
| 23 | **Gross Margin $** | SUM(gross_margin) | fact_order_line_item.gross_margin | Derived: net_amount - (cost * qty) | lineItems + variants.inventoryItem.unitCost |
| 24 | **Gross Margin %** | SUM(gross_margin) / SUM(net_amount) * 100 | fact_order_line_item | Derived | Calculated |
| 25 | **Available Inventory** | available_quantity | fact_inventory_snapshot.available_quantity | stg_inventory_levels.available | inventoryLevels.quantities.available |
| 26 | **Inventory Value (Cost)** | SUM(inventory_cost_value) | fact_inventory_snapshot.inventory_cost_value | stg_inventory_levels.on_hand * cost | inventoryLevels + inventoryItem.unitCost |
| 27 | **Stock-Out Rate** | COUNT(is_out_of_stock = TRUE) / Total SKUs * 100 | fact_inventory_snapshot.is_out_of_stock | stg_inventory_levels.available = 0 | inventoryLevels.quantities.available |
| 28 | **Product Return Rate** | Refunded Qty / Sold Qty * 100 | fact_refund + fact_order_line_item | stg_refund_line_items + stg_order_line_items | refunds.refundLineItems + lineItems |
| 29 | **Sell-Through Rate** | Units Sold / Beginning Inventory * 100 | fact_order_line_item + fact_inventory_snapshot | Derived | Calculated |

### Marketing & Promotions Metrics (9)

| # | Metric | Formula | DWH Source | STG Source | API Field |
|---|--------|---------|------------|------------|-----------|
| 30 | **Discount Usage Rate** | Orders with Discount / Total Orders * 100 | fact_order.has_discount | stg_orders.total_discounts > 0 | orders.totalDiscountsSet |
| 31 | **Total Discount Amount** | SUM(discount_amount) | fact_order.discount_amount | stg_orders.total_discounts | orders.totalDiscountsSet.shopMoney.amount |
| 32 | **Average Discount per Order** | SUM(discount_amount) / COUNT(DISTINCT order_key) | fact_order.discount_amount | stg_orders.total_discounts | orders.totalDiscountsSet |
| 33 | **Discount Code Revenue** | SUM(total_amount) GROUP BY discount_code | fact_order.total_amount, discount_1_code | stg_orders, stg_order_discount_applications | orders, discountApplications |
| 34 | **Discount Code Usage Count** | current_usage_count | dim_discount.current_usage_count | stg_discount_codes.usage_count | codeDiscount.asyncUsageCount |
| 35 | **Discount Redemption Rate** | usage_count / usage_limit * 100 | dim_discount | stg_discount_codes | codeDiscount.asyncUsageCount / usageLimit |
| 36 | **Revenue by Landing Site** | SUM(total_amount) GROUP BY landing_site | fact_order.total_amount, fact_order.landing_site | stg_orders.total_price, stg_orders.landing_site | orders.totalPriceSet, orders.landingSite |
| 37 | **Revenue by Referring Site** | SUM(total_amount) GROUP BY referring_site | fact_order.total_amount, fact_order.referring_site | stg_orders.total_price, stg_orders.referring_site | orders.totalPriceSet, orders.referringSite |
| 38 | **Cart Abandonment Rate** | Abandoned / (Abandoned + Completed) * 100 | stg_abandoned_checkouts | stg_abandoned_checkouts.completed_at IS NULL | abandonedCheckouts |

### Operations & Fulfillment Metrics (11)

| # | Metric | Formula | DWH Source | STG Source | API Field |
|---|--------|---------|------------|------------|-----------|
| 39 | **Fulfillment Time (Hours)** | AVG(fulfillment_time_hours) | fact_fulfillment.fulfillment_time_hours | stg_fulfillments.created_at - stg_orders.created_at | fulfillments.createdAt - orders.createdAt |
| 40 | **Fulfillment Time (Days)** | AVG(fulfillment_time_days) | fact_fulfillment.fulfillment_time_days | Derived | Calculated |
| 41 | **Same-Day Fulfillment Rate** | COUNT(is_same_day = TRUE) / Total * 100 | fact_fulfillment.is_same_day | Derived: fulfillment < 24h | Calculated |
| 42 | **On-Time Shipping Rate** | COUNT(is_within_48h = TRUE) / Total * 100 | fact_fulfillment.is_within_48h | Derived | Calculated |
| 43 | **Late Fulfillment Rate** | COUNT(is_late = TRUE) / Total * 100 | fact_fulfillment.is_late | Derived: fulfillment > 72h | Calculated |
| 44 | **Refund Rate** | Orders with Refunds / Total Orders * 100 | fact_refund + fact_order | stg_refunds + stg_orders | refunds + orders |
| 45 | **Refund Amount** | SUM(refund_amount) | fact_refund.refund_amount | stg_refunds.total_refunded | refunds.totalRefundedSet.shopMoney.amount |
| 46 | **Refund % of Revenue** | SUM(refund_amount) / SUM(total_amount) * 100 | fact_refund + fact_order | stg_refunds, stg_orders | Calculated |
| 47 | **Items Refunded** | SUM(total_items_refunded) | fact_refund.total_items_refunded | SUM(stg_refund_line_items.quantity) | refundLineItems.quantity |
| 48 | **Restock Rate** | items_restocked / total_items_refunded * 100 | fact_refund | stg_refund_line_items.restock_type | refundLineItems.restockType |
| 49 | **Fulfillments by Location** | COUNT(*) GROUP BY location_key | fact_fulfillment.location_key | stg_fulfillments.location_id | fulfillments.location.id |

### Financial Metrics (8)

| # | Metric | Formula | DWH Source | STG Source | API Field |
|---|--------|---------|------------|------------|-----------|
| 50 | **Cost of Goods Sold (COGS)** | SUM(quantity * unit_cost) | fact_order_line_item.unit_cost, quantity_ordered | stg_product_variants.cost, stg_order_line_items.quantity | variants.inventoryItem.unitCost, lineItems.quantity |
| 51 | **Gross Profit** | Net Revenue - COGS | Derived | Derived | Calculated |
| 52 | **Gross Profit Margin %** | Gross Profit / Net Revenue * 100 | Derived | Derived | Calculated |
| 53 | **Tax Collected** | SUM(tax_amount) | fact_order.tax_amount | stg_orders.total_tax | orders.totalTaxSet.shopMoney.amount |
| 54 | **Tax by Region** | SUM(tax_amount) GROUP BY country | fact_order.tax_amount + dim_geography | stg_orders.total_tax, shipping_address | orders.totalTaxSet, shippingAddress |
| 55 | **Shipping Revenue** | SUM(shipping_amount) | fact_order.shipping_amount | stg_orders.total_shipping | orders.totalShippingPriceSet.shopMoney.amount |
| 56 | **Net Revenue After Refunds** | SUM(net_amount) | fact_order.net_amount | stg_orders.total_price - stg_orders.total_refunded | orders.totalPriceSet - totalRefundedSet |
| 57 | **Inventory Valuation (Retail)** | SUM(inventory_retail_value) | fact_inventory_snapshot.inventory_retail_value | stg_inventory_levels.on_hand * variant.price | inventoryLevels * variants.price |

---

## Complete Data Lineage Examples

### Example 1: Gross Margin % by Product

**Report:** Which products have the best margins?

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ METRIC: Gross Margin % by Product                                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│ FORMULA: (SUM(net_amount) - SUM(quantity * unit_cost)) / SUM(net_amount) * 100      │
│                                                                                      │
│ DWH QUERY:                                                                           │
│   SELECT                                                                             │
│     p.product_title,                                                                 │
│     SUM(f.net_amount) as revenue,                                                    │
│     SUM(f.quantity_ordered * f.unit_cost) as cogs,                                  │
│     (SUM(f.net_amount) - SUM(f.quantity_ordered * f.unit_cost))                     │
│       / NULLIF(SUM(f.net_amount), 0) * 100 as margin_pct                            │
│   FROM fact_order_line_item f                                                        │
│   JOIN dim_product p ON f.product_key = p.product_key                               │
│   GROUP BY p.product_title                                                           │
│                                                                                      │
│ STG SOURCE:                                                                          │
│   • stg_order_line_items.discounted_total → net_amount                              │
│   • stg_order_line_items.quantity → quantity_ordered                                │
│   • stg_product_variants.cost → unit_cost                                           │
│                                                                                      │
│ API SOURCE:                                                                          │
│   • lineItems.discountedTotalSet.shopMoney.amount                                   │
│   • lineItems.quantity                                                               │
│   • variants.inventoryItem.unitCost.amount                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Example 2: Fulfillment Performance by Location

**Report:** Which locations fulfill orders fastest?

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ METRIC: Average Fulfillment Time by Location                                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│ FORMULA: AVG(fulfillment_created_at - order_created_at) in hours                    │
│                                                                                      │
│ DWH QUERY:                                                                           │
│   SELECT                                                                             │
│     l.location_name,                                                                 │
│     AVG(ff.fulfillment_time_hours) as avg_hours,                                    │
│     COUNT(*) as fulfillment_count,                                                   │
│     SUM(CASE WHEN ff.is_same_day THEN 1 ELSE 0 END) * 100.0                         │
│       / COUNT(*) as same_day_pct                                                     │
│   FROM fact_fulfillment ff                                                           │
│   JOIN dim_location l ON ff.location_key = l.location_key                           │
│   GROUP BY l.location_name                                                           │
│                                                                                      │
│ STG SOURCE:                                                                          │
│   • stg_fulfillments.created_at - stg_orders.created_at → fulfillment_time_hours    │
│   • stg_fulfillments.location_id → location_key                                     │
│   • stg_locations.name → location_name                                               │
│                                                                                      │
│ API SOURCE:                                                                          │
│   • fulfillments.createdAt                                                           │
│   • orders.createdAt                                                                 │
│   • fulfillments.location.id                                                         │
│   • locations.name                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Example 3: RFM Customer Segmentation

**Report:** Customer distribution by RFM segment

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ METRIC: Customer Count & Revenue by RFM Segment                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│ DWH QUERY:                                                                           │
│   SELECT                                                                             │
│     rfm_segment,                                                                     │
│     COUNT(*) as customer_count,                                                      │
│     SUM(lifetime_revenue) as total_revenue,                                         │
│     AVG(average_order_value) as avg_aov,                                            │
│     AVG(days_since_last_order) as avg_recency                                       │
│   FROM dim_customer                                                                  │
│   WHERE customer_key > 0  -- Exclude unknown                                        │
│   GROUP BY rfm_segment                                                               │
│                                                                                      │
│ STG SOURCE:                                                                          │
│   • stg_customers + aggregations from stg_orders                                    │
│   • RFM scores calculated during dim_customer load:                                 │
│     - rfm_recency_score: NTILE(5) OVER (ORDER BY MAX(order_date) DESC)             │
│     - rfm_frequency_score: NTILE(5) OVER (ORDER BY COUNT(order_id))                │
│     - rfm_monetary_score: NTILE(5) OVER (ORDER BY SUM(total_price))                │
│                                                                                      │
│ API SOURCE:                                                                          │
│   • customers.id, customers.email                                                    │
│   • orders.customer.id, orders.createdAt, orders.totalPriceSet                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Schema Coverage Summary

### STG Layer Coverage

| STG Table | Status | Metrics Enabled |
|-----------|--------|-----------------|
| stg_orders | ✓ Enhanced | Revenue, AOV, Order Count, Channel Attribution |
| stg_order_line_items | ✓ Enhanced | Units, Product Revenue, Margin |
| stg_order_transactions | ✓ | Payment Methods, Payment Amounts |
| stg_order_tax_lines | ✓ | Tax by Region |
| stg_order_discount_applications | ✓ | Discount Usage |
| stg_order_shipping_lines | ✓ | Shipping Methods |
| stg_customers | ✓ | Customer Count, Marketing Consent |
| stg_products | ✓ | Product Catalog |
| stg_product_variants | ✓ | SKU, Cost, Pricing |
| stg_discount_codes | ✓ | Discount Performance |
| stg_locations | ✓ | Location Analytics |
| **stg_fulfillments** | ✓ NEW | Fulfillment Time, Shipping Performance |
| **stg_fulfillment_line_items** | ✓ NEW | Item-level fulfillment tracking |
| **stg_refunds** | ✓ NEW | Refund Rate, Refund Amount |
| **stg_refund_line_items** | ✓ NEW | Product Return Rate, Restock Analysis |
| **stg_inventory_levels** | ✓ NEW | Stock Levels, Inventory Valuation |
| **stg_abandoned_checkouts** | ✓ NEW | Cart Abandonment Rate, Recovery |

### DWH Layer Coverage

| DWH Table | Status | Primary Use Case |
|-----------|--------|------------------|
| fact_order | ✓ Enhanced | Order-level sales & revenue |
| fact_order_line_item | ✓ | Product-level sales & margin |
| **fact_fulfillment** | ✓ NEW | Fulfillment performance metrics |
| **fact_refund** | ✓ NEW | Refund and return analysis |
| **fact_inventory_snapshot** | ✓ NEW | Inventory tracking over time |
| dim_customer | ✓ Enhanced | Customer analytics, RFM segmentation |
| dim_product | ✓ | Product master data |
| dim_geography | ✓ | Geographic analysis |
| dim_discount | ✓ | Discount performance |
| dim_location | ✓ | Fulfillment location analysis |
| dim_date | ✓ | Time-based analysis |
| dim_time | ✓ | Hour-of-day analysis |

### Metrics Coverage: 57 metrics fully supported

| Category | Count | Coverage |
|----------|-------|----------|
| Sales & Revenue | 8 | 100% |
| Customer Analytics | 11 | 100% |
| Product Performance | 10 | 100% |
| Marketing & Promotions | 9 | 100% (ROAS requires external data) |
| Operations & Fulfillment | 11 | 100% |
| Financial | 8 | 100% |
| **Total** | **57** | **100%** |
