# Shopify API → DWH Field Mapping

**Version:** 1.2
**Last Updated:** 2026-01-30

Complete field mapping from Shopify GraphQL Admin API to DWH schema.

---

## Understanding GraphQL Queries

Unlike REST APIs with multiple endpoints (`/orders`, `/products`, `/customers`), GraphQL uses a **single endpoint** for all data:

**Endpoint:** `POST https://{shop}.myshopify.com/admin/api/2024-01/graphql.json`

The **"GraphQL Query"** column in this document refers to the **query body** sent to this endpoint, not a URL path:

```
┌─────────────────────────────────────────────────────────────────┐
│  POST /admin/api/2024-01/graphql.json                          │
│                                                                 │
│  Body: {                                                        │
│    "query": "query { orders(first: 10) { nodes { id } } }"     │
│  }                     ↑                                        │
│                        └── This is what "GraphQL Query: orders" │
│                            refers to in the tables below        │
└─────────────────────────────────────────────────────────────────┘
```

**Key difference from REST:**
| REST | GraphQL |
|------|---------|
| `GET /orders.json` | `POST /graphql.json` with `query { orders { ... } }` |
| `GET /products.json` | `POST /graphql.json` with `query { products { ... } }` |
| Multiple endpoints | Single endpoint, different query bodies |

---

## Quick Reference

| DWH Table | GraphQL Query | Shopify Object | API Scope | Bulk Support |
|-----------|---------------|----------------|-----------|--------------|
| fact_order_line_item | `orders` | Order → lineItems | read_orders | ✓ Yes |
| fact_order_header | `orders` | Order | read_orders | ✓ Yes |
| dim_customer | `customers` | Customer | read_customers | ✓ Yes |
| dim_product | `productVariants` | ProductVariant → Product, InventoryItem | read_products, read_inventory | ✓ Yes |
| dim_order | `orders` | Order | read_orders | ✓ Yes |
| dim_discount | `codeDiscountNodes` | DiscountCodeNode | read_discounts | ✓ Yes |
| dim_geography | `orders` | Order.shippingAddress, Order.billingAddress | read_orders | ✓ Yes |
| dim_location | `locations` | Location | read_locations | ✗ No (small dataset) |
| dim_date | N/A | Generated | N/A | N/A |
| dim_time | N/A | Generated | N/A | N/A |

---

## fact_order_line_item

**Grain:** One row per line item per order
**GraphQL Query:** `orders` (with `lineItems` connection)
**Bulk Operation:** Yes - recommended for full sync
**Source Object:** `Order.lineItems`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| line_item_key | Generated | BIGINT | Surrogate PK |
| order_key | Generated | BIGINT | FK lookup from order_id |
| product_key | lineItem.variant.id | BIGINT | FK lookup from variant_id |
| customer_key | order.customer.id | BIGINT | FK lookup, nullable for guests |
| order_date_key | order.createdAt | INT | Transform to YYYYMMDD |
| order_time_key | order.createdAt | INT | Extract hour (0-23) |
| ship_address_key | order.shippingAddress | BIGINT | FK lookup from address hash |
| discount_key | order.discountApplications | BIGINT | FK lookup, 0 if no discount |
| order_id | order.id | VARCHAR(50) | Extract numeric from gid |
| order_name | order.name | VARCHAR(20) | e.g., "#1001" |
| line_item_id | lineItem.id | VARCHAR(50) | Extract numeric from gid |
| sku | lineItem.sku | VARCHAR(100) | |
| quantity | lineItem.quantity | INT | |
| unit_price | lineItem.originalUnitPriceSet.shopMoney.amount | DECIMAL(18,2) | |
| line_subtotal | lineItem.originalTotalSet.shopMoney.amount | DECIMAL(18,2) | |
| line_discount_amount | lineItem.totalDiscountSet.shopMoney.amount | DECIMAL(18,2) | |
| line_tax_amount | SUM(lineItem.taxLines[].priceSet.shopMoney.amount) | DECIMAL(18,2) | Aggregate from array |
| line_total | lineItem.discountedTotalSet.shopMoney.amount | DECIMAL(18,2) | |
| is_gift_card | lineItem.isGiftCard | BOOLEAN | |
| is_taxable | lineItem.taxable | BOOLEAN | |
| is_fulfilled | lineItem.unfulfilledQuantity == 0 | BOOLEAN | Derived |
| is_refunded | lineItem.currentQuantity < lineItem.quantity | BOOLEAN | Derived |
| _loaded_at | ETL timestamp | TIMESTAMP | |

