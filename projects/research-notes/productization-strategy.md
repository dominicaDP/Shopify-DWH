# Productization Strategy

**Version:** 1.0
**Last Updated:** 2026-01-30

Strategy for making the Shopify DWH configurable and deployable across multiple customers.

---

## Overview

The generic Shopify DWH (Layer 1) should be **configuration-driven** rather than hardcoded. This enables:

- Deployment to multiple Shopify merchants
- Customer-specific schema generation
- Self-documenting column names
- No mixing of data into generic columns

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  CONFIGURATION LAYER                                            │
│                                                                 │
│  deployment_config.yaml (per customer)                          │
│  - Payment methods                                              │
│  - Tax types                                                    │
│  - Discount categories                                          │
│  - Shipping carriers                                            │
│  - Custom fields (metafields)                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SCHEMA GENERATOR                                               │
│                                                                 │
│  Input: deployment_config.yaml                                  │
│  Output: DDL scripts with customer-specific columns             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ETL GENERATOR                                                  │
│                                                                 │
│  Input: deployment_config.yaml                                  │
│  Output: Parameterized pivot/transform logic                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SHOPIFY_DWH (customer-specific schema)                         │
│                                                                 │
│  fact_order with named columns per config                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuration Schema

### deployment_config.yaml

```yaml
# Deployment Configuration
# One file per customer/deployment

deployment:
  name: "dress_your_tech"
  shopify_store: "dyt.myshopify.com"
  database_schema: "dyt_dwh"
  timezone: "Africa/Johannesburg"

# Payment Methods
# Each becomes a column: payment_{name}_amount
payment_methods:
  - name: shopify_payments
    display_name: "Shopify Payments"
    gateway_match: "shopify_payments"

  - name: gift_card
    display_name: "Gift Card"
    gateway_match: "gift_card"

  - name: paypal
    display_name: "PayPal"
    gateway_match: "paypal"

  - name: manual
    display_name: "Manual Payment"
    gateway_match: "manual"

# Tax Types
# Each becomes columns: tax_{name}_rate, tax_{name}_amount
tax_types:
  - name: vat
    display_name: "VAT"
    title_match: ["VAT", "Value Added Tax"]

  - name: levy
    display_name: "Levy"
    title_match: ["Levy", "Environmental Levy"]

# Discount Categories
# Each becomes columns: discount_{name}_code, discount_{name}_amount
discount_categories:
  - name: voucher
    display_name: "Voucher"
    code_pattern: "^[A-Z0-9]{15,16}$"  # 15-16 char alphanumeric

  - name: promotion
    display_name: "Promotion"
    code_pattern: "^PROMO.*"

  - name: staff
    display_name: "Staff Discount"
    code_pattern: "^STAFF.*"

  - name: manual
    display_name: "Manual Discount"
    type_match: "ManualDiscountApplication"

# Shipping Carriers
# Each becomes columns: shipping_{name}_method, shipping_{name}_amount
shipping_carriers:
  - name: standard
    display_name: "Standard Shipping"
    carrier_match: ["standard", "default"]

  - name: express
    display_name: "Express Shipping"
    carrier_match: ["express", "overnight"]

  - name: collect
    display_name: "Click & Collect"
    carrier_match: ["collect", "pickup"]

# Custom Fields (Shopify Metafields)
# Each becomes a column with specified name
custom_fields:
  - name: corporate_client_id
    display_name: "Corporate Client ID"
    metafield_namespace: "custom"
    metafield_key: "corporate_client"
    data_type: "VARCHAR(50)"

  - name: campaign_code
    display_name: "Campaign Code"
    metafield_namespace: "custom"
    metafield_key: "campaign"
    data_type: "VARCHAR(100)"

# Feature Flags
features:
  include_refund_details: true
  include_fulfillment_tracking: false
  include_inventory_levels: false
  multi_currency: false

# ═══════════════════════════════════════════════════════════════════════════
# ADDITIONAL CONFIGURATION ELEMENTS
# ═══════════════════════════════════════════════════════════════════════════

# Pivot Limits
# Controls how many columns are generated for pivoted arrays
pivot_limits:
  max_payment_methods: 3        # payment_1, payment_2, payment_3 OR named columns
  max_tax_types: 2              # tax_1, tax_2 OR named columns
  max_discounts: 2              # discount_1, discount_2 OR named columns
  max_shipping_lines: 1         # Usually 1, but some stores have multiple

# Customer Segmentation Rules
# Defines the business logic for customer_segment in dim_customer
customer_segments:
  - name: new
    display_name: "New"
    rule: "lifetime_order_count = 1 AND days_since_first_order <= 30"

  - name: active
    display_name: "Active"
    rule: "days_since_last_order <= 90"

  - name: at_risk
    display_name: "At Risk"
    rule: "days_since_last_order BETWEEN 91 AND 180"

  - name: lapsed
    display_name: "Lapsed"
    rule: "days_since_last_order > 180"

# Product Option Labels
# Maps generic option1/option2/option3 to meaningful names
product_options:
  option_1:
    name: "size"
    display_name: "Size"
  option_2:
    name: "color"
    display_name: "Color"
  option_3:
    name: "material"
    display_name: "Material"

# Product Type Hierarchy
# Groups product types into categories for reporting
product_categories:
  - category: "Accessories"
    display_name: "Accessories"
    product_types: ["Phone Case", "Screen Protector", "Cable"]

  - category: "Audio"
    display_name: "Audio"
    product_types: ["Headphones", "Earbuds", "Speakers"]

# Fiscal Calendar
# Defines fiscal year and quarter boundaries
fiscal_calendar:
  fiscal_year_start_month: 3      # March = fiscal year starts March 1
  week_start_day: "Monday"        # Monday or Sunday

  # Optional: Custom fiscal periods
  # periods:
  #   - name: "Q1"
  #     start: "03-01"
  #     end: "05-31"

# Geographic Regions
# Maps countries to regions for reporting aggregation
geographic_regions:
  - region: "South Africa"
    display_name: "South Africa"
    countries: ["ZA"]

  - region: "Africa Other"
    display_name: "Africa (Other)"
    countries: ["NA", "BW", "ZW", "MZ"]

  - region: "International"
    display_name: "International"
    countries: ["*"]  # Catch-all for unmapped

# Order Status Mappings
# Defines which Shopify statuses map to DWH flags
order_status_mappings:
  is_paid:
    - "PAID"
    - "PARTIALLY_REFUNDED"

  is_fully_refunded:
    - "REFUNDED"

  is_fulfilled:
    - "FULFILLED"

  is_partially_fulfilled:
    - "PARTIAL"
    - "IN_PROGRESS"

# Order Tags as Flags
# Shopify tags to capture as boolean columns
order_tag_flags:
  - tag_pattern: "VIP"
    column_name: "is_vip_order"
    description: "Order has VIP tag"

  - tag_pattern: "B2B"
    column_name: "is_b2b_order"
    description: "B2B transaction"

  - tag_pattern: "GIFT"
    column_name: "is_gift"
    description: "Marked as gift"

# Customer Tags for Segmentation
# Tags that create customer flags/attributes
customer_tag_flags:
  - tag_pattern: "wholesale"
    column_name: "is_wholesale"
    description: "Wholesale customer"

  - tag_pattern: "VIP"
    column_name: "is_vip"
    description: "VIP customer"

# Data Retention
retention:
  stg_retention_days: 7           # Keep staging data for 7 days
  fact_history_months: 60         # 5 years of fact data
  soft_delete: true               # Soft delete vs hard delete

# Schema Naming
schema_naming:
  staging_schema: "SHOPIFY_STG"   # Can customize prefix
  warehouse_schema: "SHOPIFY_DWH"
  use_customer_prefix: true       # dyt_stg, dyt_dwh vs generic

# Refresh Configuration
refresh:
  orders_lookback_days: 3         # Re-process last 3 days of orders
  full_refresh_day: "Sunday"      # Full dimension refresh
  incremental_frequency: "hourly" # hourly, daily

# Currency Configuration (if multi_currency = true)
currency:
  base_currency: "ZAR"
  store_presentment: false        # Store customer currency amounts
  exchange_rate_source: null      # null = no conversion, or "daily_rates" table

# Denormalization Options
# Which attributes to denormalize onto facts for faster queries
denormalization:
  fact_order:
    include_customer_fields:
      - "customer_email"
      - "customer_name"
      - "customer_segment"
    include_geography_fields:
      - "shipping_city"
      - "shipping_province"
      - "shipping_country"
      - "shipping_country_code"

  fact_order_line_item:
    include_product_fields:
      - "product_type"
      - "vendor"
      - "unit_cost"
    include_order_fields:
      - "order_created_date"
      - "order_financial_status"
      - "shipping_country"
```

