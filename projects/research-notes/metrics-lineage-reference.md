# Metrics Lineage Reference

**Version:** 1.0
**Last Updated:** 2026-02-04
**Purpose:** Complete traceability for all 57 ecommerce metrics from report to API field

---

## How to Use This Document

Each metric includes:
- **Formula**: How to calculate
- **DWH**: Data warehouse table.field
- **STG**: Staging table.field
- **API**: Shopify GraphQL field path
- **Notes**: Special considerations

**Lineage Direction:** Report → Metric → DWH → STG → API

---

## 1. Sales & Revenue Metrics (8)

### 1.1 Gross Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Total revenue before discounts, refunds |
| **Formula** | `SUM(gross_amount)` |
| **Granularity** | Line item level, aggregate to order/day/product |
| **DWH Table** | `fact_order_line_item` |
| **DWH Field** | `gross_amount` |
| **STG Table** | `stg_order_line_items` |
| **STG Field** | `total_price` |
| **API Path** | `orders.lineItems.edges.node.originalTotalSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | Use `originalTotalSet` not deprecated `originalTotal` |

---

### 1.2 Net Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue after line-level discounts |
| **Formula** | `SUM(net_amount)` |
| **Granularity** | Line item level |
| **DWH Table** | `fact_order_line_item` |
| **DWH Field** | `net_amount` |
| **STG Table** | `stg_order_line_items` |
| **STG Field** | `discounted_total` |
| **API Path** | `orders.lineItems.edges.node.discountedTotalSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | This is post-discount, pre-tax amount |

---

### 1.3 Total Revenue (Order Level)

| Attribute | Value |
|-----------|-------|
| **Definition** | Final order total including tax and shipping |
| **Formula** | `SUM(total_amount)` |
| **Granularity** | Order level |
| **DWH Table** | `fact_order` |
| **DWH Field** | `total_amount` |
| **STG Table** | `stg_orders` |
| **STG Field** | `total_price` |
| **API Path** | `orders.edges.node.totalPriceSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | Includes tax, shipping; use for AOV calculations |

---

### 1.4 Average Order Value (AOV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average revenue per order |
| **Formula** | `SUM(total_amount) / COUNT(DISTINCT order_key)` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `order_key` |
| **STG Table** | `stg_orders` |
| **STG Fields** | `total_price`, `id` |
| **API Path** | `orders.edges.node.totalPriceSet.shopMoney.amount`, `orders.edges.node.id` |
| **Notes** | Derived calculation, no direct API field |

---

### 1.5 Order Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Total number of orders |
| **Formula** | `COUNT(DISTINCT order_key)` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_order` |
| **DWH Field** | `order_key` |
| **STG Table** | `stg_orders` |
| **STG Field** | `id` |
| **API Path** | `orders.edges.node.id` |
| **API Type** | GID string |
| **Notes** | Filter by date range, exclude cancelled if needed |

---

