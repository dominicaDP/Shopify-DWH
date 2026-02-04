# Shopify DWH - Metrics Reference

**Version:** 2.0
**Last Updated:** 2026-02-04
**Author:** Digital Planet Analytics

---

## Overview

This document provides complete definitions and data lineage for all 57 ecommerce metrics supported by the Shopify Data Warehouse.

**Metrics Summary:**
| Category | Count |
|----------|-------|
| Sales & Revenue | 8 |
| Customer Analytics | 11 |
| Product Performance | 10 |
| Marketing & Promotions | 9 |
| Operations & Fulfillment | 11 |
| Financial | 8 |
| **Total** | **57** |

**Lineage Direction:** Report → Metric → DWH Table → STG Table → Shopify API

---

## 1. Sales & Revenue Metrics (8)

### 1.1 Gross Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Total revenue before discounts and refunds |
| **Formula** | `SUM(gross_amount)` |
| **DWH Source** | `fact_order_line_item.gross_amount` |
| **STG Source** | `stg_order_line_items.total_price` |
| **API Field** | `orders.lineItems.originalTotalSet.shopMoney.amount` |

### 1.2 Net Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue after line-level discounts |
| **Formula** | `SUM(net_amount)` |
| **DWH Source** | `fact_order_line_item.net_amount` |
| **STG Source** | `stg_order_line_items.discounted_total` |
| **API Field** | `orders.lineItems.discountedTotalSet.shopMoney.amount` |

### 1.3 Total Revenue (Order Level)

| Attribute | Value |
|-----------|-------|
| **Definition** | Final order total including tax and shipping |
| **Formula** | `SUM(total_amount)` |
| **DWH Source** | `fact_order.total_amount` |
| **STG Source** | `stg_orders.total_price` |
| **API Field** | `orders.totalPriceSet.shopMoney.amount` |

### 1.4 Average Order Value (AOV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average revenue per order |
| **Formula** | `SUM(total_amount) / COUNT(DISTINCT order_key)` |
| **DWH Source** | `fact_order.total_amount`, `fact_order.order_key` |
| **STG Source** | `stg_orders.total_price`, `stg_orders.id` |
| **Notes** | Derived calculation |

### 1.5 Order Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Total number of orders |
| **Formula** | `COUNT(DISTINCT order_key)` |
| **DWH Source** | `fact_order.order_key` |
| **STG Source** | `stg_orders.id` |
| **API Field** | `orders.id` |

### 1.6 Units Per Transaction (UPT)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average items per order |
| **Formula** | `SUM(quantity_ordered) / COUNT(DISTINCT order_key)` |
| **DWH Source** | `fact_order_line_item.quantity_ordered` |
| **STG Source** | `stg_order_line_items.quantity` |
| **API Field** | `orders.lineItems.quantity` |

### 1.7 Revenue by Channel

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue breakdown by sales channel |
| **Formula** | `SUM(total_amount) GROUP BY source_name` |
| **DWH Source** | `fact_order.total_amount`, `fact_order.source_name` |
| **STG Source** | `stg_orders.total_price`, `stg_orders.source_name` |
| **API Field** | `orders.sourceName` |
| **Values** | "web", "pos", "shopify_draft_order", "iphone", "android" |

### 1.8 Sales Growth Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Period-over-period percentage change |
| **Formula** | `((Current Period - Prior Period) / Prior Period) * 100` |
| **DWH Source** | `fact_order.total_amount` + `dim_date` |
| **STG Source** | `stg_orders.total_price`, `stg_orders.created_at` |
| **Notes** | Requires window functions or period comparison |

---

## 2. Customer Analytics Metrics (11)

### 2.1 Customer Lifetime Value (CLV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Total revenue from a customer |
| **Formula** | Pre-calculated in dimension |
| **DWH Source** | `dim_customer.lifetime_revenue` |
| **STG Source** | `SUM(stg_orders.total_price) per customer` |
| **API Field** | `customers.amountSpent.amount` (or calculated) |

### 2.2 Lifetime Order Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Total orders placed by customer |
| **Formula** | Pre-calculated in dimension |
| **DWH Source** | `dim_customer.lifetime_order_count` |
| **STG Source** | `COUNT(stg_orders.id) per customer` |
| **API Field** | `customers.numberOfOrders` |

