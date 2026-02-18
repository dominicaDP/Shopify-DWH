# Tasks

**Project:** Shopify DWH
**Last Updated:** 2026-02-18

---

## Urgent (Due Today)

---

## High Priority

(none)

---

## Normal

---

## Backlog

### Schema & Design (Layer 2 - DYT Specific)
- [ ] Update schema-dyt.md with report mapping findings (campaign_name, subscription parsing, is_marketing, breakage, overspend, is_dual_redemption)
- [ ] Clarify billing/cost data source for Report 18 (team discussion needed)
- [ ] Verify membership tiers in Shopify discount code names (during ETL build)
- [ ] Validate gift card join strategy with real data (Shopify GID vs last 4 chars)
- [ ] Assess which Layer 2 elements could be productized for the core product

### ETL Implementation
- [ ] Set up ETL project structure on Linux server
- [ ] Implement Shopify GraphQL client wrapper
- [ ] Implement PyExasol loader utilities
- [ ] Create SHOPIFY_STG schema (16 staging tables per schema-layered.md)
- [ ] Create SHOPIFY_DWH schema (5 facts + 7 dims per schema-layered.md)
- [ ] Build STG loaders:
  - [ ] stg_orders + stg_order_line_items + stg_order_transactions + stg_order_tax_lines + stg_order_discount_applications + stg_order_shipping_lines
  - [ ] stg_fulfillments + stg_fulfillment_line_items
  - [ ] stg_refunds + stg_refund_line_items
  - [ ] stg_customers
  - [ ] stg_products + stg_product_variants
  - [ ] stg_discount_codes
  - [ ] stg_locations
  - [ ] stg_inventory_levels
  - [ ] stg_abandoned_checkouts
  - [ ] stg_gift_cards
- [ ] Build STG → DWH transforms:
  - [ ] Pivot payments/taxes/discounts → fact_order
  - [ ] Denormalize → fact_order_line_item
  - [ ] Build fact_fulfillment (fulfillment timing metrics)
  - [ ] Build fact_refund (refund analytics)
  - [ ] Build fact_inventory_snapshot (inventory tracking)
  - [ ] Aggregate LTV + RFM metrics → dim_customer
  - [ ] Build dim_product, dim_geography, dim_discount, dim_location
  - [ ] Generate dim_date, dim_time
- [ ] Configure systemd timers
- [ ] Add error handling & monitoring

### ETL Implementation (Layer 2 - DYT)
- [ ] Set up SQL Server connection and extraction for DYT_STG
- [ ] Build DYT_STG loaders:
  - [ ] stg_channels (from SQL Server)
  - [ ] stg_voucher_inventory (from SQL Server)
  - [ ] stg_voucher_distributions (from SQL Server)
- [ ] Build DYT_DWH transforms:
  - [ ] dim_channel ← stg_channels
  - [ ] dim_voucher ← stg_voucher_inventory + distributions + Shopify data
  - [ ] fact_voucher_lifecycle ← all sources joined
  - [ ] fact_channel_daily ← aggregation of fact_voucher_lifecycle

### Productization (Configuration-Driven)
- [ ] Define configuration schema (YAML structure) for deployment_config.yaml
- [ ] Build schema generator (Jinja2-based DDL from config)
- [ ] Build ETL generator (parameterized pivot SQL from config)
- [ ] Create auto-discovery script (extract payment methods, tax types from Shopify)
- [ ] Config validation tool
- [ ] Deployment automation scripts

### Other
- [ ] Market opportunity analysis

---

## Blocked

---

## Completed

### Week of 2026-02-17

- [x] Analyse 38 existing DYT reports against Layer 2 schema
  **Priority:** HIGH | **Added:** 2026-02-18 | **Completed:** 2026-02-18
  **Created:** report-mapping-analysis.md with coverage mapping, 11 Q&A items, CampaignSegmentTbl analysis
  **Key findings:** Client = dim_channel, Campaign = attribute on dim_voucher, subscription tiers encoded in Campaign name
  **Open:** Billing/cost data source (Q4), membership tiers (Q6)

- [x] Query and analyse CampaignSegmentTbl Campaign-Client relationships
  **Priority:** HIGH | **Added:** 2026-02-18 | **Completed:** 2026-02-18
  **Finding:** ~30+ real business clients, Campaign is sub-classification (not a standalone dimension)
  **Data quality:** Refund tracking uses two inconsistent patterns, Marketing is catch-all for internal vouchers

