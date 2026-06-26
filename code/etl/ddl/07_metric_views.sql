-- =============================================================================
-- Phase D — metric view layer (SHOPIFY_DWH views)
-- Run AFTER 05_transforms.sql.  CREATE OR REPLACE VIEW throughout, so re-running
-- is idempotent and safe to redeploy on top of an existing set.
--
-- This is where the named business measures live. The facts deliberately store
-- only atomic components (gross/net/discount/tax/refund amounts, quantities); the
-- headline measures ("Revenue", "AOV", margin %, the rates) are defined here, in
-- the view layer — the revenue-definition decision on record (ACTIONS.md §D).
-- Reporting tools (Yellowfin) point at these views, not the raw facts.
--
-- Structure: the 57 metrics in metrics-lineage-reference.md share grains, so they
-- map onto a handful of reporting views rather than 57 single-number views. Each
-- view's header lists the metric numbers it serves.
--
-- 57-metric coverage map:
--   v_order_enriched .............. 3,5,7,16,17,30,31,33,53,54,55,56 (order slice base)
--   v_order_line_enriched ......... 1,2,6,20,21,22,23,24,50,51,52    (line slice base)
--   v_sales_daily ................. 1,2,3,4,5,6,20,31,53,55,56 + 8 (growth via window)
--   v_channel_performance ......... 7
--   v_customer_metrics ............ 9,10,11,12,13,18,19              (dim_customer passthrough)
--   v_customer_summary ............ 14*,15,16,17                     (*retention = repeat proxy)
--   v_product_performance ......... 20,21,22,23,24,50,51,52
--   v_discount_summary ............ 30,31,32
--   v_discount_code_performance ... 33,34,35
--   v_fulfillment_performance ..... 39,40,41,42,43,49
--   v_refund_analysis ............. 44,45,46,47,48
--   v_inventory_status / _summary . 25,26,27,57
--   v_abandoned_checkout_summary .. 38
--   v_revenue_by_product_by_day ... 21 (POC reconciliation anchor — ported verbatim)
--
-- Known gaps (need data not in the current model — documented, not silently dropped):
--   28 / 3.9 Product Return Rate  — fact_refund is refund-grain (no product_key);
--            needs a refund-line fact joining refund_line_items -> product. Backlog.
--   29 Sell-Through Rate          — needs a beginning-of-period inventory balance;
--            available once >1 daily snapshot has accumulated.
--   36/37 Revenue by Landing/Referring Site — landing_site/referring_site were removed
--            from the 2026-04 Order API (always NULL). Columns exposed, will populate
--            only if a future API/customerJourneySummary backfill lands.
-- =============================================================================


-- --- v_order_enriched  (order grain, sliceable) ------------------------------
-- Metrics 3,5,7,16,17,30,31,33,53,54,55,56. One row per order with friendly dim
-- attributes + atomic measures; aggregate in the BI tool to get totals/AOV/etc.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_order_enriched AS
SELECT
    fo.order_key,
    d.full_date              AS order_date,
    d.cal_year, d.cal_quarter, d.cal_month, d.month_name,
    d.day_name, d.is_weekend,
    t.hour_24                AS order_hour,
    t.day_part,
    fo.order_number,
    fo.order_created_at,
    fo.source_name           AS channel,
    fo.financial_status,
    fo.fulfillment_status,
    fo.is_paid, fo.is_cancelled, fo.is_first_order, fo.is_repeat_customer, fo.has_discount,
    fo.customer_key,
    fo.customer_name,
    fo.customer_email,
    fo.customer_segment,
    dc.membership_tier,
    dc.rfm_segment,
    fo.shipping_city, fo.shipping_province, fo.shipping_country, fo.shipping_country_code,
    fo.discount_1_code       AS discount_code,
    fo.subtotal_amount,
    fo.shipping_amount,
    fo.tax_amount,
    fo.discount_amount,
    fo.total_amount,
    fo.refund_amount,
    fo.net_amount,
    fo.line_item_count,
    fo.total_quantity,
    fo.unique_product_count,
    fo.currency_code,
    fo.landing_site, fo.referring_site
FROM SHOPIFY_DWH.fact_order fo
JOIN SHOPIFY_DWH.dim_date d ON d.date_key = fo.order_date_key
LEFT JOIN SHOPIFY_DWH.dim_time t ON t.time_key = fo.order_time_key
LEFT JOIN SHOPIFY_DWH.dim_customer dc ON dc.customer_key = fo.customer_key;


