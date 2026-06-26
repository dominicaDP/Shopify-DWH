-- =============================================================================
-- Phase D — reconciliation (OUR side). Run AFTER 07_metric_views.sql.
--
-- This is the production version of the POC's recon_our_side.sql. It runs the same
-- definition the POC used to hit a 0.30% gap vs Fivetran, but without the 60-day
-- floor (production has read_all_orders, so full history is available). The Fivetran
-- side stays the comparison method that worked: join shopify.order_line to
-- shopify.order on the same window, line net = price*quantity - total_discount, and
-- compare orders / products / units / net revenue.
--
-- How to use when the pipeline is live (post Gate A -> B -> C):
--   1. Pick a window (e.g. a full calendar month both systems cover).
--   2. Run section A/B/C below for that window (edit the DATE literals).
--   3. Run the equivalent Fivetran query for the same window/definition.
--   4. Compare; explain any gap (the POC's was entirely the 60-day boundary day).
-- Replace the DATE '2026-01-01' floors with the window you are reconciling.
-- =============================================================================

-- A. Headline totals, line-item grain (revenue = SUM net_amount) --------------
SELECT
    COUNT(DISTINCT li.order_key)                AS orders,
    COUNT(DISTINCT li.product_key)              AS products,
    SUM(li.quantity_ordered)                    AS units,
    ROUND(SUM(li.net_amount), 2)                AS line_net_revenue
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d ON d.date_key = li.order_date_key
WHERE d.full_date >= DATE '2026-01-01';

-- B. Order-header totals for the same window (if Fivetran reports at order grain)
SELECT
    COUNT(*)                       AS orders,
    ROUND(SUM(total_amount), 2)    AS header_total_revenue,
    ROUND(SUM(net_amount), 2)      AS header_net_of_refunds
FROM SHOPIFY_DWH.fact_order
WHERE order_created_at >= DATE '2026-01-01';

-- C. Top 15 products by line net revenue (spot-check targets) -----------------
SELECT
    dp.product_id,
    dp.product_title,
    ROUND(SUM(li.net_amount), 2) AS revenue,
    SUM(li.quantity_ordered)     AS units
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d     ON d.date_key     = li.order_date_key
JOIN SHOPIFY_DWH.dim_product dp ON dp.product_key = li.product_key
WHERE d.full_date >= DATE '2026-01-01'
GROUP BY dp.product_id, dp.product_title
ORDER BY revenue DESC
LIMIT 15;

-- D. Same headline via the metric view (sanity: must match section A) ---------
SELECT
    COUNT(DISTINCT product_id)  AS products,
    ROUND(SUM(revenue), 2)      AS total_revenue,
    SUM(units)                  AS total_units
FROM SHOPIFY_DWH.v_revenue_by_product_by_day
WHERE order_date >= DATE '2026-01-01';
