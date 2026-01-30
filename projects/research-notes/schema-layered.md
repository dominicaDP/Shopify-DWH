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
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

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
  └── shippingAddress ───────► (embedded in stg_orders) ───────────────► dim_geography
      billingAddress


customers ───────────────────► stg_customers ──────────────────────────► dim_customer
                                    │                                      │
                                    └── + aggregations from stg_orders ────┘


productVariants ─────────────► stg_product_variants ───────┬───────────► dim_product
  │                                                        │
  └── product ───────────────► stg_products ───────────────┘


codeDiscountNodes ───────────► stg_discount_codes ─────────────────────► dim_discount


locations ───────────────────► stg_locations ──────────────────────────► dim_location


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
| **STG** | stg_orders | ~25 | Raw order data |
| **STG** | stg_order_transactions | ~12 | Row per payment |
| **STG** | stg_order_tax_lines | ~6 | Row per tax |
| **STG** | stg_order_discount_applications | ~12 | Row per discount |
| **DWH** | fact_order | ~70 | Pivoted + denormalized |
| **STG** | stg_order_line_items | ~18 | Raw line items |
| **DWH** | fact_order_line_item | ~35 | + denormalized attributes |

The DWH tables are wider (more columns) but with fewer joins required for reporting.