### 1.6 Units Per Transaction (UPT)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average items per order |
| **Formula** | `SUM(quantity_ordered) / COUNT(DISTINCT order_key)` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_order_line_item` |
| **DWH Fields** | `quantity_ordered`, `order_key` |
| **STG Table** | `stg_order_line_items` |
| **STG Fields** | `quantity`, `order_id` |
| **API Path** | `orders.lineItems.edges.node.quantity` |
| **API Type** | Integer |
| **Notes** | Derived calculation |

---

### 1.7 Revenue by Channel

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue breakdown by sales channel |
| **Formula** | `SUM(total_amount) GROUP BY source_name` |
| **Granularity** | Order level, grouped |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `source_name` |
| **STG Table** | `stg_orders` |
| **STG Fields** | `total_price`, `source_name` |
| **API Path** | `orders.edges.node.totalPriceSet.shopMoney.amount`, `orders.edges.node.sourceName` |
| **API Type** | Decimal, String |
| **Notes** | Values: "web", "pos", "shopify_draft_order", "iphone", "android", etc. |

---

### 1.8 Sales Growth Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Period-over-period percentage change |
| **Formula** | `((Current Period - Prior Period) / Prior Period) * 100` |
| **Granularity** | Aggregate metric over time |
| **DWH Table** | `fact_order` + `dim_date` |
| **DWH Fields** | `total_amount`, `order_date_key` |
| **STG Table** | `stg_orders` |
| **STG Fields** | `total_price`, `created_at` |
| **API Path** | `orders.edges.node.totalPriceSet.shopMoney.amount`, `orders.edges.node.createdAt` |
| **Notes** | Derived calculation requiring window functions or period comparison |

---

## 2. Customer Analytics Metrics (11)

### 2.1 Customer Lifetime Value (CLV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Total revenue from a customer |
| **Formula** | `lifetime_revenue` (pre-calculated) |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `lifetime_revenue` |
| **STG Tables** | `stg_customers` + `stg_orders` |
| **STG Derivation** | `SUM(stg_orders.total_price) WHERE customer_id = X` |
| **API Path** | `customers.edges.node.amountSpent.amount` (or calculate from orders) |
| **Notes** | Shopify provides `amountSpent` but recalculating from orders is more accurate |

---

### 2.2 Lifetime Order Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Total orders placed by customer |
| **Formula** | `lifetime_order_count` (pre-calculated) |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `lifetime_order_count` |
| **STG Tables** | `stg_customers` + `stg_orders` |
| **STG Derivation** | `COUNT(stg_orders.id) WHERE customer_id = X` |
| **API Path** | `customers.edges.node.numberOfOrders` |
| **API Type** | Integer |
| **Notes** | Shopify provides this directly on Customer object |

---

### 2.3 Average Order Value (Customer)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average spend per order for a customer |
| **Formula** | `lifetime_revenue / lifetime_order_count` |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `average_order_value` |
| **STG Derivation** | Calculated during dim_customer load |
| **API Path** | N/A - derived |
| **Notes** | Pre-calculated in dimension for performance |

---

### 2.4 Days Since Last Order

| Attribute | Value |
|-----------|-------|
| **Definition** | Recency metric - days since last purchase |
| **Formula** | `CURRENT_DATE - last_order_date` |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `days_since_last_order` |
| **STG Derivation** | `CURRENT_DATE - MAX(stg_orders.created_at)` per customer |
| **API Path** | `orders.edges.node.createdAt` (need to find MAX per customer) |
| **Notes** | Refreshed daily; key input to RFM Recency score |

---

### 2.5 First Order Date

| Attribute | Value |
|-----------|-------|
| **Definition** | Date of customer's first purchase |
| **Formula** | `MIN(order_created_at)` per customer |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `first_order_date` |
| **STG Derivation** | `MIN(stg_orders.created_at) WHERE customer_id = X` |
| **API Path** | `orders.edges.node.createdAt` (need MIN per customer) |
| **Notes** | Used for cohort analysis; determines "new" vs "returning" |

---

### 2.6 Customer Retention Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of customers who made repeat purchases |
| **Formula** | `((Customers at End - New Customers) / Customers at Start) * 100` |
| **Granularity** | Aggregate metric over time period |
| **DWH Tables** | `dim_customer` + `fact_order` |
| **DWH Fields** | `customer_key`, `first_order_date`, `order_date_key` |
| **STG Tables** | `stg_customers`, `stg_orders` |
| **API Path** | Multiple - requires customer + order data |
| **Notes** | Complex calculation requiring cohort definition |

---

### 2.7 Repeat Purchase Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of customers with 2+ orders |
| **Formula** | `COUNT(customers WHERE lifetime_order_count >= 2) / COUNT(customers) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `lifetime_order_count` |
| **STG Derivation** | Count customers with multiple orders |
| **API Path** | `customers.edges.node.numberOfOrders` |
| **Notes** | Simple threshold check on order count |

---

### 2.8 New Customer Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue from first-time buyers |
| **Formula** | `SUM(total_amount) WHERE is_first_order = TRUE` |
| **Granularity** | Order level, filtered |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `is_first_order` |
| **STG Derivation** | Order where customer's order_count at time = 1 |
| **API Path** | `orders.edges.node.totalPriceSet` + customer order history |
| **Notes** | `is_first_order` flag calculated during fact_order load |

---

