-- =============================================================================
-- Phase C — Gate C verification (run after 05_transforms.sql).
-- Each query prints a row; eyeball against the expectations in the comments.
-- Ported from the POC's verify_dwh.sql and extended to all 12 DWH objects.
-- =============================================================================

-- 1. Row counts across the whole DWH ------------------------------------------
SELECT 'dim_date' AS obj, COUNT(*) AS n FROM SHOPIFY_DWH.dim_date
UNION ALL SELECT 'dim_time', COUNT(*) FROM SHOPIFY_DWH.dim_time
UNION ALL SELECT 'dim_customer', COUNT(*) FROM SHOPIFY_DWH.dim_customer
UNION ALL SELECT 'dim_product', COUNT(*) FROM SHOPIFY_DWH.dim_product
UNION ALL SELECT 'dim_geography', COUNT(*) FROM SHOPIFY_DWH.dim_geography
UNION ALL SELECT 'dim_discount', COUNT(*) FROM SHOPIFY_DWH.dim_discount
UNION ALL SELECT 'dim_location', COUNT(*) FROM SHOPIFY_DWH.dim_location
UNION ALL SELECT 'fact_order', COUNT(*) FROM SHOPIFY_DWH.fact_order
UNION ALL SELECT 'fact_order_line_item', COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item
UNION ALL SELECT 'fact_fulfillment', COUNT(*) FROM SHOPIFY_DWH.fact_fulfillment
UNION ALL SELECT 'fact_refund', COUNT(*) FROM SHOPIFY_DWH.fact_refund
UNION ALL SELECT 'fact_inventory_snapshot', COUNT(*) FROM SHOPIFY_DWH.fact_inventory_snapshot
ORDER BY obj;

-- 2. Generated-dimension sanity -----------------------------------------------
-- Expect: dim_date 4018 days (2020-01-01 .. 2030-12-31); dim_time exactly 24 rows.
SELECT MIN(full_date) AS min_date, MAX(full_date) AS max_date, COUNT(*) AS days
FROM SHOPIFY_DWH.dim_date;

SELECT COUNT(*) AS time_rows, MIN(time_key) AS min_key, MAX(time_key) AS max_key
FROM SHOPIFY_DWH.dim_time;

-- 3. Sentinel members must exist (one row each) -------------------------------
-- Expect every count = 1.
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_product  WHERE product_key  = -1) AS unknown_product,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_customer WHERE customer_key = -1) AS unknown_customer,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_geography WHERE geography_key = -1) AS unknown_geography,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_location WHERE location_key = -1) AS unknown_location,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_discount WHERE discount_key = 0)  AS no_discount;

-- 4. fact_order reconciles to stg_orders (counts + money) ---------------------
-- Expect fact_order_rows = stg_order_rows and fact_total = stg_total (exact;
-- every order becomes exactly one fact row, total_amount is a direct mapping).
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order)                       AS fact_order_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_orders)                       AS stg_order_rows,
    (SELECT ROUND(SUM(total_amount), 2) FROM SHOPIFY_DWH.fact_order)    AS fact_total,
    (SELECT ROUND(SUM(total_price), 2)  FROM SHOPIFY_STG.stg_orders)    AS stg_total;

-- 5. fact_order_line_item reconciles to stg_order_line_items ------------------
-- Matched lines only; orphan lines whose order header is absent (live-store drift)
-- are intentionally dropped, so fact_line_rows may be <= stg_line_rows.
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item)                        AS fact_line_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_order_line_items)                        AS stg_line_rows,
    (SELECT ROUND(SUM(net_amount), 2) FROM SHOPIFY_DWH.fact_order_line_item)       AS fact_net,
    (SELECT ROUND(SUM(discounted_total), 2) FROM SHOPIFY_STG.stg_order_line_items) AS stg_net;

-- 6. Child-fact row counts vs their STG parents ------------------------------
-- fact_fulfillment <= stg_fulfillments, fact_refund <= stg_refunds,
-- fact_inventory_snapshot = stg_inventory_levels (no header join to drop rows).
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_fulfillment)        AS fact_fulfillment_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_fulfillments)        AS stg_fulfillment_rows,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_refund)             AS fact_refund_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_refunds)             AS stg_refund_rows,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_inventory_snapshot) AS fact_inventory_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_inventory_levels)    AS stg_inventory_rows;

-- 7. NULL / orphan FK checks (all must be 0; *_unknown columns are informational)
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order fo
       LEFT JOIN SHOPIFY_DWH.dim_date d ON d.date_key = fo.order_date_key
       WHERE d.date_key IS NULL)                                          AS order_dates_missing_in_dimdate,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order WHERE customer_key IS NULL)          AS order_null_customer_key,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order WHERE shipping_geography_key IS NULL) AS order_null_ship_geo_key,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item WHERE order_key IS NULL)   AS line_null_order_key,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item WHERE product_key IS NULL) AS line_null_product_key;

-- 8. Informational: how many facts fell back to a sentinel member -------------
-- High numbers here are expected pre-prerequisites (e.g. customer_key all -1 until
-- read_customers + customers load; product_key -1 = variant no longer in catalogue).
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order WHERE customer_key = -1)             AS order_unknown_customer,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order WHERE shipping_geography_key = -1)   AS order_unknown_ship_geo,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item WHERE product_key = -1)    AS line_unknown_product,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_fulfillment WHERE location_key = -1)       AS fulfillment_unknown_location;