-- --- v_order_line_enriched  (line grain, sliceable) --------------------------
-- Metrics 1,2,6,20,21,22,23,24,50,51,52. One row per line item with product + date.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_order_line_enriched AS
SELECT
    li.line_item_key,
    li.order_key,
    d.full_date              AS order_date,
    d.cal_year, d.cal_quarter, d.cal_month, d.month_name,
    li.product_key,
    dp.product_id,
    li.sku,
    li.product_title,
    li.variant_title,
    li.product_type,
    li.vendor,
    li.quantity_ordered,
    li.quantity_refunded,
    li.unit_price,
    li.unit_cost,
    li.gross_amount,
    li.discount_amount,
    li.net_amount,
    li.quantity_ordered * li.unit_cost          AS line_cogs,
    li.gross_margin,
    li.gross_margin_percent,
    li.is_gift_card,
    li.order_financial_status,
    li.customer_email,
    li.shipping_country
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d ON d.date_key = li.order_date_key
LEFT JOIN SHOPIFY_DWH.dim_product dp ON dp.product_key = li.product_key;


-- --- v_sales_daily  (one row per day) ----------------------------------------
-- Metrics 1,2,3,4,5,6,20,31,53,55,56. Order-grain and line-grain aggregates are
-- computed separately then joined on the date to avoid line-item fan-out inflating
-- the order-level sums. Metric 8 (growth) = window/lag over this view.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_sales_daily AS
WITH ord AS (
    SELECT order_date_key,
           COUNT(*) AS order_count,
           SUM(total_amount) AS total_revenue,
           SUM(net_amount) AS net_revenue_after_refunds,
           SUM(tax_amount) AS tax_collected,
           SUM(shipping_amount) AS shipping_revenue,
           SUM(discount_amount) AS discount_amount,
           SUM(refund_amount) AS refund_amount
    FROM SHOPIFY_DWH.fact_order
    GROUP BY order_date_key
),
line AS (
    SELECT order_date_key,
           SUM(gross_amount) AS gross_revenue,
           SUM(net_amount) AS net_line_revenue,
           SUM(quantity_ordered) AS units_sold
    FROM SHOPIFY_DWH.fact_order_line_item
    GROUP BY order_date_key
)
SELECT
    d.full_date AS order_date,
    d.cal_year, d.cal_quarter, d.cal_month, d.month_name, d.day_name, d.is_weekend,
    COALESCE(ord.order_count, 0)                                   AS order_count,
    ord.total_revenue,
    ord.total_revenue / NULLIF(ord.order_count, 0)                AS average_order_value,
    line.gross_revenue,
    line.net_line_revenue,
    ord.net_revenue_after_refunds,
    line.units_sold,
    line.units_sold / NULLIF(ord.order_count, 0)                  AS units_per_transaction,
    ord.tax_collected,
    ord.shipping_revenue,
    ord.discount_amount,
    ord.refund_amount
FROM SHOPIFY_DWH.dim_date d
LEFT JOIN ord  ON ord.order_date_key  = d.date_key
LEFT JOIN line ON line.order_date_key = d.date_key
WHERE ord.order_date_key IS NOT NULL OR line.order_date_key IS NOT NULL;


-- --- v_channel_performance  (one row per sales channel) ----------------------
-- Metric 7 (Revenue by Channel).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_channel_performance AS
SELECT
    COALESCE(source_name, '(unknown)') AS channel,
    COUNT(*)                           AS order_count,
    SUM(total_amount)                  AS total_revenue,
    SUM(total_amount) / NULLIF(COUNT(*), 0) AS average_order_value,
    SUM(total_quantity)                AS units_sold
FROM SHOPIFY_DWH.fact_order
GROUP BY source_name;


-- --- v_customer_metrics  (customer grain — dim_customer passthrough) ---------
-- Metrics 9,10,11,12,13,18,19. Excludes the -1 Unknown member.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_customer_metrics AS
SELECT
    customer_key,
    customer_id,
    full_name,
    email,
    customer_segment,
    membership_tier,
    lifetime_revenue            AS customer_lifetime_value,
    lifetime_order_count,
    average_order_value,
    first_order_date,
    last_order_date,
    days_since_last_order,
    rfm_recency_score,
    rfm_frequency_score,
    rfm_monetary_score,
    rfm_combined_score,
    rfm_segment
FROM SHOPIFY_DWH.dim_customer
WHERE customer_key > 0;