---

## Configuration Element Summary

All configurable elements organized by category:

| Category | Element | Impact | Required? |
|----------|---------|--------|-----------|
| **Deployment** | name, store, schema, timezone | Schema names, timestamps | Yes |
| **Pivot - Financial** | payment_methods | payment_{name}_amount columns | Yes |
| **Pivot - Financial** | tax_types | tax_{name}_rate, tax_{name}_amount columns | Yes |
| **Pivot - Financial** | discount_categories | discount_{name}_code, discount_{name}_amount columns | Yes |
| **Pivot - Shipping** | shipping_carriers | shipping_{name}_amount columns | Optional |
| **Pivot - Limits** | pivot_limits | Max columns for generic pivots | Optional |
| **Custom Data** | custom_fields (metafields) | Custom columns on facts/dims | Optional |
| **Business Logic** | customer_segments | customer_segment derivation rules | Recommended |
| **Business Logic** | order_status_mappings | is_paid, is_fulfilled flag definitions | Optional (has defaults) |
| **Categorization** | product_options | option_1 → size label mapping | Optional |
| **Categorization** | product_categories | product_type → category grouping | Optional |
| **Categorization** | geographic_regions | country → region mapping | Optional |
| **Tagging** | order_tag_flags | Tags → boolean columns | Optional |
| **Tagging** | customer_tag_flags | Tags → boolean columns | Optional |
| **Calendar** | fiscal_calendar | Fiscal year, week start | Optional (calendar year default) |
| **Currency** | currency | Base currency, multi-currency options | Optional |
| **Operations** | retention | STG retention, history depth | Optional (has defaults) |
| **Operations** | refresh | Lookback, frequency | Optional (has defaults) |
| **Performance** | denormalization | Which fields to denormalize | Optional (has defaults) |
| **Features** | features flags | Enable/disable optional features | Optional |

