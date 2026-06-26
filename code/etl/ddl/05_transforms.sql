-- =============================================================================
-- Phase C — STG -> DWH transforms (pure SQL, rebuildable)
-- Run AFTER 02_dwh_schema.sql, 03_dim_date.sql, 04_dim_time.sql.
-- Each object TRUNCATEs then re-INSERTs, so the whole file is idempotent and the
-- run order matters: dimensions first (facts look them up), then facts.
--
-- Patterns carried from the POC (validated on Exasol 8):
--   - GIDs reduced to their trailing numeric id with REGEXP_SUBSTR(x,'[0-9]+$')
--     so natural keys join consistently across tables.
--   - Surrogate keys = ROW_NUMBER() (repeatable); sentinel members get fixed
--     keys (-1 Unknown, 0 No-Discount) that ROW_NUMBER (from 1) never hits.
--   - Unknown/sentinel members keep fact FKs non-NULL when a lookup misses.
--
-- Address parsing (dim_geography, dim_customer.default_*, fact_order geo):
--   stg_orders/stg_customers store the address as the JSON our loaders wrote with
--   json.dumps (keys: city, province, provinceCode, countryCodeV2, country, zip).
--   We pull a value with REGEXP_SUBSTR(json,'"key": "[^"]*') then strip the
--   '"key": "' prefix with REGEXP_REPLACE — no JSON functions, no lookbehind, so
--   it runs on any Exasol build. FIRST-RUN VERIFY: confirm the parsed city/country
--   are populated on a sample (the json.dumps ': ' spacing is what the pattern
--   assumes); an address value containing an escaped quote would truncate (rare).
-- =============================================================================


-- #############################################################################
-- DIMENSIONS
-- #############################################################################

-- --- dim_product  (variant grain — POC transform, unchanged) ------------------
TRUNCATE TABLE SHOPIFY_DWH.dim_product;

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


-- --- dim_customer  (stg_customers + order aggregations + RFM) -----------------
TRUNCATE TABLE SHOPIFY_DWH.dim_customer;

INSERT INTO SHOPIFY_DWH.dim_customer (customer_key, customer_id, full_name, loaded_at)
VALUES (-1, NULL, 'Unknown Customer', CURRENT_TIMESTAMP);