---

## fact_order_header

**Grain:** One row per order
**GraphQL Query:** `orders`
**Bulk Operation:** Yes - recommended for full sync
**Source Object:** `Order`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| order_key | Generated | BIGINT | Surrogate PK |
| customer_key | customer.id | BIGINT | FK lookup |
| order_date_key | createdAt | INT | Transform to YYYYMMDD |
| order_time_key | createdAt | INT | Extract hour (0-23) |
| ship_address_key | shippingAddress | BIGINT | FK lookup |
| bill_address_key | billingAddress | BIGINT | FK lookup |
| order_id | id | VARCHAR(50) | Extract numeric from gid |
| order_name | name | VARCHAR(20) | |
| subtotal | subtotalPriceSet.shopMoney.amount | DECIMAL(18,2) | |
| total_discount | totalDiscountsSet.shopMoney.amount | DECIMAL(18,2) | |
| total_tax | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | |
| shipping_amount | totalShippingPriceSet.shopMoney.amount | DECIMAL(18,2) | |
| total_price | totalPriceSet.shopMoney.amount | DECIMAL(18,2) | |
| total_refunded | totalRefundedSet.shopMoney.amount | DECIMAL(18,2) | |
| net_payment | netPaymentSet.shopMoney.amount | DECIMAL(18,2) | |
| line_item_count | COUNT(lineItems) | INT | Computed |
| total_quantity | SUM(lineItems[].quantity) | INT | Computed |
| is_cancelled | cancelledAt IS NOT NULL | BOOLEAN | Derived |
| is_fulfilled | displayFulfillmentStatus == 'FULFILLED' | BOOLEAN | Derived |
| is_partially_fulfilled | displayFulfillmentStatus == 'PARTIALLY_FULFILLED' | BOOLEAN | Derived |
| _loaded_at | ETL timestamp | TIMESTAMP | |

---

## dim_customer

**Type:** SCD Type 1
**GraphQL Query:** `customers`
**Bulk Operation:** Yes - recommended for full sync
**Source Object:** `Customer`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| customer_key | Generated | BIGINT | Surrogate PK |
| customer_id | id | VARCHAR(50) | Extract numeric from gid |
| email | defaultEmailAddress.emailAddress | VARCHAR(255) | ⚠️ Use new field, not deprecated `email` |
| first_name | firstName | VARCHAR(100) | |
| last_name | lastName | VARCHAR(100) | |
| phone | defaultPhoneNumber.phoneNumber | VARCHAR(50) | ⚠️ Use new field, not deprecated `phone` |
| accepts_marketing | defaultEmailAddress.marketingState | BOOLEAN | TRUE if SUBSCRIBED or PENDING |
| created_at | createdAt | TIMESTAMP | |
| order_count | numberOfOrders | INT | |
| total_spent | amountSpent.amount | DECIMAL(18,2) | MoneyV2 type |
| default_country | defaultAddress.country | VARCHAR(100) | |
| default_province | defaultAddress.province | VARCHAR(100) | |
| tags | tags | VARCHAR(1000) | Join array with commas |
| _loaded_at | ETL timestamp | TIMESTAMP | |

**Deprecated Fields to Avoid:**
- ❌ `email` → ✓ `defaultEmailAddress.emailAddress`
- ❌ `phone` → ✓ `defaultPhoneNumber.phoneNumber`
- ❌ `emailMarketingConsent` → ✓ `defaultEmailAddress.marketingState`

---

## dim_product

