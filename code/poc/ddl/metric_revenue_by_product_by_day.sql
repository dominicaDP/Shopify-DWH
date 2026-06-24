-- =============================================================================
-- POC Phase 4.1 — "Revenue by product by day" (window narrowed 90->60 days)
--
-- Revenue definition for the POC: SUM of line-item net_amount (discounted line
-- total, post-discount). Refunds/cancellations are NOT netted out here — that is
-- a definitional choice to confirm against the Fivetran source in 4.2/4.3.
-- Grain: one row per (order_date, product). Variants roll up to product_id.
-- =============================================================================

CREATE OR REPLACE VIEW SHOPIFY_DWH.v_revenue_by_product_by_day AS
SELECT
    d.full_date                              AS order_date,
    dp.product_id,
    dp.product_title,
    SUM(COALESCE(li.net_amount, 0))          AS revenue,
    SUM(COALESCE(li.quantity_ordered, 0))    AS units,
    COUNT(DISTINCT li.order_key)             AS orders
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d     ON d.date_key    = li.order_date_key
JOIN SHOPIFY_DWH.dim_product dp ON dp.product_key = li.product_key
GROUP BY d.full_date, dp.product_id, dp.product_title;

-- Headline totals for the last 60 days
SELECT
    COUNT(*)                       AS product_day_rows,
    COUNT(DISTINCT order_date)     AS distinct_days,
    COUNT(DISTINCT product_id)     AS distinct_products,
    ROUND(SUM(revenue), 2)         AS total_revenue,
    SUM(units)                     AS total_units
FROM SHOPIFY_DWH.v_revenue_by_product_by_day
WHERE order_date >= CURRENT_DATE - 60;

-- Top 15 products by revenue over the window
SELECT product_title, ROUND(SUM(revenue), 2) AS revenue, SUM(units) AS units
FROM SHOPIFY_DWH.v_revenue_by_product_by_day
WHERE order_date >= CURRENT_DATE - 60
GROUP BY product_id, product_title
ORDER BY revenue DESC
LIMIT 15;

-- Daily revenue trend (most recent 14 days, for a quick eyeball)
SELECT order_date, ROUND(SUM(revenue), 2) AS revenue, SUM(units) AS units, SUM(orders) AS orders
FROM SHOPIFY_DWH.v_revenue_by_product_by_day
WHERE order_date >= CURRENT_DATE - 14
GROUP BY order_date
ORDER BY order_date;