INSERT INTO SHOPIFY_DWH.dim_customer (
    customer_key, customer_id, email, first_name, last_name, full_name, phone,
    accepts_email_marketing, accepts_sms_marketing, customer_created_date,
    default_country, default_city, tags, membership_tier, is_tax_exempt,
    lifetime_order_count, lifetime_revenue, first_order_date, last_order_date,
    average_order_value, days_since_last_order, customer_segment,
    rfm_recency_score, rfm_frequency_score, rfm_monetary_score,
    rfm_combined_score, rfm_segment, loaded_at
)
WITH order_agg AS (
    SELECT
        REGEXP_SUBSTR(customer_id, '[0-9]+$') AS cust_num,
        COUNT(*) AS lifetime_order_count,
        SUM(total_price) AS lifetime_revenue,
        CAST(MIN(created_at) AS DATE) AS first_order_date,
        CAST(MAX(created_at) AS DATE) AS last_order_date
    FROM SHOPIFY_STG.stg_orders
    WHERE customer_id IS NOT NULL
    GROUP BY REGEXP_SUBSTR(customer_id, '[0-9]+$')
),
joined AS (
    SELECT
        c.id, c.email, c.first_name, c.last_name, c.phone,
        c.email_marketing_state, c.sms_marketing_state, c.created_at,
        c.default_address_json, c.tags, c.tax_exempt,
        REGEXP_SUBSTR(c.id, '[0-9]+$') AS cust_num,
        COALESCE(oa.lifetime_order_count, 0) AS lifetime_order_count,
        COALESCE(oa.lifetime_revenue, 0) AS lifetime_revenue,
        oa.first_order_date,
        oa.last_order_date
    FROM SHOPIFY_STG.stg_customers c
    LEFT JOIN order_agg oa ON oa.cust_num = REGEXP_SUBSTR(c.id, '[0-9]+$')
),
scored AS (
    SELECT
        joined.*,
        CASE WHEN lifetime_order_count > 0
             THEN lifetime_revenue / lifetime_order_count END AS average_order_value,
        CASE WHEN last_order_date IS NOT NULL
             THEN DAYS_BETWEEN(CURRENT_DATE, last_order_date) END AS days_since_last_order,
        CASE WHEN lifetime_order_count > 0
             THEN NTILE(5) OVER (ORDER BY last_order_date) END AS rfm_recency_score,
        CASE WHEN lifetime_order_count > 0
             THEN NTILE(5) OVER (ORDER BY lifetime_order_count) END AS rfm_frequency_score,
        CASE WHEN lifetime_order_count > 0
             THEN NTILE(5) OVER (ORDER BY lifetime_revenue) END AS rfm_monetary_score
    FROM joined
)
SELECT
    ROW_NUMBER() OVER (ORDER BY cust_num) AS customer_key,
    cust_num AS customer_id,
    email,
    first_name,
    last_name,
    NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '') AS full_name,
    phone,
    CASE WHEN email_marketing_state IN ('SUBSCRIBED', 'PENDING') THEN TRUE ELSE FALSE END AS accepts_email_marketing,
    CASE WHEN sms_marketing_state IN ('SUBSCRIBED', 'PENDING') THEN TRUE ELSE FALSE END AS accepts_sms_marketing,
    CAST(created_at AS DATE) AS customer_created_date,
    REGEXP_REPLACE(REGEXP_SUBSTR(default_address_json, '"country": "[^"]*'), '^"country": "', '') AS default_country,
    REGEXP_REPLACE(REGEXP_SUBSTR(default_address_json, '"city": "[^"]*'), '^"city": "', '') AS default_city,
    tags,
    CASE
        WHEN tags LIKE '%SB-Platinum%' THEN 'Standard Bank Platinum'
        WHEN tags LIKE '%SB-Gold%'     THEN 'Standard Bank Gold'
        WHEN tags LIKE '%SB-Silver%'   THEN 'Standard Bank Silver'
        ELSE NULL
    END AS membership_tier,
    tax_exempt AS is_tax_exempt,
    lifetime_order_count,
    lifetime_revenue,
    first_order_date,
    last_order_date,
    average_order_value,
    days_since_last_order,
    CASE
        WHEN lifetime_order_count = 0 THEN 'Prospect'
        WHEN days_since_last_order <= 90 AND lifetime_order_count = 1 THEN 'New'
        WHEN days_since_last_order <= 90 THEN 'Active'
        WHEN days_since_last_order <= 180 THEN 'At-Risk'
        ELSE 'Lapsed'
    END AS customer_segment,
    rfm_recency_score,
    rfm_frequency_score,
    rfm_monetary_score,
    COALESCE(rfm_recency_score, 0) + COALESCE(rfm_frequency_score, 0) + COALESCE(rfm_monetary_score, 0) AS rfm_combined_score,
    CASE
        WHEN rfm_recency_score IS NULL THEN NULL
        WHEN rfm_recency_score >= 4 AND rfm_frequency_score >= 4 AND rfm_monetary_score >= 4 THEN 'Champions'
        WHEN rfm_recency_score >= 3 AND rfm_frequency_score >= 4 THEN 'Loyal'
        WHEN rfm_recency_score >= 4 AND rfm_frequency_score >= 2 THEN 'Potential Loyalists'
        WHEN rfm_recency_score = 5 AND rfm_frequency_score = 1 THEN 'New Customers'
        WHEN rfm_recency_score >= 3 AND rfm_frequency_score <= 2 THEN 'Promising'
        WHEN rfm_recency_score = 3 AND rfm_frequency_score = 3 THEN 'Needs Attention'
        WHEN rfm_recency_score <= 2 AND rfm_frequency_score >= 4 AND rfm_monetary_score >= 4 THEN 'At Risk'
        WHEN rfm_recency_score <= 2 AND rfm_frequency_score >= 3 THEN 'About to Sleep'
        WHEN rfm_recency_score <= 2 AND rfm_frequency_score <= 2 THEN 'Hibernating'
        ELSE 'Others'
    END AS rfm_segment,
    CURRENT_TIMESTAMP AS loaded_at
FROM scored;


-- --- dim_geography  (distinct shipping + billing addresses from stg_orders) ---
TRUNCATE TABLE SHOPIFY_DWH.dim_geography;

INSERT INTO SHOPIFY_DWH.dim_geography (geography_key, address_hash, loaded_at)
VALUES (-1, '__unknown__', CURRENT_TIMESTAMP);

