# Shopify DWH - Warehouse Schema Reference

**Version:** 2.0
**Last Updated:** 2026-02-04
**Schema:** SHOPIFY_DWH

---

## Overview

The data warehouse layer contains 12 tables optimized for reporting and analytics:
- **7 Dimension Tables** - Master data with surrogate keys
- **5 Fact Tables** - Transactional data with metrics

**Design Principles:**
- Star schema for optimal BI tool compatibility
- Denormalized attributes on facts for query performance
- Pre-calculated metrics (LTV, RFM, margins)
- Pivoted arrays (payments, taxes, discounts as columns)

---

## Schema Diagram

```
              ┌─────────────┐    ┌─────────────┐
              │  dim_date   │    │  dim_time   │
              └──────┬──────┘    └──────┬──────┘
                     │                  │
                     └────────┬─────────┘
                              │
┌─────────────┐    ┌──────────┴──────────┐    ┌─────────────┐
│dim_customer │────┤    fact_order       ├────│ dim_product │
└─────────────┘    │    fact_order_      │    └─────────────┘
                   │      line_item      │
┌─────────────┐    │    fact_fulfillment │    ┌─────────────┐
│dim_geography│────┤    fact_refund      │────│ dim_discount│
└─────────────┘    │    fact_inventory_  │    └─────────────┘
                   │      snapshot       │
                   └──────────┬──────────┘    ┌─────────────┐
                              │               │dim_location │
                              └───────────────┴─────────────┘
```

---

## Dimension Tables

### dim_date

**Source:** Generated (not from Shopify)
**Rows:** ~3,650 (10 years)

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

### dim_time

**Source:** Generated (24 rows, one per hour)
**Rows:** 24

| Column | Type | Description |
|--------|------|-------------|
| time_key | INT | Primary key (0-23) |
| hour_24 | INT | Hour in 24h format |
| hour_12 | INT | Hour in 12h format |
| am_pm | VARCHAR(2) | AM or PM |
| hour_label | VARCHAR(10) | "9:00 AM" |
| day_part | VARCHAR(15) | Morning, Afternoon, Evening, Night |
| is_business_hours | BOOLEAN | 9:00-17:00 |

**Day Part Definitions:**
- Night: 00:00-05:59 (hours 0-5)
- Morning: 06:00-11:59 (hours 6-11)
- Afternoon: 12:00-17:59 (hours 12-17)
- Evening: 18:00-23:59 (hours 18-23)

---

### dim_customer

**Source:** stg_customers + aggregations from stg_orders
**SCD Type:** Type 1 (overwrite)

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| customer_key | BIGINT | IDENTITY | Surrogate key |
| customer_id | VARCHAR(50) | stg_customers.id | Shopify customer ID |
| **Identity** |
| email | VARCHAR(255) | stg_customers.email | Email address |
| first_name | VARCHAR(100) | stg_customers.first_name | First name |
| last_name | VARCHAR(100) | stg_customers.last_name | Last name |
| full_name | VARCHAR(200) | Derived | Full name |
| phone | VARCHAR(50) | stg_customers.phone | Phone number |
| **Marketing** |
| accepts_email_marketing | BOOLEAN | Derived | Email opt-in |
| accepts_sms_marketing | BOOLEAN | Derived | SMS opt-in |
| **Dates** |
| customer_created_date | DATE | stg_customers.created_at | Account creation |
| first_order_date | DATE | MIN(orders.created_at) | First purchase |
| last_order_date | DATE | MAX(orders.created_at) | Most recent purchase |
| **Geography** |
| default_country | VARCHAR(100) | address JSON | Default country |
| default_city | VARCHAR(100) | address JSON | Default city |
| **Lifetime Metrics** |
| lifetime_order_count | INT | COUNT(orders) | Total orders |
| lifetime_revenue | DECIMAL(18,2) | SUM(total_price) | Total spend |
| average_order_value | DECIMAL(18,2) | Derived | AOV |
| days_since_last_order | INT | Derived | Recency |
| **RFM Segmentation** |
| rfm_recency_score | INT | Quintile (1-5) | 5 = most recent |
| rfm_frequency_score | INT | Quintile (1-5) | 5 = most frequent |
| rfm_monetary_score | INT | Quintile (1-5) | 5 = highest spend |
| rfm_combined_score | INT | R + F + M | Overall score (3-15) |
| rfm_segment | VARCHAR(30) | Business logic | Segment name |
| **Segment** |
| customer_segment | VARCHAR(20) | Business logic | New/Active/At-Risk/Lapsed |
| **Other** |
| tags | VARCHAR(1000) | stg_customers.tags | Customer tags |
| is_tax_exempt | BOOLEAN | stg_customers.tax_exempt | Tax exempt flag |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