**Type:** SCD Type 1
**GraphQL Query:** `productVariants` (primary) or `products` with variants connection
**Bulk Operation:** Yes - recommended for full sync
**Source Objects:** `ProductVariant` → `Product`, `InventoryItem`
**Grain:** One row per variant

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| product_key | Generated | BIGINT | Surrogate PK |
| product_id | product.id | VARCHAR(50) | |
| variant_id | variant.id | VARCHAR(50) | |
| sku | variant.sku | VARCHAR(100) | |
| title | product.title | VARCHAR(255) | |
| variant_title | variant.title | VARCHAR(255) | |
| option1 | variant.selectedOptions[0].value | VARCHAR(255) | First option (e.g., Size) |
| option2 | variant.selectedOptions[1].value | VARCHAR(255) | Second option (e.g., Color) |
| option3 | variant.selectedOptions[2].value | VARCHAR(255) | Third option |
| barcode | variant.barcode | VARCHAR(100) | |
| product_type | product.productType | VARCHAR(255) | |
| vendor | product.vendor | VARCHAR(255) | |
| price | variant.price | DECIMAL(18,2) | |
| compare_at_price | variant.compareAtPrice | DECIMAL(18,2) | |
| cost | variant.inventoryItem.unitCost.amount | DECIMAL(18,2) | ⚠️ Requires inventoryItem traversal |
| taxable | variant.taxable | BOOLEAN | |
| requires_shipping | variant.requiresShipping | BOOLEAN | |
| weight | variant.weight | DECIMAL(10,2) | |
| weight_unit | variant.weightUnit | VARCHAR(10) | |
| tags | product.tags | VARCHAR(1000) | Join array with commas |
| status | product.status | VARCHAR(20) | ACTIVE, ARCHIVED, DRAFT |
| created_at | product.createdAt | TIMESTAMP | |
| _loaded_at | ETL timestamp | TIMESTAMP | |

**Cost Data Path:**
```
Product → variants → inventoryItem → unitCost { amount, currencyCode }
```

---

## dim_order

**Type:** SCD Type 1
**GraphQL Query:** `orders`
**Bulk Operation:** Yes - extracted alongside fact_order tables
**Source Object:** `Order`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| order_key | Generated | BIGINT | Surrogate PK |
| order_id | id | VARCHAR(50) | |
| order_name | name | VARCHAR(20) | |
| financial_status | displayFinancialStatus | VARCHAR(50) | |
| fulfillment_status | displayFulfillmentStatus | VARCHAR(50) | |
| cancel_reason | cancelReason | VARCHAR(255) | |
| source_name | channelInformation.channelDefinition.handle | VARCHAR(50) | |
| currency | currencyCode | VARCHAR(5) | Shop currency |
| processed_at | processedAt | TIMESTAMP | |
| cancelled_at | cancelledAt | TIMESTAMP | |
| closed_at | closedAt | TIMESTAMP | |
| tags | tags | VARCHAR(1000) | Join array with commas |
| _loaded_at | ETL timestamp | TIMESTAMP | |

---

## dim_discount

**Type:** SCD Type 1
**GraphQL Query:** `codeDiscountNodes`
**Bulk Operation:** Yes - recommended for full sync
**Source Objects:** `DiscountCodeNode` → `DiscountRedeemCode`, `Order.discountApplications`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| discount_key | Generated | BIGINT | Surrogate PK |
| discount_id | DiscountCodeNode.id | VARCHAR(50) | Extract numeric from gid |
| discount_code | DiscountRedeemCode.code | VARCHAR(100) | The actual code |
| title | codeDiscount.title | VARCHAR(255) | Human-readable name |
| discount_type | codeDiscount.__typename | VARCHAR(50) | basic, bxgy, free_shipping, app |
| status | codeDiscount.status | VARCHAR(20) | ACTIVE, EXPIRED, SCHEDULED |
| value | customerGets.value.amount OR .percentage | DECIMAL(18,2) | |
| value_type | MoneyV2 vs PricingPercentageValue | VARCHAR(20) | fixed_amount or percentage |
| target_type | DiscountApplication.targetType | VARCHAR(50) | LINE_ITEM or SHIPPING_LINE |
| allocation_method | DiscountApplication.allocationMethod | VARCHAR(20) | ACROSS, EACH, ONE |
| starts_at | codeDiscount.startsAt | TIMESTAMP | |
| ends_at | codeDiscount.endsAt | TIMESTAMP | |
| usage_limit | codeDiscount.usageLimit | INT | NULL = unlimited |
| usage_count | DiscountRedeemCode.asyncUsageCount | INT | Updated asynchronously |
| applies_once_per_customer | codeDiscount.appliesOncePerCustomer | BOOLEAN | |
| created_at | codeDiscount.createdAt | TIMESTAMP | |
| _loaded_at | ETL timestamp | TIMESTAMP | |

