-- =============================================================================
-- Gate B (existence) verification — all 18 SHOPIFY_STG tables exist and are empty.
-- Run after 01_stg_schema.sql on a fresh deploy:
--   python -m shopify_dwh.ddl_runner ddl/verify_stg.sql
-- Expect: 18 rows, every row_count = 0 (before any loader has run).
-- =============================================================================

SELECT 'stg_orders'                       AS table_name, COUNT(*) AS row_count FROM SHOPIFY_STG.stg_orders
UNION ALL SELECT 'stg_order_line_items',               COUNT(*) FROM SHOPIFY_STG.stg_order_line_items
UNION ALL SELECT 'stg_order_transactions',             COUNT(*) FROM SHOPIFY_STG.stg_order_transactions
UNION ALL SELECT 'stg_order_tax_lines',                COUNT(*) FROM SHOPIFY_STG.stg_order_tax_lines
UNION ALL SELECT 'stg_order_discount_applications',    COUNT(*) FROM SHOPIFY_STG.stg_order_discount_applications
UNION ALL SELECT 'stg_order_shipping_lines',           COUNT(*) FROM SHOPIFY_STG.stg_order_shipping_lines
UNION ALL SELECT 'stg_fulfillments',                   COUNT(*) FROM SHOPIFY_STG.stg_fulfillments
UNION ALL SELECT 'stg_fulfillment_line_items',         COUNT(*) FROM SHOPIFY_STG.stg_fulfillment_line_items
UNION ALL SELECT 'stg_refunds',                        COUNT(*) FROM SHOPIFY_STG.stg_refunds
UNION ALL SELECT 'stg_refund_line_items',              COUNT(*) FROM SHOPIFY_STG.stg_refund_line_items
UNION ALL SELECT 'stg_customers',                      COUNT(*) FROM SHOPIFY_STG.stg_customers
UNION ALL SELECT 'stg_products',                       COUNT(*) FROM SHOPIFY_STG.stg_products
UNION ALL SELECT 'stg_product_variants',               COUNT(*) FROM SHOPIFY_STG.stg_product_variants
UNION ALL SELECT 'stg_discount_codes',                 COUNT(*) FROM SHOPIFY_STG.stg_discount_codes
UNION ALL SELECT 'stg_locations',                      COUNT(*) FROM SHOPIFY_STG.stg_locations
UNION ALL SELECT 'stg_inventory_levels',               COUNT(*) FROM SHOPIFY_STG.stg_inventory_levels
UNION ALL SELECT 'stg_abandoned_checkouts',            COUNT(*) FROM SHOPIFY_STG.stg_abandoned_checkouts
UNION ALL SELECT 'stg_gift_cards',                     COUNT(*) FROM SHOPIFY_STG.stg_gift_cards
ORDER BY table_name;

-- Structural cross-check: how many tables + columns did SHOPIFY_STG actually get?
-- Expect table_count = 18. (Column total is a quick "did every column land" tripwire.)
SELECT COUNT(DISTINCT COLUMN_TABLE) AS table_count,
       COUNT(*)                     AS column_count
FROM SYS.EXA_ALL_COLUMNS
WHERE COLUMN_SCHEMA = 'SHOPIFY_STG';