**RFM Segment Definitions:**

| Segment | R Score | F Score | M Score | Description |
|---------|---------|---------|---------|-------------|
| Champions | 5 | 5 | 5 | Best customers |
| Loyal | 4-5 | 4-5 | 3-5 | Consistent valuable customers |
| Potential Loyalists | 4-5 | 2-3 | 2-3 | Growth potential |
| New Customers | 5 | 1 | 1-3 | Just acquired |
| Promising | 3-4 | 1-2 | 1-2 | Recent but low engagement |
| Needs Attention | 3 | 3 | 3 | Average across all |
| About to Sleep | 2-3 | 2-3 | 2-3 | Declining engagement |
| At Risk | 1-2 | 4-5 | 4-5 | Were valuable, now inactive |
| Can't Lose | 1-2 | 4-5 | 5 | Highest value but churning |
| Hibernating | 1-2 | 1-2 | 1-2 | Low value, inactive |
| Lost | 1 | 1 | 1 | No recent activity |

---

### dim_product

**Source:** stg_products + stg_product_variants
**SCD Type:** Type 1 (overwrite)
**Grain:** One row per variant

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| product_key | BIGINT | IDENTITY | Surrogate key |
| product_id | VARCHAR(50) | stg_products.id | Shopify product ID |
| variant_id | VARCHAR(50) | stg_product_variants.id | Shopify variant ID |
| **Identifiers** |
| sku | VARCHAR(100) | stg_product_variants.sku | SKU |
| barcode | VARCHAR(100) | stg_product_variants.barcode | Barcode/UPC |
| **Names** |
| product_title | VARCHAR(255) | stg_products.title | Product name |
| variant_title | VARCHAR(255) | stg_product_variants.title | Variant name |
| full_title | VARCHAR(500) | Derived | Combined title |
| **Classification** |
| product_type | VARCHAR(255) | stg_products.product_type | Category |
| vendor | VARCHAR(255) | stg_products.vendor | Vendor/Brand |
| **Options** |
| option_1_value | VARCHAR(255) | stg_product_variants.option1 | Size, etc. |
| option_2_value | VARCHAR(255) | stg_product_variants.option2 | Color, etc. |
| option_3_value | VARCHAR(255) | stg_product_variants.option3 | Material, etc. |
| **Pricing** |
| current_price | DECIMAL(18,2) | stg_product_variants.price | Selling price |
| compare_at_price | DECIMAL(18,2) | stg_product_variants.compare_at_price | Original price |
| unit_cost | DECIMAL(18,2) | stg_product_variants.cost | Cost of goods |
| **Calculated** |
| is_on_sale | BOOLEAN | Derived | On sale flag |
| discount_percentage | DECIMAL(5,2) | Derived | Sale discount % |
| **Attributes** |
| is_taxable | BOOLEAN | stg_product_variants.taxable | Taxable flag |
| requires_shipping | BOOLEAN | stg_product_variants.requires_shipping | Physical product |
| weight_grams | DECIMAL(10,2) | Normalized | Weight in grams |
| **Status** |
| product_status | VARCHAR(20) | stg_products.status | ACTIVE/DRAFT/ARCHIVED |
| tags | VARCHAR(1000) | stg_products.tags | Product tags |
| product_created_date | DATE | stg_products.created_at | Creation date |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### dim_geography