---

## Generated Schema Example

### fact_order (for Dress Your Tech config)

Based on the config above, the schema generator produces:

```sql
CREATE TABLE dyt_dwh.fact_order (
    -- Keys (standard)
    order_key                       BIGINT IDENTITY PRIMARY KEY,
    order_date_key                  INT NOT NULL,
    order_time_key                  INT NOT NULL,
    customer_key                    BIGINT,
    shipping_geography_key          BIGINT,

    -- Order Identifiers (standard)
    order_id                        VARCHAR(50) NOT NULL,
    order_number                    VARCHAR(20),

    -- Financial Base (standard)
    subtotal_amount                 DECIMAL(18,2),
    shipping_amount                 DECIMAL(18,2),
    tax_amount                      DECIMAL(18,2),
    discount_amount                 DECIMAL(18,2),
    total_amount                    DECIMAL(18,2),
    refund_amount                   DECIMAL(18,2),
    net_amount                      DECIMAL(18,2),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Payment Methods
    -- Generated from: payment_methods[]
    -- ═══════════════════════════════════════════════════════════
    payment_shopify_payments_amount DECIMAL(18,2),
    payment_gift_card_amount        DECIMAL(18,2),
    payment_paypal_amount           DECIMAL(18,2),
    payment_manual_amount           DECIMAL(18,2),
    payment_method_count            INT,

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Tax Types
    -- Generated from: tax_types[]
    -- ═══════════════════════════════════════════════════════════
    tax_vat_rate                    DECIMAL(5,4),
    tax_vat_amount                  DECIMAL(18,2),
    tax_levy_rate                   DECIMAL(5,4),
    tax_levy_amount                 DECIMAL(18,2),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Discount Categories
    -- Generated from: discount_categories[]
    -- ═══════════════════════════════════════════════════════════
    discount_voucher_code           VARCHAR(100),
    discount_voucher_amount         DECIMAL(18,2),
    discount_promotion_code         VARCHAR(100),
    discount_promotion_amount       DECIMAL(18,2),
    discount_staff_code             VARCHAR(100),
    discount_staff_amount           DECIMAL(18,2),
    discount_manual_amount          DECIMAL(18,2),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Shipping Carriers
    -- Generated from: shipping_carriers[]
    -- ═══════════════════════════════════════════════════════════
    shipping_standard_amount        DECIMAL(18,2),
    shipping_express_amount         DECIMAL(18,2),
    shipping_collect_amount         DECIMAL(18,2),
    shipping_method_name            VARCHAR(255),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Custom Fields (Metafields)
    -- Generated from: custom_fields[]
    -- ═══════════════════════════════════════════════════════════
    corporate_client_id             VARCHAR(50),
    campaign_code                   VARCHAR(100),

    -- Status Flags (standard)
    is_paid                         BOOLEAN,
    is_cancelled                    BOOLEAN,
    is_fulfilled                    BOOLEAN,
    has_discount                    BOOLEAN,

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Order Tag Flags
    -- Generated from: order_tag_flags[]
    -- ═══════════════════════════════════════════════════════════
    is_vip_order                    BOOLEAN,
    is_b2b_order                    BOOLEAN,
    is_gift                         BOOLEAN,

    -- ETL
    _loaded_at                      TIMESTAMP
)
DISTRIBUTE BY order_key
PARTITION BY order_date_key;
```

### dim_customer (for Dress Your Tech config)