**Discount Code Types:**
- `DiscountCodeBasic` - Fixed amount or percentage
- `DiscountCodeBxgy` - Buy X Get Y
- `DiscountCodeFreeShipping` - Free shipping
- `DiscountCodeApp` - App-defined

**Type Mapping:**
```python
def map_discount_type(typename: str) -> str:
    return {
        'DiscountCodeBasic': 'basic',
        'DiscountCodeBxgy': 'bxgy',
        'DiscountCodeFreeShipping': 'free_shipping',
        'DiscountCodeApp': 'app'
    }.get(typename, 'unknown')
```

**ETL Query Example:**
```graphql
query {
  codeDiscountNodes(first: 100) {
    nodes {
      id
      codeDiscount {
        ... on DiscountCodeBasic {
          __typename
          title
          status
          startsAt
          endsAt
          usageLimit
          appliesOncePerCustomer
          createdAt
          codes(first: 10) {
            nodes {
              code
              asyncUsageCount
            }
          }
          customerGets {
            value {
              ... on MoneyV2 { amount currencyCode }
              ... on PricingPercentageValue { percentage }
            }
          }
        }
        ... on DiscountCodeBxgy {
          __typename
          title
          status
          startsAt
          endsAt
          usageLimit
          createdAt
          codes(first: 10) {
            nodes {
              code
              asyncUsageCount
            }
          }
        }
        ... on DiscountCodeFreeShipping {
          __typename
          title
          status
          startsAt
          endsAt
          usageLimit
          createdAt
          codes(first: 10) {
            nodes {
              code
              asyncUsageCount
            }
          }
        }
      }
    }
  }
}
```

---

## dim_geography

**Type:** SCD Type 1
**GraphQL Query:** `orders` (extracted from address fields)
**Bulk Operation:** Yes - extracted alongside order data
**Source Objects:** `Order.shippingAddress`, `Order.billingAddress`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| geography_key | Generated | BIGINT | Surrogate PK |
| address_hash | Generated | VARCHAR(64) | Hash for deduplication |
| city | city | VARCHAR(255) | |
| province | province | VARCHAR(255) | |
| province_code | provinceCode | VARCHAR(10) | |
| country | country | VARCHAR(100) | |
| country_code | countryCodeV2 | VARCHAR(5) | Use V2 field |
| postal_code | zip | VARCHAR(20) | |
| latitude | latitude | DECIMAL(10,6) | |
| longitude | longitude | DECIMAL(10,6) | |
| _loaded_at | ETL timestamp | TIMESTAMP | |

---

## dim_location

**Type:** SCD Type 1
**GraphQL Query:** `locations`
**Bulk Operation:** No - small dataset, paginated query sufficient
**Source Object:** `Location`

| DWH Field | Shopify API Field | Type | Notes |
|-----------|-------------------|------|-------|
| location_key | Generated | BIGINT | Surrogate PK |
| location_id | id | VARCHAR(50) | |
| name | name | VARCHAR(255) | |
| address1 | address.address1 | VARCHAR(255) | |
| address2 | address.address2 | VARCHAR(255) | |
| city | address.city | VARCHAR(100) | |
| province | address.province | VARCHAR(100) | |
| province_code | address.provinceCode | VARCHAR(10) | |
| country | address.country | VARCHAR(100) | |
| country_code | address.countryCode | VARCHAR(5) | |
| zip | address.zip | VARCHAR(20) | |
| phone | address.phone | VARCHAR(50) | |
| is_active | isActive | BOOLEAN | |
| fulfills_online_orders | fulfillsOnlineOrders | BOOLEAN | |
| _loaded_at | ETL timestamp | TIMESTAMP | |

---

## dim_date

**Type:** Conformed, pre-generated
**GraphQL Query:** N/A - generated locally
**Bulk Operation:** N/A
**Source:** ETL script generates rows

Pre-populate with date range covering historical data + future buffer (e.g., 2020-01-01 to 2030-12-31).

---

## dim_time

**Type:** Conformed, pre-generated (24 rows)
**GraphQL Query:** N/A - generated locally
**Bulk Operation:** N/A
**Source:** ETL script generates 24 static rows (hours 0-23)