**Source:** Unique addresses from stg_orders
**SCD Type:** Type 1 (overwrite)

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| geography_key | BIGINT | IDENTITY | Surrogate key |
| address_hash | VARCHAR(64) | hash_address() | Deduplication hash |
| city | VARCHAR(255) | address.city | City |
| province | VARCHAR(255) | address.province | State/Province |
| province_code | VARCHAR(10) | address.provinceCode | Province code |
| country | VARCHAR(100) | address.country | Country name |
| country_code | VARCHAR(5) | address.countryCodeV2 | ISO country code |
| postal_code | VARCHAR(20) | address.zip | Postal/ZIP code |
| region | VARCHAR(50) | Derived | Geographic region |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### dim_discount

**Source:** stg_discount_codes
**SCD Type:** Type 1 (overwrite)

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| discount_key | BIGINT | IDENTITY (0 = No Discount) | Surrogate key |
| discount_id | VARCHAR(50) | stg_discount_codes.id | Shopify discount ID |
| discount_code | VARCHAR(100) | stg_discount_codes.code | The code itself |
| discount_title | VARCHAR(255) | stg_discount_codes.title | Friendly name |
| discount_type | VARCHAR(50) | Mapped | basic/bxgy/free_shipping/app |
| value_type | VARCHAR(20) | Derived | fixed_amount or percentage |
| discount_value | DECIMAL(18,2) | Derived | Amount or percentage |
| discount_status | VARCHAR(20) | stg_discount_codes.status | ACTIVE/EXPIRED/SCHEDULED |
| starts_at | DATE | stg_discount_codes.starts_at | Start date |
| ends_at | DATE | stg_discount_codes.ends_at | End date |
| usage_limit | INT | stg_discount_codes.usage_limit | Max uses |
| current_usage_count | INT | stg_discount_codes.usage_count | Times used |
| is_one_per_customer | BOOLEAN | stg_discount_codes.applies_once_per_customer | Limit flag |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### dim_location

**Source:** stg_locations
**SCD Type:** Type 1 (overwrite)

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| location_key | BIGINT | IDENTITY | Surrogate key |
| location_id | VARCHAR(50) | stg_locations.id | Shopify location ID |
| location_name | VARCHAR(255) | stg_locations.name | Location name |
| address | VARCHAR(500) | Concatenated | Full address |
| city | VARCHAR(100) | stg_locations.city | City |
| province | VARCHAR(100) | stg_locations.province | Province |
| country | VARCHAR(100) | stg_locations.country | Country |
| country_code | VARCHAR(5) | stg_locations.country_code | Country code |
| is_active | BOOLEAN | stg_locations.is_active | Active flag |
| fulfills_online | BOOLEAN | stg_locations.fulfills_online_orders | Online fulfillment |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## Fact Tables

### fact_order

