# DYT Complete Report Inventory - Segmented by Department

# LOGISTICS TEAM
## 1. DYT & Gamma Order Comparison
Purpose: Reconciliation report comparing DYT orders with Gammatek supplier orders to identify discrepancies in order fulfillment.
Key Fields: DYT Order Number, DYT Order Date, Gammatek Order Number, Received Date/Time

## 2. DYT & Gamma Stock Update
Purpose: Inventory update report showing variant SKUs with inventory quantities and update commands for stock synchronization.
Key Fields: Variant SKU, Variant Inventory Qty, Command (UPDATE)

## 3. DYT Gammatek Sales Report
Purpose: Inventory fulfillment report showing products received from Gammatek supplier with quantities.
Key Fields: SKU, Item Name, Quantity

## 4. DYT Gamma Sku's Reconciliation
Purpose: SKU matching and availability report comparing Gammatek file SKUs against Gammatek API SKUs to identify inventory discrepancies.
Key Fields: GammaFile_Sku, GammaAPI_Sku, Item Description, Category Description, SOH, API Sku Availability
Drill-through: Shows 'Sku Not Present' exceptions

## 5. DYT Pargo Detail
Purpose: Logistics tracking report for Pargo deliveries showing delivery status, consignment tracking, and customer collection details.
Key Fields: Reference, Event Date, Description (Consignment accepted, Order created, Parcel on route, Parcel ready for collection, SMS reminders, Parcel collected)

## 6. DYT Orders - Missing Cell for updating
Purpose: Exception report identifying orders with missing cell phone numbers that require updating for customer contact.
Key Fields: ExtOrderNo, EndCustTelNo

# FINANCE AND EXCO
## 7. DYT Financials (AR and AP)
Purpose: Financial reconciliation report tracking voucher transactions including gift cards, payment IDs, and discount amounts for accounts receivable and accounts payable.
Key Fields: Shopify Transaction Year/Month, Transaction Date, Gammatek Order Date, Order Number, Gammatek Invoice Nbr, Voucher Denomination, Gift Card ID, Voucher Redeemed, Discount Amount, Payment ID

## 8. DYT Order Details (MTD)
Purpose: Month-to-date financial summary of all order transactions including vouchers, discounts, payment methods, and promotional breakdowns by campaign and client.
Key Fields: Transaction Date, Order Number, Voucher Value, Discount Amount, Payfast, Sum Discount_Denomination, Payflex, Total Amount, Avg. Order Value, Breakage Amount, Campaign, Discount Name, Client

## 9. DYT Discount Details (MTD-drill-through New)
Purpose: Detailed drill-through report from Order Details showing granular discount allocation.
Key Fields: Transaction Date, Order Number, Discount Amount, Voucher Amount, Cash Amount, Discount Code, Discount Campaign, Voucher Channel, Discount Target
Relationship: Drill-through from Order Details (MTD)

## 10. DYT Order Summary
Purpose: Executive dashboard showing high-level order statistics by client with total revenue and order counts, including graphical visualization.
Key Fields: Transaction Date, Number of Orders, Voucher Value, Discount Amount, B2C Revenue, Payfast, Payflex, Total Amount, Avg. Order Value, Breakage Amount, Discount Name, Campaign, Client
Visualization: Includes bar chart showing revenue by client (total 335 orders shown)

## 11. DYT Order Volume (MTD)
Purpose: Daily order volume tracking report showing transaction counts per day for month-to-date period.
Key Fields: Transaction Date, Number of Orders

## 12. DYT Order Volume (Summary MTD)
Purpose: Monthly aggregated summary of order volume showing total orders for the month.
Key Fields: Transaction Month, Number of Orders
Relationship: Summary version of Order Volume (MTD)

## 13. DYT Orders (Line-Item Level- MTD)
Purpose: Detailed line-item breakdown of orders showing individual products ordered with cost and pricing information for financial analysis.
Key Fields: Transaction Date, Order Number, SKU, Item Name, Qty, Total Cost (Excl_VAT), Total Prices (Excl_VAT)

## 14. DYT Revenue (Daily Exco Summary)
Purpose: Executive daily revenue summary showing revenue breakdown by payment type (gift cards, discount vouchers, cash) with cash percentage metrics.
Key Fields: Transaction_Date, Number of Orders, Total Revenue, Gift Card Spend, Discount Voucher Spend, Cash Spend, Cash % of Total