| DWH Field | Source | Type | Notes |
|-----------|--------|------|-------|
| time_key | Generated | INT | 0-23 (hour of day) |
| hour_24 | Generated | INT | 0-23 |
| hour_12 | Generated | INT | 1-12 |
| am_pm | Generated | VARCHAR(2) | AM or PM |
| hour_label | Generated | VARCHAR(10) | "12:00 AM", "1:00 PM"... |
| day_part | Generated | VARCHAR(15) | Morning, Afternoon, Evening, Night |
| day_part_order | Generated | INT | Sort order (1-4) |
| is_business_hours | Generated | BOOLEAN | 9:00-17:00 default |

**ETL Derivation:**
```python
def extract_time_key(created_at: str) -> int:
    """Extract hour from ISO timestamp for dim_time lookup."""
    # created_at format: "2026-01-30T14:35:22Z"
    from datetime import datetime
    dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
    return dt.hour  # Returns 0-23

# Example:
# "2026-01-30T14:35:22Z" → 14
```

**Note:** Consider timezone conversion if shop timezone differs from UTC.

---

## Transformations Reference

This section documents all data transformations required between Shopify source and Exasol destination.

### Quick Transformation Matrix

| Transformation | Shopify Source | Exasol Target | Function |
|----------------|----------------|---------------|----------|
| GID extraction | `gid://shopify/Order/123` | `123` | `extract_id()` |
| Date key | `2026-01-30T14:35:22Z` | `20260130` | `to_date_key()` |
| Time key | `2026-01-30T14:35:22Z` | `14` | `to_time_key()` |
| Money extraction | `{ amount: "99.95" }` | `99.95` | `to_decimal()` |
| Array to string | `["tag1", "tag2"]` | `"tag1,tag2"` | `join_array()` |
| Boolean derivation | `unfulfilledQuantity: 0` | `TRUE` | Business logic |
| Address hash | Address fields | `SHA256 hash` | `hash_address()` |
| Null handling | `null` | Default value | `coalesce()` |
| Marketing state | `SUBSCRIBED` | `TRUE` | `map_marketing()` |
| Discount type | `DiscountCodeBasic` | `basic` | `map_discount_type()` |

---

### 1. GID Extraction

Shopify GraphQL IDs use Global ID format. Extract the numeric portion for storage.

**Source Format:**
```
gid://shopify/Order/1234567890
gid://shopify/Customer/9876543210
gid://shopify/ProductVariant/44567890123
```

**Transformation:**
```python
def extract_id(gid: str) -> str:
    """Extract numeric ID from Shopify GID."""
    if gid is None:
        return None
    return gid.split('/')[-1]

# Examples:
# "gid://shopify/Order/1234567890" → "1234567890"
# "gid://shopify/Customer/9876543210" → "9876543210"
# None → None
```

**Applies to:** All `*_id` fields (order_id, customer_id, product_id, variant_id, etc.)

---

### 2. Date Key Transformation

Convert ISO 8601 timestamps to integer date keys for dim_date lookup.

**Source Format:** `2026-01-30T14:35:22Z` (ISO 8601 with timezone)

**Transformation:**
```python
from datetime import datetime

def to_date_key(iso_timestamp: str) -> int:
    """Convert ISO timestamp to YYYYMMDD integer."""
    if iso_timestamp is None:
        return None
    dt = datetime.fromisoformat(iso_timestamp.replace('Z', '+00:00'))
    return int(dt.strftime('%Y%m%d'))

# Examples:
# "2026-01-30T14:35:22Z" → 20260130
# "2026-12-25T00:00:00Z" → 20261225
# None → None
```

**Applies to:** order_date_key, ship_date_key, etc.

---

### 3. Time Key Extraction

Extract hour from timestamp for dim_time lookup.

**Transformation:**
```python
from datetime import datetime

def to_time_key(iso_timestamp: str) -> int:
    """Extract hour (0-23) from ISO timestamp."""
    if iso_timestamp is None:
        return None
    dt = datetime.fromisoformat(iso_timestamp.replace('Z', '+00:00'))
    return dt.hour

# Examples:
# "2026-01-30T14:35:22Z" → 14
# "2026-01-30T00:05:00Z" → 0
# "2026-01-30T23:59:59Z" → 23
```

**Timezone Note:** Consider converting to shop timezone before extraction if needed.

**Applies to:** order_time_key

---

### 4. Money Extraction

Extract decimal amount from Shopify MoneyV2/MoneyBag objects.

