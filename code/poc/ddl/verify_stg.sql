-- Gate 1->2 verification: all 4 POC STG tables exist and are empty (COUNT = 0).
SELECT 'stg_orders'            AS table_name, COUNT(*) AS row_count FROM SHOPIFY_STG.stg_orders
UNION ALL
SELECT 'stg_order_line_items'  AS table_name, COUNT(*) AS row_count FROM SHOPIFY_STG.stg_order_line_items
UNION ALL
SELECT 'stg_products'          AS table_name, COUNT(*) AS row_count FROM SHOPIFY_STG.stg_products
UNION ALL
SELECT 'stg_product_variants'  AS table_name, COUNT(*) AS row_count FROM SHOPIFY_STG.stg_product_variants
ORDER BY table_name;