### 2.3 Average Order Value (Customer)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average spend per order for a customer |
| **Formula** | `lifetime_revenue / lifetime_order_count` |
| **DWH Source** | `dim_customer.average_order_value` |
| **Notes** | Pre-calculated during dimension load |

### 2.4 Days Since Last Order

| Attribute | Value |
|-----------|-------|
| **Definition** | Recency metric - days since last purchase |
| **Formula** | `CURRENT_DATE - last_order_date` |
| **DWH Source** | `dim_customer.days_since_last_order` |
| **STG Source** | `MAX(stg_orders.created_at) per customer` |
| **Notes** | Key input to RFM Recency score |

### 2.5 First Order Date

| Attribute | Value |
|-----------|-------|
| **Definition** | Date of customer's first purchase |
| **Formula** | `MIN(order_created_at) per customer` |
| **DWH Source** | `dim_customer.first_order_date` |
| **STG Source** | `MIN(stg_orders.created_at) per customer` |
| **Notes** | Used for cohort analysis |

### 2.6 Customer Retention Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of customers who made repeat purchases |
| **Formula** | `((End Customers - New) / Start Customers) * 100` |
| **DWH Source** | `dim_customer` + `fact_order` |
| **Notes** | Complex calculation requiring cohort definition |

### 2.7 Repeat Purchase Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of customers with 2+ orders |
| **Formula** | `COUNT(lifetime_order_count >= 2) / COUNT(*) * 100` |
| **DWH Source** | `dim_customer.lifetime_order_count` |
| **API Field** | `customers.numberOfOrders` |

### 2.8 New Customer Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue from first-time buyers |
| **Formula** | `SUM(total_amount) WHERE is_first_order = TRUE` |
| **DWH Source** | `fact_order.total_amount`, `fact_order.is_first_order` |
| **Notes** | `is_first_order` flag calculated during ETL |

### 2.9 Returning Customer Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue from repeat buyers |
| **Formula** | `SUM(total_amount) WHERE is_first_order = FALSE` |
| **DWH Source** | `fact_order.total_amount`, `fact_order.is_first_order` |
| **Notes** | Complement of new customer revenue |

### 2.10 RFM Recency Score

| Attribute | Value |
|-----------|-------|
| **Definition** | Quintile score (1-5) based on days since last order |
| **Formula** | `NTILE(5) OVER (ORDER BY days_since_last_order ASC)` |
| **DWH Source** | `dim_customer.rfm_recency_score` |
| **Notes** | 5 = most recent (best), 1 = least recent |

### 2.11 RFM Segment

| Attribute | Value |
|-----------|-------|
| **Definition** | Customer segment based on R/F/M scores |
| **Formula** | Business logic mapping R+F+M combinations |
| **DWH Source** | `dim_customer.rfm_segment` |
| **Segments** | Champions, Loyal, Potential Loyalists, New Customers, Promising, Needs Attention, About to Sleep, At Risk, Can't Lose, Hibernating, Lost |

---

## 3. Product Performance Metrics (10)

### 3.1 Units Sold

| Attribute | Value |
|-----------|-------|
| **Definition** | Total quantity sold |
| **Formula** | `SUM(quantity_ordered)` |
| **DWH Source** | `fact_order_line_item.quantity_ordered` |
| **STG Source** | `stg_order_line_items.quantity` |
| **API Field** | `orders.lineItems.quantity` |

### 3.2 Product Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue by product/variant |
| **Formula** | `SUM(net_amount) GROUP BY product_key` |
| **DWH Source** | `fact_order_line_item.net_amount`, `product_key` |
| **STG Source** | `stg_order_line_items.discounted_total`, `variant_id` |
| **Notes** | Join to dim_product for attributes |

### 3.3 Average Selling Price (ASP)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average revenue per unit sold |
| **Formula** | `SUM(net_amount) / SUM(quantity_ordered)` |
| **DWH Source** | `fact_order_line_item.net_amount`, `quantity_ordered` |
| **Notes** | Compare to list price for discount impact |

### 3.4 Gross Margin $

| Attribute | Value |
|-----------|-------|
| **Definition** | Profit after COGS |
| **Formula** | `net_amount - (quantity_ordered * unit_cost)` |
| **DWH Source** | `fact_order_line_item.gross_margin` |
| **STG Source** | `stg_order_line_items` + `stg_product_variants.cost` |
| **API Field** | `productVariants.inventoryItem.unitCost.amount` |

