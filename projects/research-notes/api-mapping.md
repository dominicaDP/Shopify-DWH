# Shopify API → DWH Field Mapping

**Version:** 1.0
**Last Updated:** 2026-01-30

Complete field mapping from Shopify GraphQL Admin API to DWH schema.

---

## Quick Reference

| DWH Table | Shopify Source | API Scope |
|-----------|----------------|-----------|
| fact_order_line_item | Order.lineItems | read_orders |
| fact_order_header | Order | read_orders |
| dim_customer | Customer | read_customers |
| dim_product | Product, ProductVariant, InventoryItem | read_products, read_inventory |
| dim_order | Order | read_orders |
| dim_discount | DiscountCodeNode, DiscountApplication | read_discounts |
| dim_geography | Order.shippingAddress, Order.billingAddress | read_orders |
| dim_location | Location | read_locations |
| dim_date | Generated | N/A |

---

## fact_order_line_item

**Grain:** One row per line item per order
**Source:** `Order.lineItems`

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
**Source:** `Order`

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
**Source:** `Customer`

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
**Source:** `Product`, `ProductVariant`, `InventoryItem`
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
**Source:** `Order`

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
**Source:** `DiscountCodeNode`, `DiscountRedeemCode`, `Order.discountApplications`

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
**Source:** `Order.shippingAddress`, `Order.billingAddress`

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
**Source:** `Location`

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
**Source:** Generated (not from Shopify)

Pre-populate with date range covering historical data + future buffer.

---

## dim_time

**Type:** Conformed, pre-generated (24 rows)
**Source:** Generated (not from Shopify)

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

## GraphQL ID Handling

Shopify GraphQL IDs are in GID format:
```
gid://shopify/Order/1234567890
gid://shopify/Customer/9876543210
```

**ETL Transformation:**
```python
def extract_id(gid: str) -> str:
    """Extract numeric ID from Shopify GID."""
    return gid.split('/')[-1]

# Example:
# "gid://shopify/Order/1234567890" → "1234567890"
```

---

## MoneyBag Handling

All `*Set` financial fields return MoneyBag:

```graphql
totalPriceSet {
  shopMoney {
    amount         # Use this for DWH
    currencyCode   # Store in dim_order.currency
  }
  presentmentMoney {
    amount         # Customer's currency (not stored)
    currencyCode
  }
}
```

**ETL Rule:** Always use `shopMoney.amount` for financial fields.

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