INSERT INTO SHOPIFY_DWH.dim_geography (
    geography_key, address_hash, city, province, province_code,
    country, country_code, postal_code, region, loaded_at
)
WITH addrs AS (
    SELECT
        REGEXP_REPLACE(REGEXP_SUBSTR(shipping_address_json, '"city": "[^"]*'), '^"city": "', '') AS city,
        REGEXP_REPLACE(REGEXP_SUBSTR(shipping_address_json, '"province": "[^"]*'), '^"province": "', '') AS province,
        REGEXP_REPLACE(REGEXP_SUBSTR(shipping_address_json, '"provinceCode": "[^"]*'), '^"provinceCode": "', '') AS province_code,
        REGEXP_REPLACE(REGEXP_SUBSTR(shipping_address_json, '"country": "[^"]*'), '^"country": "', '') AS country,
        REGEXP_REPLACE(REGEXP_SUBSTR(shipping_address_json, '"countryCodeV2": "[^"]*'), '^"countryCodeV2": "', '') AS country_code,
        REGEXP_REPLACE(REGEXP_SUBSTR(shipping_address_json, '"zip": "[^"]*'), '^"zip": "', '') AS postal_code
    FROM SHOPIFY_STG.stg_orders
    WHERE shipping_address_json IS NOT NULL
    UNION ALL
    SELECT
        REGEXP_REPLACE(REGEXP_SUBSTR(billing_address_json, '"city": "[^"]*'), '^"city": "', ''),
        REGEXP_REPLACE(REGEXP_SUBSTR(billing_address_json, '"province": "[^"]*'), '^"province": "', ''),
        REGEXP_REPLACE(REGEXP_SUBSTR(billing_address_json, '"provinceCode": "[^"]*'), '^"provinceCode": "', ''),
        REGEXP_REPLACE(REGEXP_SUBSTR(billing_address_json, '"country": "[^"]*'), '^"country": "', ''),
        REGEXP_REPLACE(REGEXP_SUBSTR(billing_address_json, '"countryCodeV2": "[^"]*'), '^"countryCodeV2": "', ''),
        REGEXP_REPLACE(REGEXP_SUBSTR(billing_address_json, '"zip": "[^"]*'), '^"zip": "', '')
    FROM SHOPIFY_STG.stg_orders
    WHERE billing_address_json IS NOT NULL
),
hashed AS (
    SELECT
        LOWER(COALESCE(city, '') || '|' || COALESCE(province, '') || '|'
              || COALESCE(country, '') || '|' || COALESCE(postal_code, '')) AS address_hash,
        city, province, province_code, country, country_code, postal_code
    FROM addrs
    WHERE city IS NOT NULL OR province IS NOT NULL OR country IS NOT NULL OR postal_code IS NOT NULL
),
deduped AS (
    SELECT
        address_hash,
        MAX(city) AS city,
        MAX(province) AS province,
        MAX(province_code) AS province_code,
        MAX(country) AS country,
        MAX(country_code) AS country_code,
        MAX(postal_code) AS postal_code
    FROM hashed
    GROUP BY address_hash
)
SELECT
    ROW_NUMBER() OVER (ORDER BY address_hash) AS geography_key,
    address_hash, city, province, province_code, country, country_code, postal_code,
    CASE country_code WHEN 'ZA' THEN 'Southern Africa' ELSE NULL END AS region,
    CURRENT_TIMESTAMP AS loaded_at
FROM deduped;


-- --- dim_discount  (stg_discount_codes — empty until read_discounts granted) --
TRUNCATE TABLE SHOPIFY_DWH.dim_discount;

INSERT INTO SHOPIFY_DWH.dim_discount (discount_key, discount_title, loaded_at)
VALUES (0, 'No Discount', CURRENT_TIMESTAMP);

INSERT INTO SHOPIFY_DWH.dim_discount (
    discount_key, discount_id, discount_code, discount_title, discount_type,
    value_type, discount_value, discount_status, starts_at, ends_at,
    usage_limit, current_usage_count, is_one_per_customer, loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY id) AS discount_key,
    REGEXP_SUBSTR(id, '[0-9]+$') AS discount_id,
    code AS discount_code,
    title AS discount_title,
    discount_type,
    CASE WHEN value_type LIKE '%Percentage%' THEN 'percentage'
         WHEN value_type LIKE '%Money%' THEN 'fixed_amount'
         ELSE value_type END AS value_type,
    COALESCE(value_amount, value_percentage) AS discount_value,
    status AS discount_status,
    CAST(starts_at AS DATE) AS starts_at,
    CAST(ends_at AS DATE) AS ends_at,
    usage_limit,
    usage_count AS current_usage_count,
    applies_once_per_customer AS is_one_per_customer,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_discount_codes;


-- --- dim_location  (stg_locations) -------------------------------------------
TRUNCATE TABLE SHOPIFY_DWH.dim_location;

INSERT INTO SHOPIFY_DWH.dim_location (location_key, location_name, loaded_at)
VALUES (-1, 'Unknown Location', CURRENT_TIMESTAMP);

INSERT INTO SHOPIFY_DWH.dim_location (
    location_key, location_id, location_name, address, city, province,
    country, country_code, is_active, fulfills_online, loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY id) AS location_key,
    REGEXP_SUBSTR(id, '[0-9]+$') AS location_id,
    name AS location_name,
    NULLIF(TRIM(COALESCE(address1, '')
        || CASE WHEN address2 IS NOT NULL THEN ', ' || address2 ELSE '' END), '') AS address,
    city,
    province,
    country,
    country_code,
    is_active,
    fulfills_online_orders AS fulfills_online,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_locations;


-- #############################################################################
-- FACTS
-- #############################################################################

-- --- fact_order  (header grain — pivots + denormalized customer/geography) ----
TRUNCATE TABLE SHOPIFY_DWH.fact_order;

