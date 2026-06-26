-- =============================================================================
-- Layer 1 production — SHOPIFY_DWH schema + all 12 reporting objects (Phase C)
-- Source of truth: projects/research-notes/schema-layered.md (v1.1, Exasol-safe)
-- Deploy:  python -m shopify_dwh.ddl_runner ddl/02_dwh_schema.sql
-- Then:    03_dim_date.sql, 04_dim_time.sql, 05_transforms.sql, 06_verify_dwh.sql
--
-- This is the full DWH the POC proved in miniature (4 of these 12 objects deployed
-- and reconciled on Exasol 8 / v2025.2.1). It widens the POC's dim_product /
-- fact_order / fact_order_line_item to their design width and adds the remaining
-- 9 objects: 5 more dims (date, time, customer, geography, discount, location) and
-- 3 more facts (fulfillment, refund, inventory_snapshot).
--
-- Conventions (carried from the POC + the STG layer, see ddl/README.md):
--   - Surrogate keys are deterministic ROW_NUMBER() values assigned in the
--     transform (NOT IDENTITY), so a full rebuild is repeatable. Sentinel members
--     use fixed negative/zero keys (-1 Unknown, 0 No-Discount) that ROW_NUMBER
--     (which starts at 1) never collides with.
--   - Atomic measures only: facts store the component amounts (gross/discount/net/
--     tax/refund). Named business measures ("Revenue", "AOV", ...) are defined in
--     the Phase D metric VIEW layer, not baked into the fact — the revenue-
--     definition decision on record (build-plan / ACTIONS.md §D).
--   - Identifiers unquoted -> Exasol folds to UPPERCASE (required; see ddl/README).
--     No year/month/day/object/rows (reserved) — dim_date uses cal_year etc.
--   - TEXT -> VARCHAR(2000000); INT -> INTEGER; DECIMAL/BOOLEAN/TIMESTAMP/DATE as-is.
--   - CREATE ... IF NOT EXISTS throughout -> re-running this file is idempotent.
--
-- Reserved-word watch (DWH layer, unverifiable without the live instance — rename,
-- never quote, if a CREATE fails): `address` (dim_location), `region`
-- (dim_geography). The POC proved name/status/title/price/cost/quantity safe.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS SHOPIFY_DWH;

-- #############################################################################
-- DIMENSIONS
-- #############################################################################

-- -----------------------------------------------------------------------------
-- dim_date  (generated — see 03_dim_date.sql)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_date (
    date_key        INTEGER,        -- YYYYMMDD
    full_date       DATE,
    cal_year        INTEGER,
    cal_quarter     INTEGER,
    cal_month       INTEGER,
    month_name      VARCHAR(12),
    week_of_year    INTEGER,
    day_of_month    INTEGER,
    day_of_week     INTEGER,        -- 1 = Monday .. 7 = Sunday
    day_name        VARCHAR(12),
    is_weekend      BOOLEAN,
    is_month_end    BOOLEAN,
    fiscal_year     INTEGER,        -- defaults to calendar (no fiscal offset set)
    fiscal_quarter  INTEGER
);

-- -----------------------------------------------------------------------------
-- dim_time  (generated, 24 rows — see 04_dim_time.sql)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_time (
    time_key          INTEGER,      -- 0..23
    hour_24           INTEGER,
    hour_12           INTEGER,
    am_pm             VARCHAR(2),
    hour_label        VARCHAR(12),
    day_part          VARCHAR(15),  -- Night/Morning/Afternoon/Evening
    is_business_hours BOOLEAN
);