- [x] Generate Word document for report mapping analysis (07-Report-Mapping-Analysis.docx)
  **Priority:** NORMAL | **Added:** 2026-02-18 | **Completed:** 2026-02-18

- [x] Design DYT Layer 2 B2B2C voucher & channel schema
  **Priority:** HIGH | **Added:** 2026-02-18 | **Completed:** 2026-02-18
  **Created:** schema-dyt.md with 3 DYT_STG tables, 2 dimensions, 2 facts, 22 metrics
  **Schemas:** DYT_STG (SQL Server source) + DYT_DWH (channel-centric analytics)

- [x] Add stg_gift_cards to Layer 1 schema (gap fill)
  **Priority:** HIGH | **Added:** 2026-02-18 | **Completed:** 2026-02-18
  **Added:** stg_gift_cards to SHOPIFY_STG in schema-layered.md (14 columns from giftCards API)
  **Note:** Shopify masks full gift card codes - only last 4 chars available via API

- [x] Document Layer 2 join strategy (Shopify ↔ SQL Server)
  **Priority:** HIGH | **Added:** 2026-02-18 | **Completed:** 2026-02-18
  **Documented:** Discount code join (direct code match), gift card join (3 options with confidence levels)

- [x] Define 22 DYT-specific metrics (voucher funnel, channel financial, timing, subscription)
  **Priority:** NORMAL | **Added:** 2026-02-18 | **Completed:** 2026-02-18
  **Categories:** Voucher funnel (7), Channel financial (6), Timing (3), Subscription (3), Distribution (3)

---

### Week of 2026-02-03

- [x] Conduct metrics gap analysis against standard ecommerce KPIs
  **Priority:** HIGH | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Finding:** Identified 6 missing STG tables, 5 missing STG fields, 3 missing DWH tables

- [x] Add fulfillment tracking to schema (stg_fulfillments, stg_fulfillment_line_items, fact_fulfillment)
  **Priority:** HIGH | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Metrics enabled:** Fulfillment time, same-day rate, on-time shipping rate

- [x] Add refund tracking to schema (stg_refunds, stg_refund_line_items, fact_refund)
  **Priority:** HIGH | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Metrics enabled:** Refund rate, return rate, restock analysis

- [x] Add inventory tracking to schema (stg_inventory_levels, fact_inventory_snapshot)
  **Priority:** MEDIUM | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Metrics enabled:** Sell-through rate, stock-out rate, inventory valuation

- [x] Add abandoned checkout tracking (stg_abandoned_checkouts)
  **Priority:** MEDIUM | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Metrics enabled:** Cart abandonment rate, recovery rate

- [x] Add channel attribution fields to stg_orders (source_name, landing_site, referring_site)
  **Priority:** HIGH | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Metrics enabled:** Revenue by channel, marketing attribution

- [x] Add RFM segmentation to dim_customer
  **Priority:** MEDIUM | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Added:** rfm_recency/frequency/monetary_score, rfm_segment with 11 segment definitions

- [x] Create comprehensive metrics lineage documentation (57 metrics)
  **Priority:** HIGH | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Created:** Metrics lineage section in schema-layered.md + metrics-lineage-reference.md

- [x] Create ecommerce metrics reference with industry benchmarks
  **Priority:** NORMAL | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Created:** ecommerce-metrics-reference.md with 57 metrics, formulas, and benchmarks

- [x] Add Metrics-Driven Schema Design pattern to dev-patterns.md
  **Priority:** NORMAL | **Added:** 2026-02-04 | **Completed:** 2026-02-04
  **Pattern:** Start with metrics, work backwards to data sources

---

### Week of 2026-01-27

- [x] Set up Second Brain knowledge management system
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29

- [x] Document business context (Digital Planet, DYT, Gamatek, B2B2C model)
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29

- [x] Define project vision and two-layer architecture
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29

- [x] Establish scope boundaries and phased approach
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29

- [x] Research data modeling approaches (Star vs Data Vault vs alternatives)
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29
  **Decision:** Star schema - best fit for Exasol, Shopify, productizable

- [x] Map Shopify Orders data model (API entities and fields)
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29

- [x] Define Orders fact table structure for generic Shopify DWH
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29
  **Decision:** Two facts - fact_order_line_item (line grain) + fact_order_header