### 2.9 Returning Customer Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue from repeat buyers |
| **Formula** | `SUM(total_amount) WHERE is_first_order = FALSE` |
| **Granularity** | Order level, filtered |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `is_first_order` |
| **STG Derivation** | Order where customer's prior order_count >= 1 |
| **API Path** | `orders.edges.node.totalPriceSet` + customer order history |
| **Notes** | Complement of new customer revenue |

---

### 2.10 RFM Recency Score

| Attribute | Value |
|-----------|-------|
| **Definition** | Quintile score (1-5) based on days since last order |
| **Formula** | `NTILE(5) OVER (ORDER BY days_since_last_order ASC)` |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `rfm_recency_score` |
| **STG Derivation** | Quintile of `MAX(stg_orders.created_at)` per customer |
| **API Path** | N/A - derived from order dates |
| **Notes** | 5 = most recent (best), 1 = least recent |

---

### 2.11 RFM Segment

| Attribute | Value |
|-----------|-------|
| **Definition** | Customer segment based on R/F/M scores |
| **Formula** | Business logic mapping R+F+M combinations to segments |
| **Granularity** | Customer level |
| **DWH Table** | `dim_customer` |
| **DWH Field** | `rfm_segment` |
| **STG Derivation** | Calculated from rfm_recency/frequency/monetary_score |
| **API Path** | N/A - fully derived |
| **Segments** | Champions, Loyal, Potential Loyalists, New Customers, Promising, Needs Attention, About to Sleep, At Risk, Can't Lose, Hibernating, Lost |
| **Notes** | See dim_customer definition in schema-layered.md for segment rules |

---

## 3. Product Performance Metrics (10)

### 3.1 Units Sold

| Attribute | Value |
|-----------|-------|
| **Definition** | Total quantity sold |
| **Formula** | `SUM(quantity_ordered)` |
| **Granularity** | Line item level, aggregate by product |
| **DWH Table** | `fact_order_line_item` |
| **DWH Field** | `quantity_ordered` |
| **STG Table** | `stg_order_line_items` |
| **STG Field** | `quantity` |
| **API Path** | `orders.lineItems.edges.node.quantity` |
| **API Type** | Integer |
| **Notes** | Original quantity ordered (not current after refunds) |

---

### 3.2 Product Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue by product/variant |
| **Formula** | `SUM(net_amount) GROUP BY product_key` |
| **Granularity** | Line item level, grouped |
| **DWH Table** | `fact_order_line_item` |
| **DWH Fields** | `net_amount`, `product_key` |
| **STG Table** | `stg_order_line_items` |
| **STG Fields** | `discounted_total`, `variant_id` |
| **API Path** | `orders.lineItems.edges.node.discountedTotalSet.shopMoney.amount`, `orders.lineItems.edges.node.variant.id` |
| **Notes** | Join to dim_product for product attributes |

---

### 3.3 Average Selling Price (ASP)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average revenue per unit sold |
| **Formula** | `SUM(net_amount) / SUM(quantity_ordered)` |
| **Granularity** | Aggregate by product |
| **DWH Table** | `fact_order_line_item` |
| **DWH Fields** | `net_amount`, `quantity_ordered` |
| **STG Table** | `stg_order_line_items` |
| **STG Fields** | `discounted_total`, `quantity` |
| **API Path** | Derived from line item data |
| **Notes** | Compare to list price to see discount impact |

---

### 3.4 Gross Margin $

| Attribute | Value |
|-----------|-------|
| **Definition** | Profit after COGS |
| **Formula** | `net_amount - (quantity_ordered * unit_cost)` |
| **Granularity** | Line item level |
| **DWH Table** | `fact_order_line_item` |
| **DWH Field** | `gross_margin` |
| **STG Tables** | `stg_order_line_items` + `stg_product_variants` |
| **STG Fields** | `discounted_total`, `quantity`, `cost` |
| **API Path** | Line items + `productVariants.edges.node.inventoryItem.unitCost.amount` |
| **Notes** | Requires cost data from InventoryItem |

---

### 3.5 Gross Margin %

| Attribute | Value |
|-----------|-------|
| **Definition** | Margin as percentage of revenue |
| **Formula** | `(gross_margin / net_amount) * 100` |
| **Granularity** | Line item or aggregate |
| **DWH Table** | `fact_order_line_item` |
| **DWH Field** | `gross_margin_percent` |
| **STG Derivation** | Calculated from margin and revenue |
| **API Path** | N/A - derived |
| **Notes** | Pre-calculated in fact table |