-- -----------------------------------------------------------------------------
-- dim_customer  (stg_customers + aggregations from stg_orders + RFM)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_customer (
    customer_key             BIGINT,
    customer_id              VARCHAR(50),
    email                    VARCHAR(255),
    first_name               VARCHAR(100),
    last_name                VARCHAR(100),
    full_name                VARCHAR(200),
    phone                    VARCHAR(50),
    accepts_email_marketing  BOOLEAN,
    accepts_sms_marketing    BOOLEAN,
    customer_created_date    DATE,
    default_country          VARCHAR(100),
    default_city             VARCHAR(100),
    tags                     VARCHAR(2000000),
    membership_tier          VARCHAR(50),   -- derived from tags (B2B loyalty tiers)
    is_tax_exempt            BOOLEAN,
    lifetime_order_count     INTEGER,
    lifetime_revenue         DECIMAL(18,2),
    first_order_date         DATE,
    last_order_date          DATE,
    average_order_value      DECIMAL(18,2),
    days_since_last_order    INTEGER,
    customer_segment         VARCHAR(20),
    rfm_recency_score        INTEGER,
    rfm_frequency_score      INTEGER,
    rfm_monetary_score       INTEGER,
    rfm_combined_score       INTEGER,
    rfm_segment              VARCHAR(30),
    loaded_at                TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- dim_product  (variant grain: stg_products x stg_product_variants) [POC-proven]
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_product (
    product_key          BIGINT,
    product_id           VARCHAR(50),
    variant_id           VARCHAR(50),
    sku                  VARCHAR(100),
    barcode              VARCHAR(100),
    product_title        VARCHAR(255),
    variant_title        VARCHAR(255),
    full_title           VARCHAR(500),
    product_type         VARCHAR(255),
    vendor               VARCHAR(255),
    option_1_value       VARCHAR(255),
    option_2_value       VARCHAR(255),
    option_3_value       VARCHAR(255),
    current_price        DECIMAL(18,2),
    compare_at_price     DECIMAL(18,2),
    unit_cost            DECIMAL(18,2),
    is_on_sale           BOOLEAN,
    discount_percentage  DECIMAL(6,2),
    is_taxable           BOOLEAN,
    requires_shipping    BOOLEAN,
    weight_grams         DECIMAL(12,2),
    product_status       VARCHAR(20),
    tags                 VARCHAR(2000000),
    product_created_date DATE,
    loaded_at            TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- dim_geography  (distinct shipping + billing addresses parsed from stg_orders)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_geography (
    geography_key   BIGINT,
    address_hash    VARCHAR(1000),  -- dedup + join key: lower(city|province|country|zip)
    city            VARCHAR(255),
    province        VARCHAR(255),
    province_code   VARCHAR(10),
    country         VARCHAR(100),
    country_code    VARCHAR(5),
    postal_code     VARCHAR(20),
    region          VARCHAR(50),
    loaded_at       TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- dim_discount  (stg_discount_codes — loader deferred, so only the 0 sentinel
-- lands until read_discounts is granted; the table + transform are ready)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_discount (
    discount_key         BIGINT,    -- 0 = No Discount
    discount_id          VARCHAR(50),
    discount_code        VARCHAR(100),
    discount_title       VARCHAR(255),
    discount_type        VARCHAR(50),
    value_type           VARCHAR(20),
    discount_value       DECIMAL(18,2),
    discount_status      VARCHAR(20),
    starts_at            DATE,
    ends_at              DATE,
    usage_limit          INTEGER,
    current_usage_count  INTEGER,
    is_one_per_customer  BOOLEAN,
    loaded_at            TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- dim_location  (stg_locations)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_location (
    location_key     BIGINT,
    location_id      VARCHAR(50),
    location_name    VARCHAR(255),
    address          VARCHAR(500),  -- reserved-word watch (rename if CREATE fails)
    city             VARCHAR(100),
    province         VARCHAR(100),
    country          VARCHAR(100),
    country_code     VARCHAR(5),
    is_active        BOOLEAN,
    fulfills_online  BOOLEAN,
    loaded_at        TIMESTAMP
);

-- #############################################################################
-- FACTS
-- #############################################################################

-- -----------------------------------------------------------------------------
-- fact_order  (one row per order header — pivoted payments/taxes/discounts,
-- denormalized customer + geography)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_order (
    order_key               BIGINT,
    order_date_key          INTEGER,     -- FK -> dim_date
    order_time_key          INTEGER,     -- FK -> dim_time
    customer_key            BIGINT,      -- FK -> dim_customer (-1 = Unknown)
    shipping_geography_key  BIGINT,      -- FK -> dim_geography (-1 = Unknown)
    billing_geography_key   BIGINT,      -- FK -> dim_geography (-1 = Unknown)
    order_id                VARCHAR(50),
    order_number            VARCHAR(20),
    order_email             VARCHAR(255),
    checkout_id             VARCHAR(50), -- removed from 2026-04 API: stays NULL
    source_name             VARCHAR(50),
    landing_site            VARCHAR(2000000), -- removed from 2026-04 API: stays NULL
    referring_site          VARCHAR(2000000), -- removed from 2026-04 API: stays NULL
    order_created_at        TIMESTAMP,
    order_processed_at      TIMESTAMP,
    order_cancelled_at      TIMESTAMP,
    order_closed_at         TIMESTAMP,
    subtotal_amount         DECIMAL(18,2),
    shipping_amount         DECIMAL(18,2),
    tax_amount              DECIMAL(18,2),
    discount_amount         DECIMAL(18,2),
    total_amount            DECIMAL(18,2),
    refund_amount           DECIMAL(18,2),
    net_amount              DECIMAL(18,2),
    currency_code           VARCHAR(5),
    payment_1_gateway       VARCHAR(100),
    payment_1_amount        DECIMAL(18,2),
    payment_2_gateway       VARCHAR(100),
    payment_2_amount        DECIMAL(18,2),
    payment_3_gateway       VARCHAR(100),
    payment_3_amount        DECIMAL(18,2),
    total_payment_count     INTEGER,
    tax_1_name              VARCHAR(100),
    tax_1_rate              DECIMAL(10,6),
    tax_1_amount            DECIMAL(18,2),
    tax_2_name              VARCHAR(100),
    tax_2_rate              DECIMAL(10,6),
    tax_2_amount            DECIMAL(18,2),
    discount_1_code         VARCHAR(100),
    discount_1_type         VARCHAR(20),
    discount_1_amount       DECIMAL(18,2),
    discount_2_code         VARCHAR(100),
    discount_2_type         VARCHAR(20),
    discount_2_amount       DECIMAL(18,2),
    primary_discount_key    BIGINT,      -- FK -> dim_discount (0 = No Discount)
    shipping_method         VARCHAR(255),
    shipping_carrier        VARCHAR(100),
    financial_status        VARCHAR(50),
    fulfillment_status      VARCHAR(50),
    cancel_reason           VARCHAR(50),
    is_paid                 BOOLEAN,
    is_fully_refunded       BOOLEAN,
    is_cancelled            BOOLEAN,
    is_fulfilled            BOOLEAN,
    has_discount            BOOLEAN,
    has_multiple_payments   BOOLEAN,
    line_item_count         INTEGER,
    total_quantity          INTEGER,
    unique_product_count    INTEGER,
    customer_email          VARCHAR(255),
    customer_name           VARCHAR(200),
    customer_segment        VARCHAR(20),
    is_first_order          BOOLEAN,
    is_repeat_customer      BOOLEAN,
    shipping_city           VARCHAR(255),
    shipping_province       VARCHAR(255),
    shipping_country        VARCHAR(100),
    shipping_country_code   VARCHAR(5),
    tags                    VARCHAR(2000000),
    notes                   VARCHAR(2000000),
    loaded_at               TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- fact_order_line_item  (one row per line item) [POC-proven, widened to design]
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_order_line_item (
    line_item_key             BIGINT,
    order_key                 BIGINT,    -- FK -> fact_order
    order_date_key            INTEGER,   -- FK -> dim_date
    order_time_key            INTEGER,   -- FK -> dim_time
    product_key               BIGINT,    -- FK -> dim_product (-1 = Unknown)
    customer_key              BIGINT,    -- FK -> dim_customer
    line_item_id              VARCHAR(50),
    order_id                  VARCHAR(50),
    order_number              VARCHAR(20),
    sku                       VARCHAR(100),
    product_title             VARCHAR(255),
    variant_title             VARCHAR(255),
    product_type              VARCHAR(255),
    vendor                    VARCHAR(255),
    quantity_ordered          INTEGER,
    quantity_fulfilled        INTEGER,
    quantity_refunded         INTEGER,
    quantity_current          INTEGER,
    unit_price                DECIMAL(18,2),
    unit_cost                 DECIMAL(18,2),
    gross_amount              DECIMAL(18,2),
    discount_amount           DECIMAL(18,2),
    net_amount                DECIMAL(18,2),
    gross_margin              DECIMAL(18,2),
    gross_margin_percent      DECIMAL(8,2),
    is_gift_card              BOOLEAN,
    is_taxable                BOOLEAN,
    is_fulfilled              BOOLEAN,
    is_partially_fulfilled    BOOLEAN,
    is_refunded               BOOLEAN,
    is_fully_refunded         BOOLEAN,
    order_created_date        DATE,
    order_financial_status    VARCHAR(50),
    order_fulfillment_status  VARCHAR(50),
    customer_email            VARCHAR(255),
    customer_name             VARCHAR(200),
    shipping_country          VARCHAR(100),
    shipping_country_code     VARCHAR(5),
    loaded_at                 TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- fact_fulfillment  (one row per fulfillment / shipment)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_fulfillment (
    fulfillment_key         BIGINT,
    order_key               BIGINT,      -- FK -> fact_order
    order_date_key          INTEGER,     -- FK -> dim_date
    fulfillment_date_key    INTEGER,     -- FK -> dim_date
    fulfillment_time_key    INTEGER,     -- FK -> dim_time
    location_key            BIGINT,      -- FK -> dim_location (-1 = Unknown)
    customer_key            BIGINT,      -- FK -> dim_customer
    fulfillment_id          VARCHAR(50),
    order_id                VARCHAR(50),
    order_number            VARCHAR(20),
    order_created_at        TIMESTAMP,
    fulfillment_created_at  TIMESTAMP,
    fulfillment_updated_at  TIMESTAMP,
    fulfillment_time_hours  DECIMAL(12,2),
    fulfillment_time_days   DECIMAL(12,2),
    tracking_number         VARCHAR(255),
    tracking_company        VARCHAR(100),
    tracking_url            VARCHAR(2000000),
    shipping_service        VARCHAR(100),
    fulfillment_status      VARCHAR(20),
    shipment_status         VARCHAR(50),
    is_successful           BOOLEAN,
    is_pending              BOOLEAN,
    total_quantity          INTEGER,
    line_item_count         INTEGER,
    location_name           VARCHAR(255),
    customer_email          VARCHAR(255),
    customer_name           VARCHAR(200),
    shipping_country        VARCHAR(100),
    is_same_day             BOOLEAN,
    is_within_48h           BOOLEAN,
    is_late                 BOOLEAN,
    loaded_at               TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- fact_refund  (one row per refund)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_refund (
    refund_key            BIGINT,
    order_key             BIGINT,        -- FK -> fact_order
    order_date_key        INTEGER,       -- FK -> dim_date
    refund_date_key       INTEGER,       -- FK -> dim_date
    customer_key          BIGINT,        -- FK -> dim_customer
    refund_id             VARCHAR(50),
    order_id              VARCHAR(50),
    order_number          VARCHAR(20),
    order_created_at      TIMESTAMP,
    refund_created_at     TIMESTAMP,
    days_to_refund        INTEGER,
    refund_amount         DECIMAL(18,2),
    refund_subtotal       DECIMAL(18,2),
    refund_tax            DECIMAL(18,2),
    original_order_total  DECIMAL(18,2),
    refund_percentage     DECIMAL(8,2),
    total_items_refunded  INTEGER,
    line_item_count       INTEGER,
    items_restocked       INTEGER,
    items_not_restocked   INTEGER,
    refund_note           VARCHAR(2000000),
    is_full_refund        BOOLEAN,
    is_partial_refund     BOOLEAN,
    has_restock           BOOLEAN,
    customer_email        VARCHAR(255),
    customer_name         VARCHAR(200),
    loaded_at             TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- fact_inventory_snapshot  (one row per inventory item x location x snapshot date)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_inventory_snapshot (
    inventory_snapshot_key  BIGINT,
    snapshot_date_key       INTEGER,     -- FK -> dim_date
    product_key             BIGINT,      -- FK -> dim_product (-1 = Unknown)
    location_key            BIGINT,      -- FK -> dim_location (-1 = Unknown)
    inventory_item_id       VARCHAR(50),
    location_id             VARCHAR(50),
    snapshot_date           DATE,
    available_quantity      INTEGER,
    on_hand_quantity        INTEGER,
    committed_quantity      INTEGER,
    incoming_quantity       INTEGER,
    reserved_quantity       INTEGER,
    total_inventory         INTEGER,
    sellable_inventory      INTEGER,
    unit_cost               DECIMAL(18,2),
    inventory_cost_value    DECIMAL(18,2),
    unit_price              DECIMAL(18,2),
    inventory_retail_value  DECIMAL(18,2),
    sku                     VARCHAR(100),
    product_title           VARCHAR(255),
    variant_title           VARCHAR(255),
    product_type            VARCHAR(255),
    vendor                  VARCHAR(255),
    location_name           VARCHAR(255),
    location_country        VARCHAR(100),
    is_out_of_stock         BOOLEAN,
    is_low_stock            BOOLEAN,
    is_overstocked          BOOLEAN,
    loaded_at               TIMESTAMP
);
