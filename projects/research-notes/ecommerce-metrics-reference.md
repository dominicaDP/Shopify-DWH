# Ecommerce Metrics & KPIs Reference

**Purpose:** Comprehensive reference for Shopify data warehouse schema validation
**Last Updated:** 2026-02-04
**Sources:** Industry research, Shopify documentation, ecommerce analytics best practices

---

## Table of Contents

1. [Sales & Revenue Metrics](#1-sales--revenue-metrics)
2. [Customer Analytics](#2-customer-analytics)
3. [Product Performance](#3-product-performance)
4. [Marketing & Promotions](#4-marketing--promotions)
5. [Operations & Fulfillment](#5-operations--fulfillment)
6. [Financial Metrics](#6-financial-metrics)
7. [Funnel & Conversion Metrics](#7-funnel--conversion-metrics)
8. [Shopify Data Field Mapping](#8-shopify-data-field-mapping)

---

## 1. Sales & Revenue Metrics

### 1.1 Gross Revenue (Total Sales)

| Attribute | Value |
|-----------|-------|
| **Definition** | Total revenue generated from all sales before any deductions |
| **Formula** | `SUM(order_line_items.price * order_line_items.quantity)` |
| **Source Fields** | `orders.total_price`, `line_items.price`, `line_items.quantity` |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | Varies by business size |

### 1.2 Net Revenue (Net Sales)

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue after discounts, returns, and refunds are subtracted |
| **Formula** | `Gross Revenue - Discounts - Returns - Refunds` |
| **Source Fields** | `orders.total_price`, `orders.total_discounts`, `refunds.amount` |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | Aim for Net/Gross ratio > 85% |

### 1.3 Average Order Value (AOV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average revenue per order |
| **Formula** | `Total Revenue / Number of Orders` |
| **Source Fields** | `orders.total_price`, `COUNT(orders.id)` |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | Industry varies; $50-$150 typical for general ecommerce |

### 1.4 Units Per Transaction (UPT)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average number of items per order |
| **Formula** | `Total Units Sold / Number of Orders` |
| **Source Fields** | `SUM(line_items.quantity)`, `COUNT(orders.id)` |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | 2-4 items typical |

### 1.5 Revenue Per Visitor (RPV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average revenue generated per website visitor |
| **Formula** | `Total Revenue / Total Visitors` |
| **Source Fields** | `orders.total_price`, website analytics sessions |
| **Granularity** | Daily, Weekly |
| **Benchmark** | $1-$5 typical |

### 1.6 Sales Growth Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Period-over-period percentage change in sales |
| **Formula** | `((Current Period Sales - Previous Period Sales) / Previous Period Sales) * 100` |
| **Source Fields** | `orders.total_price`, `orders.created_at` |
| **Granularity** | Monthly, Quarterly, Yearly |
| **Benchmark** | 15-25% YoY for healthy growth |

### 1.7 Order Count

| Attribute | Value |
|-----------|-------|
| **Definition** | Total number of orders placed |
| **Formula** | `COUNT(orders.id)` |
| **Source Fields** | `orders.id`, `orders.created_at` |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | Varies by business |

### 1.8 Revenue by Channel

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue breakdown by sales channel (online, POS, wholesale) |
| **Formula** | `SUM(orders.total_price) GROUP BY orders.source_name` |
| **Source Fields** | `orders.source_name`, `orders.total_price` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Varies by business model |

---

## 2. Customer Analytics

### 2.1 Customer Lifetime Value (CLV/LTV)

| Attribute | Value |
|-----------|-------|
| **Definition** | Total revenue expected from a customer over their entire relationship |
| **Formula** | `Average Order Value * Purchase Frequency * Average Customer Lifespan` |
| **Alternative Formula** | `Average Margin Per User / Churn Rate` |
| **Source Fields** | `orders.total_price`, `orders.customer_id`, `orders.created_at` |
| **Granularity** | Monthly, Quarterly (cohort-based) |
| **Benchmark** | LTV:CAC ratio should be 3:1 or higher |

### 2.2 Customer Acquisition Cost (CAC)

| Attribute | Value |
|-----------|-------|
| **Definition** | Total cost to acquire a new customer |
| **Formula** | `Total Sales & Marketing Costs / Number of New Customers Acquired` |
| **Source Fields** | External marketing spend + `customers.created_at` for new customer count |
| **Granularity** | Monthly |
| **Benchmark** | $50-$130 average; Fashion $10-$50; Electronics $80-$200 |

### 2.3 LTV:CAC Ratio

| Attribute | Value |
|-----------|-------|
| **Definition** | Ratio of customer lifetime value to acquisition cost |
| **Formula** | `Customer Lifetime Value / Customer Acquisition Cost` |
| **Source Fields** | Derived from CLV and CAC calculations |
| **Granularity** | Monthly, Quarterly |
| **Benchmark** | 3:1 to 5:1 is healthy; >5:1 may indicate underinvestment |

### 2.4 Customer Retention Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of customers who make repeat purchases |
| **Formula** | `((Customers at End - New Customers) / Customers at Start) * 100` |
| **Source Fields** | `customers.id`, `orders.customer_id`, `orders.created_at` |
| **Granularity** | Monthly, Quarterly, Yearly |
| **Benchmark** | 30-38% average for ecommerce; 60-70% for best-in-class |

### 2.5 Customer Churn Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of customers who stop purchasing |
| **Formula** | `(Customers Lost During Period / Customers at Start of Period) * 100` |
| **Source Fields** | `customers.id`, `orders.customer_id`, `orders.created_at` |
| **Granularity** | Monthly, Quarterly |
| **Benchmark** | <10% monthly is good; >10% monthly is concerning |

### 2.6 Repeat Purchase Rate (Repurchase Rate)

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of customers who have purchased more than once |
| **Formula** | `(Customers with 2+ Orders / Total Customers) * 100` |
| **Source Fields** | `customers.orders_count`, `customers.id` |
| **Granularity** | Monthly, Quarterly |
| **Benchmark** | 20-40% is healthy; Consumables 30-45%; Fashion 20-25% |

### 2.7 Purchase Frequency

| Attribute | Value |
|-----------|-------|
| **Definition** | Average number of purchases per customer in a period |
| **Formula** | `Total Orders / Unique Customers` |
| **Source Fields** | `COUNT(orders.id)`, `COUNT(DISTINCT orders.customer_id)` |
| **Granularity** | Monthly, Quarterly, Yearly |
| **Benchmark** | Varies by product type; consumables higher |

### 2.8 Time Between Purchases

| Attribute | Value |
|-----------|-------|
| **Definition** | Average days between a customer's orders |
| **Formula** | `AVG(Order Date - Previous Order Date)` per customer |
| **Source Fields** | `orders.created_at`, `orders.customer_id` |
| **Granularity** | Monthly analysis |
| **Benchmark** | 30-60 days typical; use for re-engagement timing |

### 2.9 New vs Returning Customer Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue split between first-time and repeat customers |
| **Formula** | Revenue WHERE customer.orders_count = 1 vs > 1 |
| **Source Fields** | `orders.total_price`, `customers.orders_count` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Returning customers spend 67% more on average |

### 2.10 RFM Segmentation

| Attribute | Value |
|-----------|-------|
| **Definition** | Customer segmentation based on Recency, Frequency, Monetary value |
| **Recency** | Days since last purchase |
| **Frequency** | Number of purchases in period |
| **Monetary** | Total spend in period |
| **Source Fields** | `orders.created_at`, `orders.customer_id`, `orders.total_price` |
| **Granularity** | Monthly refresh |
| **Segments** | Champions, Loyal, At Risk, Lost, etc. |

### 2.11 Cohort Analysis Metrics

| Attribute | Value |
|-----------|-------|
| **Definition** | Tracking customer behavior by acquisition cohort |
| **Metrics** | Retention by cohort, Revenue by cohort, LTV by cohort |
| **Source Fields** | `customers.created_at` (cohort), `orders.created_at`, `orders.total_price` |
| **Granularity** | Monthly cohorts, tracked over 12+ months |
| **Use Case** | Identify changes in customer quality over time |

---

## 3. Product Performance

### 3.1 Sell-Through Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of inventory sold in a period |
| **Formula** | `(Units Sold / Beginning Inventory) * 100` |
| **Source Fields** | `inventory_levels.available`, `line_items.quantity` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | 60% average; 80%+ excellent |

### 3.2 Inventory Turnover Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | How many times inventory is sold and replaced in a period |
| **Formula** | `Cost of Goods Sold / Average Inventory Value` |
| **Source Fields** | COGS calculation, `inventory_levels.available`, `products.cost` |
| **Granularity** | Monthly, Quarterly, Yearly |
| **Benchmark** | 4-6x/year retail; 2-4x electronics; 8-12x consumables |

### 3.3 Days Sales of Inventory (DSI)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average days to sell current inventory |
| **Formula** | `(Average Inventory / COGS) * 365` or `365 / Inventory Turnover` |
| **Source Fields** | Inventory value, COGS |
| **Granularity** | Monthly |
| **Benchmark** | Lower is better; 30-60 days typical |

### 3.4 Product Revenue Contribution

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue contribution by product/category |
| **Formula** | `Product Revenue / Total Revenue * 100` |
| **Source Fields** | `line_items.price`, `line_items.quantity`, `products.id` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Identify top 20% products (Pareto principle) |

### 3.5 Units Sold by Product

| Attribute | Value |
|-----------|-------|
| **Definition** | Quantity sold per product/variant |
| **Formula** | `SUM(line_items.quantity) GROUP BY product_id` |
| **Source Fields** | `line_items.quantity`, `line_items.product_id` |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | Varies; track velocity trends |

### 3.6 Average Selling Price (ASP)

| Attribute | Value |
|-----------|-------|
| **Definition** | Average price at which a product is sold |
| **Formula** | `Total Product Revenue / Units Sold` |
| **Source Fields** | `line_items.price`, `line_items.quantity` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Compare to list price for discount impact |

### 3.7 Stock-Out Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of time a product is out of stock |
| **Formula** | `(Days Out of Stock / Total Days) * 100` |
| **Source Fields** | `inventory_levels.available`, historical snapshots |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | <5% ideal; high rates indicate lost sales |

### 3.8 Dead Stock Percentage

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of inventory with no sales in X days |
| **Formula** | `(Value of Dead Stock / Total Inventory Value) * 100` |
| **Source Fields** | `inventory_levels`, `line_items` with no recent sales |
| **Granularity** | Monthly, Quarterly |
| **Benchmark** | <10% of inventory |

### 3.9 Product Return Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of units returned by product |
| **Formula** | `(Units Returned / Units Sold) * 100` |
| **Source Fields** | `refund_line_items.quantity`, `line_items.quantity` |
| **Granularity** | Monthly |
| **Benchmark** | <30% (online avg); varies by category |

### 3.10 Daily Sales Velocity

| Attribute | Value |
|-----------|-------|
| **Definition** | Average units sold per day |
| **Formula** | `Total Units Sold / Number of Days` |
| **Source Fields** | `line_items.quantity`, date range |
| **Granularity** | Daily rolling average |
| **Benchmark** | Use for inventory planning |

---

## 4. Marketing & Promotions

### 4.1 Discount Usage Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of orders using a discount |
| **Formula** | `(Orders with Discount / Total Orders) * 100` |
| **Source Fields** | `orders.total_discounts > 0`, `discount_applications` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Monitor for over-discounting (>40% may erode margins) |

### 4.2 Average Discount Amount

| Attribute | Value |
|-----------|-------|
| **Definition** | Average discount value per discounted order |
| **Formula** | `Total Discounts / Number of Discounted Orders` |
| **Source Fields** | `orders.total_discounts` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Track as % of AOV |

### 4.3 Discount Penetration Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of revenue sold at discount |
| **Formula** | `(Discounted Revenue / Total Revenue) * 100` |
| **Source Fields** | Revenue from orders with discounts |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | <30% for healthy margins |

### 4.4 Promotion Code Performance

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue and orders attributed to specific codes |
| **Formula** | `SUM(revenue), COUNT(orders) GROUP BY discount_code` |
| **Source Fields** | `discount_codes.code`, `orders.total_price` |
| **Granularity** | Per campaign, Monthly |
| **Benchmark** | Compare code performance for optimization |

### 4.5 Return on Ad Spend (ROAS)

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue generated per dollar of ad spend |
| **Formula** | `Revenue from Ads / Ad Spend` |
| **Source Fields** | Attributed orders + external ad platform data |
| **Granularity** | Daily, Weekly, Monthly |
| **Benchmark** | 4:1 or higher is good; varies by industry |

### 4.6 Marketing ROI

| Attribute | Value |
|-----------|-------|
| **Definition** | Return on total marketing investment |
| **Formula** | `((Revenue - Marketing Cost) / Marketing Cost) * 100` |
| **Source Fields** | `orders.total_price` + external marketing costs |
| **Granularity** | Monthly, Quarterly |
| **Benchmark** | 5:1 or higher is good |

### 4.7 Revenue by Traffic Source

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue breakdown by acquisition channel |
| **Formula** | `SUM(orders.total_price) GROUP BY traffic_source` |
| **Source Fields** | `orders.landing_site`, UTM parameters, referring_site |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Diversify; don't rely on single channel |

### 4.8 Email Marketing Metrics

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue and conversions from email campaigns |
| **Metrics** | Open rate, Click rate, Conversion rate, Revenue per email |
| **Source Fields** | External email platform + attributed orders |
| **Granularity** | Per campaign, Monthly |
| **Benchmark** | 50%+ open rate; 3-7% click rate; 3-4% conversion |

### 4.9 Affiliate/Partner Revenue

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue attributed to affiliate/partner channels |
| **Formula** | `SUM(orders.total_price) WHERE source = affiliate` |
| **Source Fields** | `orders.source_name`, UTM tracking |
| **Granularity** | Monthly |
| **Benchmark** | Track commission costs vs revenue |

---

## 5. Operations & Fulfillment

### 5.1 Order Fulfillment Time

| Attribute | Value |
|-----------|-------|
| **Definition** | Time from order placement to shipment |
| **Formula** | `AVG(fulfillment.created_at - order.created_at)` |
| **Source Fields** | `orders.created_at`, `fulfillments.created_at` |
| **Granularity** | Daily, Weekly |
| **Benchmark** | <24-48 hours ideal; <72 hours acceptable |

### 5.2 Total Order Cycle Time

| Attribute | Value |
|-----------|-------|
| **Definition** | Time from order placement to customer delivery |
| **Formula** | `AVG(delivery_date - order.created_at)` |
| **Source Fields** | `orders.created_at`, tracking data delivery date |
| **Granularity** | Weekly |
| **Benchmark** | <6 days (50% abandon if >6 days expected) |

### 5.3 On-Time Shipping Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of orders shipped by promised date |
| **Formula** | `(Orders Shipped On Time / Total Orders) * 100` |
| **Source Fields** | `fulfillments.created_at`, promised ship date |
| **Granularity** | Daily, Weekly |
| **Benchmark** | >95% good; >98% best-in-class; <93.4% needs attention |

### 5.4 On-Time Delivery Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of orders delivered by promised date |
| **Formula** | `(Orders Delivered On Time / Total Orders) * 100` |
| **Source Fields** | Carrier tracking data, promised delivery date |
| **Granularity** | Weekly |
| **Benchmark** | >95% good |

### 5.5 Order Accuracy Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of orders shipped without errors |
| **Formula** | `(Accurate Orders / Total Orders) * 100` |
| **Source Fields** | Returns with reason "wrong item", customer complaints |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | >99% for best-in-class |

### 5.6 Return Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of orders returned |
| **Formula** | `(Returned Orders / Total Orders) * 100` |
| **Source Fields** | `COUNT(refunds)`, `COUNT(orders)` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | 20-30% average for online; lower is better |

### 5.7 Return Reason Analysis

| Attribute | Value |
|-----------|-------|
| **Definition** | Breakdown of returns by reason |
| **Formula** | `COUNT(returns) GROUP BY return_reason` |
| **Source Fields** | `refunds.note`, return reason tags |
| **Granularity** | Monthly |
| **Benchmark** | Identify top reasons for reduction |

### 5.8 Shipping Cost per Order

| Attribute | Value |
|-----------|-------|
| **Definition** | Average shipping cost incurred per order |
| **Formula** | `Total Shipping Costs / Number of Orders` |
| **Source Fields** | Carrier invoices, `orders.shipping_lines.price` (charged) |
| **Granularity** | Monthly |
| **Benchmark** | Keep below 10-15% of AOV |

### 5.9 Cost Per Order (Fulfillment)

| Attribute | Value |
|-----------|-------|
| **Definition** | Total fulfillment cost per order |
| **Formula** | `(Labor + Packaging + Shipping + Overhead) / Orders` |
| **Source Fields** | External cost data + order counts |
| **Granularity** | Monthly |
| **Benchmark** | Varies; track trend over time |

### 5.10 Refund Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of orders with full or partial refunds |
| **Formula** | `(Orders with Refunds / Total Orders) * 100` |
| **Source Fields** | `refunds.order_id`, `orders.id` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | <5% healthy |

### 5.11 Refund Amount

| Attribute | Value |
|-----------|-------|
| **Definition** | Total value of refunds issued |
| **Formula** | `SUM(refund_transactions.amount)` |
| **Source Fields** | `refunds.transactions.amount` |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | Track as % of gross revenue |

---

## 6. Financial Metrics

### 6.1 Gross Profit

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue minus cost of goods sold |
| **Formula** | `Net Revenue - COGS` |
| **Source Fields** | `orders.total_price`, `orders.total_discounts`, product costs |
| **Granularity** | Monthly |
| **Benchmark** | Must be positive for viable business |

### 6.2 Gross Profit Margin

| Attribute | Value |
|-----------|-------|
| **Definition** | Gross profit as percentage of revenue |
| **Formula** | `(Gross Profit / Net Revenue) * 100` |
| **Source Fields** | Gross profit calculation |
| **Granularity** | Monthly |
| **Benchmark** | 40-80% for ecommerce; 45% average; 50-70% considered good |

**Industry Benchmarks:**
- Digital products/Software: 70-90%
- Beauty/Cosmetics: 50-70%
- Luxury goods: 60-70%
- Fashion/Apparel: 45-60%
- Electronics: 15-25%

### 6.3 Net Profit Margin

| Attribute | Value |
|-----------|-------|
| **Definition** | Net profit as percentage of revenue after all expenses |
| **Formula** | `(Net Profit / Total Revenue) * 100` |
| **Source Fields** | All revenue and expense data |
| **Granularity** | Monthly, Quarterly |
| **Benchmark** | 10-20% healthy; <5% is poor; Shopify merchants avg 10-20% |

### 6.4 Cost of Goods Sold (COGS)

| Attribute | Value |
|-----------|-------|
| **Definition** | Direct costs of products sold |
| **Includes** | Product cost, shipping to warehouse, packaging, direct labor |
| **Formula** | `SUM(line_items.quantity * product.cost)` |
| **Source Fields** | Product cost (variant level), `line_items.quantity` |
| **Granularity** | Monthly |
| **Benchmark** | Lower COGS = higher margins |

### 6.5 Contribution Margin

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue minus variable costs per unit/order |
| **Formula** | `(Price - Variable Costs) / Price * 100` |
| **Source Fields** | `line_items.price`, product costs, variable fulfillment costs |
| **Granularity** | Per product, Monthly |
| **Benchmark** | Must cover fixed costs and profit |

### 6.6 Revenue Per Employee

| Attribute | Value |
|-----------|-------|
| **Definition** | Revenue generated per full-time employee |
| **Formula** | `Total Revenue / Number of Employees` |
| **Source Fields** | `orders.total_price` + HR data |
| **Granularity** | Quarterly, Yearly |
| **Benchmark** | $200K-$500K typical for ecommerce |

### 6.7 Tax Collected

| Attribute | Value |
|-----------|-------|
| **Definition** | Total sales tax collected |
| **Formula** | `SUM(orders.total_tax)` |
| **Source Fields** | `orders.total_tax`, `orders.tax_lines` |
| **Granularity** | Monthly |
| **Benchmark** | Must match remittance requirements |

### 6.8 Shipping Revenue vs Cost

| Attribute | Value |
|-----------|-------|
| **Definition** | Comparison of shipping charged vs shipping paid |
| **Formula** | `Shipping Revenue - Actual Shipping Cost` |
| **Source Fields** | `orders.shipping_lines.price`, carrier invoices |
| **Granularity** | Monthly |
| **Benchmark** | Aim for neutral or positive |

---

## 7. Funnel & Conversion Metrics

### 7.1 Conversion Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of visitors who complete a purchase |
| **Formula** | `(Orders / Sessions) * 100` |
| **Source Fields** | `COUNT(orders)`, website analytics sessions |
| **Granularity** | Daily, Weekly |
| **Benchmark** | 2-4% average; >4% is excellent |

### 7.2 Add-to-Cart Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of visitors who add items to cart |
| **Formula** | `(Sessions with Add-to-Cart / Total Sessions) * 100` |
| **Source Fields** | Website analytics cart events |
| **Granularity** | Daily, Weekly |
| **Benchmark** | 7.52% average |

### 7.3 Cart-to-Checkout Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of carts that reach checkout |
| **Formula** | `(Checkouts Started / Carts Created) * 100` |
| **Source Fields** | `checkouts` data, cart events |
| **Granularity** | Daily, Weekly |
| **Benchmark** | 30-40% typical |

### 7.4 Cart Abandonment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of carts abandoned before purchase |
| **Formula** | `(Abandoned Carts / Total Carts) * 100` |
| **Source Fields** | `abandoned_checkouts`, completed orders |
| **Granularity** | Daily, Weekly |
| **Benchmark** | 70.22% average; <60% is good; >70% needs optimization |

### 7.5 Checkout Abandonment Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of started checkouts not completed |
| **Formula** | `((Checkouts Started - Orders) / Checkouts Started) * 100` |
| **Source Fields** | `checkouts` started vs `orders` completed |
| **Granularity** | Daily, Weekly |
| **Benchmark** | Identify checkout friction |

### 7.6 Bounce Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of visitors who leave without interaction |
| **Formula** | `(Single-page Sessions / Total Sessions) * 100` |
| **Source Fields** | Website analytics |
| **Granularity** | Daily |
| **Benchmark** | 40-60% typical; lower is better |

### 7.7 Abandoned Cart Recovery Rate

| Attribute | Value |
|-----------|-------|
| **Definition** | Percentage of abandoned carts recovered through email/remarketing |
| **Formula** | `(Recovered Carts / Abandoned Carts) * 100` |
| **Source Fields** | `abandoned_checkouts` + subsequent orders |
| **Granularity** | Weekly, Monthly |
| **Benchmark** | 3-5% recovery rate typical |

---

## 8. Shopify Data Field Mapping

### Orders Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Revenue** | `total_price`, `subtotal_price`, `total_discounts`, `total_tax` |
| **Customer** | `customer_id`, `email`, `customer.orders_count` |
| **Time** | `created_at`, `processed_at`, `closed_at`, `cancelled_at` |
| **Status** | `financial_status`, `fulfillment_status` |
| **Channel** | `source_name`, `landing_site`, `referring_site` |
| **Location** | `billing_address`, `shipping_address` |
| **Shipping** | `shipping_lines` (price, title, carrier) |

### Line Items Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Product** | `product_id`, `variant_id`, `title`, `sku` |
| **Quantity** | `quantity`, `fulfillable_quantity` |
| **Pricing** | `price`, `total_discount`, `tax_lines` |
| **Properties** | `properties` (custom attributes) |

### Customers Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Identity** | `id`, `email`, `first_name`, `last_name` |
| **History** | `orders_count`, `total_spent`, `created_at` |
| **Marketing** | `accepts_marketing`, `marketing_opt_in_level` |
| **Tags** | `tags` (for segmentation) |

### Products Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Identity** | `id`, `title`, `handle`, `product_type` |
| **Classification** | `vendor`, `tags`, `collections` |
| **Variants** | `variants.price`, `variants.sku`, `variants.inventory_quantity` |
| **Status** | `status`, `published_at` |

### Inventory Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Levels** | `inventory_item_id`, `location_id`, `available`, `on_hand` |
| **Tracking** | `inventory_management`, `inventory_policy` |
| **Cost** | `inventory_item.cost` (requires scope) |

### Fulfillments Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Timing** | `created_at`, `updated_at` |
| **Status** | `status`, `shipment_status` |
| **Tracking** | `tracking_number`, `tracking_url`, `tracking_company` |
| **Items** | `line_items` (fulfilled items) |

### Refunds Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Identity** | `id`, `order_id`, `created_at` |
| **Amount** | `transactions.amount`, `transactions.kind` |
| **Items** | `refund_line_items.quantity`, `refund_line_items.line_item_id` |
| **Reason** | `note` |

### Discount Codes Object

| Metric Category | Key Fields |
|-----------------|------------|
| **Identity** | `code`, `price_rule_id` |
| **Type** | `value_type` (fixed_amount, percentage) |
| **Value** | `value` |
| **Usage** | `usage_count` |

---

## Summary: Essential Metrics by Business Function

### Must-Have Metrics (Core)

| Function | Essential Metrics |
|----------|-------------------|
| **Sales** | Gross Revenue, Net Revenue, AOV, Order Count |
| **Customer** | CLV, CAC, Retention Rate, Repeat Purchase Rate |
| **Product** | Units Sold, Sell-Through Rate, Product Revenue |
| **Marketing** | Discount Usage, ROAS (if ads) |
| **Operations** | Fulfillment Time, Return Rate, Refund Amount |
| **Financial** | Gross Margin, COGS |
| **Funnel** | Conversion Rate, Cart Abandonment Rate |

### Recommended Metrics (Enhanced Analytics)

| Function | Recommended Metrics |
|----------|---------------------|
| **Sales** | Revenue by Channel, Sales Growth Rate, UPT |
| **Customer** | RFM Segmentation, Cohort Analysis, Time Between Purchases |
| **Product** | Inventory Turnover, Stock-Out Rate, ASP |
| **Marketing** | Code Performance, Revenue by Source |
| **Operations** | On-Time Rate, Return Reasons, Shipping Cost |
| **Financial** | Net Margin, Contribution Margin |
| **Funnel** | Add-to-Cart Rate, Checkout Abandonment |

---

## Sources

- [Shopify 70+ Ecommerce KPIs](https://www.shopify.com/blog/7365564-32-key-performance-indicators-kpis-for-ecommerce)
- [NetSuite 38 Ecommerce Metrics](https://www.netsuite.com/portal/resource/articles/ecommerce/ecommerce-metrics.shtml)
- [BigCommerce Ecommerce Metrics 2026](https://www.bigcommerce.com/articles/ecommerce/ecommerce-metrics/)
- [Baymard Cart Abandonment Statistics](https://baymard.com/lists/cart-abandonment-rate)
- [Shopify Customer Lifetime Value](https://www.shopify.com/blog/customer-lifetime-value)
- [DCL Logistics Fulfillment Metrics](https://dclcorp.com/blog/fulfillment/ecommerce-fulfillment-metrics/)
- [Linnworks Inventory Turnover](https://www.linnworks.com/blog/inventory-turnover-ratios-in-ecommerce/)
- [TrueProfit Gross Margin Benchmarks](https://trueprofit.io/blog/what-is-a-good-gross-profit-margin)
- [Peel Insights RFM Analysis](https://www.peelinsights.com/post/what-is-rfm-analysis)
- [LoyaltyLion Retention Metrics](https://loyaltylion.com/blog/customer-retention-rate)
- [Smile.io Purchase Frequency](https://blog.smile.io/how-to-calculate-purchase-frequency/)
- [Shopify Data Model - Panoply](https://panoply.io/shopify-analytics-guide/understanding-the-shopify-data-model/)
- [Fivetran Shopify Transform Model](https://fivetran.com/docs/transformations/data-models/shopify-data-model/shopify-transform-model)