---

### 3.6 Available Inventory

| Attribute | Value |
|-----------|-------|
| **Definition** | Units available to sell |
| **Formula** | `available_quantity` |
| **Granularity** | Per item per location per snapshot |
| **DWH Table** | `fact_inventory_snapshot` |
| **DWH Field** | `available_quantity` |
| **STG Table** | `stg_inventory_levels` |
| **STG Field** | `available` |
| **API Path** | `inventoryLevels.edges.node.quantities[name="available"].quantity` |
| **API Type** | Integer |
| **Notes** | Shopify returns quantities as named array |

---

### 3.7 Inventory Value (Cost)

| Attribute | Value |
|-----------|-------|
| **Definition** | Inventory valued at cost |
| **Formula** | `on_hand_quantity * unit_cost` |
| **Granularity** | Per item per location |
| **DWH Table** | `fact_inventory_snapshot` |
| **DWH Field** | `inventory_cost_value` |
| **STG Tables** | `stg_inventory_levels` + `stg_product_variants` |
| **STG Fields** | `on_hand`, `cost` |
| **API Path** | `inventoryLevels.quantities[name="on_hand"]` + `inventoryItem.unitCost.amount` |
| **Notes** | Join inventory levels to variant cost |

---

### 3.8 Stock-Out Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of SKUs with zero available |
| **Formula** | `COUNT(WHERE is_out_of_stock = TRUE) / COUNT(*) * 100` |
| **Granularity** | Aggregate across inventory |
| **DWH Table** | `fact_inventory_snapshot` |
| **DWH Field** | `is_out_of_stock` |
| **STG Table** | `stg_inventory_levels` |
| **STG Derivation** | `available = 0` |
| **API Path** | `inventoryLevels.edges.node.quantities[name="available"].quantity = 0` |
| **Notes** | Flag pre-calculated in fact table |

---

### 3.9 Product Return Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of units returned by product |
| **Formula** | `SUM(refunded_qty) / SUM(sold_qty) * 100` by product |
| **Granularity** | Product level |
| **DWH Tables** | `fact_refund` + `fact_order_line_item` |
| **DWH Fields** | Refund quantities + sold quantities |
| **STG Tables** | `stg_refund_line_items` + `stg_order_line_items` |
| **STG Fields** | `quantity` (refund), `quantity` (order) |
| **API Path** | `orders.refunds.refundLineItems.edges.node.quantity`, `orders.lineItems.edges.node.quantity` |
| **Notes** | Match on line_item_id to link refunds to original sales |

---

### 3.10 Sell-Through Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of starting inventory sold |
| **Formula** | `Units Sold / Beginning Inventory * 100` |
| **Granularity** | Per product over time period |
| **DWH Tables** | `fact_order_line_item` + `fact_inventory_snapshot` |
| **DWH Fields** | `quantity_ordered`, `on_hand_quantity` (period start) |
| **STG Tables** | `stg_order_line_items` + `stg_inventory_levels` |
| **API Path** | Derived from sales + inventory snapshots |
| **Notes** | Requires historical inventory snapshots for beginning balance |

---

## 4. Marketing & Promotions Metrics (9)

### 4.1 Discount Usage Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of orders using a discount |
| **Formula** | `COUNT(WHERE has_discount = TRUE) / COUNT(*) * 100` |
| **Granularity** | Aggregate across orders |
| **DWH Table** | `fact_order` |
| **DWH Field** | `has_discount` |
| **STG Table** | `stg_orders` |
| **STG Derivation** | `total_discounts > 0` |
| **API Path** | `orders.edges.node.totalDiscountsSet.shopMoney.amount > 0` |
| **Notes** | Flag pre-calculated in fact table |

---

### 4.2 Total Discount Amount

