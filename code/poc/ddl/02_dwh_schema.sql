-- =============================================================================
-- POC Phase 3 — SHOPIFY_DWH schema + 4 reporting tables (minimal POC subset)
--
-- Scope is the "revenue by product by day" metric, so these are deliberately
-- trimmed vs schema-layered.md:
--   - no payment / tax / discount pivots on fact_order
--   - no customer / geography dimensions (out of POC scope)
--   - surrogate keys are deterministic ROW_NUMBER() values assigned in the
--     transform (not IDENTITY) so a rebuild is repeatable
--   - dim_product carries a -1 "Unknown Product" member for line items whose
--     variant no longer exists, keeping fact FKs non-NULL
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS SHOPIFY_DWH;

-- -----------------------------------------------------------------------------
-- dim_date  (generated, pure SQL — see 03_dim_date.sql)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.dim_date (
    date_key      INTEGER,        -- YYYYMMDD
    full_date     DATE,
    cal_year      INTEGER,
    cal_quarter   INTEGER,
    cal_month     INTEGER,
    month_name    VARCHAR(12),
    cal_day       INTEGER,
    day_of_week   INTEGER,         -- 0 = Monday .. 6 = Sunday
    day_name      VARCHAR(12),
    is_weekend    BOOLEAN
);

-- -----------------------------------------------------------------------------
-- dim_product  (variant grain: stg_products x stg_product_variants)
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
-- fact_order  (one row per order header — minimal, no pivots)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_order (
    order_key            BIGINT,
    order_date_key       INTEGER,     -- FK -> dim_date
    order_id             VARCHAR(50),
    order_number         VARCHAR(20),
    order_email          VARCHAR(255),
    source_name          VARCHAR(50),
    order_created_at     TIMESTAMP,
    order_processed_at   TIMESTAMP,
    order_cancelled_at   TIMESTAMP,
    order_closed_at      TIMESTAMP,
    subtotal_amount      DECIMAL(18,2),
    shipping_amount      DECIMAL(18,2),
    tax_amount           DECIMAL(18,2),
    discount_amount      DECIMAL(18,2),
    total_amount         DECIMAL(18,2),
    refund_amount        DECIMAL(18,2),
    net_amount           DECIMAL(18,2),
    currency_code        VARCHAR(5),
    financial_status     VARCHAR(50),
    fulfillment_status   VARCHAR(50),
    cancel_reason        VARCHAR(50),
    is_cancelled         BOOLEAN,
    is_paid              BOOLEAN,
    has_discount         BOOLEAN,
    line_item_count      INTEGER,
    total_quantity       INTEGER,
    tags                 VARCHAR(2000000),
    notes                VARCHAR(2000000),
    loaded_at            TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- fact_order_line_item  (one row per line item — the metric's grain)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_DWH.fact_order_line_item (
    line_item_key           BIGINT,
    order_key               BIGINT,      -- FK -> fact_order
    order_date_key          INTEGER,     -- FK -> dim_date
    product_key             BIGINT,      -- FK -> dim_product (-1 = Unknown)
    line_item_id            VARCHAR(50),
    order_id                VARCHAR(50),
    order_number            VARCHAR(20),
    sku                     VARCHAR(100),
    product_title           VARCHAR(255),
    variant_title           VARCHAR(255),
    product_type            VARCHAR(255),
    vendor                  VARCHAR(255),
    quantity_ordered        INTEGER,
    quantity_current        INTEGER,
    quantity_refunded       INTEGER,
    unit_price              DECIMAL(18,2),
    unit_cost               DECIMAL(18,2),
    gross_amount            DECIMAL(18,2),
    discount_amount         DECIMAL(18,2),
    net_amount              DECIMAL(18,2),
    is_gift_card            BOOLEAN,
    is_taxable              BOOLEAN,
    order_created_date      DATE,
    order_financial_status  VARCHAR(50),
    loaded_at               TIMESTAMP
);