**Source:** stg_orders + pivoted child tables
**Grain:** One row per order

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| order_key | BIGINT | IDENTITY | Surrogate key |
| order_date_key | INT | to_date_key() | FK to dim_date |
| order_time_key | INT | to_time_key() | FK to dim_time |
| customer_key | BIGINT | Lookup | FK to dim_customer |
| shipping_geography_key | BIGINT | Lookup | FK to dim_geography |
| billing_geography_key | BIGINT | Lookup | FK to dim_geography |
| primary_discount_key | BIGINT | Lookup | FK to dim_discount |
| **Order Identifiers** |
| order_id | VARCHAR(50) | stg_orders.id | Shopify order ID |
| order_number | VARCHAR(20) | stg_orders.name | Display order # |
| order_email | VARCHAR(255) | stg_orders.email | Customer email |
| checkout_id | VARCHAR(50) | stg_orders.checkout_id | Associated checkout |
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
| net_amount | DECIMAL(18,2) | Derived | Net revenue |
| currency_code | VARCHAR(5) | stg_orders.currency_code | Currency |
| **Payments - Pivoted (up to 3)** |
| payment_1_gateway | VARCHAR(100) | Pivot | First payment method |
| payment_1_amount | DECIMAL(18,2) | Pivot | First payment amount |
| payment_2_gateway | VARCHAR(100) | Pivot | Second payment method |
| payment_2_amount | DECIMAL(18,2) | Pivot | Second payment amount |
| payment_3_gateway | VARCHAR(100) | Pivot | Third payment method |
| payment_3_amount | DECIMAL(18,2) | Pivot | Third payment amount |
| total_payment_count | INT | COUNT | Number of payments |
| **Taxes - Pivoted (up to 2)** |
| tax_1_name | VARCHAR(100) | Pivot | First tax name |
| tax_1_rate | DECIMAL(5,4) | Pivot | First tax rate |
| tax_1_amount | DECIMAL(18,2) | Pivot | First tax amount |
| tax_2_name | VARCHAR(100) | Pivot | Second tax name |
| tax_2_rate | DECIMAL(5,4) | Pivot | Second tax rate |
| tax_2_amount | DECIMAL(18,2) | Pivot | Second tax amount |
| **Discounts - Pivoted (up to 2)** |
| discount_1_code | VARCHAR(100) | Pivot | First discount code |
| discount_1_type | VARCHAR(20) | Pivot | fixed/percentage |
| discount_1_amount | DECIMAL(18,2) | Pivot | First discount value |
| discount_2_code | VARCHAR(100) | Pivot | Second discount code |
| discount_2_type | VARCHAR(20) | Pivot | fixed/percentage |
| discount_2_amount | DECIMAL(18,2) | Pivot | Second discount value |
| **Shipping** |
| shipping_method | VARCHAR(255) | stg_order_shipping_lines | Shipping method |
| shipping_carrier | VARCHAR(100) | stg_order_shipping_lines | Carrier |
| **Status & Flags** |
| financial_status | VARCHAR(50) | stg_orders | Payment status |
| fulfillment_status | VARCHAR(50) | stg_orders | Fulfillment status |
| cancel_reason | VARCHAR(50) | stg_orders | Why cancelled |
| is_paid | BOOLEAN | Derived | Paid flag |
| is_fully_refunded | BOOLEAN | Derived | Full refund flag |
| is_cancelled | BOOLEAN | Derived | Cancelled flag |
| is_fulfilled | BOOLEAN | Derived | Fulfilled flag |
| has_discount | BOOLEAN | Derived | Discount applied flag |
| has_multiple_payments | BOOLEAN | Derived | Multiple payments flag |
| is_first_order | BOOLEAN | Derived | First purchase flag |
| is_repeat_customer | BOOLEAN | Derived | Repeat buyer flag |
| **Counts** |
| line_item_count | INT | COUNT | Number of line items |
| total_quantity | INT | SUM | Total units |
| unique_product_count | INT | COUNT DISTINCT | Unique products |
| **Denormalized Customer** |
| customer_email | VARCHAR(255) | dim_customer | Customer email |
| customer_name | VARCHAR(200) | dim_customer | Customer name |
| customer_segment | VARCHAR(20) | dim_customer | Customer segment |
| **Denormalized Geography** |
| shipping_city | VARCHAR(255) | dim_geography | Ship to city |
| shipping_province | VARCHAR(255) | dim_geography | Ship to province |
| shipping_country | VARCHAR(100) | dim_geography | Ship to country |
| shipping_country_code | VARCHAR(5) | dim_geography | Country code |
| **Other** |
| tags | VARCHAR(1000) | stg_orders.tags | Order tags |
| notes | TEXT | stg_orders.note | Order notes |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### fact_order_line_item

