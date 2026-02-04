# Shopify DWH - Staging Schema Reference

**Version:** 2.0
**Last Updated:** 2026-02-04
**Schema:** SHOPIFY_STG

---

## Overview

The staging layer contains 16 tables that mirror the Shopify GraphQL API structure. Each table maps directly to a Shopify object or connection.

**Design Principles:**
- Field names match Shopify API (camelCase → snake_case)
- No transformations or business logic
- Row-based storage (one row per child object)
- All tables include `_extracted_at` timestamp

---

## Table Summary

| Table | Source API | Rows Per | Description |
|-------|-----------|----------|-------------|
| stg_orders | orders | Order | Order headers |
| stg_order_line_items | orders.lineItems | Line item | Products ordered |
| stg_order_transactions | orders.transactions | Payment | Payment records |
| stg_order_tax_lines | orders.taxLines | Tax type | Tax breakdown |
| stg_order_discount_applications | orders.discountApplications | Discount | Discounts applied |
| stg_order_shipping_lines | orders.shippingLines | Shipping method | Shipping details |
| stg_fulfillments | orders.fulfillments | Shipment | Fulfillment records |
| stg_fulfillment_line_items | fulfillments.lineItems | Item fulfilled | Items per shipment |
| stg_refunds | orders.refunds | Refund | Refund headers |
| stg_refund_line_items | refunds.refundLineItems | Item refunded | Refunded items |
| stg_customers | customers | Customer | Customer records |
| stg_products | products | Product | Product headers |
| stg_product_variants | productVariants | Variant | Product variants |
| stg_discount_codes | codeDiscountNodes | Discount code | Discount definitions |
| stg_locations | locations | Location | Fulfillment locations |
| stg_inventory_levels | inventoryLevels | Item × Location | Stock quantities |
| stg_abandoned_checkouts | abandonedCheckouts | Checkout | Abandoned carts |

---

## Order Domain Tables

### stg_orders