### 3.5 Gross Margin %

| Attribute | Value |
|-----------|-------|
| **Definition** | Margin as percentage of revenue |
| **Formula** | `(gross_margin / net_amount) * 100` |
| **DWH Source** | `fact_order_line_item.gross_margin_percent` |
| **Notes** | Pre-calculated in fact table |

### 3.6 Available Inventory

| Attribute | Value |
|-----------|-------|
| **Definition** | Units available to sell |
| **Formula** | Direct field |
| **DWH Source** | `fact_inventory_snapshot.available_quantity` |
| **STG Source** | `stg_inventory_levels.available` |
| **API Field** | `inventoryLevels.quantities[name="available"].quantity` |

### 3.7 Inventory Value (Cost)

| Attribute | Value |
|-----------|-------|
| **Definition** | Inventory valued at cost |
| **Formula** | `on_hand_quantity * unit_cost` |
| **DWH Source** | `fact_inventory_snapshot.inventory_cost_value` |
| **STG Source** | `stg_inventory_levels.on_hand` + `stg_product_variants.cost` |

### 3.8 Stock-Out Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of SKUs with zero available |
| **Formula** | `COUNT(is_out_of_stock = TRUE) / COUNT(*) * 100` |
| **DWH Source** | `fact_inventory_snapshot.is_out_of_stock` |
| **STG Source** | `stg_inventory_levels.available = 0` |

### 3.9 Product Return Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of units returned by product |
| **Formula** | `SUM(refunded_qty) / SUM(sold_qty) * 100` |
| **DWH Source** | `fact_refund` + `fact_order_line_item` |
| **STG Source** | `stg_refund_line_items.quantity` + `stg_order_line_items.quantity` |

### 3.10 Sell-Through Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of starting inventory sold |
| **Formula** | `Units Sold / Beginning Inventory * 100` |
| **DWH Source** | `fact_order_line_item` + `fact_inventory_snapshot` |
| **Notes** | Requires historical inventory snapshots |

---

## 4. Marketing & Promotions Metrics (9)

### 4.1 Discount Usage Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of orders using a discount |
| **Formula** | `COUNT(has_discount = TRUE) / COUNT(*) * 100` |
| **DWH Source** | `fact_order.has_discount` |
| **STG Source** | `stg_orders.total_discounts > 0` |

### 4.2 Total Discount Amount

| Attribute | Value |
|-----------|-------|
| **Definition** | Sum of all discounts applied |
| **Formula** | `SUM(discount_amount)` |
| **DWH Source** | `fact_order.discount_amount` |
| **STG Source** | `stg_orders.total_discounts` |
| **API Field** | `orders.totalDiscountsSet.shopMoney.amount` |

### 4.3 Average Discount per Order

| Attribute | Value |
|-----------|-------|
| **Definition** | Average discount on discounted orders |
| **Formula** | `SUM(discount_amount) / COUNT(has_discount = TRUE)` |
| **DWH Source** | `fact_order.discount_amount`, `has_discount` |
| **Notes** | Only count discounted orders in denominator |

### 4.4 Discount Code Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue attributed to specific discount codes |
| **Formula** | `SUM(total_amount) GROUP BY discount_code` |
| **DWH Source** | `fact_order.total_amount`, `discount_1_code` |
| **STG Source** | `stg_order_discount_applications.code` |

### 4.5 Discount Code Usage Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Times a specific code was redeemed |
| **Formula** | Direct field |
| **DWH Source** | `dim_discount.current_usage_count` |
| **STG Source** | `stg_discount_codes.usage_count` |
| **API Field** | `codeDiscountNodes.codeDiscount.codes.asyncUsageCount` |

### 4.6 Discount Redemption Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of allowed uses consumed |
| **Formula** | `usage_count / usage_limit * 100` |
| **DWH Source** | `dim_discount.current_usage_count`, `usage_limit` |
| **Notes** | NULL usage_limit means unlimited |

### 4.7 Revenue by Landing Site

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue by first URL visited |
| **Formula** | `SUM(total_amount) GROUP BY landing_site` |
| **DWH Source** | `fact_order.total_amount`, `landing_site` |
| **STG Source** | `stg_orders.landing_site` |
| **API Field** | `orders.landingSite` |