## 15. DYT Revenue (Exco Summary)
Purpose: Monthly executive summary aggregating revenue by period with payment type breakdown.
Key Fields: Period, Orders, Total Revenue, Gift Card Spend, Discount Voucher Spend, Cash Spend, Cash % of Total
Relationship: Monthly aggregation of Daily Exco Summary

## 16. DYT Revenue by Client (Exco)
Purpose: Client-level revenue analysis showing number of orders and total revenue per client for executive review.
Key Fields: Client, Number of Orders, Total Revenue

## 17. DYT Revenue by Client (In Process detail)
Purpose: Client revenue tracking report showing transactions that are 'In Process', including order numbers, gift card IDs, and total revenue.
Key Fields: Client, Number of Orders, Gift Card ID, Total Revenue
Period: Current period (e.g., Feb-2026)

## 18. DYT Provisional Billing V1
Purpose: Client billing calculation report showing quantity allocated, redeemed vouchers, redemption rates, voucher base costs, sales revenue, total costs, and profit margins by client and voucher type.
Key Fields: Client, Description, Sum quantity, Sum Total_Redeemed_Vouchers, Redemption_Rate, Sum Voucher Base, Sum Sales Revenue, Sum Total_Costs, Sum Margin

# SALES TEAM
## 19. DYT Gift Card Redemptions
Purpose: Complete gift card lifecycle tracking report showing all gift card details with transaction dates, voucher creation dates, redemption information, and customer segmentation.
Key Fields: Client, Campaign, Voucher Creation Date, Transaction Date, Order ID, Gift Card ID, Last Characters, Note, Voucher Denomination, Voucher Redeemed

## 20. DYT Missing Redemption Info
Purpose: Exception report identifying gift cards with incomplete redemption data to flag processing issues.
Key Fields: Transaction_Date, Order Number, Discount Name, Gift Card ID, Client (Final)

## 21. DYT Redemptions (6 Months Trend)
Purpose: Trending analysis report showing redemption patterns over 6 months with graphical visualization, segmented by month, client, campaign, and discount types.
Key Fields: Month Name, Client, Campaign, Discount Campaign, Discount Name, No. of Orders, Redeemed Vouchers, B2C Revenue, Voucher Amount, Redeemed Discounts, Discount Amount, Overspend, Total Amount

## 22. DYT Redemptions Summary (6 Months Trend)
Purpose: Aggregated summary version of 6-month redemption trend, segmented by specific client showing campaign-level performance.
Key Fields: Month Name, Campaign, Discount Campaign, Voucher Denomination, Total Amount, Redeemed Vouchers, Voucher Amount, Redeemed Discounts, Discount Amount
Relationship: Summary drill-through from Redemptions (6 Months Trend)

## 23. DYT Redemptions (More than 1 redemption)
Purpose: Exception report identifying orders where both a voucher and a discount code have been applied to flag potential redemption issues or fraud.
Key Fields: Client, Campaign, Discount Campaign (More than 1 redemption), Voucher Denomination, No. of Orders, Redeemed Vouchers, Voucher Amount, Discount Amount, Cash Payment, Total Amount, Avg. Order Value

## 24. DYT Redemptions (MTD Campaign drill-through)
Purpose: Month-to-date campaign-level drill-through report showing detailed redemption metrics by client and campaign.
Key Fields: Client, Campaign, Discount Campaign, Voucher Denomination, No. of Orders, Redeemed Vouchers, Redeemed Discounts, Voucher Amount, Discount Amount, Cash Payment, Total Amount, Avg. Order Value
Note: Filtered for Telkom client showing Virtual and Telkom campaigns

## 25. DYT Virtual Subscription Vouchers Report
Purpose: Subscription voucher allocation and performance tracking report showing virtual subscription vouchers allocated via SMS/email, including redemption timing analysis.
Key Fields: Allocation Date, Transaction Date, Order Number, Avg. Order Value, Cash Value, Redemption day difference, Voucher Denomination, Campaign, Client, Customer_Type

# PRODUCT TEAM
## 26. DYT Popular Products (Historical)
Purpose: Historical product sales performance showing top-selling products ranked by quantity sold with pricing.
Key Fields: Product Name, Price (Incl. VAT), Quantity