| Attribute | Value |
|-----------|-------|
| **Definition** | Sum of all discounts applied |
| **Formula** | `SUM(discount_amount)` |
| **Granularity** | Order level |
| **DWH Table** | `fact_order` |
| **DWH Field** | `discount_amount` |
| **STG Table** | `stg_orders` |
| **STG Field** | `total_discounts` |
| **API Path** | `orders.edges.node.totalDiscountsSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | Includes all discount types (code, automatic, manual) |

---

### 4.3 Average Discount per Order

| Attribute | Value |
|-----------|-------|
| **Definition** | Average discount on discounted orders |
| **Formula** | `SUM(discount_amount) / COUNT(WHERE has_discount = TRUE)` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `discount_amount`, `has_discount` |
| **STG Table** | `stg_orders` |
| **STG Fields** | `total_discounts` |
| **API Path** | Derived |
| **Notes** | Only count orders with discounts in denominator |

---

### 4.4 Discount Code Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue attributed to specific discount codes |
| **Formula** | `SUM(total_amount) GROUP BY discount_code` |
| **Granularity** | Order level, grouped by code |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `discount_1_code` |
| **STG Tables** | `stg_orders` + `stg_order_discount_applications` |
| **STG Fields** | `total_price`, `code` |
| **API Path** | `orders.edges.node.totalPriceSet`, `orders.edges.node.discountApplications.edges.node.code` |
| **Notes** | Uses first discount code (discount_1_code) if multiple |

---

### 4.5 Discount Code Usage Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Times a specific code was redeemed |
| **Formula** | `current_usage_count` |
| **Granularity** | Per discount code |
| **DWH Table** | `dim_discount` |
| **DWH Field** | `current_usage_count` |
| **STG Table** | `stg_discount_codes` |
| **STG Field** | `usage_count` |
| **API Path** | `codeDiscountNodes.edges.node.codeDiscount.codes.edges.node.asyncUsageCount` |
| **API Type** | Integer |
| **Notes** | Shopify tracks this automatically |

---

### 4.6 Discount Redemption Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of allowed uses consumed |
| **Formula** | `usage_count / usage_limit * 100` |
| **Granularity** | Per discount code |
| **DWH Table** | `dim_discount` |
| **DWH Fields** | `current_usage_count`, `usage_limit` |
| **STG Table** | `stg_discount_codes` |
| **STG Fields** | `usage_count`, `usage_limit` |
| **API Path** | `codeDiscount.codes.asyncUsageCount`, `codeDiscount.usageLimit` |
| **Notes** | NULL usage_limit means unlimited |

---

### 4.7 Revenue by Landing Site

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue by first URL visited |
| **Formula** | `SUM(total_amount) GROUP BY landing_site` |
| **Granularity** | Order level, grouped |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `landing_site` |
| **STG Table** | `stg_orders` |
| **STG Fields** | `total_price`, `landing_site` |
| **API Path** | `orders.edges.node.totalPriceSet`, `orders.edges.node.landingSite` |
| **API Type** | Decimal, URL string |
| **Notes** | May need URL parsing for meaningful grouping |

---

### 4.8 Revenue by Referring Site

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue by traffic source |
| **Formula** | `SUM(total_amount) GROUP BY referring_site` |
| **Granularity** | Order level, grouped |
| **DWH Table** | `fact_order` |
| **DWH Fields** | `total_amount`, `referring_site` |
| **STG Table** | `stg_orders` |
| **STG Fields** | `total_price`, `referring_site` |
| **API Path** | `orders.edges.node.totalPriceSet`, `orders.edges.node.referringSite` |
| **API Type** | Decimal, URL string |
| **Notes** | Common values: google.com, facebook.com, direct, etc. |

---

### 4.9 Cart Abandonment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of checkouts not completed |
| **Formula** | `Abandoned / (Abandoned + Completed) * 100` |
| **Granularity** | Aggregate metric |
| **DWH/STG Table** | `stg_abandoned_checkouts` |
| **STG Fields** | `id`, `completed_at` |
| **API Path** | `abandonedCheckouts.edges.node.id`, `abandonedCheckouts.edges.node.completedAt` |
| **Notes** | Abandoned = `completed_at IS NULL`; Completed = has matching order |

---

## 5. Operations & Fulfillment Metrics (11)

### 5.1 Fulfillment Time (Hours)

| Attribute | Value |
|-----------|-------|
| **Definition** | Hours from order to shipment |
| **Formula** | `AVG(fulfillment_time_hours)` |
| **Granularity** | Per fulfillment, aggregate |
| **DWH Table** | `fact_fulfillment` |
| **DWH Field** | `fulfillment_time_hours` |
| **STG Tables** | `stg_fulfillments` + `stg_orders` |
| **STG Derivation** | `(stg_fulfillments.created_at - stg_orders.created_at) / 3600` |
| **API Path** | `orders.fulfillments.edges.node.createdAt`, `orders.edges.node.createdAt` |
| **API Type** | DateTime |
| **Notes** | Calculated during ETL |

---

### 5.2 Fulfillment Time (Days)

| Attribute | Value |
|-----------|-------|
| **Definition** | Days from order to shipment |
| **Formula** | `AVG(fulfillment_time_days)` |
| **Granularity** | Per fulfillment, aggregate |
| **DWH Table** | `fact_fulfillment` |
| **DWH Field** | `fulfillment_time_days` |
| **STG Derivation** | `fulfillment_time_hours / 24` |
| **API Path** | N/A - derived |
| **Notes** | Convenience field for day-based reporting |

---

### 5.3 Same-Day Fulfillment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % fulfilled within 24 hours |
| **Formula** | `COUNT(WHERE is_same_day = TRUE) / COUNT(*) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_fulfillment` |
| **DWH Field** | `is_same_day` |
| **STG Derivation** | `fulfillment_time_hours < 24` |
| **API Path** | N/A - derived |
| **Notes** | Flag pre-calculated in fact table |

---

### 5.4 On-Time Shipping Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % fulfilled within 48 hours |
| **Formula** | `COUNT(WHERE is_within_48h = TRUE) / COUNT(*) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_fulfillment` |
| **DWH Field** | `is_within_48h` |
| **STG Derivation** | `fulfillment_time_hours <= 48` |
| **API Path** | N/A - derived |
| **Notes** | Threshold configurable per business |

---

### 5.5 Late Fulfillment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % taking more than 72 hours |
| **Formula** | `COUNT(WHERE is_late = TRUE) / COUNT(*) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_fulfillment` |
| **DWH Field** | `is_late` |
| **STG Derivation** | `fulfillment_time_hours > 72` |
| **API Path** | N/A - derived |
| **Notes** | Threshold configurable per business |

---

### 5.6 Refund Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of orders with refunds |
| **Formula** | `COUNT(DISTINCT refunded_orders) / COUNT(DISTINCT orders) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Tables** | `fact_refund` + `fact_order` |
| **DWH Fields** | `order_key` from both |
| **STG Tables** | `stg_refunds` + `stg_orders` |
| **API Path** | `orders.refunds.edges` (count orders with refunds) |
| **Notes** | Join refunds to orders on order_id |