```sql
CREATE TABLE dyt_dwh.dim_customer (
    -- Keys
    customer_key                    BIGINT IDENTITY PRIMARY KEY,
    customer_id                     VARCHAR(50) NOT NULL,

    -- Identity
    email                           VARCHAR(255),
    first_name                      VARCHAR(100),
    last_name                       VARCHAR(100),
    full_name                       VARCHAR(200),
    phone                           VARCHAR(50),

    -- Marketing
    accepts_email_marketing         BOOLEAN,
    accepts_sms_marketing           BOOLEAN,

    -- Geography
    default_country                 VARCHAR(100),
    default_city                    VARCHAR(100),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Customer Tag Flags
    -- Generated from: customer_tag_flags[]
    -- ═══════════════════════════════════════════════════════════
    is_wholesale                    BOOLEAN,
    is_vip                          BOOLEAN,

    -- Lifetime Metrics
    lifetime_order_count            INT,
    lifetime_revenue                DECIMAL(18,2),
    first_order_date                DATE,
    last_order_date                 DATE,
    average_order_value             DECIMAL(18,2),
    days_since_last_order           INT,

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Customer Segmentation
    -- Generated from: customer_segments[]
    -- ═══════════════════════════════════════════════════════════
    customer_segment                VARCHAR(20),  -- New, Active, At Risk, Lapsed

    -- Standard
    tags                            VARCHAR(1000),
    is_tax_exempt                   BOOLEAN,
    customer_created_date           DATE,

    -- ETL
    _loaded_at                      TIMESTAMP
);
```

### dim_product (for Dress Your Tech config)

```sql
CREATE TABLE dyt_dwh.dim_product (
    -- Keys
    product_key                     BIGINT IDENTITY PRIMARY KEY,
    product_id                      VARCHAR(50) NOT NULL,
    variant_id                      VARCHAR(50) NOT NULL,

    -- Identifiers
    sku                             VARCHAR(100),
    barcode                         VARCHAR(100),
    product_title                   VARCHAR(255),
    variant_title                   VARCHAR(255),
    full_title                      VARCHAR(500),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Product Options (with meaningful names)
    -- Generated from: product_options
    -- ═══════════════════════════════════════════════════════════
    size                            VARCHAR(255),  -- was option_1
    color                           VARCHAR(255),  -- was option_2
    material                        VARCHAR(255),  -- was option_3

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Product Category (grouped from product_type)
    -- Generated from: product_categories[]
    -- ═══════════════════════════════════════════════════════════
    product_type                    VARCHAR(255),  -- Original Shopify type
    product_category                VARCHAR(100),  -- Grouped: Accessories, Audio, etc.

    -- Vendor
    vendor                          VARCHAR(255),

    -- Pricing
    current_price                   DECIMAL(18,2),
    compare_at_price                DECIMAL(18,2),
    unit_cost                       DECIMAL(18,2),
    is_on_sale                      BOOLEAN,
    discount_percentage             DECIMAL(5,2),

    -- Attributes
    is_taxable                      BOOLEAN,
    requires_shipping               BOOLEAN,
    weight_grams                    DECIMAL(10,2),
    product_status                  VARCHAR(20),
    tags                            VARCHAR(1000),
    product_created_date            DATE,

    -- ETL
    _loaded_at                      TIMESTAMP
);
```

### dim_geography (for Dress Your Tech config)

```sql
CREATE TABLE dyt_dwh.dim_geography (
    -- Keys
    geography_key                   BIGINT IDENTITY PRIMARY KEY,
    address_hash                    VARCHAR(64) NOT NULL,

    -- Address Components
    city                            VARCHAR(255),
    province                        VARCHAR(255),
    province_code                   VARCHAR(10),
    country                         VARCHAR(100),
    country_code                    VARCHAR(5),
    postal_code                     VARCHAR(20),

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Geographic Region
    -- Generated from: geographic_regions[]
    -- ═══════════════════════════════════════════════════════════
    region                          VARCHAR(50),  -- South Africa, Africa (Other), International

    -- ETL
    _loaded_at                      TIMESTAMP
);
```

### dim_date (with fiscal calendar config)

```sql
CREATE TABLE dyt_dwh.dim_date (
    -- Key
    date_key                        INT PRIMARY KEY,  -- YYYYMMDD

    -- Standard Calendar
    full_date                       DATE,
    year                            INT,
    quarter                         INT,
    month                           INT,
    month_name                      VARCHAR(20),
    week_of_year                    INT,
    day_of_month                    INT,
    day_of_week                     INT,
    day_name                        VARCHAR(20),
    is_weekend                      BOOLEAN,
    is_month_end                    BOOLEAN,

    -- ═══════════════════════════════════════════════════════════
    -- CONFIGURED: Fiscal Calendar
    -- Generated from: fiscal_calendar (start_month: 3)
    -- ═══════════════════════════════════════════════════════════
    fiscal_year                     INT,    -- Year starting March
    fiscal_quarter                  INT     -- Q1 = Mar-May, Q2 = Jun-Aug, etc.
);
```

---

## Generated ETL Example

### Payment Pivot (parameterized)