### 4.8 Revenue by Referring Site

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue by traffic source |
| **Formula** | `SUM(total_amount) GROUP BY referring_site` |
| **DWH Source** | `fact_order.total_amount`, `referring_site` |
| **STG Source** | `stg_orders.referring_site` |
| **API Field** | `orders.referringSite` |

### 4.9 Cart Abandonment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of checkouts not completed |
| **Formula** | `Abandoned / (Abandoned + Completed) * 100` |
| **STG Source** | `stg_abandoned_checkouts.id`, `completed_at` |
| **API Field** | `abandonedCheckouts.completedAt` |
| **Notes** | Abandoned = `completed_at IS NULL` |

---

## 5. Operations & Fulfillment Metrics (11)

### 5.1 Fulfillment Time (Hours)

| Attribute | Value |
|-----------|-------|
| **Definition** | Hours from order to shipment |
| **Formula** | `AVG(fulfillment_time_hours)` |
| **DWH Source** | `fact_fulfillment.fulfillment_time_hours` |
| **STG Source** | `(stg_fulfillments.created_at - stg_orders.created_at) / 3600` |

### 5.2 Fulfillment Time (Days)

| Attribute | Value |
|-----------|-------|
| **Definition** | Days from order to shipment |
| **Formula** | `AVG(fulfillment_time_days)` |
| **DWH Source** | `fact_fulfillment.fulfillment_time_days` |
| **Notes** | `fulfillment_time_hours / 24` |

### 5.3 Same-Day Fulfillment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % fulfilled within 24 hours |
| **Formula** | `COUNT(is_same_day = TRUE) / COUNT(*) * 100` |
| **DWH Source** | `fact_fulfillment.is_same_day` |
| **Notes** | `fulfillment_time_hours < 24` |

### 5.4 On-Time Shipping Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % fulfilled within 48 hours |
| **Formula** | `COUNT(is_within_48h = TRUE) / COUNT(*) * 100` |
| **DWH Source** | `fact_fulfillment.is_within_48h` |
| **Notes** | Threshold configurable per business |

### 5.5 Late Fulfillment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % taking more than 72 hours |
| **Formula** | `COUNT(is_late = TRUE) / COUNT(*) * 100` |
| **DWH Source** | `fact_fulfillment.is_late` |
| **Notes** | `fulfillment_time_hours > 72` |

### 5.6 Refund Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of orders with refunds |
| **Formula** | `COUNT(DISTINCT refunded_orders) / COUNT(DISTINCT orders) * 100` |
| **DWH Source** | `fact_refund.order_key` + `fact_order.order_key` |
| **STG Source** | `stg_refunds.order_id` + `stg_orders.id` |

### 5.7 Refund Amount

| Attribute | Value |
|-----------|-------|
| **Definition** | Total value refunded |
| **Formula** | `SUM(refund_amount)` |
| **DWH Source** | `fact_refund.refund_amount` |
| **STG Source** | `stg_refunds.total_refunded` |
| **API Field** | `orders.refunds.totalRefundedSet.shopMoney.amount` |

### 5.8 Refund % of Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Refunds as % of total revenue |
| **Formula** | `SUM(refund_amount) / SUM(total_amount) * 100` |
| **DWH Source** | `fact_refund.refund_amount` + `fact_order.total_amount` |
| **Notes** | Key financial health indicator |

### 5.9 Items Refunded

| Attribute | Value |
|-----------|-------|
| **Definition** | Total units refunded |
| **Formula** | `SUM(total_items_refunded)` |
| **DWH Source** | `fact_refund.total_items_refunded` |
| **STG Source** | `stg_refund_line_items.quantity` |
| **API Field** | `orders.refunds.refundLineItems.quantity` |

### 5.10 Restock Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | % of refunded items returned to inventory |
| **Formula** | `items_restocked / total_items_refunded * 100` |
| **DWH Source** | `fact_refund.items_restocked`, `total_items_refunded` |
| **STG Source** | `stg_refund_line_items.restock_type` |
| **Notes** | Restocked when `restock_type IN ('RETURN', 'CANCEL')` |

### 5.11 Fulfillments by Location

| Attribute | Value |
|-----------|-------|
| **Definition** | Distribution of fulfillments by warehouse |
| **Formula** | `COUNT(*) GROUP BY location_key` |
| **DWH Source** | `fact_fulfillment.location_key` |
| **STG Source** | `stg_fulfillments.location_id` |
| **Notes** | Join to dim_location for details |