INSERT INTO SHOPIFY_DWH.fact_order (
    order_key, order_date_key, order_time_key, customer_key, shipping_geography_key,
    billing_geography_key, order_id, order_number, order_email, checkout_id,
    source_name, landing_site, referring_site, order_created_at, order_processed_at,
    order_cancelled_at, order_closed_at, subtotal_amount, shipping_amount, tax_amount,
    discount_amount, total_amount, refund_amount, net_amount, currency_code,
    payment_1_gateway, payment_1_amount, payment_2_gateway, payment_2_amount,
    payment_3_gateway, payment_3_amount, total_payment_count,
    tax_1_name, tax_1_rate, tax_1_amount, tax_2_name, tax_2_rate, tax_2_amount,
    discount_1_code, discount_1_type, discount_1_amount,
    discount_2_code, discount_2_type, discount_2_amount, primary_discount_key,
    shipping_method, shipping_carrier, financial_status, fulfillment_status,
    cancel_reason, is_paid, is_fully_refunded, is_cancelled, is_fulfilled,
    has_discount, has_multiple_payments, line_item_count, total_quantity,
    unique_product_count, customer_email, customer_name, customer_segment,
    is_first_order, is_repeat_customer, shipping_city, shipping_province,
    shipping_country, shipping_country_code, tags, notes, loaded_at
)
WITH ords AS (
    SELECT
        o.*,
        REGEXP_SUBSTR(o.id, '[0-9]+$') AS o_num,
        REGEXP_SUBSTR(o.customer_id, '[0-9]+$') AS cust_num,
        LOWER(
            COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.shipping_address_json, '"city": "[^"]*'), '^"city": "', ''), '') || '|'
         || COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.shipping_address_json, '"province": "[^"]*'), '^"province": "', ''), '') || '|'
         || COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.shipping_address_json, '"country": "[^"]*'), '^"country": "', ''), '') || '|'
         || COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.shipping_address_json, '"zip": "[^"]*'), '^"zip": "', ''), '')
        ) AS ship_hash,
        LOWER(
            COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.billing_address_json, '"city": "[^"]*'), '^"city": "', ''), '') || '|'
         || COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.billing_address_json, '"province": "[^"]*'), '^"province": "', ''), '') || '|'
         || COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.billing_address_json, '"country": "[^"]*'), '^"country": "', ''), '') || '|'
         || COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(o.billing_address_json, '"zip": "[^"]*'), '^"zip": "', ''), '')
        ) AS bill_hash
    FROM SHOPIFY_STG.stg_orders o
),
pay AS (
    SELECT
        REGEXP_SUBSTR(order_id, '[0-9]+$') AS oid,
        MAX(CASE WHEN rn = 1 THEN gateway END) AS payment_1_gateway,
        MAX(CASE WHEN rn = 1 THEN amount END) AS payment_1_amount,
        MAX(CASE WHEN rn = 2 THEN gateway END) AS payment_2_gateway,
        MAX(CASE WHEN rn = 2 THEN amount END) AS payment_2_amount,
        MAX(CASE WHEN rn = 3 THEN gateway END) AS payment_3_gateway,
        MAX(CASE WHEN rn = 3 THEN amount END) AS payment_3_amount,
        COUNT(*) AS total_payment_count
    FROM (
        SELECT order_id, gateway, amount,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY created_at) AS rn
        FROM SHOPIFY_STG.stg_order_transactions
        WHERE kind = 'SALE' AND status = 'SUCCESS'
    ) t
    GROUP BY REGEXP_SUBSTR(order_id, '[0-9]+$')
),
tax AS (
    SELECT
        REGEXP_SUBSTR(order_id, '[0-9]+$') AS oid,
        MAX(CASE WHEN rn = 1 THEN title END) AS tax_1_name,
        MAX(CASE WHEN rn = 1 THEN rate END)  AS tax_1_rate,
        MAX(CASE WHEN rn = 1 THEN price END) AS tax_1_amount,
        MAX(CASE WHEN rn = 2 THEN title END) AS tax_2_name,
        MAX(CASE WHEN rn = 2 THEN rate END)  AS tax_2_rate,
        MAX(CASE WHEN rn = 2 THEN price END) AS tax_2_amount
    FROM (
        SELECT order_id, title, rate, price,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY line_number) AS rn
        FROM SHOPIFY_STG.stg_order_tax_lines
    ) t
    GROUP BY REGEXP_SUBSTR(order_id, '[0-9]+$')
),
disc AS (
    SELECT
        REGEXP_SUBSTR(order_id, '[0-9]+$') AS oid,
        MAX(CASE WHEN rn = 1 THEN code END)  AS discount_1_code,
        MAX(CASE WHEN rn = 1 THEN dtype END) AS discount_1_type,
        MAX(CASE WHEN rn = 1 THEN dval END)  AS discount_1_amount,
        MAX(CASE WHEN rn = 2 THEN code END)  AS discount_2_code,
        MAX(CASE WHEN rn = 2 THEN dtype END) AS discount_2_type,
        MAX(CASE WHEN rn = 2 THEN dval END)  AS discount_2_amount
    FROM (
        SELECT order_id, code,
               CASE WHEN value_type LIKE '%Percentage%' THEN 'percentage'
                    WHEN value_type LIKE '%Money%' THEN 'fixed' ELSE value_type END AS dtype,
               COALESCE(value_amount, value_percentage) AS dval,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY line_number) AS rn
        FROM SHOPIFY_STG.stg_order_discount_applications
    ) t
    GROUP BY REGEXP_SUBSTR(order_id, '[0-9]+$')
),
ship AS (
    SELECT oid, shipping_method, shipping_carrier FROM (
        SELECT REGEXP_SUBSTR(order_id, '[0-9]+$') AS oid,
               title AS shipping_method,
               carrier_identifier AS shipping_carrier,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY id) AS rn
        FROM SHOPIFY_STG.stg_order_shipping_lines
    ) s WHERE rn = 1
),
li AS (
    SELECT REGEXP_SUBSTR(order_id, '[0-9]+$') AS oid,
           COUNT(*) AS line_item_count,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT product_id) AS unique_product_count
    FROM SHOPIFY_STG.stg_order_line_items
    GROUP BY REGEXP_SUBSTR(order_id, '[0-9]+$')
),
cust_first AS (
    SELECT REGEXP_SUBSTR(customer_id, '[0-9]+$') AS cust_num,
           MIN(created_at) AS first_created
    FROM SHOPIFY_STG.stg_orders
    WHERE customer_id IS NOT NULL
    GROUP BY REGEXP_SUBSTR(customer_id, '[0-9]+$')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY ords.created_at, ords.id) AS order_key,
    YEAR(ords.created_at) * 10000 + MONTH(ords.created_at) * 100 + DAY(ords.created_at) AS order_date_key,
    HOUR(ords.created_at) AS order_time_key,
    COALESCE(dc.customer_key, -1) AS customer_key,
    COALESCE(sg.geography_key, -1) AS shipping_geography_key,
    COALESCE(bg.geography_key, -1) AS billing_geography_key,
    ords.o_num AS order_id,
    ords.name AS order_number,
    ords.email AS order_email,
    ords.checkout_id,
    ords.source_name,
    ords.landing_site,
    ords.referring_site,
    ords.created_at AS order_created_at,
    ords.processed_at AS order_processed_at,
    ords.cancelled_at AS order_cancelled_at,
    ords.closed_at AS order_closed_at,
    ords.subtotal_price AS subtotal_amount,
    ords.total_shipping AS shipping_amount,
    ords.total_tax AS tax_amount,
    ords.total_discounts AS discount_amount,
    ords.total_price AS total_amount,
    ords.total_refunded AS refund_amount,
    ords.total_price - COALESCE(ords.total_refunded, 0) AS net_amount,
    ords.currency_code,
    pay.payment_1_gateway, pay.payment_1_amount,
    pay.payment_2_gateway, pay.payment_2_amount,
    pay.payment_3_gateway, pay.payment_3_amount,
    COALESCE(pay.total_payment_count, 0) AS total_payment_count,
    tax.tax_1_name, tax.tax_1_rate, tax.tax_1_amount,
    tax.tax_2_name, tax.tax_2_rate, tax.tax_2_amount,
    disc.discount_1_code, disc.discount_1_type, disc.discount_1_amount,
    disc.discount_2_code, disc.discount_2_type, disc.discount_2_amount,
    COALESCE(dd.discount_key, 0) AS primary_discount_key,
    ship.shipping_method, ship.shipping_carrier,
    ords.financial_status,
    ords.fulfillment_status,
    ords.cancel_reason,
    CASE WHEN ords.financial_status IN ('PAID', 'PARTIALLY_REFUNDED') THEN TRUE ELSE FALSE END AS is_paid,
    CASE WHEN ords.financial_status = 'REFUNDED' THEN TRUE ELSE FALSE END AS is_fully_refunded,
    CASE WHEN ords.cancelled_at IS NOT NULL THEN TRUE ELSE FALSE END AS is_cancelled,
    CASE WHEN ords.fulfillment_status = 'FULFILLED' THEN TRUE ELSE FALSE END AS is_fulfilled,
    CASE WHEN COALESCE(ords.total_discounts, 0) > 0 THEN TRUE ELSE FALSE END AS has_discount,
    CASE WHEN COALESCE(pay.total_payment_count, 0) > 1 THEN TRUE ELSE FALSE END AS has_multiple_payments,
    COALESCE(li.line_item_count, 0) AS line_item_count,
    COALESCE(li.total_quantity, 0) AS total_quantity,
    COALESCE(li.unique_product_count, 0) AS unique_product_count,
    COALESCE(dc.email, ords.email) AS customer_email,
    dc.full_name AS customer_name,
    dc.customer_segment,
    CASE WHEN ords.customer_id IS NOT NULL AND ords.created_at = cf.first_created THEN TRUE ELSE FALSE END AS is_first_order,
    CASE WHEN COALESCE(dc.lifetime_order_count, 0) > 1 THEN TRUE ELSE FALSE END AS is_repeat_customer,
    sg.city AS shipping_city,
    sg.province AS shipping_province,
    sg.country AS shipping_country,
    sg.country_code AS shipping_country_code,
    ords.tags,
    ords.note AS notes,
    CURRENT_TIMESTAMP AS loaded_at
