# Shopify DWH Schema

**Version:** 1.1 (Exasol-optimized)
**Last Updated:** 2026-01-30

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
| `option1` | VARCHAR(255) | YES | First variant option (e.g., Size) |
| `option2` | VARCHAR(255) | YES | Second variant option (e.g., Color) |
| `option3` | VARCHAR(255) | YES | Third variant option (e.g., Material) |
| `barcode` | VARCHAR(100) | YES | Product barcode (UPC, EAN, etc.) |
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

### dim_location

**Type:** SCD Type 1

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `location_key` | BIGINT | NO | Surrogate PK |
| `location_id` | VARCHAR(50) | NO | Shopify location ID |
| `name` | VARCHAR(255) | NO | Location name |
| `address1` | VARCHAR(255) | YES | Street address |
| `address2` | VARCHAR(255) | YES | Additional address |
| `city` | VARCHAR(100) | YES | City |
| `province` | VARCHAR(100) | YES | Province/state |
| `province_code` | VARCHAR(10) | YES | Province code |
| `country` | VARCHAR(100) | YES | Country |
| `country_code` | VARCHAR(5) | YES | ISO country code |
| `zip` | VARCHAR(20) | YES | Postal code |
| `phone` | VARCHAR(50) | YES | Contact phone |
| `is_active` | BOOLEAN | NO | Currently active |
| `fulfills_online_orders` | BOOLEAN | NO | Fulfills online orders |
| `_loaded_at` | TIMESTAMP | NO | ETL load timestamp |

**Note:** Row with `location_key = 0` reserved for "Unknown Location" default.

**Future Use:**
- FK for fact_fulfillment (when implemented)
- FK for fact_inventory_snapshot (when implemented)

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
| dim_location | 0 | Unknown Location |

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

## Currency Handling

**Approach:** Option B - Store currency code, use shop currency amounts

| Aspect | Implementation |
|--------|----------------|
| Financial amounts | `shopMoney.amount` from Shopify MoneyBag |
| Currency storage | `dim_order.currency` (per order) |
| Multi-currency shops | Filter/group by `dim_order.currency` |
| Cost data | `dim_product.cost` in shop currency |