---

### 5.7 Refund Amount

| Attribute | Value |
|-----------|-------|
| **Definition** | Total value refunded |
| **Formula** | `SUM(refund_amount)` |
| **Granularity** | Per refund, aggregate |
| **DWH Table** | `fact_refund` |
| **DWH Field** | `refund_amount` |
| **STG Table** | `stg_refunds` |
| **STG Field** | `total_refunded` |
| **API Path** | `orders.refunds.edges.node.totalRefundedSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | Sum across all refunds |

---

### 5.8 Refund % of Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Refunds as % of total revenue |
| **Formula** | `SUM(refund_amount) / SUM(total_amount) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Tables** | `fact_refund` + `fact_order` |
| **DWH Fields** | `refund_amount`, `total_amount` |
| **STG Tables** | `stg_refunds` + `stg_orders` |
| **API Path** | Derived from refund and order totals |
| **Notes** | Key financial health indicator |

---

### 5.9 Items Refunded

| Attribute | Value |
|-----------|-------|
| **Definition** | Total units refunded |
| **Formula** | `SUM(total_items_refunded)` |
| **Granularity** | Per refund, aggregate |
| **DWH Table** | `fact_refund` |
| **DWH Field** | `total_items_refunded` |
| **STG Table** | `stg_refund_line_items` |
| **STG Field** | `quantity` |
| **API Path** | `orders.refunds.refundLineItems.edges.node.quantity` |
| **API Type** | Integer |
| **Notes** | Sum of quantities across refund line items |

