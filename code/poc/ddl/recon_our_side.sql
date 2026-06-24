-- =============================================================================
-- Lightweight reconciliation — OUR side (local Exasol POC).
-- Window pinned to explicit dates (order created date >= 2026-04-25, our 60-day
-- floor) so it stays comparable regardless of when the Fivetran query is run.
-- Dates are UTC (as extracted from Shopify).
-- =============================================================================

-- A. Headline totals, line-item grain (the metric definition: SUM net_amount)
SELECT
    COUNT(DISTINCT li.order_key)                AS orders,
    COUNT(DISTINCT li.product_key)              AS products,
    SUM(li.quantity_ordered)                    AS units,
    ROUND(SUM(li.net_amount), 2)                AS line_net_revenue
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d ON d.date_key = li.order_date_key
WHERE d.full_date >= DATE '2026-04-25';

-- B. Order-header total for the same window (in case Fivetran reports at order grain)
SELECT
    COUNT(*)                       AS orders,
    ROUND(SUM(total_amount), 2)    AS header_total_revenue,
    ROUND(SUM(net_amount), 2)      AS header_net_of_refunds
FROM SHOPIFY_DWH.fact_order
WHERE order_created_at >= DATE '2026-04-25';

-- C. Top 15 products by line net revenue (spot-check targets)
SELECT
    dp.product_id,
    dp.product_title,
    ROUND(SUM(li.net_amount), 2) AS revenue,
    SUM(li.quantity_ordered)     AS units
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d     ON d.date_key    = li.order_date_key
JOIN SHOPIFY_DWH.dim_product dp ON dp.product_key = li.product_key
WHERE d.full_date >= DATE '2026-04-25'
GROUP BY dp.product_id, dp.product_title
ORDER BY revenue DESC
LIMIT 15;