-- --- v_customer_summary  (single row) ----------------------------------------
-- Metrics 15 (repeat purchase rate), 16/17 (new vs returning revenue),
-- 14 (retention — approximated by repeat-purchase rate; true cohort retention
-- needs a period definition, left to the BI layer).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_customer_summary AS
SELECT
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_customer WHERE customer_key > 0)                              AS total_customers,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_customer WHERE customer_key > 0 AND lifetime_order_count >= 2) AS repeat_customers,
    (SELECT COUNT(*) FROM SHOPIFY_DWH.dim_customer WHERE customer_key > 0 AND lifetime_order_count >= 2) * 100.0
        / NULLIF((SELECT COUNT(*) FROM SHOPIFY_DWH.dim_customer WHERE customer_key > 0), 0)            AS repeat_purchase_rate,
    (SELECT AVG(lifetime_revenue) FROM SHOPIFY_DWH.dim_customer WHERE customer_key > 0)                AS avg_lifetime_value,
    (SELECT SUM(total_amount) FROM SHOPIFY_DWH.fact_order WHERE is_first_order = TRUE)                 AS new_customer_revenue,
    (SELECT SUM(total_amount) FROM SHOPIFY_DWH.fact_order WHERE is_first_order = FALSE)                AS returning_customer_revenue;


-- --- v_product_performance  (one row per product) ----------------------------
-- Metrics 20,21,22,23,24,50,51,52. Excludes the -1 Unknown member.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_product_performance AS
SELECT
    dp.product_key,
    dp.product_id,
    dp.product_title,
    dp.product_type,
    dp.vendor,
    dp.sku,
    SUM(li.quantity_ordered)                                        AS units_sold,
    SUM(li.net_amount)                                              AS product_revenue,
    SUM(li.gross_amount)                                            AS gross_revenue,
    SUM(li.net_amount) / NULLIF(SUM(li.quantity_ordered), 0)        AS average_selling_price,
    SUM(li.quantity_ordered * li.unit_cost)                        AS cogs,
    SUM(li.gross_margin)                                           AS gross_margin,
    SUM(li.gross_margin) / NULLIF(SUM(li.net_amount), 0) * 100     AS gross_margin_percent
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_product dp ON dp.product_key = li.product_key
WHERE li.product_key > 0
GROUP BY dp.product_key, dp.product_id, dp.product_title, dp.product_type, dp.vendor, dp.sku;