---

## 6. Financial Metrics (8)

### 6.1 Cost of Goods Sold (COGS)

| Attribute | Value |
|-----------|-------|
| **Definition** | Direct cost of products sold |
| **Formula** | `SUM(quantity_ordered * unit_cost)` |
| **DWH Source** | `fact_order_line_item.quantity_ordered`, `unit_cost` |
| **STG Source** | `stg_order_line_items.quantity` + `stg_product_variants.cost` |
| **API Field** | `productVariants.inventoryItem.unitCost.amount` |

### 6.2 Gross Profit

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue minus COGS |
| **Formula** | `SUM(net_amount) - SUM(quantity_ordered * unit_cost)` |
| **DWH Source** | `fact_order_line_item.gross_margin` |
| **Notes** | Pre-calculated per line item |

### 6.3 Gross Profit Margin %

| Attribute | Value |
|-----------|-------|
| **Definition** | Gross profit as % of revenue |
| **Formula** | `(Gross Profit / Net Revenue) * 100` |
| **DWH Source** | `fact_order_line_item.gross_margin`, `net_amount` |
| **Benchmark** | 50-70% for fashion, 20-40% for electronics |

### 6.4 Tax Collected

| Attribute | Value |
|-----------|-------|
| **Definition** | Total sales tax collected |
| **Formula** | `SUM(tax_amount)` |
| **DWH Source** | `fact_order.tax_amount` |
| **STG Source** | `stg_orders.total_tax` |
| **API Field** | `orders.totalTaxSet.shopMoney.amount` |

### 6.5 Tax by Region

| Attribute | Value |
|-----------|-------|
| **Definition** | Tax collected by geography |
| **Formula** | `SUM(tax_amount) GROUP BY country` |
| **DWH Source** | `fact_order.tax_amount` + `dim_geography` |
| **Notes** | Join on shipping_geography_key |

### 6.6 Shipping Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue from shipping charges |
| **Formula** | `SUM(shipping_amount)` |
| **DWH Source** | `fact_order.shipping_amount` |
| **STG Source** | `stg_orders.total_shipping` |
| **API Field** | `orders.totalShippingPriceSet.shopMoney.amount` |

### 6.7 Net Revenue After Refunds

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue minus all refunds |
| **Formula** | `SUM(total_price - total_refunded)` |
| **DWH Source** | `fact_order.net_amount` |
| **STG Source** | `stg_orders.total_price - stg_orders.total_refunded` |
| **Notes** | True realized revenue |

### 6.8 Inventory Valuation (Retail)

| Attribute | Value |
|-----------|-------|
| **Definition** | Inventory valued at selling price |
| **Formula** | `SUM(on_hand_quantity * unit_price)` |
| **DWH Source** | `fact_inventory_snapshot.inventory_retail_value` |
| **STG Source** | `stg_inventory_levels.on_hand` + `stg_product_variants.price` |
| **Notes** | Compare to cost valuation for potential margin |

---

## External Data Requirements

These metrics require data from outside Shopify:

| Metric | External Source |
|--------|-----------------|
| Customer Acquisition Cost (CAC) | Marketing platforms (Google/Meta ads) |
| ROAS (Return on Ad Spend) | Marketing platforms |
| Marketing ROI | All marketing costs |
| Shipping Cost (Actual) | Carrier invoices |
| Revenue Per Visitor | Analytics platform (GA4) |
| Conversion Rate | Analytics platform |

---

## Industry Benchmarks

| Metric | Fashion/Apparel | Electronics | General |
|--------|-----------------|-------------|---------|
| AOV | $80-150 | $150-300 | $75-100 |
| Cart Abandonment | 70-75% | 65-70% | 69.99% |
| Return Rate | 20-30% | 8-12% | 15-20% |
| Repeat Purchase Rate | 25-30% | 15-20% | 27% |
| Gross Margin % | 50-70% | 20-40% | 40-50% |
| Fulfillment Time | 1-2 days | 1-2 days | 2 days |

---

## Document Set

This metrics reference is part of a 5-document set:

1. **Architecture Overview** - Design principles and structure
2. **Staging Schema** - All 16 STG table definitions
3. **Warehouse Schema** - All dimension and fact table definitions
4. **Data Lineage** - Transformation details and examples
5. **Metrics Reference** (this document) - 57 metrics with complete lineage