**Not implemented (backlogged):**
- presentmentMoney (customer's display currency)
- Exchange rate conversion
- Normalized currency

---

## Open Items

- [x] Confirm Exasol-specific data types
- [x] Define indexes/distribution keys for Exasol
- [x] Multi-currency handling decision
- [ ] Consider dim_time for time-of-day analysis
- [ ] Define view layer for calculated measures

---

## Exasol-Specific Optimizations

**Last Reviewed:** 2026-01-30

### Data Type Assessment

| Current Type | Assessment | Recommendation |
|--------------|------------|----------------|
| BIGINT (surrogate keys) | ✓ Good | Efficient for joins |
| INT (date_key) | ✓ Good | Compact, efficient |
| VARCHAR(50) for IDs | ✓ Good | Shopify IDs ~13 chars |
| VARCHAR(500) for titles | ⚠ Oversized | Shopify limits to 255 chars |
| VARCHAR(1000) for tags | ✓ Reasonable | Tags can be long |
| VARCHAR(255) for names | ✓ Standard | - |
| DECIMAL(18,2) for money | ✓ Good | Standard precision |
| DECIMAL(10,6) for coords | ✓ Good | 6 decimal places sufficient |
| BOOLEAN | ✓ Good | Native Exasol type |
| TIMESTAMP | ✓ Good | Default millisecond precision |

**Recommended Changes:**
```sql
-- Reduce oversized VARCHARs
dim_product.title: VARCHAR(500) → VARCHAR(255)
dim_product.variant_title: VARCHAR(500) → VARCHAR(255)
```

### Distribution Keys

**Principle:** Distribute on JOIN columns (not WHERE columns) to enable local joins.

| Table | Distribution Key | Rationale |
|-------|------------------|-----------|
| `fact_order_line_item` | `order_key` | Most common join to dim_order/fact_order_header |
| `fact_order_header` | `customer_key` | Common join for customer analysis |
| `dim_customer` | `customer_key` | Match fact table distribution |
| `dim_product` | `product_key` | Match fact table joins |
| `dim_order` | `order_key` | Match fact table distribution |
| `dim_geography` | (none - replicate) | Small table |
| `dim_date` | (none - replicate) | Small table, conformed |
| `dim_discount` | (none - replicate) | Small table |

**DDL Examples:**
```sql
CREATE TABLE fact_order_line_item (
    ...
)
DISTRIBUTE BY order_key;

CREATE TABLE fact_order_header (
    ...
)
DISTRIBUTE BY customer_key;
```

### Partition Keys

**Principle:** Partition on WHERE filter columns for large tables.

| Table | Partition Key | Rationale |
|-------|---------------|-----------|
| `fact_order_line_item` | `order_date_key` | Date filtering in most queries |
| `fact_order_header` | `order_date_key` | Date filtering in most queries |
| Dimensions | (none) | Too small to benefit |

**DDL Example:**
```sql
CREATE TABLE fact_order_line_item (
    ...
)
DISTRIBUTE BY order_key
PARTITION BY order_date_key;
```

**Note:** Partitioning is optional at current scale (2-4k orders/month). Consider adding when:
- Tables exceed memory capacity
- Query performance degrades on date-filtered queries

### Replication Border (Star Schema Optimization)

For star schema, increase replication border so dimension tables are replicated to all nodes:

```sql
-- Check current setting
SELECT * FROM EXA_PARAMETERS WHERE PARAMETER_NAME = 'REPLICATION_BORDER';

-- Increase for star schema (default is 100,000 rows)
ALTER SYSTEM SET REPLICATION_BORDER = 500000;
```

**Expected dimension sizes:**
| Dimension | Est. Rows | Replicate? |
|-----------|-----------|------------|
| dim_date | ~3,650 (10 years) | ✓ Yes |
| dim_customer | <50,000 | ✓ Yes |
| dim_product | <10,000 | ✓ Yes |
| dim_geography | <10,000 | ✓ Yes |
| dim_order | <50,000 | ✓ Yes |
| dim_discount | <1,000 | ✓ Yes |
| dim_location | <100 | ✓ Yes |

All dimensions well under default 100k border - will auto-replicate.

### Join Best Practices

| Practice | Implementation |
|----------|----------------|
| Use surrogate keys | ✓ All joins on BIGINT/INT keys |
| Avoid VARCHAR joins | ✓ Natural keys stored but not joined on |
| Matching data types | ✓ All FKs match PK types |
| Use ON not USING | Use explicit ON clauses in multi-joins |

### Index Considerations

**Exasol auto-creates indexes** - do not manually create indexes.

Exasol's automatic index management handles:
- Join columns (auto-indexed when used)
- Filter columns (auto-indexed when used)

**Anti-pattern to avoid:**
```sql
-- DON'T DO THIS in Exasol
CREATE INDEX idx_customer ON fact_order_line_item(customer_key);
```

### Staging Schema Considerations

For ETL staging tables (SHOPIFY_STG):

```sql
-- Staging tables: no distribution/partition (simpler, faster loads)
CREATE TABLE shopify_stg.stg_products (
    id VARCHAR(50),
    title VARCHAR(255),
    ...
)
-- No DISTRIBUTE BY (use default round-robin for bulk loads)
```

**Load pattern:**
1. TRUNCATE staging table
2. Bulk INSERT/IMPORT (no distribution = faster parallel load)
3. MERGE/INSERT into final tables (with proper distribution)

---

## DDL Reference

### fact_order_line_item (Exasol-optimized)

```sql
CREATE OR REPLACE TABLE shopify_dwh.fact_order_line_item (
    line_item_key       BIGINT NOT NULL,
    order_key           BIGINT NOT NULL,
    product_key         BIGINT NOT NULL,
    customer_key        BIGINT,
    order_date_key      INT NOT NULL,
    ship_address_key    BIGINT,
    discount_key        BIGINT,
    order_id            VARCHAR(50) NOT NULL,
    order_name          VARCHAR(20) NOT NULL,
    line_item_id        VARCHAR(50) NOT NULL,
    sku                 VARCHAR(100),
    quantity            INT NOT NULL,
    unit_price          DECIMAL(18,2) NOT NULL,
    line_subtotal       DECIMAL(18,2) NOT NULL,
    line_discount_amount DECIMAL(18,2) NOT NULL,
    line_tax_amount     DECIMAL(18,2) NOT NULL,
    line_total          DECIMAL(18,2) NOT NULL,
    is_gift_card        BOOLEAN NOT NULL,
    is_taxable          BOOLEAN NOT NULL,
    is_fulfilled        BOOLEAN NOT NULL,
    is_refunded         BOOLEAN NOT NULL,
    _loaded_at          TIMESTAMP NOT NULL,

    PRIMARY KEY (line_item_key)
)
DISTRIBUTE BY order_key
PARTITION BY order_date_key;
```

### dim_product (Exasol-optimized)

```sql
CREATE OR REPLACE TABLE shopify_dwh.dim_product (
    product_key         BIGINT NOT NULL,
    product_id          VARCHAR(50) NOT NULL,
    variant_id          VARCHAR(50) NOT NULL,
    sku                 VARCHAR(100),
    title               VARCHAR(255) NOT NULL,      -- Reduced from 500
    variant_title       VARCHAR(255),                -- Reduced from 500
    option1             VARCHAR(255),
    option2             VARCHAR(255),
    option3             VARCHAR(255),
    barcode             VARCHAR(100),
    product_type        VARCHAR(255),
    vendor              VARCHAR(255),
    price               DECIMAL(18,2) NOT NULL,
    compare_at_price    DECIMAL(18,2),
    cost                DECIMAL(18,2),
    taxable             BOOLEAN NOT NULL,
    requires_shipping   BOOLEAN NOT NULL,
    weight              DECIMAL(10,2),
    weight_unit         VARCHAR(10),
    tags                VARCHAR(1000),
    status              VARCHAR(20) NOT NULL,
    created_at          TIMESTAMP,
    _loaded_at          TIMESTAMP NOT NULL,

    PRIMARY KEY (product_key)
)
DISTRIBUTE BY product_key;
```

---

## Performance Monitoring Queries

### Check Table Statistics

```sql
-- Table sizes and distribution
SELECT
    table_schema,
    table_name,
    table_rows,
    raw_object_size / 1024 / 1024 AS size_mb,
    distribute_key,
    partition_key
FROM exa_all_tables
WHERE table_schema = 'SHOPIFY_DWH'
ORDER BY table_rows DESC;
```

### Check Replication Border

```sql
SELECT parameter_name, parameter_value
FROM exa_parameters
WHERE parameter_name = 'REPLICATION_BORDER';
```

### Identify Join Performance Issues

```sql
-- Check if tables are being replicated as expected
SELECT
    table_name,
    table_rows,
    CASE WHEN table_rows < 100000 THEN 'Will replicate'
         ELSE 'Distributed' END AS replication_status
FROM exa_all_tables
WHERE table_schema = 'SHOPIFY_DWH';
```