```python
def generate_payment_pivot_sql(config: dict) -> str:
    """Generate payment pivot SQL from config."""

    payment_methods = config['payment_methods']

    # Build CASE statements for each configured payment method
    cases = []
    for pm in payment_methods:
        name = pm['name']
        match = pm['gateway_match']
        cases.append(f"""
        SUM(CASE WHEN gateway = '{match}' THEN amount ELSE 0 END)
            AS payment_{name}_amount""")

    case_sql = ','.join(cases)

    return f"""
    SELECT
        order_id,
        {case_sql},
        COUNT(*) AS payment_method_count
    FROM stg_order_transactions
    WHERE kind = 'SALE' AND status = 'SUCCESS'
    GROUP BY order_id
    """

# Example output for DYT config:
"""
SELECT
    order_id,
    SUM(CASE WHEN gateway = 'shopify_payments' THEN amount ELSE 0 END)
        AS payment_shopify_payments_amount,
    SUM(CASE WHEN gateway = 'gift_card' THEN amount ELSE 0 END)
        AS payment_gift_card_amount,
    SUM(CASE WHEN gateway = 'paypal' THEN amount ELSE 0 END)
        AS payment_paypal_amount,
    SUM(CASE WHEN gateway = 'manual' THEN amount ELSE 0 END)
        AS payment_manual_amount,
    COUNT(*) AS payment_method_count
FROM stg_order_transactions
WHERE kind = 'SALE' AND status = 'SUCCESS'
GROUP BY order_id
"""
```

### Tax Pivot (parameterized)

```python
def generate_tax_pivot_sql(config: dict) -> str:
    """Generate tax pivot SQL from config."""

    tax_types = config['tax_types']

    cases = []
    for tax in tax_types:
        name = tax['name']
        matches = tax['title_match']
        match_condition = ' OR '.join([f"title ILIKE '%{m}%'" for m in matches])

        cases.append(f"""
        MAX(CASE WHEN {match_condition} THEN rate END) AS tax_{name}_rate,
        SUM(CASE WHEN {match_condition} THEN price ELSE 0 END) AS tax_{name}_amount""")

    case_sql = ','.join(cases)

    return f"""
    SELECT
        order_id,
        {case_sql}
    FROM stg_order_tax_lines
    GROUP BY order_id
    """
```

### Discount Categorization (parameterized)

```python
def generate_discount_pivot_sql(config: dict) -> str:
    """Generate discount pivot SQL from config."""

    categories = config['discount_categories']

    cases = []
    for cat in categories:
        name = cat['name']

        # Build match condition based on config
        conditions = []
        if 'code_pattern' in cat:
            conditions.append(f"code ~ '{cat['code_pattern']}'")
        if 'type_match' in cat:
            conditions.append(f"discount_type = '{cat['type_match']}'")

        match_condition = ' OR '.join(conditions) if conditions else 'FALSE'

        cases.append(f"""
        MAX(CASE WHEN {match_condition} THEN code END) AS discount_{name}_code,
        SUM(CASE WHEN {match_condition} THEN
            COALESCE(value_amount, value_percentage) ELSE 0 END) AS discount_{name}_amount""")

    case_sql = ','.join(cases)

    return f"""
    SELECT
        order_id,
        {case_sql}
    FROM stg_order_discount_applications
    GROUP BY order_id
    """
```

### Customer Segmentation (parameterized)

```python
def generate_customer_segment_sql(config: dict) -> str:
    """Generate customer segment CASE statement from config."""

    segments = config['customer_segments']

    cases = []
    for seg in segments:
        name = seg['name']
        display = seg['display_name']
        rule = seg['rule']
        cases.append(f"WHEN {rule} THEN '{display}'")

    case_sql = '\n        '.join(cases)

    return f"""
    CASE
        {case_sql}
        ELSE 'Unknown'
    END AS customer_segment
    """

# Example output for DYT config:
"""
CASE
    WHEN lifetime_order_count = 1 AND days_since_first_order <= 30 THEN 'New'
    WHEN days_since_last_order <= 90 THEN 'Active'
    WHEN days_since_last_order BETWEEN 91 AND 180 THEN 'At Risk'
    WHEN days_since_last_order > 180 THEN 'Lapsed'
    ELSE 'Unknown'
END AS customer_segment
"""
```

### Order Tag Flags (parameterized)