## 27. DYT Popular Products Report
Purpose: Current month trending analysis comparing product demand for current month versus previous 5 months.
Key Fields: Quantity, Title, Monthly breakdown (September, October, November, December, January, February)
Relationship: Extended trending version of Popular Products (Historical)

## 28. DYT Least Products Report
Purpose: Inverse trending analysis identifying least sold products for current month vs previous 5 months to flag underperforming inventory.
Key Fields: Quantity, Product Name, Monthly breakdown
Relationship: Inverse analysis of Popular Products Report

## 29. DYT Least Products Report (Aigs)
Purpose: Alternative version of least products report with same purpose but different presentation or filtering criteria.
Key Fields: Product Name, Quantity, Monthly trend data

## 30. DYT Product Catalogue
Purpose: Master product catalog reference report listing all DYT products with categorization, pricing, and Ebucks promotional information.
Key Fields: SKU, Name, Product Type, Ebucks Category, Recommended Retail Price, Promo Price

## 31. DYT Product Levels
Purpose: Real-time inventory level tracking report from Shopify showing current stock quantities and last update timestamps for inventory management.
Key Fields: SKU, Title, Inventory_quantity, Updated_at
Data Source: [shopify].[DYTAllProcuts_VW]

## 32. DYT Promo Pricing
Purpose: Promotional pricing report showing products with special pricing presented to Ebucks customers for campaign management.
Key Fields: SKU, Category, PromoPrice
Note: All items shown are in 'Deals and Promotions' category

## 33. DYT New Product Update Result
Purpose: Product catalog management report showing new products added to the system with creation dates and draft status for product team review.
Key Fields: DateCreated, ID, SKU, Title, Status
Note: All records show DRAFT status, indicating products pending publication

## 34. DYT New Product Update Result Summary
Purpose: Daily summary of new product additions showing count of new SKUs added by date for tracking product catalog growth.
Key Fields: DateCreated, Status, SKU (count)
Relationship: Summary aggregation of New Product Update Result

## 35. DYT Capitec (Skull Candy)
Purpose: Client-specific product performance report showing Skull Candy brand products sold through Capitec campaign with cost and pricing analysis.
Key Fields: SKU, Item Name, Quantity, Cost Price (Excl VAT), Total Cost, Unit Price, Total Unit Price
Filters: Client=Capitec, Product Brand=Skull Candy

# CUSTOMER SERVICE / SUPPORT DEPARTMENT
## 36. DYT Service Desk (Yesterday's Emails)
Purpose: Daily customer service workload tracking showing email volume by agent and disposition status to monitor service desk performance.
Key Fields: No. of Emails, Disposition, Agent, Created Date
Time Period: Daily snapshot covering previous day's emails

# MEMBERSHIP / SUBSCRIPTION SERVICES DEPARTMENT
## 37. STD Bank DYT Membership Order Summary
Purpose: Bank membership program tracking showing order volumes by membership tier and discount level for Standard Bank customers.
Key Fields: Period, No. of Orders, Membership tiers (DYTSquad25, GETDRESSED, etc.), Standard Bank Discount levels (15%, 20%, 30%, 40%, 50%), THANKYOU100, Total
Analysis: Monthly trend from Jul-2024 through Feb-2026

# CLIENT-SPECIFIC / MULTI-PURPOSE REPORTS
## 38. Teljoy DYT Vouchers Daily Summary
Purpose: Client-specific daily voucher issuance tracking for Teljoy showing number of customers receiving vouchers per day.
Key Fields: Date, Customers
Client: Teljoy


### Key Drill-Through Relationships:
- Order Details (MTD) → Discount Details (MTD-drill-through New)
- Redemptions (6 Months Trend) → Redemptions Summary (6 Months Trend)
- Redemptions (6 Months Trend) → Redemptions (MTD Campaign drill-through)
- Order Volume (MTD) → Order Volume (Summary MTD)
- Revenue (Daily Exco Summary) → Revenue (Exco Summary)
- Popular Products (Historical) → Popular Products Report
- New Product Update Result → New Product Update Result Summary
- Product Catalogue → Capitec (Skull Candy) [filtered view]
- Gamma Sku's Reconciliation → Sku Not Present exception view