- [x] Define dimension tables for Orders domain
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29
  **Dimensions:** dim_date, dim_customer, dim_product, dim_geography, dim_order, dim_discount

- [x] Research competitive landscape (Shopify DWH/analytics products)
  **Priority:** NORMAL | **Added:** 2026-01-29 | **Completed:** 2026-01-29
  **Finding:** Gap exists for Exasol-native, B2B2C-capable, mid-market priced solution

- [x] Define Finance-specific measures and calculations
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29
  **Defined:** Revenue, Discount, Profitability, Averages, Refunds, Volume, Trends

- [x] Research Shopify Product API and validate dim_product schema
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-29
  **Finding:** Added option1/2/3, barcode. Cost comes from InventoryItem API.
  **Note:** REST API deprecated - use GraphQL for ETL

- [x] Research InventoryItem API for cost data
  **Priority:** NORMAL | **Added:** 2026-01-29 | **Completed:** 2026-01-30
  **Finding:** unitCost in InventoryItem (MoneyV2 type). InventoryLevel tracks quantities per location.

- [x] Document Shopify discount/voucher data structures
  **Priority:** NORMAL | **Added:** 2026-01-29 | **Completed:** 2026-01-30
  **Finding:** 4 discount code types, DiscountRedeemCode.asyncUsageCount for redemptions, DiscountApplication on orders

- [x] Evaluate ETL/pipeline tooling options for Shopify → Exasol
  **Priority:** NORMAL | **Added:** 2026-01-29 | **Completed:** 2026-01-30
  **Decision:** Custom Python ETL with PyExasol, systemd timers, Shopify bulk operations

- [x] Review and refine schema.md for Exasol-specific considerations
  **Priority:** HIGH | **Added:** 2026-01-29 | **Completed:** 2026-01-30
  **Added:** Distribution keys, partition keys, replication border config, VARCHAR sizing, DDL examples

- [x] Research Orders API structure for ETL design
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Finding:** Schema validated against API. All fields map correctly. Use shopMoney from MoneyBag.

- [x] Research Customers API and validate dim_customer schema
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Finding:** Schema validated. Note deprecated fields (email, phone, emailMarketingConsent) - use new object patterns in ETL.

- [x] Research Fulfillment API for generic layer
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Finding:** FulfillmentOrder (plan) vs Fulfillment (actual). Current schema sufficient (Option A). Backlog fact_fulfillment for carrier analytics.

- [x] Define Inventory domain data model
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Decision:** Option C - Add dim_location now, backlog fact_inventory_snapshot for later.

- [x] Decide on multi-currency handling
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Decision:** Option B - Use shopMoney amounts, store currency in dim_order.currency.

- [x] Consolidate generic layer documentation
  **Priority:** HIGH | **Completed:** 2026-01-30
  **Created:** README.md, api-mapping.md, implementation-guide.md

- [x] Enhance dim_discount schema
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Added:** discount_id, title, status, starts_at, ends_at, usage_limit, usage_count, applies_once_per_customer, created_at

- [x] Add dim_time for time-of-day analysis
  **Priority:** LOW | **Completed:** 2026-01-30
  **Added:** 24-row dimension with hour, day_part, business hours. Added order_time_key to fact tables.

- [x] Create Word documents for design review
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Created:** Overview, Schema Reference, API Mapping documents for stakeholder review

- [x] Add GraphQL endpoint references to API mapping
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Added:** Query names, bulk operation flags, example queries for each table

- [x] Add comprehensive transformations reference
  **Priority:** HIGH | **Completed:** 2026-01-30
  **Added:** 13 transformation types with code examples (GID extraction, date/time keys, money extraction, pivots, etc.)

- [x] Add GraphQL vs REST clarification to documentation
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Added:** Explanation that GraphQL uses single endpoint with different query bodies

- [x] Redesign schema with two-layer architecture (STG + DWH)
  **Priority:** HIGH | **Completed:** 2026-01-30
  **Decision:** STG mirrors Shopify API (row-based), DWH is reporting-optimized (pivoted columns, denormalized)
  **Created:** schema-layered.md with 10 STG tables, reporting-optimized DWH facts/dims, data lineage

- [x] Create layered schema Word document
  **Priority:** NORMAL | **Completed:** 2026-01-30
  **Created:** Shopify-DWH-Schema-Layered.docx with STG tables, DWH tables, pivot examples, lineage