```python
def generate_tag_flag_columns(config: dict) -> tuple[str, str]:
    """Generate DDL and SQL for order tag flags."""

    flags = config.get('order_tag_flags', [])

    # DDL columns
    ddl_cols = []
    for flag in flags:
        ddl_cols.append(f"    {flag['column_name']}  BOOLEAN,  -- {flag['description']}")

    # SQL expressions
    sql_cols = []
    for flag in flags:
        pattern = flag['tag_pattern']
        col = flag['column_name']
        sql_cols.append(f"    tags ILIKE '%{pattern}%' AS {col}")

    return '\n'.join(ddl_cols), ',\n'.join(sql_cols)

# Example DDL output:
"""
    is_vip_order        BOOLEAN,  -- Order has VIP tag
    is_b2b_order        BOOLEAN,  -- B2B transaction
    is_gift             BOOLEAN,  -- Marked as gift
"""

# Example SQL output:
"""
    tags ILIKE '%VIP%' AS is_vip_order,
    tags ILIKE '%B2B%' AS is_b2b_order,
    tags ILIKE '%GIFT%' AS is_gift
"""
```

### Geographic Region Mapping (parameterized)

```python
def generate_region_case_sql(config: dict) -> str:
    """Generate region mapping CASE statement."""

    regions = config['geographic_regions']

    cases = []
    for reg in regions:
        name = reg['display_name']
        countries = reg['countries']

        if countries == ['*']:
            # Catch-all - must be last
            continue

        country_list = "', '".join(countries)
        cases.append(f"WHEN country_code IN ('{country_list}') THEN '{name}'")

    # Add catch-all last
    for reg in regions:
        if reg['countries'] == ['*']:
            cases.append(f"ELSE '{reg['display_name']}'")
            break

    return f"""
    CASE
        {chr(10).join('        ' + c for c in cases)}
    END AS region
    """

# Example output:
"""
CASE
    WHEN country_code IN ('ZA') THEN 'South Africa'
    WHEN country_code IN ('NA', 'BW', 'ZW', 'MZ') THEN 'Africa (Other)'
    ELSE 'International'
END AS region
"""
```

### Product Option Label Mapping

```python
def generate_product_option_aliases(config: dict) -> str:
    """Generate product option column aliases."""

    options = config.get('product_options', {})

    aliases = []
    for i in range(1, 4):
        key = f'option_{i}'
        if key in options:
            name = options[key]['name']
            aliases.append(f"    option{i} AS {name}")
        else:
            aliases.append(f"    option{i}")

    return ',\n'.join(aliases)

# Example output:
"""
    option1 AS size,
    option2 AS color,
    option3 AS material
"""
```

### Fiscal Calendar Generation

```python
def generate_fiscal_columns(config: dict) -> str:
    """Generate fiscal year/quarter logic."""

    calendar = config.get('fiscal_calendar', {})
    start_month = calendar.get('fiscal_year_start_month', 1)

    if start_month == 1:
        # Calendar year = fiscal year
        return """
    year AS fiscal_year,
    quarter AS fiscal_quarter
        """

    # Offset calculation
    offset = 12 - start_month + 1

    return f"""
    CASE
        WHEN month >= {start_month} THEN year
        ELSE year - 1
    END AS fiscal_year,
    CASE
        WHEN month >= {start_month} THEN ((month - {start_month}) / 3) + 1
        ELSE ((month + {offset}) / 3) + 1
    END AS fiscal_quarter
    """

# Example output for fiscal year starting March:
"""
CASE
    WHEN month >= 3 THEN year
    ELSE year - 1
END AS fiscal_year,
CASE
    WHEN month >= 3 THEN ((month - 3) / 3) + 1
    ELSE ((month + 10) / 3) + 1
END AS fiscal_quarter
"""
```

---

## Schema Generator

### generate_schema.py