FROM ords
LEFT JOIN SHOPIFY_DWH.dim_customer dc ON dc.customer_id = ords.cust_num
LEFT JOIN pay  ON pay.oid  = ords.o_num
LEFT JOIN tax  ON tax.oid  = ords.o_num
LEFT JOIN disc ON disc.oid = ords.o_num
LEFT JOIN ship ON ship.oid = ords.o_num
LEFT JOIN li   ON li.oid   = ords.o_num
LEFT JOIN cust_first cf ON cf.cust_num = ords.cust_num
LEFT JOIN SHOPIFY_DWH.dim_geography sg ON sg.address_hash = ords.ship_hash
LEFT JOIN SHOPIFY_DWH.dim_geography bg ON bg.address_hash = ords.bill_hash
LEFT JOIN SHOPIFY_DWH.dim_discount dd ON dd.discount_code = disc.discount_1_code;


-- --- fact_order_line_item  (line grain — POC transform widened to design) -----
TRUNCATE TABLE SHOPIFY_DWH.fact_order_line_item;

INSERT INTO SHOPIFY_DWH.fact_order_line_item (
    line_item_key, order_key, order_date_key, order_time_key, product_key, customer_key,
    line_item_id, order_id, order_number, sku, product_title, variant_title,
    product_type, vendor, quantity_ordered, quantity_fulfilled, quantity_refunded,
    quantity_current, unit_price, unit_cost, gross_amount, discount_amount, net_amount,
    gross_margin, gross_margin_percent, is_gift_card, is_taxable, is_fulfilled,
    is_partially_fulfilled, is_refunded, is_fully_refunded, order_created_date,
    order_financial_status, order_fulfillment_status, customer_email, customer_name,
    shipping_country, shipping_country_code, loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY li.id) AS line_item_key,
    fo.order_key,
    fo.order_date_key,
    fo.order_time_key,
    COALESCE(dp.product_key, -1) AS product_key,
    fo.customer_key,
    REGEXP_SUBSTR(li.id, '[0-9]+$') AS line_item_id,
    fo.order_id,
    fo.order_number,
    li.sku,
    li.title AS product_title,
    li.variant_title,
    dp.product_type,
    dp.vendor,
    li.quantity AS quantity_ordered,
    COALESCE(li.quantity, 0) - COALESCE(li.unfulfilled_quantity, 0) AS quantity_fulfilled,
    COALESCE(li.quantity, 0) - COALESCE(li.current_quantity, li.quantity) AS quantity_refunded,
    li.current_quantity AS quantity_current,
    li.unit_price,
    dp.unit_cost,
    li.total_price AS gross_amount,
    li.total_discount AS discount_amount,
    li.discounted_total AS net_amount,
    li.discounted_total - COALESCE(dp.unit_cost, 0) * COALESCE(li.quantity, 0) AS gross_margin,
    CASE WHEN li.discounted_total > 0
         THEN (li.discounted_total - COALESCE(dp.unit_cost, 0) * COALESCE(li.quantity, 0)) / li.discounted_total * 100
    END AS gross_margin_percent,
    li.is_gift_card,
    li.taxable AS is_taxable,
    CASE WHEN COALESCE(li.unfulfilled_quantity, 0) = 0 THEN TRUE ELSE FALSE END AS is_fulfilled,
    CASE WHEN COALESCE(li.unfulfilled_quantity, 0) > 0 AND COALESCE(li.unfulfilled_quantity, 0) < li.quantity
         THEN TRUE ELSE FALSE END AS is_partially_fulfilled,
    CASE WHEN COALESCE(li.quantity, 0) - COALESCE(li.current_quantity, li.quantity) > 0
         THEN TRUE ELSE FALSE END AS is_refunded,
    CASE WHEN li.current_quantity = 0 THEN TRUE ELSE FALSE END AS is_fully_refunded,
    CAST(fo.order_created_at AS DATE) AS order_created_date,
    fo.financial_status AS order_financial_status,
    fo.fulfillment_status AS order_fulfillment_status,
    fo.customer_email,
    fo.customer_name,
    fo.shipping_country,
    fo.shipping_country_code,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_order_line_items li