**Source:** stg_order_line_items with denormalized attributes
**Grain:** One row per line item

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| line_item_key | BIGINT | IDENTITY | Surrogate key |
| order_key | BIGINT | FK lookup | FK to fact_order |
| order_date_key | INT | From order | FK to dim_date |
| order_time_key | INT | From order | FK to dim_time |
| product_key | BIGINT | Lookup | FK to dim_product |
| customer_key | BIGINT | From order | FK to dim_customer |
| **Identifiers** |
| line_item_id | VARCHAR(50) | stg_order_line_items.id | Line item ID |
| order_id | VARCHAR(50) | stg_order_line_items.order_id | Order ID |
| order_number | VARCHAR(20) | From order | Display order # |
| **Product (Denormalized)** |
| sku | VARCHAR(100) | stg_order_line_items.sku | SKU |
| product_title | VARCHAR(255) | stg_order_line_items.title | Title at sale |
| variant_title | VARCHAR(255) | stg_order_line_items.variant_title | Variant at sale |
| product_type | VARCHAR(255) | dim_product | Category |
| vendor | VARCHAR(255) | dim_product | Vendor |
| **Quantities** |
| quantity_ordered | INT | stg_order_line_items.quantity | Originally ordered |
| quantity_fulfilled | INT | Derived | Fulfilled |
| quantity_refunded | INT | Derived | Refunded |
| quantity_current | INT | stg_order_line_items.current_quantity | After refunds |
| **Financial** |
| unit_price | DECIMAL(18,2) | stg_order_line_items.unit_price | Price per unit |
| unit_cost | DECIMAL(18,2) | dim_product.unit_cost | Cost per unit |
| gross_amount | DECIMAL(18,2) | stg_order_line_items.total_price | Before discount |
| discount_amount | DECIMAL(18,2) | stg_order_line_items.total_discount | Line discount |
| net_amount | DECIMAL(18,2) | stg_order_line_items.discounted_total | After discount |
| gross_margin | DECIMAL(18,2) | Calculated | Margin $ |
| gross_margin_percent | DECIMAL(5,2) | Calculated | Margin % |
| **Flags** |
| is_gift_card | BOOLEAN | stg_order_line_items | Gift card flag |
| is_taxable | BOOLEAN | stg_order_line_items | Taxable flag |
| is_fulfilled | BOOLEAN | Derived | Fulfilled flag |
| is_partially_fulfilled | BOOLEAN | Derived | Partial flag |
| is_refunded | BOOLEAN | Derived | Refund flag |
| is_fully_refunded | BOOLEAN | Derived | Full refund flag |
| **Denormalized Order** |
| order_created_date | DATE | From order | Order date |
| order_financial_status | VARCHAR(50) | From order | Payment status |
| order_fulfillment_status | VARCHAR(50) | From order | Fulfillment status |
| **Denormalized Customer** |
| customer_email | VARCHAR(255) | dim_customer | Customer email |
| customer_name | VARCHAR(200) | dim_customer | Customer name |
| **Denormalized Geography** |
| shipping_country | VARCHAR(100) | From order | Ship to country |
| shipping_country_code | VARCHAR(5) | From order | Country code |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### fact_fulfillment