```python
"""
Schema Generator - Creates customer-specific DDL from config.
"""
import yaml
from pathlib import Path
from jinja2 import Template

def load_config(config_path: str) -> dict:
    """Load deployment configuration."""
    with open(config_path) as f:
        return yaml.safe_load(f)

def generate_fact_order_ddl(config: dict) -> str:
    """Generate fact_order DDL from config."""

    template = Template("""
CREATE TABLE {{ schema }}.fact_order (
    -- Keys (standard)
    order_key                       BIGINT IDENTITY PRIMARY KEY,
    order_date_key                  INT NOT NULL,
    order_time_key                  INT NOT NULL,
    customer_key                    BIGINT,
    shipping_geography_key          BIGINT,

    -- Order Identifiers (standard)
    order_id                        VARCHAR(50) NOT NULL,
    order_number                    VARCHAR(20),

    -- Financial Base (standard)
    subtotal_amount                 DECIMAL(18,2),
    shipping_amount                 DECIMAL(18,2),
    tax_amount                      DECIMAL(18,2),
    discount_amount                 DECIMAL(18,2),
    total_amount                    DECIMAL(18,2),
    refund_amount                   DECIMAL(18,2),
    net_amount                      DECIMAL(18,2),

    -- Payment Methods (configured)
    {% for pm in payment_methods %}
    payment_{{ pm.name }}_amount    DECIMAL(18,2),
    {% endfor %}
    payment_method_count            INT,

    -- Tax Types (configured)
    {% for tax in tax_types %}
    tax_{{ tax.name }}_rate         DECIMAL(5,4),
    tax_{{ tax.name }}_amount       DECIMAL(18,2),
    {% endfor %}

    -- Discount Categories (configured)
    {% for dc in discount_categories %}
    discount_{{ dc.name }}_code     VARCHAR(100),
    discount_{{ dc.name }}_amount   DECIMAL(18,2),
    {% endfor %}

    -- Shipping Carriers (configured)
    {% for sc in shipping_carriers %}
    shipping_{{ sc.name }}_amount   DECIMAL(18,2),
    {% endfor %}
    shipping_method_name            VARCHAR(255),

    -- Custom Fields (configured)
    {% for cf in custom_fields %}
    {{ cf.name }}                   {{ cf.data_type }},
    {% endfor %}

    -- Status Flags (standard)
    is_paid                         BOOLEAN,
    is_cancelled                    BOOLEAN,
    is_fulfilled                    BOOLEAN,
    has_discount                    BOOLEAN,

    -- ETL
    _loaded_at                      TIMESTAMP
)
DISTRIBUTE BY order_key
PARTITION BY order_date_key;
""")

    return template.render(
        schema=config['deployment']['database_schema'],
        payment_methods=config.get('payment_methods', []),
        tax_types=config.get('tax_types', []),
        discount_categories=config.get('discount_categories', []),
        shipping_carriers=config.get('shipping_carriers', []),
        custom_fields=config.get('custom_fields', [])
    )

def main():
    config = load_config('deployment_config.yaml')

    # Generate DDL
    ddl = generate_fact_order_ddl(config)

    # Write to file
    output_path = Path(f"ddl/{config['deployment']['name']}_fact_order.sql")
    output_path.parent.mkdir(exist_ok=True)
    output_path.write_text(ddl)

    print(f"Generated: {output_path}")

if __name__ == '__main__':
    main()
```

---

## Deployment Workflow

### New Customer Onboarding

```
1. DISCOVERY
   └── Identify payment methods, tax types, discount patterns
   └── Document Shopify metafields in use
   └── Understand reporting requirements

2. CONFIGURATION
   └── Create deployment_config.yaml
   └── Validate against Shopify store data

3. GENERATION
   └── Run schema generator → DDL scripts
   └── Run ETL generator → Transform scripts
   └── Review generated artifacts

4. DEPLOYMENT
   └── Create database schema
   └── Execute DDL scripts
   └── Deploy ETL jobs
   └── Configure scheduler

5. VALIDATION
   └── Run initial data load
   └── Verify column population
   └── Test reporting queries
```

### Adding New Payment Method (existing customer)

```
1. Update deployment_config.yaml:
   payment_methods:
     - name: afterpay
       display_name: "Afterpay"
       gateway_match: "afterpay"

2. Re-run schema generator (outputs ALTER TABLE)

3. Re-run ETL generator (updates pivot logic)

4. Deploy changes:
   - Execute ALTER TABLE
   - Deploy updated ETL
   - Backfill historical data (optional)
```

---

## Configuration Discovery

### Auto-Discovery Script

```python
"""
Discover configuration values from Shopify store.
Helps populate deployment_config.yaml for new customers.
"""

def discover_payment_methods(shopify_client) -> list:
    """Query unique payment gateways from historical orders."""
    query = """
    query {
      orders(first: 250, query: "created_at:>2024-01-01") {
        nodes {
          transactions(first: 10) {
            gateway
          }
        }
      }
    }
    """
    # Extract unique gateways
    gateways = set()
    for order in execute_query(query):
        for txn in order['transactions']:
            gateways.add(txn['gateway'])

    return [{'name': g.replace('-', '_'), 'gateway_match': g} for g in gateways]

def discover_tax_types(shopify_client) -> list:
    """Query unique tax names from historical orders."""
    # Similar pattern - extract unique tax titles
    pass

def discover_discount_patterns(shopify_client) -> list:
    """Analyze discount codes to identify patterns."""
    # Regex pattern detection on historical codes
    pass

def generate_config_template(shopify_client) -> dict:
    """Generate initial config from store discovery."""
    return {
        'payment_methods': discover_payment_methods(shopify_client),
        'tax_types': discover_tax_types(shopify_client),
        'discount_categories': discover_discount_patterns(shopify_client),
    }
```

---

## Comparison: Generic vs Configured

| Aspect | Generic (Current) | Configured (Productized) |
|--------|-------------------|--------------------------|
| Column names | `payment_1_gateway` | `payment_shopify_payments_amount` |
| Self-documenting | No | Yes |
| Data mixing | Possible (payment_1 could be different types) | No (dedicated column per type) |
| Schema changes | Manual | Generated from config |
| New customer setup | Copy and modify | Configure and generate |
| Reporting queries | Need CASE statements | Direct column access |
| Maintainability | Lower | Higher |