JOIN SHOPIFY_DWH.fact_order fo ON fo.order_id = REGEXP_SUBSTR(li.order_id, '[0-9]+$')
LEFT JOIN SHOPIFY_DWH.dim_product dp ON dp.variant_id = REGEXP_SUBSTR(li.variant_id, '[0-9]+$');


-- --- fact_fulfillment  (shipment grain — timing metrics) ----------------------
TRUNCATE TABLE SHOPIFY_DWH.fact_fulfillment;

INSERT INTO SHOPIFY_DWH.fact_fulfillment (
    fulfillment_key, order_key, order_date_key, fulfillment_date_key, fulfillment_time_key,
    location_key, customer_key, fulfillment_id, order_id, order_number, order_created_at,
    fulfillment_created_at, fulfillment_updated_at, fulfillment_time_hours,
    fulfillment_time_days, tracking_number, tracking_company, tracking_url,
    shipping_service, fulfillment_status, shipment_status, is_successful, is_pending,
    total_quantity, line_item_count, location_name, customer_email, customer_name,
    shipping_country, is_same_day, is_within_48h, is_late, loaded_at
)
WITH fli AS (
    SELECT REGEXP_SUBSTR(fulfillment_id, '[0-9]+$') AS fid,
           COUNT(*) AS line_item_count
    FROM SHOPIFY_STG.stg_fulfillment_line_items
    GROUP BY REGEXP_SUBSTR(fulfillment_id, '[0-9]+$')
),
ff AS (
    SELECT
        f.id, f.order_id, f.status, f.created_at, f.updated_at,
        f.tracking_number, f.tracking_company, f.tracking_url, f.location_id,
        f.service, f.shipment_status, f.total_quantity,
        fo.order_key, fo.order_date_key, fo.customer_key, fo.order_number,
        fo.order_created_at, fo.shipping_country, fo.customer_email, fo.customer_name,
        HOURS_BETWEEN(f.created_at, fo.order_created_at) AS ftime_hours
    FROM SHOPIFY_STG.stg_fulfillments f
    JOIN SHOPIFY_DWH.fact_order fo ON fo.order_id = REGEXP_SUBSTR(f.order_id, '[0-9]+$')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY ff.created_at, ff.id) AS fulfillment_key,
    ff.order_key,
    ff.order_date_key,
    YEAR(ff.created_at) * 10000 + MONTH(ff.created_at) * 100 + DAY(ff.created_at) AS fulfillment_date_key,
    HOUR(ff.created_at) AS fulfillment_time_key,
    COALESCE(dl.location_key, -1) AS location_key,
    ff.customer_key,
    REGEXP_SUBSTR(ff.id, '[0-9]+$') AS fulfillment_id,
    REGEXP_SUBSTR(ff.order_id, '[0-9]+$') AS order_id,
    ff.order_number,
    ff.order_created_at,
    ff.created_at AS fulfillment_created_at,
    ff.updated_at AS fulfillment_updated_at,
    ff.ftime_hours AS fulfillment_time_hours,
    ff.ftime_hours / 24 AS fulfillment_time_days,
    ff.tracking_number,
    ff.tracking_company,
    ff.tracking_url,
    ff.service AS shipping_service,
    ff.status AS fulfillment_status,
    ff.shipment_status,
    CASE WHEN ff.status = 'SUCCESS' THEN TRUE ELSE FALSE END AS is_successful,
    CASE WHEN ff.status = 'PENDING' THEN TRUE ELSE FALSE END AS is_pending,
    ff.total_quantity,
    COALESCE(fli.line_item_count, 0) AS line_item_count,
    dl.location_name,
    ff.customer_email,
    ff.customer_name,
    ff.shipping_country,
    CASE WHEN ff.ftime_hours < 24 THEN TRUE ELSE FALSE END AS is_same_day,
    CASE WHEN ff.ftime_hours <= 48 THEN TRUE ELSE FALSE END AS is_within_48h,
    CASE WHEN ff.ftime_hours > 72 THEN TRUE ELSE FALSE END AS is_late,
    CURRENT_TIMESTAMP AS loaded_at