**Source:** stg_fulfillments + stg_fulfillment_line_items
**Grain:** One row per fulfillment (shipment)

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| fulfillment_key | BIGINT | IDENTITY | Surrogate key |
| order_key | BIGINT | Lookup | FK to fact_order |
| order_date_key | INT | From order | FK to dim_date |
| fulfillment_date_key | INT | to_date_key() | FK to dim_date |
| fulfillment_time_key | INT | to_time_key() | FK to dim_time |
| location_key | BIGINT | Lookup | FK to dim_location |
| customer_key | BIGINT | From order | FK to dim_customer |
| **Identifiers** |
| fulfillment_id | VARCHAR(50) | stg_fulfillments.id | Fulfillment ID |
| order_id | VARCHAR(50) | stg_fulfillments.order_id | Order ID |
| order_number | VARCHAR(20) | From order | Display order # |
| **Timestamps** |
| order_created_at | TIMESTAMP | From order | Order creation |
| fulfillment_created_at | TIMESTAMP | stg_fulfillments.created_at | Fulfillment creation |
| fulfillment_updated_at | TIMESTAMP | stg_fulfillments.updated_at | Last update |
| **Timing Metrics** |
| fulfillment_time_hours | DECIMAL(10,2) | Calculated | Hours to fulfill |
| fulfillment_time_days | DECIMAL(10,2) | Calculated | Days to fulfill |
| **Tracking** |
| tracking_number | VARCHAR(255) | stg_fulfillments | Tracking number |
| tracking_company | VARCHAR(100) | stg_fulfillments | Carrier name |
| tracking_url | TEXT | stg_fulfillments | Tracking URL |
| shipping_service | VARCHAR(100) | stg_fulfillments | Shipping service |
| **Status** |
| fulfillment_status | VARCHAR(20) | stg_fulfillments | SUCCESS, PENDING, etc. |
| shipment_status | VARCHAR(50) | stg_fulfillments | LABEL_PRINTED, etc. |
| is_successful | BOOLEAN | Derived | Success flag |
| is_pending | BOOLEAN | Derived | Pending flag |
| **Quantities** |
| total_quantity | INT | stg_fulfillments | Items in shipment |
| line_item_count | INT | COUNT | Distinct line items |
| **Denormalized** |
| location_name | VARCHAR(255) | dim_location | Fulfillment location |
| customer_email | VARCHAR(255) | dim_customer | Customer email |
| customer_name | VARCHAR(200) | dim_customer | Customer name |
| shipping_country | VARCHAR(100) | From order | Destination country |
| **Performance Flags** |
| is_same_day | BOOLEAN | Derived | Fulfilled < 24h |
| is_within_48h | BOOLEAN | Derived | Fulfilled <= 48h |
| is_late | BOOLEAN | Derived | Fulfilled > 72h |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### fact_refund

**Source:** stg_refunds + stg_refund_line_items
**Grain:** One row per refund

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| refund_key | BIGINT | IDENTITY | Surrogate key |
| order_key | BIGINT | Lookup | FK to fact_order |
| order_date_key | INT | From order | FK to dim_date |
| refund_date_key | INT | to_date_key() | FK to dim_date |
| customer_key | BIGINT | From order | FK to dim_customer |
| **Identifiers** |
| refund_id | VARCHAR(50) | stg_refunds.id | Refund ID |
| order_id | VARCHAR(50) | stg_refunds.order_id | Order ID |
| order_number | VARCHAR(20) | From order | Display order # |
| **Timestamps** |
| order_created_at | TIMESTAMP | From order | Order creation |
| refund_created_at | TIMESTAMP | stg_refunds.created_at | Refund creation |
| **Timing** |
| days_to_refund | INT | Calculated | Days between order and refund |
| **Financial** |
| refund_amount | DECIMAL(18,2) | stg_refunds.total_refunded | Total refund amount |
| refund_subtotal | DECIMAL(18,2) | SUM(line items) | Line items subtotal |
| refund_tax | DECIMAL(18,2) | SUM(line items) | Tax refunded |
| original_order_total | DECIMAL(18,2) | From order | Original order value |
| refund_percentage | DECIMAL(5,2) | Calculated | % of order refunded |
| **Items** |
| total_items_refunded | INT | SUM(quantity) | Units refunded |
| line_item_count | INT | COUNT DISTINCT | Line items affected |
| **Restock** |
| items_restocked | INT | SUM where RETURN/CANCEL | Units returned to inventory |
| items_not_restocked | INT | SUM where NO_RESTOCK | Units not restocked |
| **Reason** |
| refund_note | TEXT | stg_refunds.note | Refund reason/note |
| **Flags** |
| is_full_refund | BOOLEAN | Derived | refund_pct >= 99 |
| is_partial_refund | BOOLEAN | Derived | Partial refund |
| has_restock | BOOLEAN | Derived | Items were restocked |
| **Denormalized** |
| customer_email | VARCHAR(255) | dim_customer | Customer email |
| customer_name | VARCHAR(200) | dim_customer | Customer name |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### fact_inventory_snapshot