---

## Implementation Phases

### Phase 1: Core Configuration (Foundation)
- [ ] Define configuration schema (YAML structure) ← **Document complete**
- [ ] Document all configuration options ← **Document complete**
- [ ] Manual DDL based on config (no generator yet)
- [ ] Validate YAML structure with JSON Schema

**Configuration scope:**
- Deployment settings (name, store, schema, timezone)
- Payment methods (pivot columns)
- Tax types (pivot columns)
- Discount categories (pivot columns)
- Shipping carriers (pivot columns)

### Phase 2: Schema Generator (DDL)
- [ ] Build Jinja2-based DDL generator
- [ ] Generate all DWH tables:
  - [ ] fact_order (with all pivoted/tagged columns)
  - [ ] fact_order_line_item
  - [ ] dim_customer (with segments, tag flags)
  - [ ] dim_product (with category, named options)
  - [ ] dim_geography (with regions)
  - [ ] dim_date (with fiscal calendar)
  - [ ] dim_discount, dim_location, dim_time
- [ ] Add ALTER TABLE support for config changes
- [ ] Generate STG schema (simpler - direct from template)

### Phase 3: ETL Generator (Transform Logic)
- [ ] Payment pivot SQL (parameterized by gateway names)
- [ ] Tax pivot SQL (parameterized by tax titles)
- [ ] Discount categorization SQL (parameterized by patterns)
- [ ] Customer segment CASE logic
- [ ] Order tag flag derivation
- [ ] Customer tag flag derivation
- [ ] Region mapping CASE logic
- [ ] Product category mapping
- [ ] Fiscal calendar logic
- [ ] Overflow handling (4th payment → "other")

### Phase 4: Discovery & Validation
- [ ] Auto-discovery script for payment gateways
- [ ] Auto-discovery for tax types
- [ ] Discount code pattern analyzer
- [ ] Config validation tool (compare config vs actual data)
- [ ] Config drift detection (periodic re-scan)
- [ ] Unmatched data report (what's going to "other")

### Phase 5: Deployment Automation
- [ ] New customer onboarding script
- [ ] Schema migration generator (config diff → ALTER statements)
- [ ] Backfill script generator
- [ ] Config update workflow (validate → generate → deploy → backfill)
- [ ] Rollback capability

---

## Open Questions

### Deployment Model

1. **Version control for configs?**
   - Git repo per customer?
   - Central config database?
   - **Recommendation:** Git repo with customer branch or separate config directory per customer

2. **Multi-tenant vs single-tenant?**
   - Separate schema per customer (current assumption)?
   - Shared schema with customer_id column?
   - **Recommendation:** Single-tenant (separate schemas) for isolation and simpler queries

### Schema Evolution

3. **Schema migration strategy?**
   - How to handle config changes on live deployments?
   - Backfill historical data for new columns?
   - **Options:**
     - A) ALTER TABLE + backfill script
     - B) Recreate table with new structure + data migration
     - C) Versioned tables (fact_order_v1, fact_order_v2)

4. **Adding new payment methods mid-operation?**
   - Historical orders won't have the new column populated
   - Should we backfill from STG? (if STG retained)
   - **Recommendation:** Retain STG for lookback period, generate ALTER + backfill script

### Validation

5. **Config validation before deployment?**
   - Validate payment gateway names exist in Shopify data
   - Warn on unmatched transactions (data going to "other" bucket)
   - **Recommendation:** Auto-discovery comparison report

6. **Config drift detection?**
   - What happens when Shopify store adds new payment methods?
   - Periodic re-discovery and config update alerts?

### Business Logic

7. **Customer segment rule conflicts?**
   - What if a customer matches multiple segment rules?
   - **Current behavior:** First match wins (order matters in CASE)
   - **Alternative:** Priority field in config

8. **Tag pattern matching sensitivity?**
   - Case sensitive or insensitive?
   - Exact match vs contains?
   - **Recommendation:** ILIKE (case-insensitive contains) as default, configurable

### Performance

9. **Denormalization trade-offs?**
   - More denormalized = faster queries but larger tables
   - Should denormalization be configurable per use case?
   - **Recommendation:** Provide sensible defaults, allow override

10. **Pivot column limits?**
    - What happens when order has 4 payments but config allows 3?
    - **Options:**
      - A) Drop 4th payment (data loss)
      - B) Sum into "other" column
      - C) Fail ETL with error
    - **Recommendation:** Option B with logging

---

## Related Documents

- [schema-layered.md](schema-layered.md) - Base schema design
- [api-mapping.md](api-mapping.md) - Shopify API field mappings
- [implementation-guide.md](implementation-guide.md) - ETL implementation reference