FROM ff
LEFT JOIN fli ON fli.fid = REGEXP_SUBSTR(ff.id, '[0-9]+$')
LEFT JOIN SHOPIFY_DWH.dim_location dl ON dl.location_id = REGEXP_SUBSTR(ff.location_id, '[0-9]+$');


-- --- fact_refund  (refund grain — line-item aggregates + restock analysis) ----
TRUNCATE TABLE SHOPIFY_DWH.fact_refund;

INSERT INTO SHOPIFY_DWH.fact_refund (
    refund_key, order_key, order_date_key, refund_date_key, customer_key, refund_id,
    order_id, order_number, order_created_at, refund_created_at, days_to_refund,
    refund_amount, refund_subtotal, refund_tax, original_order_total, refund_percentage,
    total_items_refunded, line_item_count, items_restocked, items_not_restocked,
    refund_note, is_full_refund, is_partial_refund, has_restock, customer_email,
    customer_name, loaded_at
)
WITH rli AS (
    SELECT REGEXP_SUBSTR(refund_id, '[0-9]+$') AS rid,
           SUM(quantity) AS total_items_refunded,
           SUM(subtotal_amount) AS refund_subtotal,
           SUM(total_tax_amount) AS refund_tax,
           COUNT(DISTINCT line_item_id) AS line_item_count,
           SUM(CASE WHEN restock_type IN ('RETURN', 'CANCEL') THEN quantity ELSE 0 END) AS items_restocked,
           SUM(CASE WHEN restock_type = 'NO_RESTOCK' THEN quantity ELSE 0 END) AS items_not_restocked
    FROM SHOPIFY_STG.stg_refund_line_items
    GROUP BY REGEXP_SUBSTR(refund_id, '[0-9]+$')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY r.created_at, r.id) AS refund_key,
    fo.order_key,
    fo.order_date_key,
    YEAR(r.created_at) * 10000 + MONTH(r.created_at) * 100 + DAY(r.created_at) AS refund_date_key,
    fo.customer_key,
    REGEXP_SUBSTR(r.id, '[0-9]+$') AS refund_id,
    fo.order_id,
    fo.order_number,
    fo.order_created_at,
    r.created_at AS refund_created_at,
    DAYS_BETWEEN(CAST(r.created_at AS DATE), CAST(fo.order_created_at AS DATE)) AS days_to_refund,
    r.total_refunded AS refund_amount,
    COALESCE(rli.refund_subtotal, 0) AS refund_subtotal,
    COALESCE(rli.refund_tax, 0) AS refund_tax,
    fo.total_amount AS original_order_total,
    CASE WHEN fo.total_amount > 0 THEN r.total_refunded / fo.total_amount * 100 END AS refund_percentage,
    COALESCE(rli.total_items_refunded, 0) AS total_items_refunded,
    COALESCE(rli.line_item_count, 0) AS line_item_count,
    COALESCE(rli.items_restocked, 0) AS items_restocked,
    COALESCE(rli.items_not_restocked, 0) AS items_not_restocked,
    r.note AS refund_note,
    CASE WHEN fo.total_amount > 0 AND r.total_refunded / fo.total_amount * 100 >= 99 THEN TRUE ELSE FALSE END AS is_full_refund,
    CASE WHEN fo.total_amount > 0 AND r.total_refunded / fo.total_amount * 100 > 0
              AND r.total_refunded / fo.total_amount * 100 < 99 THEN TRUE ELSE FALSE END AS is_partial_refund,
    CASE WHEN COALESCE(rli.items_restocked, 0) > 0 THEN TRUE ELSE FALSE END AS has_restock,
    fo.customer_email,
    fo.customer_name,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_refunds r
