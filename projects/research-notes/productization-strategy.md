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
```

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

    -- ETL
    _loaded_at                      TIMESTAMP
)
DISTRIBUTE BY order_key
PARTITION BY order_date_key;
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

### Phase 1: Static Configuration (Current Sprint)
- [ ] Define configuration schema (YAML structure)
- [ ] Document configuration options
- [ ] Manual DDL based on config (no generator yet)

### Phase 2: Schema Generator
- [ ] Build Jinja2-based DDL generator
- [ ] Generate fact_order, fact_order_line_item
- [ ] Add ALTER TABLE support for changes

### Phase 3: ETL Generator
- [ ] Parameterized pivot SQL generation
- [ ] Configuration-driven transform logic
- [ ] Validation against config

### Phase 4: Discovery & Tooling
- [ ] Auto-discovery from Shopify store
- [ ] Config validation tool
- [ ] Deployment automation

---

## Open Questions

1. **Version control for configs?**
   - Git repo per customer?
   - Central config database?

2. **Schema migration strategy?**
   - How to handle config changes on live deployments?
   - Backfill historical data for new columns?

3. **Config validation?**
   - Validate against Shopify store before deployment?
   - Warn on unmatched transactions?

4. **Multi-tenant vs single-tenant?**
   - Separate schema per customer (current assumption)?
   - Shared schema with customer_id column?

---

## Related Documents

- [schema-layered.md](schema-layered.md) - Base schema design
- [api-mapping.md](api-mapping.md) - Shopify API field mappings
- [implementation-guide.md](implementation-guide.md) - ETL implementation reference
