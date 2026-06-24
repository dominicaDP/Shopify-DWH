-- =============================================================================
-- POC Phase 3.4-3.6 — STG -> DWH transforms (pure SQL, rebuildable)
-- Run AFTER 02_dwh_schema.sql and 03_dim_date.sql.
-- Each step TRUNCATEs then re-INSERTs, so the whole file is idempotent.
-- GIDs are reduced to their trailing numeric id with REGEXP_SUBSTR(x,'[0-9]+$')
-- so the natural keys join consistently across tables.
-- =============================================================================

-- --- 3.4  dim_product --------------------------------------------------------
TRUNCATE TABLE SHOPIFY_DWH.dim_product;

-- -1 sentinel for line items whose variant no longer exists (keeps FKs non-NULL)
INSERT INTO SHOPIFY_DWH.dim_product (product_key, product_id, variant_id, product_title, full_title, loaded_at)
VALUES (-1, NULL, NULL, 'Unknown Product', 'Unknown Product', CURRENT_TIMESTAMP);

INSERT INTO SHOPIFY_DWH.dim_product (
    product_key, product_id, variant_id, sku, barcode, product_title, variant_title,
    full_title, product_type, vendor, option_1_value, option_2_value, option_3_value,
    current_price, compare_at_price, unit_cost, is_on_sale, discount_percentage,
    is_taxable, requires_shipping, weight_grams, product_status, tags,
    product_created_date, loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY v.id) AS product_key,
    REGEXP_SUBSTR(p.id, '[0-9]+$') AS product_id,
    REGEXP_SUBSTR(v.id, '[0-9]+$') AS variant_id,
    v.sku,
    v.barcode,
    p.title AS product_title,
    v.title AS variant_title,
    p.title || CASE WHEN v.title IS NOT NULL AND v.title <> 'Default Title'
                    THEN ' - ' || v.title ELSE '' END AS full_title,
    p.product_type,
    p.vendor,
    v.option1,
    v.option2,
    v.option3,
    v.price AS current_price,
    v.compare_at_price,
    v.cost AS unit_cost,
    CASE WHEN v.compare_at_price > v.price THEN TRUE ELSE FALSE END AS is_on_sale,
    CASE WHEN v.compare_at_price > v.price AND v.compare_at_price > 0
         THEN (v.compare_at_price - v.price) / v.compare_at_price * 100 END AS discount_percentage,
    v.taxable AS is_taxable,
    v.requires_shipping,
    CASE UPPER(v.weight_unit)
        WHEN 'GRAMS'      THEN v.weight
        WHEN 'KILOGRAMS'  THEN v.weight * 1000
        WHEN 'POUNDS'     THEN v.weight * 453.592
        WHEN 'OUNCES'     THEN v.weight * 28.3495
        ELSE v.weight
    END AS weight_grams,
    p.status AS product_status,
    p.tags,
    CAST(p.created_at AS DATE) AS product_created_date,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_product_variants v
JOIN SHOPIFY_STG.stg_products p ON v.product_id = p.id;

-- --- 3.5  fact_order ---------------------------------------------------------
TRUNCATE TABLE SHOPIFY_DWH.fact_order;

INSERT INTO SHOPIFY_DWH.fact_order (
    order_key, order_date_key, order_id, order_number, order_email, source_name,
    order_created_at, order_processed_at, order_cancelled_at, order_closed_at,
    subtotal_amount, shipping_amount, tax_amount, discount_amount, total_amount,
    refund_amount, net_amount, currency_code, financial_status, fulfillment_status,
    cancel_reason, is_cancelled, is_paid, has_discount, line_item_count,
    total_quantity, tags, notes, loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY o.created_at, o.id) AS order_key,
    YEAR(o.created_at) * 10000 + MONTH(o.created_at) * 100 + DAY(o.created_at) AS order_date_key,
    REGEXP_SUBSTR(o.id, '[0-9]+$') AS order_id,
    o.name AS order_number,
    o.email AS order_email,
    o.source_name,
    o.created_at AS order_created_at,
    o.processed_at AS order_processed_at,
    o.cancelled_at AS order_cancelled_at,
    o.closed_at AS order_closed_at,
    o.subtotal_price AS subtotal_amount,
    o.total_shipping AS shipping_amount,
    o.total_tax AS tax_amount,
    o.total_discounts AS discount_amount,
    o.total_price AS total_amount,
    o.total_refunded AS refund_amount,
    o.total_price - COALESCE(o.total_refunded, 0) AS net_amount,
    o.currency_code,
    o.financial_status,
    o.fulfillment_status,
    o.cancel_reason,
    CASE WHEN o.cancelled_at IS NOT NULL THEN TRUE ELSE FALSE END AS is_cancelled,
    CASE WHEN o.financial_status IN ('PAID', 'PARTIALLY_REFUNDED') THEN TRUE ELSE FALSE END AS is_paid,
    CASE WHEN COALESCE(o.total_discounts, 0) > 0 THEN TRUE ELSE FALSE END AS has_discount,
    COALESCE(li.line_item_count, 0) AS line_item_count,
    COALESCE(li.total_quantity, 0) AS total_quantity,
    o.tags,
    o.note AS notes,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_orders o
LEFT JOIN (
    SELECT order_id, COUNT(*) AS line_item_count, SUM(quantity) AS total_quantity
    FROM SHOPIFY_STG.stg_order_line_items
    GROUP BY order_id
) li ON li.order_id = o.id;

-- --- 3.6  fact_order_line_item ----------------------------------------------
TRUNCATE TABLE SHOPIFY_DWH.fact_order_line_item;

INSERT INTO SHOPIFY_DWH.fact_order_line_item (
    line_item_key, order_key, order_date_key, product_key, line_item_id, order_id,
    order_number, sku, product_title, variant_title, product_type, vendor,
    quantity_ordered, quantity_current, quantity_refunded, unit_price, unit_cost,
    gross_amount, discount_amount, net_amount, is_gift_card, is_taxable,
    order_created_date, order_financial_status, loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY li.id) AS line_item_key,
    fo.order_key,
    fo.order_date_key,
    COALESCE(dp.product_key, -1) AS product_key,
    REGEXP_SUBSTR(li.id, '[0-9]+$') AS line_item_id,
    fo.order_id,
    fo.order_number,
    li.sku,
    li.title AS product_title,
    li.variant_title,
    dp.product_type,
    dp.vendor,
    li.quantity AS quantity_ordered,
    li.current_quantity AS quantity_current,
    COALESCE(li.quantity, 0) - COALESCE(li.current_quantity, li.quantity) AS quantity_refunded,
    li.unit_price,
    dp.unit_cost,
    li.total_price AS gross_amount,
    li.total_discount AS discount_amount,
    li.discounted_total AS net_amount,
    li.is_gift_card,
    li.taxable AS is_taxable,
    CAST(fo.order_created_at AS DATE) AS order_created_date,
    fo.financial_status AS order_financial_status,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_order_line_items li
JOIN SHOPIFY_DWH.fact_order fo
    ON fo.order_id = REGEXP_SUBSTR(li.order_id, '[0-9]+$')
LEFT JOIN SHOPIFY_DWH.dim_product dp
    ON dp.variant_id = REGEXP_SUBSTR(li.variant_id, '[0-9]+$');