---

### 5.10 Restock Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of refunded items returned to inventory |
| **Formula** | `items_restocked / total_items_refunded * 100` |
| **Granularity** | Per refund, aggregate |
| **DWH Table** | `fact_refund` |
| **DWH Fields** | `items_restocked`, `total_items_refunded` |
| **STG Table** | `stg_refund_line_items` |
| **STG Fields** | `quantity`, `restock_type` |
| **API Path** | `refundLineItems.edges.node.restockType`, `refundLineItems.edges.node.quantity` |
| **Notes** | Restocked when `restock_type IN ('RETURN', 'CANCEL')` |

---

### 5.11 Fulfillments by Location

| Attribute | Value |
|-----------|-------|
| **Definition** | Distribution of fulfillments by warehouse |
| **Formula** | `COUNT(*) GROUP BY location_key` |
| **Granularity** | Aggregate by location |
| **DWH Table** | `fact_fulfillment` |
| **DWH Field** | `location_key` |
| **STG Table** | `stg_fulfillments` |
| **STG Field** | `location_id` |
| **API Path** | `orders.fulfillments.edges.node.location.id` |
| **API Type** | GID string |
| **Notes** | Join to dim_location for location details |

---

## 6. Financial Metrics (8)

### 6.1 Cost of Goods Sold (COGS)

| Attribute | Value |
|-----------|-------|
| **Definition** | Direct cost of products sold |
| **Formula** | `SUM(quantity_ordered * unit_cost)` |
| **Granularity** | Line item level, aggregate |
| **DWH Table** | `fact_order_line_item` |
| **DWH Fields** | `quantity_ordered`, `unit_cost` |
| **STG Tables** | `stg_order_line_items` + `stg_product_variants` |
| **STG Fields** | `quantity`, `cost` |
| **API Path** | `lineItems.quantity`, `productVariants.inventoryItem.unitCost.amount` |
| **Notes** | Requires cost data populated in variants |

---

### 6.2 Gross Profit

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue minus COGS |
| **Formula** | `SUM(net_amount) - SUM(quantity_ordered * unit_cost)` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_order_line_item` |
| **DWH Fields** | `net_amount`, `gross_margin` |
| **STG Derivation** | Calculated from revenue and cost |
| **API Path** | N/A - derived |
| **Notes** | `gross_margin` is pre-calculated per line |

---

### 6.3 Gross Profit Margin %

| Attribute | Value |
|-----------|-------|
| **Definition** | Gross profit as % of revenue |
| **Formula** | `(Gross Profit / Net Revenue) * 100` |
| **Granularity** | Aggregate metric |
| **DWH Table** | `fact_order_line_item` |
| **DWH Fields** | `gross_margin`, `net_amount` |
| **STG Derivation** | Calculated |
| **API Path** | N/A - derived |
| **Notes** | Target varies by industry (see benchmarks in metrics reference) |

---

### 6.4 Tax Collected

| Attribute | Value |
|-----------|-------|
| **Definition** | Total sales tax collected |
| **Formula** | `SUM(tax_amount)` |
| **Granularity** | Order level |
| **DWH Table** | `fact_order` |
| **DWH Field** | `tax_amount` |
| **STG Table** | `stg_orders` |
| **STG Field** | `total_tax` |
| **API Path** | `orders.edges.node.totalTaxSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | For tax remittance reporting |

---

### 6.5 Tax by Region

| Attribute | Value |
|-----------|-------|
| **Definition** | Tax collected by geography |
| **Formula** | `SUM(tax_amount) GROUP BY country` |
| **Granularity** | Order level, grouped |
| **DWH Tables** | `fact_order` + `dim_geography` |
| **DWH Fields** | `tax_amount`, `shipping_geography_key` → `country` |
| **STG Tables** | `stg_orders` + address parsing |
| **API Path** | `orders.totalTaxSet`, `orders.shippingAddress.countryCodeV2` |
| **Notes** | Join to dim_geography for country details |

---

