# Shopify DWH - Data Lineage Reference

**Version:** 2.0
**Last Updated:** 2026-02-04

---

## Overview

This document describes how data flows from Shopify API through staging to the data warehouse, including all transformations applied.

---

## Complete Lineage Diagram

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

## Transformation Types

### 1. GID Extraction

Shopify returns Global IDs (GIDs) like `gid://shopify/Order/123456789`. We extract the numeric ID.

**Input:** `gid://shopify/Order/123456789`
**Output:** `123456789`

**SQL:**
```sql
REGEXP_SUBSTR(id, '[0-9]+$') AS order_id
```

---

### 2. Date Key Generation

Convert timestamps to integer date keys for dim_date joins.

**Input:** `2026-02-04T14:30:00Z`
**Output:** `20260204`

**SQL:**
```sql
CAST(TO_CHAR(created_at, 'YYYYMMDD') AS INT) AS order_date_key
```

---

### 3. Time Key Generation

Extract hour (0-23) for dim_time joins.

**Input:** `2026-02-04T14:30:00Z`
**Output:** `14`

**SQL:**
```sql
EXTRACT(HOUR FROM created_at) AS order_time_key
```

---

### 4. Money Extraction

Shopify returns MoneyBag with shopMoney and presentmentMoney. We use shopMoney (merchant's currency).

**Input:**
```json
{
  "totalPriceSet": {
    "shopMoney": { "amount": "199.99", "currencyCode": "ZAR" },
    "presentmentMoney": { "amount": "199.99", "currencyCode": "ZAR" }
  }
}
```

**Output:** `199.99` (DECIMAL)

**SQL:**
```sql
CAST(total_price_set->>'shopMoney'->>'amount' AS DECIMAL(18,2)) AS total_amount
```

---

### 5. Marketing State Mapping

Map Shopify marketing states to boolean flags.

**Input:** `SUBSCRIBED`, `PENDING`, `UNSUBSCRIBED`, `NOT_SUBSCRIBED`
**Output:** `TRUE` or `FALSE`

**SQL:**
```sql
CASE
  WHEN email_marketing_state IN ('SUBSCRIBED', 'PENDING') THEN TRUE
  ELSE FALSE
END AS accepts_email_marketing
```

---

### 6. Address Hashing

Generate hash for dim_geography deduplication.

**SQL:**
```sql
MD5(CONCAT(
  COALESCE(city, ''),
  COALESCE(province, ''),
  COALESCE(country, ''),
  COALESCE(zip, '')
)) AS address_hash
```

---

### 7. Customer Segment Logic

Assign customer segments based on recency and order count.

**SQL:**
```sql
CASE
  WHEN first_order_date >= CURRENT_DATE - INTERVAL '30 days' THEN 'New'
  WHEN days_since_last_order <= 90 THEN 'Active'
  WHEN days_since_last_order <= 180 THEN 'At-Risk'
  ELSE 'Lapsed'
END AS customer_segment
```

---

### 8. RFM Score Calculation

Calculate quintile scores for Recency, Frequency, Monetary.

**SQL:**
```sql
-- Recency: Lower days = Higher score (5 is best)
NTILE(5) OVER (ORDER BY days_since_last_order ASC) AS rfm_recency_score,

-- Frequency: Higher orders = Higher score
NTILE(5) OVER (ORDER BY lifetime_order_count DESC) AS rfm_frequency_score,

-- Monetary: Higher spend = Higher score
NTILE(5) OVER (ORDER BY lifetime_revenue DESC) AS rfm_monetary_score
```

---

### 9. Fulfillment Time Calculation

Calculate hours/days from order to fulfillment.

**SQL:**
```sql
EXTRACT(EPOCH FROM (fulfillment_created_at - order_created_at)) / 3600
  AS fulfillment_time_hours,

EXTRACT(EPOCH FROM (fulfillment_created_at - order_created_at)) / 86400
  AS fulfillment_time_days
```

---

### 10. Gross Margin Calculation

Calculate margin per line item.

**SQL:**
```sql
net_amount - (quantity_ordered * unit_cost) AS gross_margin,

CASE
  WHEN net_amount > 0
  THEN (net_amount - (quantity_ordered * unit_cost)) / net_amount * 100
  ELSE 0
END AS gross_margin_percent
```

---

## Pivot Transformations

### Payments Pivot (stg_order_transactions → fact_order)

**Why:** Orders can have multiple payments (credit card + gift card). We pivot rows to columns.

**Input (rows):**
```
order_id | kind | gateway          | amount
---------|------|------------------|--------
1001     | SALE | shopify_payments | 150.00
1001     | SALE | gift_card        | 50.00
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

**Why:** Orders can have multiple tax types (VAT, levy). We pivot to columns.

**Input (rows):**
```
order_id | line_number | title | rate   | price
---------|-------------|-------|--------|------
1001     | 1           | VAT   | 0.1500 | 30.00
1001     | 2           | Levy  | 0.0100 | 2.00
```

**Transformation SQL:**
```sql
SELECT
    order_id,
    MAX(CASE WHEN line_number = 1 THEN title END) AS tax_1_name,
    MAX(CASE WHEN line_number = 1 THEN rate END) AS tax_1_rate,
    MAX(CASE WHEN line_number = 1 THEN price END) AS tax_1_amount,
    MAX(CASE WHEN line_number = 2 THEN title END) AS tax_2_name,
    MAX(CASE WHEN line_number = 2 THEN rate END) AS tax_2_rate,
    MAX(CASE WHEN line_number = 2 THEN price END) AS tax_2_amount
FROM stg_order_tax_lines
GROUP BY order_id
```

**Output (columns):**
```
order_id | tax_1_name | tax_1_rate | tax_1_amount | tax_2_name | tax_2_rate | tax_2_amount
---------|------------|------------|--------------|------------|------------|-------------
1001     | VAT        | 0.1500     | 30.00        | Levy       | 0.0100     | 2.00
```

---

### Discounts Pivot (stg_order_discount_applications → fact_order)

**Why:** Orders can have multiple discounts. We pivot to columns.

**Input (rows):**
```
order_id | line_number | code      | value_type | value_amount | value_percentage
---------|-------------|-----------|------------|--------------|------------------
1001     | 1           | SAVE20    | percentage | NULL         | 20.00
1001     | 2           | FREESHIP  | fixed      | 50.00        | NULL
```

**Transformation SQL:**
```sql
SELECT
    order_id,
    MAX(CASE WHEN line_number = 1 THEN code END) AS discount_1_code,
    MAX(CASE WHEN line_number = 1 THEN
        CASE WHEN value_percentage IS NOT NULL THEN 'percentage' ELSE 'fixed' END
    END) AS discount_1_type,
    MAX(CASE WHEN line_number = 1 THEN
        COALESCE(value_amount, value_percentage)
    END) AS discount_1_amount,
    MAX(CASE WHEN line_number = 2 THEN code END) AS discount_2_code,
    MAX(CASE WHEN line_number = 2 THEN
        CASE WHEN value_percentage IS NOT NULL THEN 'percentage' ELSE 'fixed' END
    END) AS discount_2_type,
    MAX(CASE WHEN line_number = 2 THEN
        COALESCE(value_amount, value_percentage)
    END) AS discount_2_amount
FROM stg_order_discount_applications
GROUP BY order_id
```

**Output (columns):**
```
order_id | discount_1_code | discount_1_type | discount_1_amount | discount_2_code | discount_2_type | discount_2_amount
---------|-----------------|-----------------|-------------------|-----------------|-----------------|-------------------
1001     | SAVE20          | percentage      | 20.00             | FREESHIP        | fixed           | 50.00
```

---

## Transformation Summary by Target Table

### fact_order

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_orders | Direct mapping | order_id, timestamps, amounts |
| stg_orders | extract_id() | order_id |
| stg_orders | to_date_key() | order_date_key |
| stg_orders | to_time_key() | order_time_key |
| stg_orders.customer_id | FK lookup | customer_key |
| stg_orders.shipping_address | hash + lookup | shipping_geography_key |
| stg_order_transactions | PIVOT | payment_1/2/3_gateway, payment_1/2/3_amount |
| stg_order_tax_lines | PIVOT | tax_1/2_name, tax_1/2_rate, tax_1/2_amount |
| stg_order_discount_applications | PIVOT | discount_1/2_code, discount_1/2_type, discount_1/2_amount |
| stg_order_shipping_lines | First row | shipping_method, shipping_carrier |
| stg_order_line_items | COUNT, SUM | line_item_count, total_quantity |
| dim_customer | Denormalize | customer_email, customer_name, customer_segment |
| dim_geography | Denormalize | shipping_city, shipping_province, shipping_country |
| Derived | Business logic | is_paid, is_cancelled, is_fulfilled, has_discount |

---

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

---

### fact_fulfillment

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_fulfillments | Direct mapping | tracking info, status |
| stg_fulfillments | extract_id() | fulfillment_id, order_id |
| stg_fulfillments | to_date_key() | fulfillment_date_key |
| stg_fulfillments | to_time_key() | fulfillment_time_key |
| stg_fulfillments + stg_orders | Time calculation | fulfillment_time_hours, fulfillment_time_days |
| stg_fulfillment_line_items | COUNT | line_item_count |
| fact_order | Lookup | order_key, order_date_key, customer_key |
| dim_location | Denormalize | location_name |
| dim_customer | Denormalize | customer_email, customer_name |
| Derived | Business logic | is_same_day, is_within_48h, is_late |

---

### fact_refund

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_refunds | Direct mapping | refund amounts, note |
| stg_refunds | extract_id() | refund_id, order_id |
| stg_refunds | to_date_key() | refund_date_key |
| stg_refunds + stg_orders | Date difference | days_to_refund |
| stg_refund_line_items | SUM(quantity) | total_items_refunded |
| stg_refund_line_items | COUNT DISTINCT | line_item_count |
| stg_refund_line_items | Conditional SUM | items_restocked, items_not_restocked |
| fact_order | Lookup | order_key, order_date_key, original_order_total |
| Derived | Calculation | refund_percentage |
| Derived | Business logic | is_full_refund, is_partial_refund, has_restock |

---

### fact_inventory_snapshot

| Source Table(s) | Transformation | Target Column(s) |
|-----------------|----------------|------------------|
| stg_inventory_levels | Direct mapping | quantity fields |
| stg_inventory_levels | extract_id() | inventory_item_id, location_id |
| stg_inventory_levels | to_date_key() | snapshot_date_key |
| stg_inventory_levels.inventory_item_id | FK lookup | product_key |
| stg_inventory_levels.location_id | FK lookup | location_key |
| dim_product | Denormalize | sku, product_title, unit_cost, unit_price |
| dim_location | Denormalize | location_name, location_country |
| Derived | Calculation | inventory_cost_value, inventory_retail_value |
| Derived | Business logic | is_out_of_stock, is_low_stock, is_overstocked |

---

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
| Derived | NTILE(5) | rfm_recency/frequency/monetary_score |
| Derived | Business logic | rfm_segment, customer_segment |

---

## Data Quality Rules

### Required Fields (NOT NULL)

| Table | Required Fields |
|-------|-----------------|
| fact_order | order_key, order_date_key, order_id, total_amount |
| fact_order_line_item | line_item_key, order_key, product_key, quantity_ordered |
| fact_fulfillment | fulfillment_key, order_key, fulfillment_date_key |
| fact_refund | refund_key, order_key, refund_amount |
| dim_customer | customer_key, customer_id |
| dim_product | product_key, product_id, variant_id |

### Foreign Key Validation

All FK lookups should default to key = 0 (Unknown) if no match found:

```sql
COALESCE(
    (SELECT customer_key FROM dim_customer WHERE customer_id = stg.customer_id),
    0
) AS customer_key
```

### Amount Validation

All monetary amounts should be >= 0:

```sql
CASE WHEN total_amount < 0 THEN 0 ELSE total_amount END
```

---

## ETL Load Order

Due to foreign key dependencies, load tables in this order:

**Phase 1: Dimensions (no dependencies)**
1. dim_date
2. dim_time
3. dim_location
4. dim_discount

**Phase 2: Dimensions (with STG dependencies)**
5. dim_product (from stg_products + stg_product_variants)
6. dim_geography (from stg_orders addresses)
7. dim_customer (from stg_customers + stg_orders aggregations)

**Phase 3: Facts**
8. fact_order (depends on all dims)
9. fact_order_line_item (depends on fact_order, dim_product)
10. fact_fulfillment (depends on fact_order, dim_location)
11. fact_refund (depends on fact_order)
12. fact_inventory_snapshot (depends on dim_product, dim_location)
