-- =============================================================================
-- Layer 1 production — SHOPIFY_STG schema + all 18 staging tables
-- Source of truth: projects/research-notes/schema-layered.md (v1.1, Exasol-safe)
-- Deploy:  python -m shopify_dwh.ddl_runner ddl/01_stg_schema.sql
-- Verify:  python -m shopify_dwh.ddl_runner ddl/verify_stg.sql
--
-- This extends the POC's 01_stg_schema.sql (4 tables, validated on Exasol 8) to
-- the full staging layer. The 4 POC tables (stg_orders, stg_order_line_items,
-- stg_products, stg_product_variants) are reproduced verbatim from what deployed
-- and loaded cleanly; the other 14 are generated from the same design doc using
-- the same proven conventions.
--
-- Conventions (carried from the POC, see ddl/README.md for the full rationale):
--   - STG mirrors the Shopify API shape (row-based, minimal transformation).
--   - GIDs kept raw as VARCHAR(50); numeric-ID extraction happens in the DWH layer.
--   - Type mapping design -> Exasol:  TEXT -> VARCHAR(2000000) (Exasol has no TEXT,
--     and 2 MB never truncates a source value);  INT -> INTEGER;  DECIMAL/BOOLEAN/
--     TIMESTAMP/DATE/VARCHAR(n) as-is.
--   - Identifiers left unquoted -> Exasol folds them to UPPERCASE. This is REQUIRED:
--     the loaders align columns by uppercased name against EXA_ALL_COLUMNS, so a
--     quoted (case-sensitive) identifier would break loading. If a column name
--     collides with an Exasol reserved word at deploy time, RENAME it (and update
--     the loader + schema doc) rather than quote it — same fix as the DWH layer's
--     year -> cal_year. Candidates to watch on first deploy: see ddl/README.md.
--   - extracted_at is the ETL load timestamp (not a Shopify field). The design doc
--     names it _extracted_at, but Exasol unquoted identifiers can't start with '_',
--     so the prefix is dropped (a POC finding, now baked into schema-layered.md v1.1).
--   - No distribution keys yet (volume < single-digit GB). Phase E sets them where
--     warranted (e.g. DISTRIBUTE BY order_id on the order-grain tables).
--   - CREATE ... IF NOT EXISTS throughout -> re-running this file is idempotent.
--
-- Schema name: hardcoded SHOPIFY_STG (matches the EXASOL_STG_SCHEMA default). If you
-- point the ETL at a different schema, change it here too — config-driven DDL
-- generation is a later productisation step (build-plan Phase E / schema generator).
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS SHOPIFY_STG;

-- #############################################################################
-- ORDER DOMAIN — the orders query and its nested connections
-- #############################################################################

