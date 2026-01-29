# Shopify DWH Schema

**Version:** 1.0 (Draft)
**Last Updated:** 2026-01-29

---

## Overview

Star schema design for generic Shopify DWH.

- **Target Platform:** Exasol (columnar)
- **Grain:** Line item level
- **SCD Type:** Type 1 (overwrite) for all dimensions

---

## Schema Diagram

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴────────┐    ┌─────────────┐
│dim_customer │────┤                │────│ dim_product │
└─────────────┘    │                │    └─────────────┘
                   │ fact_order_    │
┌─────────────┐    │  line_item     │    ┌─────────────┐
│dim_geography│────┤                │────│ dim_discount│
└─────────────┘    │                │    └─────────────┘
                   └───────┬────────┘
                           │
                   ┌───────┴────────┐
                   │                │
                   │ fact_order_    │────┐
                   │   header       │    │
                   │                │    │
                   └───────┬────────┘    │
                           │             │
                    ┌──────┴──────┐      │
                    │  dim_order  │──────┘
                    └─────────────┘
```

---

## Fact Tables

### fact_order_line_item

**Grain:** One row per line item per order

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `line_item_key` | BIGINT | NO | Surrogate PK |
| `order_key` | BIGINT | NO | FK → dim_order |
| `product_key` | BIGINT | NO | FK → dim_product |
| `customer_key` | BIGINT | YES | FK → dim_customer |
| `order_date_key` | INT | NO | FK → dim_date |
| `ship_address_key` | BIGINT | YES | FK → dim_geography |
| `discount_key` | BIGINT | YES | FK → dim_discount |
| `order_id` | VARCHAR(50) | NO | Shopify order ID |
| `order_name` | VARCHAR(20) | NO | Order number (#1001) |
| `line_item_id` | VARCHAR(50) | NO | Shopify line item ID |
| `sku` | VARCHAR(100) | YES | Product SKU |
| `quantity` | INT | NO | Units ordered |
| `unit_price` | DECIMAL(18,2) | NO | Price per unit |
| `line_subtotal` | DECIMAL(18,2) | NO | quantity × unit_price |
| `line_discount_amount` | DECIMAL(18,2) | NO | Discount on this line |
| `line_tax_amount` | DECIMAL(18,2) | NO | Tax on this line |
| `line_total` | DECIMAL(18,2) | NO | Final line amount |
| `is_gift_card` | BOOLEAN | NO | Gift card item |
| `is_taxable` | BOOLEAN | NO | Subject to tax |
| `is_fulfilled` | BOOLEAN | NO | Has been shipped |
| `is_refunded` | BOOLEAN | NO | Has been refunded |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

---

### fact_order_header

**Grain:** One row per order

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `order_key` | BIGINT | NO | Surrogate PK (shared with dim_order) |
| `customer_key` | BIGINT | YES | FK → dim_customer |
| `order_date_key` | INT | NO | FK → dim_date |
| `ship_address_key` | BIGINT | YES | FK → dim_geography |
| `bill_address_key` | BIGINT | YES | FK → dim_geography |
| `order_id` | VARCHAR(50) | NO | Shopify order ID |
| `order_name` | VARCHAR(20) | NO | Order number |
| `subtotal` | DECIMAL(18,2) | NO | Sum of line subtotals |
| `total_discount` | DECIMAL(18,2) | NO | All discounts |
| `total_tax` | DECIMAL(18,2) | NO | All taxes |
| `shipping_amount` | DECIMAL(18,2) | NO | Shipping cost |
| `total_price` | DECIMAL(18,2) | NO | Final order total |
| `total_refunded` | DECIMAL(18,2) | NO | Amount refunded |
| `net_payment` | DECIMAL(18,2) | NO | Received minus refunded |
| `line_item_count` | INT | NO | Number of line items |
| `total_quantity` | INT | NO | Sum of quantities |
| `is_cancelled` | BOOLEAN | NO | Order cancelled |
| `is_fulfilled` | BOOLEAN | NO | Fully fulfilled |
| `is_partially_fulfilled` | BOOLEAN | NO | Partially fulfilled |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

---

## Dimensions

### dim_date

**Type:** Conformed, pre-generated

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `date_key` | INT | NO | PK (YYYYMMDD) |
| `date` | DATE | NO | Actual date |
| `day_of_week` | INT | NO | 1-7 |
| `day_name` | VARCHAR(10) | NO | Monday, Tuesday... |
| `day_of_month` | INT | NO | 1-31 |
| `day_of_year` | INT | NO | 1-366 |
| `week_of_year` | INT | NO | 1-53 |
| `month` | INT | NO | 1-12 |
| `month_name` | VARCHAR(10) | NO | January, February... |
| `quarter` | INT | NO | 1-4 |
| `year` | INT | NO | 2024, 2025... |
| `is_weekend` | BOOLEAN | NO | Saturday/Sunday |
| `is_holiday` | BOOLEAN | NO | Configurable |
| `fiscal_year` | INT | YES | If different from calendar |
| `fiscal_quarter` | INT | YES | If different from calendar |

---

### dim_customer

**Type:** SCD Type 1

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `customer_key` | BIGINT | NO | Surrogate PK |
| `customer_id` | VARCHAR(50) | NO | Shopify customer ID |
| `email` | VARCHAR(255) | YES | Email address |
| `first_name` | VARCHAR(100) | YES | First name |
| `last_name` | VARCHAR(100) | YES | Last name |
| `phone` | VARCHAR(50) | YES | Phone number |
| `accepts_marketing` | BOOLEAN | NO | Marketing consent |
| `created_at` | TIMESTAMP | YES | Customer since |
| `order_count` | INT | NO | Total orders |
| `total_spent` | DECIMAL(18,2) | NO | Lifetime value |
| `default_country` | VARCHAR(100) | YES | Default address country |
| `default_province` | VARCHAR(100) | YES | Default address province |
| `tags` | VARCHAR(1000) | YES | Shopify customer tags |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

---

### dim_product

**Type:** SCD Type 1

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `product_key` | BIGINT | NO | Surrogate PK |
| `product_id` | VARCHAR(50) | NO | Shopify product ID |
| `variant_id` | VARCHAR(50) | NO | Shopify variant ID |
| `sku` | VARCHAR(100) | YES | SKU |
| `title` | VARCHAR(500) | NO | Product title |
| `variant_title` | VARCHAR(500) | YES | Variant title |
| `product_type` | VARCHAR(255) | YES | Product type/category |
| `vendor` | VARCHAR(255) | YES | Vendor/brand |
| `price` | DECIMAL(18,2) | NO | Current price |
| `compare_at_price` | DECIMAL(18,2) | YES | Original/compare price |
| `cost` | DECIMAL(18,2) | YES | Cost price |
| `taxable` | BOOLEAN | NO | Subject to tax |
| `requires_shipping` | BOOLEAN | NO | Physical product |
| `weight` | DECIMAL(10,2) | YES | Product weight |
| `weight_unit` | VARCHAR(10) | YES | kg, g, lb, oz |
| `tags` | VARCHAR(1000) | YES | Product tags |
| `status` | VARCHAR(20) | NO | active, archived, draft |
| `created_at` | TIMESTAMP | YES | Product created |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

---

### dim_geography

**Type:** SCD Type 1

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `geography_key` | BIGINT | NO | Surrogate PK |
| `address_hash` | VARCHAR(64) | NO | Hash for deduplication |
| `city` | VARCHAR(255) | YES | City |
| `province` | VARCHAR(255) | YES | Province/state name |
| `province_code` | VARCHAR(10) | YES | Province code |
| `country` | VARCHAR(100) | NO | Country name |
| `country_code` | VARCHAR(5) | NO | ISO country code |
| `postal_code` | VARCHAR(20) | YES | Zip/postal code |
| `latitude` | DECIMAL(10,6) | YES | Latitude |
| `longitude` | DECIMAL(10,6) | YES | Longitude |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

---

### dim_order

**Type:** SCD Type 1

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `order_key` | BIGINT | NO | Surrogate PK |
| `order_id` | VARCHAR(50) | NO | Shopify order ID |
| `order_name` | VARCHAR(20) | NO | Order number (#1001) |
| `financial_status` | VARCHAR(50) | NO | pending, paid, refunded... |
| `fulfillment_status` | VARCHAR(50) | YES | fulfilled, partial, unfulfilled |
| `cancel_reason` | VARCHAR(255) | YES | Reason if cancelled |
| `source_name` | VARCHAR(50) | YES | web, pos, mobile... |
| `currency` | VARCHAR(5) | NO | Order currency |
| `processed_at` | TIMESTAMP | YES | When processed |
| `cancelled_at` | TIMESTAMP | YES | When cancelled |
| `closed_at` | TIMESTAMP | YES | When closed |
| `tags` | VARCHAR(1000) | YES | Order tags |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

---

### dim_discount

**Type:** SCD Type 1

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `discount_key` | BIGINT | NO | Surrogate PK |
| `discount_code` | VARCHAR(100) | NO | The code used |
| `discount_type` | VARCHAR(50) | NO | fixed_amount, percentage, shipping |
| `value` | DECIMAL(18,2) | NO | Amount or percentage |
| `value_type` | VARCHAR(20) | NO | fixed_amount or percentage |
| `target_type` | VARCHAR(50) | YES | line_item, shipping_line |
| `allocation_method` | VARCHAR(20) | YES | across, each |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

**Note:** Row with `discount_key = 0` reserved for "No Discount" default.

---

## Default/Unknown Rows

Each dimension should have a default row for handling nulls:

| Dimension | Key | Description |
|-----------|-----|-------------|
| dim_customer | 0 | Unknown/Guest Customer |
| dim_product | 0 | Unknown Product |
| dim_geography | 0 | Unknown Location |
| dim_order | 0 | Unknown Order |
| dim_discount | 0 | No Discount |

---

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Fact tables | `fact_` prefix | fact_order_line_item |
| Dimensions | `dim_` prefix | dim_customer |
| Surrogate keys | `_key` suffix | customer_key |
| Natural keys | `_id` suffix | customer_id |
| Booleans | `is_` prefix | is_fulfilled |
| Timestamps | `_at` suffix | created_at |
| ETL metadata | `_` prefix | _loaded_at |

---

## Finance Measures & KPIs

Standard calculated measures for the generic Shopify DWH.

### Revenue Metrics

| Measure | Calculation | Grain |
|---------|-------------|-------|
| Gross Revenue | SUM(line_subtotal) | Line/Order |
| Discount Amount | SUM(line_discount_amount) or SUM(total_discount) | Line/Order |
| Net Revenue | Gross Revenue - Discount Amount | Line/Order |
| Tax Amount | SUM(line_tax_amount) or SUM(total_tax) | Line/Order |
| Shipping Revenue | SUM(shipping_amount) | Order |
| Total Revenue | Net Revenue + Tax Amount + Shipping | Order |
| Refund Amount | SUM(total_refunded) | Order |
| Net Payment | SUM(net_payment) | Order |

### Discount Metrics

| Measure | Calculation | Notes |
|---------|-------------|-------|
| Discount Rate % | (Discount Amount / Gross Revenue) * 100 | Percentage of gross discounted |
| Orders with Discount | COUNT where total_discount > 0 | Count |
| Orders without Discount | COUNT where total_discount = 0 | Count |
| Discount Penetration % | (Orders with Discount / Total Orders) * 100 | % of orders using discount |

### Profitability Metrics

| Measure | Calculation | Notes |
|---------|-------------|-------|
| COGS | SUM(quantity * product.cost) | Requires cost in dim_product |
| Gross Profit | Net Revenue - COGS | Margin in currency |
| Gross Margin % | (Gross Profit / Net Revenue) * 100 | Margin as percentage |

**Note:** Profitability requires cost data in dim_product. If unavailable, these metrics will be null.

### Average Metrics

| Measure | Calculation | Notes |
|---------|-------------|-------|
| Average Order Value (AOV) | Net Revenue / COUNT(DISTINCT order_id) | Revenue per order |
| Average Items per Order | SUM(quantity) / COUNT(DISTINCT order_id) | Units per order |
| Average Line Value | Net Revenue / COUNT(line_item_id) | Revenue per line item |
| Average Discount per Order | Discount Amount / COUNT(DISTINCT order_id) | Discount per order |
| Average Unit Price | Net Revenue / SUM(quantity) | Revenue per unit |

### Refund Metrics

| Measure | Calculation | Notes |
|---------|-------------|-------|
| Refund Amount | SUM(total_refunded) | Total refunded |
| Orders Refunded | COUNT where total_refunded > 0 | Count |
| Refund Rate % | (Orders Refunded / Total Orders) * 100 | % of orders refunded |
| Refund Value Rate % | (Refund Amount / Total Revenue) * 100 | % of revenue refunded |

### Volume Metrics

| Measure | Calculation | Notes |
|---------|-------------|-------|
| Order Count | COUNT(DISTINCT order_id) | Number of orders |
| Line Item Count | COUNT(line_item_id) | Number of line items |
| Units Sold | SUM(quantity) | Total units |
| Unique Customers | COUNT(DISTINCT customer_key) | Customer count |
| Unique Products | COUNT(DISTINCT product_key) | Product count |

---

## Trend & Period Analysis

For time-based comparisons, typical patterns:

### Period Comparisons

| Comparison | Description |
|------------|-------------|
| vs Prior Period | Current period vs immediately prior (e.g., this week vs last week) |
| vs Same Period Last Year | Year-over-year comparison |
| vs Rolling Average | Current vs N-period rolling average |

### Growth Metrics

| Measure | Calculation |
|---------|-------------|
| Period Growth | (Current - Prior) / Prior * 100 |
| YoY Growth | (Current - Same Period LY) / Same Period LY * 100 |

### Trend Patterns

| Pattern | Implementation |
|---------|----------------|
| Daily trend | Aggregate by date_key |
| Weekly trend | Aggregate by week_of_year, year |
| Monthly trend | Aggregate by month, year |
| Quarterly trend | Aggregate by quarter, year |
| YTD cumulative | Running sum within year |
| MTD cumulative | Running sum within month |

**Note:** Trend calculations typically done in BI layer or via window functions in views.

---

## Open Items

- [ ] Confirm Exasol-specific data types
- [ ] Define indexes/distribution keys for Exasol
- [ ] Consider dim_time for time-of-day analysis
- [ ] Define view layer for calculated measures