### 6.6 Shipping Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue from shipping charges |
| **Formula** | `SUM(shipping_amount)` |
| **Granularity** | Order level |
| **DWH Table** | `fact_order` |
| **DWH Field** | `shipping_amount` |
| **STG Table** | `stg_orders` |
| **STG Field** | `total_shipping` |
| **API Path** | `orders.edges.node.totalShippingPriceSet.shopMoney.amount` |
| **API Type** | Decimal string |
| **Notes** | What customer paid for shipping |

---

### 6.7 Net Revenue After Refunds

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue minus all refunds |
| **Formula** | `SUM(net_amount)` (fact_order) or `total_price - total_refunded` |
| **Granularity** | Order level |
| **DWH Table** | `fact_order` |
| **DWH Field** | `net_amount` |
| **STG Table** | `stg_orders` |
| **STG Derivation** | `total_price - total_refunded` |
| **API Path** | `orders.totalPriceSet.shopMoney.amount`, `orders.totalRefundedSet.shopMoney.amount` |
| **Notes** | True realized revenue |

---

### 6.8 Inventory Valuation (Retail)

| Attribute | Value |
|-----------|-------|
| **Definition** | Inventory valued at selling price |
| **Formula** | `SUM(on_hand_quantity * unit_price)` |
| **Granularity** | Per item, aggregate |
| **DWH Table** | `fact_inventory_snapshot` |
| **DWH Field** | `inventory_retail_value` |
| **STG Tables** | `stg_inventory_levels` + `stg_product_variants` |
| **STG Fields** | `on_hand`, `price` |
| **API Path** | `inventoryLevels.quantities[name="on_hand"]`, `productVariants.price` |
| **Notes** | Compare to cost valuation for potential margin |

---

## Appendix A: External Data Requirements

These metrics require data from outside Shopify:

| Metric | External Source | Notes |
|--------|-----------------|-------|
| Customer Acquisition Cost (CAC) | Marketing platforms | Ad spend from Google/Meta/etc. |
| ROAS (Return on Ad Spend) | Marketing platforms | Ad spend + attributed revenue |
| Marketing ROI | Marketing platforms | All marketing costs |
| Shipping Cost (Actual) | Carrier invoices | What you paid, not what customer paid |
| Revenue Per Visitor | Analytics platform | Session data from GA4/etc. |
| Conversion Rate | Analytics platform | Sessions → Orders |

---

## Appendix B: GraphQL Query Examples

### Orders with Fulfillments and Refunds

```graphql
query GetOrdersWithDetails($cursor: String) {
  orders(first: 50, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    edges {
      node {
        id
        name
        createdAt
        sourceName
        landingSite
        referringSite
        totalPriceSet { shopMoney { amount currencyCode } }
        totalDiscountsSet { shopMoney { amount } }
        totalTaxSet { shopMoney { amount } }
        totalShippingPriceSet { shopMoney { amount } }
        totalRefundedSet { shopMoney { amount } }

        lineItems(first: 50) {
          edges {
            node {
              id
              quantity
              originalTotalSet { shopMoney { amount } }
              discountedTotalSet { shopMoney { amount } }
              variant { id product { id } }
            }
          }
        }

        fulfillments(first: 10) {
          id
          createdAt
          status
          trackingInfo { number company url }
          location { id }
        }

        refunds(first: 10) {
          id
          createdAt
          totalRefundedSet { shopMoney { amount } }
          refundLineItems(first: 50) {
            edges {
              node {
                quantity
                restockType
                lineItem { id }
              }
            }
          }
        }
      }
    }
  }
}
```

### Inventory Levels

```graphql
query GetInventoryLevels($cursor: String) {
  inventoryLevels(first: 100, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    edges {
      node {
        item { id }
        location { id }
        quantities(names: ["available", "on_hand", "committed", "incoming", "reserved"]) {
          name
          quantity
        }
        updatedAt
      }
    }
  }
}
```

### Abandoned Checkouts

```graphql
query GetAbandonedCheckouts($cursor: String) {
  abandonedCheckouts(first: 50, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    edges {
      node {
        id
        createdAt
        updatedAt
        completedAt
        email
        totalPriceSet { shopMoney { amount currencyCode } }
        abandonedCheckoutUrl
        lineItems(first: 10) {
          edges {
            node { title quantity }
          }
        }
      }
    }
  }
}
```

---

## Appendix C: Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-04 | Initial creation with 57 metrics |
