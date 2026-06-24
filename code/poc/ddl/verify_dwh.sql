-- Gate 3->4 verification.

-- 1. Row counts across the DWH
SELECT 'dim_date' AS obj, COUNT(*) AS n FROM SHOPIFY_DWH.dim_date
UNION ALL SELECT 'dim_product', COUNT(*) FROM SHOPIFY_DWH.dim_product
UNION ALL SELECT 'fact_order', COUNT(*) FROM SHOPIFY_DWH.fact_order
UNION ALL SELECT 'fact_order_line_item', COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item
ORDER BY obj;

-- 2. dim_date span sanity
SELECT MIN(full_date) AS min_date, MAX(full_date) AS max_date, COUNT(*) AS days
FROM SHOPIFY_DWH.dim_date;

-- 3. fact_order reconciles to stg_orders (counts + money)
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order)              AS fact_order_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_orders)             AS stg_order_rows,
    (SELECT ROUND(SUM(total_amount),2) FROM SHOPIFY_DWH.fact_order)     AS fact_total,
    (SELECT ROUND(SUM(total_price),2)  FROM SHOPIFY_STG.stg_orders)     AS stg_total;

-- 4. fact_order_line_item reconciles to stg_order_line_items (matched lines only;
--    orphan lines whose order header is absent are intentionally dropped)
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item)                   AS fact_line_rows,
    (SELECT COUNT(*) FROM SHOPIFY_STG.stg_order_line_items)                  AS stg_line_rows,
    (SELECT ROUND(SUM(net_amount),2) FROM SHOPIFY_DWH.fact_order_line_item)   AS fact_net,
    (SELECT ROUND(SUM(discounted_total),2) FROM SHOPIFY_STG.stg_order_line_items) AS stg_net;

-- 5. NULL / orphan FK checks (all must be 0 except unknown_product which is informational)
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order fo
       LEFT JOIN SHOPIFY_DWH.dim_date d ON d.date_key = fo.order_date_key
       WHERE d.date_key IS NULL)                                             AS order_dates_missing_in_dimdate,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item WHERE order_key IS NULL)      AS line_null_order_key,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item WHERE product_key IS NULL)    AS line_null_product_key,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item li
       LEFT JOIN SHOPIFY_DWH.dim_date d ON d.date_key = li.order_date_key
       WHERE d.date_key IS NULL)                                            AS line_dates_missing_in_dimdate,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order_line_item WHERE product_key = -1)       AS line_unknown_product;