**Source Format (MoneyBag):**
```json
{
  "shopMoney": { "amount": "99.95", "currencyCode": "ZAR" },
  "presentmentMoney": { "amount": "5.50", "currencyCode": "USD" }
}
```

**Transformation:**
```python
from decimal import Decimal

def to_decimal(money_bag: dict, use_shop_money: bool = True) -> Decimal:
    """Extract amount from MoneyBag, defaulting to shopMoney."""
    if money_bag is None:
        return Decimal('0.00')

    key = 'shopMoney' if use_shop_money else 'presentmentMoney'
    money = money_bag.get(key, {})
    amount_str = money.get('amount', '0.00')
    return Decimal(amount_str)

# Examples:
# {"shopMoney": {"amount": "99.95"}} → Decimal('99.95')
# {"shopMoney": {"amount": "0.00"}} → Decimal('0.00')
# None → Decimal('0.00')
```

**Rule:** Always use `shopMoney` (merchant's base currency) for DWH.

**Applies to:** All financial fields (unit_price, line_total, total_price, etc.)

---

### 5. Array to String

Convert Shopify arrays to comma-separated strings for storage.

**Transformation:**
```python
def join_array(arr: list, separator: str = ',') -> str:
    """Join array elements into string."""
    if arr is None or len(arr) == 0:
        return None
    return separator.join(str(item) for item in arr)

# Examples:
# ["electronics", "mobile", "accessories"] → "electronics,mobile,accessories"
# ["single"] → "single"
# [] → None
# None → None
```

**Applies to:** tags fields on Customer, Product, Order

---

### 6. Boolean Derivation

Derive boolean flags from source data using business logic.

**Transformations:**
```python
def is_fulfilled(line_item: dict) -> bool:
    """Line item is fulfilled when no unfulfilled quantity remains."""
    return line_item.get('unfulfilledQuantity', 0) == 0

def is_refunded(line_item: dict) -> bool:
    """Line item is refunded when current quantity < original quantity."""
    current = line_item.get('currentQuantity', 0)
    original = line_item.get('quantity', 0)
    return current < original

def is_cancelled(order: dict) -> bool:
    """Order is cancelled when cancelledAt timestamp exists."""
    return order.get('cancelledAt') is not None

def is_order_fulfilled(order: dict) -> bool:
    """Order is fully fulfilled based on status."""
    return order.get('displayFulfillmentStatus') == 'FULFILLED'

def is_partially_fulfilled(order: dict) -> bool:
    """Order is partially fulfilled based on status."""
    return order.get('displayFulfillmentStatus') == 'PARTIALLY_FULFILLED'
```

**Applies to:** is_fulfilled, is_refunded, is_cancelled, is_partially_fulfilled

---

### 7. Address Hash Generation

Generate deterministic hash for dim_geography deduplication.

**Transformation:**
```python
import hashlib

def hash_address(address: dict) -> str:
    """Generate SHA256 hash from address components for deduplication."""
    if address is None:
        return None

    # Normalize and concatenate address components
    components = [
        (address.get('city') or '').lower().strip(),
        (address.get('province') or '').lower().strip(),
        (address.get('provinceCode') or '').upper().strip(),
        (address.get('country') or '').lower().strip(),
        (address.get('countryCodeV2') or '').upper().strip(),
        (address.get('zip') or '').upper().strip(),
    ]

    hash_input = '|'.join(components)
    return hashlib.sha256(hash_input.encode('utf-8')).hexdigest()

# Example:
# {"city": "Cape Town", "province": "Western Cape", "countryCodeV2": "ZA", "zip": "8001"}
# → "a1b2c3d4..." (64-char hex string)
```

**Applies to:** address_hash in dim_geography

---

### 8. Null Handling & Defaults

Handle missing/null values with appropriate defaults.

**Transformation:**
```python
def coalesce(*values, default=None):
    """Return first non-None value, or default."""
    for v in values:
        if v is not None:
            return v
    return default

# Field-specific defaults
DEFAULT_VALUES = {
    'discount_key': 0,           # FK to "No Discount" row
    'customer_key': None,        # Allow NULL for guest orders
    'quantity': 0,
    'line_discount_amount': Decimal('0.00'),
    'total_refunded': Decimal('0.00'),
    'tags': None,
    'cancel_reason': None,
}

def apply_default(field_name: str, value):
    """Apply field-specific default if value is None."""
    if value is not None:
        return value
    return DEFAULT_VALUES.get(field_name)
```

**Applies to:** All fields with potential null values

---

### 9. Marketing State Mapping

Convert Shopify marketing consent states to boolean.

**Source Values:** `SUBSCRIBED`, `PENDING`, `UNSUBSCRIBED`, `NOT_SUBSCRIBED`, `REDACTED`, `INVALID`

**Transformation:**
```python
def map_marketing_state(state: str) -> bool:
    """Map marketing state to boolean accepts_marketing flag."""
    # TRUE if actively subscribed or pending confirmation
    return state in ('SUBSCRIBED', 'PENDING')

# Examples:
# "SUBSCRIBED" → True
# "PENDING" → True
# "UNSUBSCRIBED" → False
# "NOT_SUBSCRIBED" → False
# None → False
```

**Applies to:** accepts_marketing in dim_customer

---

### 10. Discount Type Mapping

Map Shopify discount type names to friendly codes.

**Transformation:**
```python
def map_discount_type(typename: str) -> str:
    """Map GraphQL __typename to friendly discount type."""
    type_map = {
        'DiscountCodeBasic': 'basic',
        'DiscountCodeBxgy': 'bxgy',
        'DiscountCodeFreeShipping': 'free_shipping',
        'DiscountCodeApp': 'app',
    }
    return type_map.get(typename, 'unknown')

# Examples:
# "DiscountCodeBasic" → "basic"
# "DiscountCodeBxgy" → "bxgy"
# "DiscountCodeFreeShipping" → "free_shipping"
```

**Applies to:** discount_type in dim_discount

---

### 11. Surrogate Key Generation

Generate surrogate keys for dimension and fact tables.

**Strategy Options:**

```python
# Option A: Sequence-based (recommended for Exasol)
# Use Exasol IDENTITY columns or sequences
# CREATE TABLE dim_customer (
#     customer_key BIGINT IDENTITY PRIMARY KEY,
#     ...
# )

# Option B: Hash-based (for deterministic keys)
def generate_surrogate_key(natural_key: str, table_name: str) -> int:
    """Generate deterministic surrogate key from natural key."""
    import hashlib
    hash_input = f"{table_name}:{natural_key}"
    hash_bytes = hashlib.md5(hash_input.encode()).digest()
    # Use first 8 bytes as BIGINT
    return int.from_bytes(hash_bytes[:8], byteorder='big', signed=True)

# Option C: Lookup table (for SCD Type 1)
# Maintain mapping table: natural_key → surrogate_key
# Lookup existing or generate new on insert
```

**Recommendation:** Use Exasol IDENTITY columns for simplicity. Maintain lookup during ETL for FK resolution.

---

### 12. Tax Line Aggregation

Aggregate multiple tax lines into single amount.

**Source:** Array of tax lines, each with amount

**Transformation:**
```python
from decimal import Decimal

def aggregate_tax_lines(tax_lines: list) -> Decimal:
    """Sum all tax line amounts."""
    if not tax_lines:
        return Decimal('0.00')

    total = Decimal('0.00')
    for tax_line in tax_lines:
        price_set = tax_line.get('priceSet', {})
        shop_money = price_set.get('shopMoney', {})
        amount = Decimal(shop_money.get('amount', '0.00'))
        total += amount

    return total

# Example:
# [{"priceSet": {"shopMoney": {"amount": "10.00"}}},
#  {"priceSet": {"shopMoney": {"amount": "5.00"}}}]
# → Decimal('15.00')
```

**Applies to:** line_tax_amount in fact_order_line_item

---

### 13. Selected Options Extraction

Extract variant options from selectedOptions array.

**Source:**
```json
{
  "selectedOptions": [
    {"name": "Size", "value": "Large"},
    {"name": "Color", "value": "Blue"},
    {"name": "Material", "value": "Cotton"}
  ]
}
```

**Transformation:**
```python
def extract_options(selected_options: list) -> tuple:
    """Extract up to 3 options from selectedOptions array."""
    options = [None, None, None]
    if selected_options:
        for i, opt in enumerate(selected_options[:3]):
            options[i] = opt.get('value')
    return tuple(options)

# Example:
# [{"name": "Size", "value": "Large"}, {"name": "Color", "value": "Blue"}]
# → ("Large", "Blue", None)
```

**Applies to:** option1, option2, option3 in dim_product

---

## GraphQL Query Examples

### Orders Query (for fact_order_*, dim_order, dim_geography)
```graphql
query GetOrders($cursor: String) {
  orders(first: 100, after: $cursor, query: "updated_at:>2026-01-01") {
    pageInfo { hasNextPage endCursor }
    nodes {
      id
      name
      createdAt
      processedAt
      cancelledAt
      closedAt
      cancelReason
      displayFinancialStatus
      displayFulfillmentStatus
      currencyCode
      tags
      subtotalPriceSet { shopMoney { amount currencyCode } }
      totalPriceSet { shopMoney { amount currencyCode } }
      totalDiscountsSet { shopMoney { amount currencyCode } }
      totalTaxSet { shopMoney { amount currencyCode } }
      totalShippingPriceSet { shopMoney { amount currencyCode } }
      totalRefundedSet { shopMoney { amount currencyCode } }
      netPaymentSet { shopMoney { amount currencyCode } }
      customer { id }
      shippingAddress { city province provinceCode country countryCodeV2 zip latitude longitude }
      billingAddress { city province provinceCode country countryCodeV2 zip latitude longitude }
      channelInformation { channelDefinition { handle } }
      lineItems(first: 50) {
        nodes {
          id
          sku
          quantity
          isGiftCard
          taxable
          currentQuantity
          unfulfilledQuantity
          originalUnitPriceSet { shopMoney { amount } }
          originalTotalSet { shopMoney { amount } }
          totalDiscountSet { shopMoney { amount } }
          discountedTotalSet { shopMoney { amount } }
          taxLines { priceSet { shopMoney { amount } } }
          variant { id }
        }
      }
      discountApplications(first: 10) {
        nodes {
          targetType
          allocationMethod
          value {
            ... on MoneyV2 { amount currencyCode }
            ... on PricingPercentageValue { percentage }
          }
        }
      }
    }
  }
}
```

### Customers Query (for dim_customer)
```graphql
query GetCustomers($cursor: String) {
  customers(first: 100, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    nodes {
      id
      firstName
      lastName
      createdAt
      numberOfOrders
      amountSpent { amount currencyCode }
      tags
      defaultEmailAddress { emailAddress marketingState }
      defaultPhoneNumber { phoneNumber marketingState }
      defaultAddress { country province city }
    }
  }
}
```

### Product Variants Query (for dim_product)
```graphql
query GetProductVariants($cursor: String) {
  productVariants(first: 100, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    nodes {
      id
      sku
      title
      barcode
      price
      compareAtPrice
      taxable
      requiresShipping
      weight
      weightUnit
      selectedOptions { name value }
      inventoryItem { unitCost { amount currencyCode } }
      product {
        id
        title
        productType
        vendor
        status
        tags
        createdAt
      }
    }
  }
}
```

### Locations Query (for dim_location)
```graphql
query GetLocations {
  locations(first: 50) {
    nodes {
      id
      name
      isActive
      fulfillsOnlineOrders
      address {
        address1
        address2
        city
        province
        provinceCode
        country
        countryCode
        zip
        phone
      }
    }
  }
}
```

---

## Required API Scopes

```
read_products      # Products, variants
read_inventory     # InventoryItem (for cost), InventoryLevel
read_orders        # Orders, line items, fulfillments
read_customers     # Customers
read_discounts     # Discount codes
read_locations     # Fulfillment locations
```

---

## Deprecated Fields Reference

| Object | Deprecated | Use Instead |
|--------|------------|-------------|
| Customer | email | defaultEmailAddress.emailAddress |
| Customer | phone | defaultPhoneNumber.phoneNumber |
| Customer | emailMarketingConsent | defaultEmailAddress.marketingState |
| Customer | smsMarketingConsent | defaultPhoneNumber.marketingState |
| Customer | addresses | defaultAddress |
| Order | totalPrice | totalPriceSet |
| Order | subtotalPrice | subtotalPriceSet |
| Order | totalDiscounts | totalDiscountsSet |
| Order | totalTax | totalTaxSet |
| Order | totalRefunded | totalRefundedSet |
| Fulfillment | status: OPEN | (deprecated) |
| Fulfillment | status: PENDING | (deprecated) |