JOIN SHOPIFY_DWH.fact_order fo ON fo.order_id = REGEXP_SUBSTR(r.order_id, '[0-9]+$')
LEFT JOIN rli ON rli.rid = REGEXP_SUBSTR(r.id, '[0-9]+$');


-- --- fact_inventory_snapshot  (item x location x snapshot_date grain) ----------
-- product_key maps via stg_product_variants: inventory_item_id -> variant -> dim_product.
TRUNCATE TABLE SHOPIFY_DWH.fact_inventory_snapshot;

INSERT INTO SHOPIFY_DWH.fact_inventory_snapshot (
    inventory_snapshot_key, snapshot_date_key, product_key, location_key,
    inventory_item_id, location_id, snapshot_date, available_quantity, on_hand_quantity,
    committed_quantity, incoming_quantity, reserved_quantity, total_inventory,
    sellable_inventory, unit_cost, inventory_cost_value, unit_price,
    inventory_retail_value, sku, product_title, variant_title, product_type, vendor,
    location_name, location_country, is_out_of_stock, is_low_stock, is_overstocked,
    loaded_at
)
SELECT
    ROW_NUMBER() OVER (ORDER BY il.snapshot_date, il.inventory_item_id, il.location_id) AS inventory_snapshot_key,
    YEAR(il.snapshot_date) * 10000 + MONTH(il.snapshot_date) * 100 + DAY(il.snapshot_date) AS snapshot_date_key,
    COALESCE(dp.product_key, -1) AS product_key,
    COALESCE(dl.location_key, -1) AS location_key,
    REGEXP_SUBSTR(il.inventory_item_id, '[0-9]+$') AS inventory_item_id,
    REGEXP_SUBSTR(il.location_id, '[0-9]+$') AS location_id,
    il.snapshot_date,
    il.available AS available_quantity,
    il.on_hand AS on_hand_quantity,
    il.committed AS committed_quantity,
    il.incoming AS incoming_quantity,
    il.reserved AS reserved_quantity,
    COALESCE(il.on_hand, 0) + COALESCE(il.incoming, 0) AS total_inventory,
    il.available AS sellable_inventory,
    dp.unit_cost,
    COALESCE(il.on_hand, 0) * COALESCE(dp.unit_cost, 0) AS inventory_cost_value,
    dp.current_price AS unit_price,
    COALESCE(il.on_hand, 0) * COALESCE(dp.current_price, 0) AS inventory_retail_value,
    dp.sku, dp.product_title, dp.variant_title, dp.product_type, dp.vendor,
    dl.location_name,
    dl.country AS location_country,
    CASE WHEN COALESCE(il.available, 0) = 0 THEN TRUE ELSE FALSE END AS is_out_of_stock,
    CASE WHEN il.available > 0 AND il.available < 10 THEN TRUE ELSE FALSE END AS is_low_stock,
    CASE WHEN il.available > 500 THEN TRUE ELSE FALSE END AS is_overstocked,
    CURRENT_TIMESTAMP AS loaded_at
FROM SHOPIFY_STG.stg_inventory_levels il
LEFT JOIN SHOPIFY_STG.stg_product_variants pv
    ON REGEXP_SUBSTR(pv.inventory_item_id, '[0-9]+$') = REGEXP_SUBSTR(il.inventory_item_id, '[0-9]+$')
LEFT JOIN SHOPIFY_DWH.dim_product dp ON dp.variant_id = REGEXP_SUBSTR(pv.id, '[0-9]+$')
LEFT JOIN SHOPIFY_DWH.dim_location dl ON dl.location_id = REGEXP_SUBSTR(il.location_id, '[0-9]+$');