**Source:** stg_inventory_levels with denormalized attributes
**Grain:** One row per inventory item per location per snapshot date

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| **Keys** |
| inventory_snapshot_key | BIGINT | IDENTITY | Surrogate key |
| snapshot_date_key | INT | to_date_key() | FK to dim_date |
| product_key | BIGINT | Lookup | FK to dim_product |
| location_key | BIGINT | Lookup | FK to dim_location |
| **Identifiers** |
| inventory_item_id | VARCHAR(50) | stg_inventory_levels | Inventory item ID |
| location_id | VARCHAR(50) | stg_inventory_levels | Location ID |
| snapshot_date | DATE | stg_inventory_levels | Snapshot date |
| **Inventory Levels** |
| available_quantity | INT | stg_inventory_levels.available | Available to sell |
| on_hand_quantity | INT | stg_inventory_levels.on_hand | Physically in stock |
| committed_quantity | INT | stg_inventory_levels.committed | Reserved for orders |
| incoming_quantity | INT | stg_inventory_levels.incoming | Expected inventory |
| reserved_quantity | INT | stg_inventory_levels.reserved | Other reservations |
| **Calculated** |
| total_inventory | INT | Calculated | Total inventory position |
| sellable_inventory | INT | = available | Truly available |
| **Valuation** |
| unit_cost | DECIMAL(18,2) | dim_product | Cost per unit |
| inventory_cost_value | DECIMAL(18,2) | Calculated | on_hand × cost |
| unit_price | DECIMAL(18,2) | dim_product | Selling price |
| inventory_retail_value | DECIMAL(18,2) | Calculated | on_hand × price |
| **Denormalized Product** |
| sku | VARCHAR(100) | dim_product | SKU |
| product_title | VARCHAR(255) | dim_product | Product name |
| variant_title | VARCHAR(255) | dim_product | Variant name |
| product_type | VARCHAR(255) | dim_product | Category |
| vendor | VARCHAR(255) | dim_product | Vendor |
| **Denormalized Location** |
| location_name | VARCHAR(255) | dim_location | Location name |
| location_country | VARCHAR(100) | dim_location | Location country |
| **Flags** |
| is_out_of_stock | BOOLEAN | Derived | available = 0 |
| is_low_stock | BOOLEAN | Derived | Below threshold |
| is_overstocked | BOOLEAN | Derived | Above threshold |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

## Column Count Summary

| Table | Columns | Purpose |
|-------|---------|---------|
| dim_date | 14 | Calendar |
| dim_time | 7 | Hour-of-day |
| dim_customer | 26 | Customer master + RFM |
| dim_product | 24 | Product catalog |
| dim_geography | 10 | Locations |
| dim_discount | 14 | Discount codes |
| dim_location | 11 | Fulfillment locations |
| fact_order | ~75 | Order metrics |
| fact_order_line_item | ~35 | Line item detail |
| fact_fulfillment | ~30 | Fulfillment metrics |
| fact_refund | ~25 | Refund analytics |
| fact_inventory_snapshot | ~25 | Inventory tracking |
| **Total** | **~296** | |

---

## Default/Unknown Rows

Each dimension has a default row (key = 0) for handling nulls:

| Dimension | Key | Description |
|-----------|-----|-------------|
| dim_customer | 0 | Unknown/Guest Customer |
| dim_product | 0 | Unknown Product |
| dim_geography | 0 | Unknown Location |
| dim_discount | 0 | No Discount |
| dim_location | 0 | Unknown Location |