-- -----------------------------------------------------------------------------
-- stg_orders  (orders query -> Order object)   [POC-validated]
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_orders (
    id                     VARCHAR(50),
    name                   VARCHAR(20),
    email                  VARCHAR(255),
    created_at             TIMESTAMP,
    processed_at           TIMESTAMP,
    updated_at             TIMESTAMP,
    cancelled_at           TIMESTAMP,
    closed_at              TIMESTAMP,
    cancel_reason          VARCHAR(50),
    currency_code          VARCHAR(5),
    subtotal_price         DECIMAL(18,2),
    total_discounts        DECIMAL(18,2),
    total_tax              DECIMAL(18,2),
    total_shipping         DECIMAL(18,2),
    total_price            DECIMAL(18,2),
    total_refunded         DECIMAL(18,2),
    financial_status       VARCHAR(50),
    fulfillment_status     VARCHAR(50),
    customer_id            VARCHAR(50),
    shipping_address_json  VARCHAR(2000000),
    billing_address_json   VARCHAR(2000000),
    tags                   VARCHAR(2000000),
    note                   VARCHAR(2000000),
    source_name            VARCHAR(50),
    landing_site           VARCHAR(2000000),
    referring_site         VARCHAR(2000000),
    checkout_id            VARCHAR(50),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_order_line_items  (Order.lineItems connection)   [POC-validated]
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_order_line_items (
    id                     VARCHAR(50),
    order_id               VARCHAR(50),
    variant_id             VARCHAR(50),
    product_id             VARCHAR(50),
    title                  VARCHAR(255),
    variant_title          VARCHAR(255),
    sku                    VARCHAR(100),
    quantity               INTEGER,
    current_quantity       INTEGER,
    unfulfilled_quantity   INTEGER,
    unit_price             DECIMAL(18,2),
    total_price            DECIMAL(18,2),
    total_discount         DECIMAL(18,2),
    discounted_total       DECIMAL(18,2),
    is_gift_card           BOOLEAN,
    taxable                BOOLEAN,
    requires_shipping      BOOLEAN,
    fulfillable_quantity   INTEGER,
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_order_transactions  (Order.transactions connection)
-- Grain: one row per payment/refund transaction.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_order_transactions (
    id                     VARCHAR(50),
    order_id               VARCHAR(50),
    kind                   VARCHAR(20),    -- SALE, REFUND, CAPTURE, ...
    status                 VARCHAR(20),    -- SUCCESS, PENDING, FAILURE, ERROR
    gateway                VARCHAR(100),
    amount                 DECIMAL(18,2),
    currency_code          VARCHAR(5),
    created_at             TIMESTAMP,
    processed_at           TIMESTAMP,
    error_code             VARCHAR(50),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_order_tax_lines  (Order.taxLines array)
-- Grain: one row per tax line.  (order_id, line_number) identifies a row.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_order_tax_lines (
    order_id               VARCHAR(50),
    line_number            INTEGER,        -- position in the array (1, 2, 3, ...)
    title                  VARCHAR(100),
    rate                   DECIMAL(10,6),  -- 0.15 = 15%
    price                  DECIMAL(18,2),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_order_discount_applications  (Order.discountApplications connection)
-- Grain: one row per discount application.  (order_id, line_number) per row.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_order_discount_applications (
    order_id               VARCHAR(50),
    line_number            INTEGER,
    discount_type          VARCHAR(50),    -- __typename (DiscountCodeApplication, ...)
    code                   VARCHAR(100),
    title                  VARCHAR(255),
    description            VARCHAR(2000000),
    value_type             VARCHAR(20),    -- MoneyV2 | PricingPercentageValue
    value_amount           DECIMAL(18,2),
    value_percentage       DECIMAL(5,2),
    target_type            VARCHAR(20),    -- LINE_ITEM | SHIPPING_LINE
    allocation_method      VARCHAR(20),    -- ACROSS | EACH | ONE
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_order_shipping_lines  (Order.shippingLines connection)
-- Grain: one row per shipping line.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_order_shipping_lines (
    id                     VARCHAR(50),
    order_id               VARCHAR(50),
    title                  VARCHAR(255),
    code                   VARCHAR(100),
    source                 VARCHAR(100),   -- reserved-word watch (see ddl/README.md)
    original_price         DECIMAL(18,2),
    discounted_price       DECIMAL(18,2),
    carrier_identifier     VARCHAR(100),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_fulfillments  (Order.fulfillments connection)
-- Grain: one row per fulfillment (shipment).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_fulfillments (
    id                     VARCHAR(50),
    order_id               VARCHAR(50),
    status                 VARCHAR(20),    -- SUCCESS, PENDING, CANCELLED, ERROR, FAILURE
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP,
    tracking_number        VARCHAR(255),
    tracking_company       VARCHAR(100),
    tracking_url           VARCHAR(2000000),
    location_id            VARCHAR(50),
    service                VARCHAR(100),
    shipment_status        VARCHAR(50),    -- LABEL_PRINTED, LABEL_PURCHASED, ...
    total_quantity         INTEGER,
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_fulfillment_line_items  (Order.fulfillments.fulfillmentLineItems connection)
-- Grain: one row per fulfilled line item.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_fulfillment_line_items (
    fulfillment_id         VARCHAR(50),
    line_item_id           VARCHAR(50),
    quantity               INTEGER,
    original_total         DECIMAL(18,2),
    discounted_total       DECIMAL(18,2),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_refunds  (Order.refunds connection)
-- Grain: one row per refund.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_refunds (
    id                     VARCHAR(50),
    order_id               VARCHAR(50),
    created_at             TIMESTAMP,
    note                   VARCHAR(2000000),
    total_refunded         DECIMAL(18,2),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_refund_line_items  (Order.refunds.refundLineItems connection)
-- Grain: one row per refunded line item.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_refund_line_items (
    refund_id              VARCHAR(50),
    line_item_id           VARCHAR(50),
    quantity               INTEGER,
    restock_type           VARCHAR(20),    -- NO_RESTOCK, CANCEL, RETURN, LEGACY_RESTOCK
    location_id            VARCHAR(50),
    subtotal_amount        DECIMAL(18,2),
    total_tax_amount       DECIMAL(18,2),
    extracted_at           TIMESTAMP
);

-- #############################################################################
-- ENTITY DOMAIN — top-level objects (customers, catalogue, discounts, locations)
-- #############################################################################

-- -----------------------------------------------------------------------------
-- stg_customers  (customers query -> Customer object)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_customers (
    id                     VARCHAR(50),
    email                  VARCHAR(255),
    phone                  VARCHAR(50),
    first_name             VARCHAR(100),
    last_name              VARCHAR(100),
    email_marketing_state  VARCHAR(20),    -- SUBSCRIBED, UNSUBSCRIBED, ...
    sms_marketing_state    VARCHAR(20),
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP,
    number_of_orders       INTEGER,
    amount_spent           DECIMAL(18,2),
    default_address_json   VARCHAR(2000000),
    tags                   VARCHAR(2000000),
    note                   VARCHAR(2000000),
    tax_exempt             BOOLEAN,
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_products  (products query -> Product object)   [POC-validated]
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_products (
    id                     VARCHAR(50),
    title                  VARCHAR(255),
    handle                 VARCHAR(255),
    description            VARCHAR(2000000),
    product_type           VARCHAR(255),
    vendor                 VARCHAR(255),
    status                 VARCHAR(20),
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP,
    published_at           TIMESTAMP,
    tags                   VARCHAR(2000000),
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_product_variants  (productVariants query -> ProductVariant object)   [POC-validated]
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_product_variants (
    id                     VARCHAR(50),
    product_id             VARCHAR(50),
    title                  VARCHAR(255),
    sku                    VARCHAR(100),
    barcode                VARCHAR(100),
    price                  DECIMAL(18,2),
    compare_at_price       DECIMAL(18,2),
    cost                   DECIMAL(18,2),
    taxable                BOOLEAN,
    requires_shipping      BOOLEAN,
    weight                 DECIMAL(10,2),
    weight_unit            VARCHAR(10),
    option1                VARCHAR(255),
    option2                VARCHAR(255),
    option3                VARCHAR(255),
    inventory_item_id      VARCHAR(50),
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP,
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_discount_codes  (codeDiscountNodes query -> DiscountCodeNode object)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_discount_codes (
    id                         VARCHAR(50),
    code                       VARCHAR(100),
    title                      VARCHAR(255),
    discount_type              VARCHAR(50),    -- DiscountCodeBasic, ...
    status                     VARCHAR(20),    -- ACTIVE, EXPIRED, SCHEDULED
    value_type                 VARCHAR(30),    -- MoneyV2 | PricingPercentageValue
    value_amount               DECIMAL(18,2),
    value_percentage           DECIMAL(5,2),
    starts_at                  TIMESTAMP,
    ends_at                    TIMESTAMP,
    usage_limit                INTEGER,
    usage_count                INTEGER,        -- asyncUsageCount
    applies_once_per_customer  BOOLEAN,
    created_at                 TIMESTAMP,
    extracted_at               TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_locations  (locations query -> Location object)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_locations (
    id                       VARCHAR(50),
    name                     VARCHAR(255),
    address1                 VARCHAR(255),
    address2                 VARCHAR(255),
    city                     VARCHAR(100),
    province                 VARCHAR(100),
    province_code            VARCHAR(10),
    country                  VARCHAR(100),
    country_code             VARCHAR(5),
    zip                      VARCHAR(20),
    phone                    VARCHAR(50),
    is_active                BOOLEAN,
    fulfills_online_orders   BOOLEAN,
    extracted_at             TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_inventory_levels  (inventoryLevels query -> InventoryLevel object)
-- Daily snapshots: (inventory_item_id, location_id, snapshot_date) per row.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_inventory_levels (
    inventory_item_id      VARCHAR(50),
    location_id            VARCHAR(50),
    available              INTEGER,
    on_hand                INTEGER,
    committed              INTEGER,    -- reserved-word watch (see ddl/README.md)
    incoming               INTEGER,
    reserved               INTEGER,    -- reserved-word watch (see ddl/README.md)
    updated_at             TIMESTAMP,
    snapshot_date          DATE,
    extracted_at           TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_abandoned_checkouts  (abandonedCheckouts query -> Checkout object)
-- Truly abandoned = completed_at IS NULL.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_abandoned_checkouts (
    id                       VARCHAR(50),
    created_at               TIMESTAMP,
    updated_at               TIMESTAMP,
    completed_at             TIMESTAMP,
    customer_id              VARCHAR(50),
    email                    VARCHAR(255),
    phone                    VARCHAR(50),
    subtotal_price           DECIMAL(18,2),
    total_tax                DECIMAL(18,2),
    total_price              DECIMAL(18,2),
    currency_code            VARCHAR(5),
    abandoned_checkout_url   VARCHAR(2000000),
    line_items_count         INTEGER,
    line_items_json          VARCHAR(2000000),
    shipping_address_json    VARCHAR(2000000),
    extracted_at             TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- stg_gift_cards  (giftCards query -> GiftCard object)
-- Shopify masks the code: only the last 4 chars are available (lastCharacters).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SHOPIFY_STG.stg_gift_cards (
    id                     VARCHAR(50),
    code                   VARCHAR(10),    -- last 4 chars only (masked by Shopify)
    initial_value          DECIMAL(18,2),
    balance                DECIMAL(18,2),
    currency_code          VARCHAR(5),
    enabled                BOOLEAN,
    expires_on             DATE,
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP,
    disabled_at            TIMESTAMP,
    customer_id            VARCHAR(50),
    order_id               VARCHAR(50),
    note                   VARCHAR(2000000),
    extracted_at           TIMESTAMP
);
