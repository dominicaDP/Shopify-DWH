-- =============================================================================
-- POC Phase 1 — SHOPIFY_STG schema + 4 staging tables
-- Source of truth: projects/research-notes/schema-layered.md
-- Scope: stg_orders, stg_order_line_items, stg_products, stg_product_variants
--
-- Conventions:
--   - STG mirrors the Shopify API shape (row-based, minimal transformation).
--   - GIDs kept raw as VARCHAR; ID extraction happens in the DWH layer.
--   - Free-text / JSON fields (schema-layered.md "TEXT") -> VARCHAR(2000000)
--     so the local POC never truncates a source value.
--   - No distribution keys for the POC (<10 GB total). Revisit for prod.
--   - Identifiers left unquoted -> Exasol folds them to UPPERCASE.
--   - extracted_at is the ETL load timestamp (not a Shopify field). Note the
--     schema-layered.md design names this _extracted_at, but Exasol unquoted
--     identifiers cannot start with an underscore, so the prefix is dropped here.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS SHOPIFY_STG;

-- -----------------------------------------------------------------------------
-- stg_orders  (orders query -> Order object)
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
-- stg_order_line_items  (Order.lineItems connection)
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
-- stg_products  (products query -> Product object)
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
-- stg_product_variants  (productVariants query -> ProductVariant object)
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