-- --- v_discount_summary  (single row) ----------------------------------------
-- Metrics 30 (usage rate), 31 (total), 32 (avg per discounted order).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_discount_summary AS
SELECT
    COUNT(*)                                                        AS total_orders,
    SUM(CASE WHEN has_discount THEN 1 ELSE 0 END)                  AS discounted_orders,
    SUM(CASE WHEN has_discount THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS discount_usage_rate,
    SUM(discount_amount)                                           AS total_discount_amount,
    SUM(discount_amount) / NULLIF(SUM(CASE WHEN has_discount THEN 1 ELSE 0 END), 0) AS avg_discount_per_order
FROM SHOPIFY_DWH.fact_order;


-- --- v_discount_code_performance  (one row per code) -------------------------
-- Metrics 33 (code revenue), 34 (usage count), 35 (redemption rate).
-- dd columns are NULL until the deferred stg_discount_codes loader runs.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_discount_code_performance AS
SELECT
    fo.discount_1_code                          AS discount_code,
    COUNT(*)                                    AS orders_using_code,
    SUM(fo.total_amount)                        AS revenue_with_code,
    SUM(fo.discount_amount)                     AS discount_given,
    MAX(dd.current_usage_count)                 AS usage_count,
    MAX(dd.usage_limit)                         AS usage_limit,
    MAX(dd.current_usage_count) * 100.0 / NULLIF(MAX(dd.usage_limit), 0) AS redemption_rate
FROM SHOPIFY_DWH.fact_order fo
LEFT JOIN SHOPIFY_DWH.dim_discount dd ON dd.discount_code = fo.discount_1_code
WHERE fo.discount_1_code IS NOT NULL
GROUP BY fo.discount_1_code;


-- --- v_fulfillment_performance  (one row per location) -----------------------
-- Metrics 39,40,41,42,43 (timing rates) + 49 (fulfillments by location).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_fulfillment_performance AS
SELECT
    COALESCE(location_name, '(unknown)')        AS location_name,
    COUNT(*)                                    AS fulfillment_count,
    AVG(fulfillment_time_hours)                 AS avg_fulfillment_hours,
    AVG(fulfillment_time_days)                  AS avg_fulfillment_days,
    SUM(CASE WHEN is_same_day THEN 1 ELSE 0 END)  * 100.0 / NULLIF(COUNT(*), 0) AS same_day_rate,
    SUM(CASE WHEN is_within_48h THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS on_time_rate,
    SUM(CASE WHEN is_late THEN 1 ELSE 0 END)      * 100.0 / NULLIF(COUNT(*), 0) AS late_rate
FROM SHOPIFY_DWH.fact_fulfillment
GROUP BY location_name;


-- --- v_refund_analysis  (single row) -----------------------------------------
-- Metrics 44 (refund rate), 45 (amount), 46 (% of revenue), 47 (items), 48 (restock).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_refund_analysis AS
SELECT
    COUNT(*)                                    AS refund_count,
    SUM(refund_amount)                          AS total_refund_amount,
    SUM(total_items_refunded)                   AS items_refunded,
    SUM(items_restocked) * 100.0 / NULLIF(SUM(total_items_refunded), 0)        AS restock_rate,
    COUNT(DISTINCT order_key) * 100.0
        / NULLIF((SELECT COUNT(*) FROM SHOPIFY_DWH.fact_order), 0)             AS refund_rate_orders,
    SUM(refund_amount) * 100.0
        / NULLIF((SELECT SUM(total_amount) FROM SHOPIFY_DWH.fact_order), 0)    AS refund_percent_of_revenue
FROM SHOPIFY_DWH.fact_refund;


-- --- v_inventory_status  (latest snapshot, item x location) ------------------
-- Metrics 25 (available), 26 (cost value), 57 (retail value) at item grain.
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_inventory_status AS
SELECT
    fis.product_key,
    fis.sku,
    fis.product_title,
    fis.variant_title,
    fis.product_type,
    fis.vendor,
    fis.location_name,
    fis.snapshot_date,
    fis.available_quantity,
    fis.on_hand_quantity,
    fis.committed_quantity,
    fis.inventory_cost_value,
    fis.inventory_retail_value,
    fis.is_out_of_stock,
    fis.is_low_stock,
    fis.is_overstocked
FROM SHOPIFY_DWH.fact_inventory_snapshot fis
WHERE fis.snapshot_date = (SELECT MAX(snapshot_date) FROM SHOPIFY_DWH.fact_inventory_snapshot);


-- --- v_inventory_summary  (single row, latest snapshot) ----------------------
-- Metric 27 (stock-out rate) + total inventory valuation (26, 57 aggregated).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_inventory_summary AS
SELECT
    COUNT(*)                                                       AS sku_location_count,
    SUM(CASE WHEN is_out_of_stock THEN 1 ELSE 0 END)              AS out_of_stock_count,
    SUM(CASE WHEN is_out_of_stock THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS stock_out_rate,
    SUM(inventory_cost_value)                                     AS total_inventory_cost_value,
    SUM(inventory_retail_value)                                   AS total_inventory_retail_value
FROM SHOPIFY_DWH.fact_inventory_snapshot
WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM SHOPIFY_DWH.fact_inventory_snapshot);


-- --- v_abandoned_checkout_summary  (single row) ------------------------------
-- Metric 38 (cart abandonment rate). Sourced from STG (no DWH fact for checkouts).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_abandoned_checkout_summary AS
SELECT
    COUNT(CASE WHEN completed_at IS NULL THEN 1 END)              AS abandoned_count,
    COUNT(CASE WHEN completed_at IS NOT NULL THEN 1 END)          AS completed_count,
    COUNT(CASE WHEN completed_at IS NULL THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) AS abandonment_rate
FROM SHOPIFY_STG.stg_abandoned_checkouts;


-- --- v_revenue_by_product_by_day  (POC reconciliation anchor — ported) -------
-- Metric 21 at (date, product) grain. Kept identical to the POC's proven view so
-- the Fivetran reconciliation (08_reconcile.sql) compares like-for-like.
-- Revenue = SUM(line net_amount); refunds NOT netted (definitional, per the POC).
CREATE OR REPLACE VIEW SHOPIFY_DWH.v_revenue_by_product_by_day AS
SELECT
    d.full_date                              AS order_date,
    dp.product_id,
    dp.product_title,
    SUM(COALESCE(li.net_amount, 0))          AS revenue,
    SUM(COALESCE(li.quantity_ordered, 0))    AS units,
    COUNT(DISTINCT li.order_key)             AS orders
FROM SHOPIFY_DWH.fact_order_line_item li
JOIN SHOPIFY_DWH.dim_date d     ON d.date_key     = li.order_date_key
JOIN SHOPIFY_DWH.dim_product dp ON dp.product_key = li.product_key
GROUP BY d.full_date, dp.product_id, dp.product_title;