**Source:** `orders` query → `Order` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Shopify GID (raw) |
| name | name | VARCHAR(20) | Order number (#1001) |
| email | email | VARCHAR(255) | Customer email on order |
| created_at | createdAt | TIMESTAMP | Order creation time |
| processed_at | processedAt | TIMESTAMP | Payment processing time |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| cancelled_at | cancelledAt | TIMESTAMP | Cancellation time |
| closed_at | closedAt | TIMESTAMP | Order closed time |
| cancel_reason | cancelReason | VARCHAR(50) | Cancellation reason |
| currency_code | currencyCode | VARCHAR(5) | Shop currency |
| subtotal_price | subtotalPriceSet.shopMoney.amount | DECIMAL(18,2) | Subtotal |
| total_discounts | totalDiscountsSet.shopMoney.amount | DECIMAL(18,2) | Total discounts |
| total_tax | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | Total tax |
| total_shipping | totalShippingPriceSet.shopMoney.amount | DECIMAL(18,2) | Shipping cost |
| total_price | totalPriceSet.shopMoney.amount | DECIMAL(18,2) | Order total |
| total_refunded | totalRefundedSet.shopMoney.amount | DECIMAL(18,2) | Refunded amount |
| financial_status | displayFinancialStatus | VARCHAR(50) | Payment status |
| fulfillment_status | displayFulfillmentStatus | VARCHAR(50) | Fulfillment status |
| customer_id | customer.id | VARCHAR(50) | Customer GID |
| shipping_address_json | shippingAddress | TEXT | Full address JSON |
| billing_address_json | billingAddress | TEXT | Full address JSON |
| tags | tags | TEXT | Comma-separated tags |
| note | note | TEXT | Order notes |
| source_name | sourceName | VARCHAR(50) | Channel (web, pos, mobile) |
| landing_site | landingSite | TEXT | First URL customer landed on |
| referring_site | referringSite | TEXT | Referring URL |
| checkout_id | checkoutId | VARCHAR(50) | Associated checkout GID |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_order_line_items

**Source:** `orders` query → `Order.lineItems` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Line item GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| variant_id | variant.id | VARCHAR(50) | Product variant GID |
| product_id | variant.product.id | VARCHAR(50) | Product GID |
| title | title | VARCHAR(255) | Product title at time of sale |
| variant_title | variantTitle | VARCHAR(255) | Variant title |
| sku | sku | VARCHAR(100) | SKU |
| quantity | quantity | INT | Quantity ordered |
| current_quantity | currentQuantity | INT | Current quantity (after refunds) |
| unfulfilled_quantity | unfulfilledQuantity | INT | Unfulfilled quantity |
| unit_price | originalUnitPriceSet.shopMoney.amount | DECIMAL(18,2) | Unit price |
| total_price | originalTotalSet.shopMoney.amount | DECIMAL(18,2) | Line subtotal |
| total_discount | totalDiscountSet.shopMoney.amount | DECIMAL(18,2) | Line discount |
| discounted_total | discountedTotalSet.shopMoney.amount | DECIMAL(18,2) | Final line total |
| is_gift_card | isGiftCard | BOOLEAN | Gift card flag |
| taxable | taxable | BOOLEAN | Taxable flag |
| requires_shipping | requiresShipping | BOOLEAN | Requires shipping |
| fulfillable_quantity | fulfillableQuantity | INT | Quantity that can be fulfilled |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_order_transactions

**Source:** `orders` query → `Order.transactions` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Transaction GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| kind | kind | VARCHAR(20) | SALE, REFUND, CAPTURE, etc. |
| status | status | VARCHAR(20) | SUCCESS, PENDING, FAILURE, ERROR |
| gateway | gateway | VARCHAR(100) | Payment gateway name |
| amount | amountSet.shopMoney.amount | DECIMAL(18,2) | Transaction amount |
| currency_code | amountSet.shopMoney.currencyCode | VARCHAR(5) | Currency |
| created_at | createdAt | TIMESTAMP | Transaction time |
| processed_at | processedAt | TIMESTAMP | Processing time |
| error_code | errorCode | VARCHAR(50) | Error code if failed |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_order_tax_lines

**Source:** `orders` query → `Order.taxLines` array

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| line_number | (array index) | INT | Position in array (1, 2, 3...) |
| title | title | VARCHAR(100) | Tax name |
| rate | rate | DECIMAL(10,6) | Tax rate (0.15 = 15%) |
| price | priceSet.shopMoney.amount | DECIMAL(18,2) | Tax amount |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_order_discount_applications

**Source:** `orders` query → `Order.discountApplications` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| line_number | (array index) | INT | Position in array |
| discount_type | __typename | VARCHAR(50) | DiscountCodeApplication, ManualDiscountApplication, etc. |
| code | code | VARCHAR(100) | Discount code (if code-based) |
| title | title | VARCHAR(255) | Discount title |
| description | description | TEXT | Description |
| value_type | value.__typename | VARCHAR(20) | MoneyV2 or PricingPercentageValue |
| value_amount | value.amount | DECIMAL(18,2) | Fixed amount (if applicable) |
| value_percentage | value.percentage | DECIMAL(5,2) | Percentage (if applicable) |
| target_type | targetType | VARCHAR(20) | LINE_ITEM or SHIPPING_LINE |
| allocation_method | allocationMethod | VARCHAR(20) | ACROSS, EACH, ONE |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_order_shipping_lines

**Source:** `orders` query → `Order.shippingLines` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Shipping line GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| title | title | VARCHAR(255) | Shipping method name |
| code | code | VARCHAR(100) | Shipping method code |
| source | source | VARCHAR(100) | Shipping rate source |
| original_price | originalPriceSet.shopMoney.amount | DECIMAL(18,2) | Original shipping price |
| discounted_price | discountedPriceSet.shopMoney.amount | DECIMAL(18,2) | After discounts |
| carrier_identifier | carrierIdentifier | VARCHAR(100) | Carrier ID |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## Fulfillment Domain Tables

### stg_fulfillments

**Source:** `orders` query → `Order.fulfillments` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Fulfillment GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| status | status | VARCHAR(20) | SUCCESS, PENDING, CANCELLED, ERROR, FAILURE |
| created_at | createdAt | TIMESTAMP | Fulfillment creation time |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| tracking_number | trackingInfo.number | VARCHAR(255) | Tracking number |
| tracking_company | trackingInfo.company | VARCHAR(100) | Carrier name |
| tracking_url | trackingInfo.url | TEXT | Tracking URL |
| location_id | location.id | VARCHAR(50) | Fulfillment location GID |
| service | service.serviceName | VARCHAR(100) | Shipping service name |
| shipment_status | displayStatus | VARCHAR(50) | LABEL_PRINTED, LABEL_PURCHASED, etc. |
| total_quantity | totalQuantity | INT | Total items fulfilled |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_fulfillment_line_items

**Source:** `orders` query → `Order.fulfillments.fulfillmentLineItems` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| fulfillment_id | (parent fulfillment) | VARCHAR(50) | Parent fulfillment GID |
| line_item_id | lineItem.id | VARCHAR(50) | Original line item GID |
| quantity | quantity | INT | Quantity fulfilled in this shipment |
| original_total | originalTotalSet.shopMoney.amount | DECIMAL(18,2) | Original total for fulfilled items |
| discounted_total | discountedTotalPriceSet.shopMoney.amount | DECIMAL(18,2) | Discounted total for fulfilled items |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## Refund Domain Tables

### stg_refunds

**Source:** `orders` query → `Order.refunds` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Refund GID |
| order_id | (parent order) | VARCHAR(50) | Parent order GID |
| created_at | createdAt | TIMESTAMP | Refund creation time |
| note | note | TEXT | Refund note/reason |
| total_refunded | totalRefundedSet.shopMoney.amount | DECIMAL(18,2) | Total refund amount |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_refund_line_items

**Source:** `orders` query → `Order.refunds.refundLineItems` connection

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| refund_id | (parent refund) | VARCHAR(50) | Parent refund GID |
| line_item_id | lineItem.id | VARCHAR(50) | Original line item GID |
| quantity | quantity | INT | Quantity refunded |
| restock_type | restockType | VARCHAR(20) | NO_RESTOCK, CANCEL, RETURN, LEGACY_RESTOCK |
| location_id | location.id | VARCHAR(50) | Restock location GID |
| subtotal_amount | subtotalSet.shopMoney.amount | DECIMAL(18,2) | Line item subtotal refunded |
| total_tax_amount | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | Tax amount refunded |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## Customer Domain Tables

### stg_customers

**Source:** `customers` query → `Customer` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Customer GID |
| email | defaultEmailAddress.emailAddress | VARCHAR(255) | Primary email |
| phone | defaultPhoneNumber.phoneNumber | VARCHAR(50) | Primary phone |
| first_name | firstName | VARCHAR(100) | First name |
| last_name | lastName | VARCHAR(100) | Last name |
| email_marketing_state | defaultEmailAddress.marketingState | VARCHAR(20) | SUBSCRIBED, UNSUBSCRIBED, etc. |
| sms_marketing_state | defaultPhoneNumber.marketingState | VARCHAR(20) | SMS consent state |
| created_at | createdAt | TIMESTAMP | Account creation |
| updated_at | updatedAt | TIMESTAMP | Last update |
| number_of_orders | numberOfOrders | INT | Order count |
| amount_spent | amountSpent.amount | DECIMAL(18,2) | Lifetime spend |
| default_address_json | defaultAddress | TEXT | Default address JSON |
| tags | tags | TEXT | Comma-separated tags |
| note | note | TEXT | Customer notes |
| tax_exempt | taxExempt | BOOLEAN | Tax exempt flag |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## Product Domain Tables

### stg_products

**Source:** `products` query → `Product` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Product GID |
| title | title | VARCHAR(255) | Product title |
| handle | handle | VARCHAR(255) | URL handle |
| description | description | TEXT | Description |
| product_type | productType | VARCHAR(255) | Product type/category |
| vendor | vendor | VARCHAR(255) | Vendor name |
| status | status | VARCHAR(20) | ACTIVE, DRAFT, ARCHIVED |
| created_at | createdAt | TIMESTAMP | Creation time |
| updated_at | updatedAt | TIMESTAMP | Last update |
| published_at | publishedAt | TIMESTAMP | Publication time |
| tags | tags | TEXT | Comma-separated tags |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_product_variants

**Source:** `productVariants` query → `ProductVariant` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Variant GID |
| product_id | product.id | VARCHAR(50) | Parent product GID |
| title | title | VARCHAR(255) | Variant title |
| sku | sku | VARCHAR(100) | SKU |
| barcode | barcode | VARCHAR(100) | Barcode |
| price | price | DECIMAL(18,2) | Current price |
| compare_at_price | compareAtPrice | DECIMAL(18,2) | Compare at price |
| cost | inventoryItem.unitCost.amount | DECIMAL(18,2) | Unit cost |
| taxable | taxable | BOOLEAN | Taxable flag |
| requires_shipping | requiresShipping | BOOLEAN | Physical product |
| weight | weight | DECIMAL(10,2) | Weight |
| weight_unit | weightUnit | VARCHAR(10) | g, kg, lb, oz |
| option1 | selectedOptions[0].value | VARCHAR(255) | First option value |
| option2 | selectedOptions[1].value | VARCHAR(255) | Second option value |
| option3 | selectedOptions[2].value | VARCHAR(255) | Third option value |
| inventory_item_id | inventoryItem.id | VARCHAR(50) | Inventory item GID |
| created_at | createdAt | TIMESTAMP | Creation time |
| updated_at | updatedAt | TIMESTAMP | Last update |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## Discount Domain Tables

### stg_discount_codes

**Source:** `codeDiscountNodes` query → `DiscountCodeNode` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Discount node GID |
| code | codeDiscount.codes.nodes[].code | VARCHAR(100) | The discount code |
| title | codeDiscount.title | VARCHAR(255) | Discount title |
| discount_type | codeDiscount.__typename | VARCHAR(50) | DiscountCodeBasic, etc. |
| status | codeDiscount.status | VARCHAR(20) | ACTIVE, EXPIRED, SCHEDULED |
| value_type | customerGets.value.__typename | VARCHAR(30) | MoneyV2 or PricingPercentageValue |
| value_amount | customerGets.value.amount | DECIMAL(18,2) | Fixed amount |
| value_percentage | customerGets.value.percentage | DECIMAL(5,2) | Percentage |
| starts_at | codeDiscount.startsAt | TIMESTAMP | Start date |
| ends_at | codeDiscount.endsAt | TIMESTAMP | End date |
| usage_limit | codeDiscount.usageLimit | INT | Total usage limit |
| usage_count | codes.nodes[].asyncUsageCount | INT | Current usage |
| applies_once_per_customer | codeDiscount.appliesOncePerCustomer | BOOLEAN | Per-customer limit |
| created_at | codeDiscount.createdAt | TIMESTAMP | Creation time |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

## Location & Inventory Tables

### stg_locations

**Source:** `locations` query → `Location` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Location GID |
| name | name | VARCHAR(255) | Location name |
| address1 | address.address1 | VARCHAR(255) | Street address |
| address2 | address.address2 | VARCHAR(255) | Address line 2 |
| city | address.city | VARCHAR(100) | City |
| province | address.province | VARCHAR(100) | Province/State |
| province_code | address.provinceCode | VARCHAR(10) | Province code |
| country | address.country | VARCHAR(100) | Country |
| country_code | address.countryCode | VARCHAR(5) | Country code |
| zip | address.zip | VARCHAR(20) | Postal code |
| phone | address.phone | VARCHAR(50) | Phone number |
| is_active | isActive | BOOLEAN | Active flag |
| fulfills_online_orders | fulfillsOnlineOrders | BOOLEAN | Fulfills online orders |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

---

### stg_inventory_levels

**Source:** `inventoryLevels` query → `InventoryLevel` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| inventory_item_id | item.id | VARCHAR(50) | Inventory item GID |
| location_id | location.id | VARCHAR(50) | Location GID |
| available | quantities.available | INT | Available to sell |
| on_hand | quantities.on_hand | INT | Physically in stock |
| committed | quantities.committed | INT | Reserved for orders |
| incoming | quantities.incoming | INT | Expected from purchase orders |
| reserved | quantities.reserved | INT | Reserved for other reasons |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| snapshot_date | ETL | DATE | Snapshot date for historical tracking |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

**Note:** This table stores daily snapshots for inventory trend analysis.

---

### stg_abandoned_checkouts

**Source:** `abandonedCheckouts` query → `Checkout` object

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Checkout GID |
| created_at | createdAt | TIMESTAMP | Checkout creation time |
| updated_at | updatedAt | TIMESTAMP | Last update time |
| completed_at | completedAt | TIMESTAMP | Completion time (NULL if abandoned) |
| customer_id | customer.id | VARCHAR(50) | Customer GID (if logged in) |
| email | email | VARCHAR(255) | Customer email |
| phone | phone | VARCHAR(50) | Customer phone |
| subtotal_price | subtotalPriceSet.shopMoney.amount | DECIMAL(18,2) | Subtotal |
| total_tax | totalTaxSet.shopMoney.amount | DECIMAL(18,2) | Tax amount |
| total_price | totalPriceSet.shopMoney.amount | DECIMAL(18,2) | Total price |
| currency_code | currencyCode | VARCHAR(5) | Currency |
| abandoned_checkout_url | abandonedCheckoutUrl | TEXT | Recovery URL |
| line_items_count | lineItems.edges.length | INT | Number of line items |
| line_items_json | lineItems | TEXT | Line items JSON for analysis |
| shipping_address_json | shippingAddress | TEXT | Shipping address JSON |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

**Note:** Only checkouts where `completed_at IS NULL` are truly abandoned.

---

## Column Count Summary

| Table | Columns |
|-------|---------|
| stg_orders | 28 |
| stg_order_line_items | 19 |
| stg_order_transactions | 11 |
| stg_order_tax_lines | 6 |
| stg_order_discount_applications | 12 |
| stg_order_shipping_lines | 9 |
| stg_fulfillments | 13 |
| stg_fulfillment_line_items | 6 |
| stg_refunds | 6 |
| stg_refund_line_items | 8 |
| stg_customers | 16 |
| stg_products | 12 |
| stg_product_variants | 19 |
| stg_discount_codes | 15 |
| stg_locations | 14 |
| stg_inventory_levels | 10 |
| stg_abandoned_checkouts | 15 |
| **Total** | **~209** |
