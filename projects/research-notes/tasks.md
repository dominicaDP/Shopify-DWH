# Tasks

**Project:** Shopify DWH
**Last Updated:** 2026-01-30

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
- [ ] Design DYT-specific customization layer (voucher tracking, B2B2C attribution, Gamatek integration)
- [ ] Define fact_fulfillment for carrier analytics (if needed)
- [ ] Define fact_inventory_snapshot for stock tracking (if needed)

### ETL Implementation
- [ ] Set up ETL project structure on Linux server
- [ ] Implement Shopify GraphQL client wrapper
- [ ] Implement PyExasol loader utilities
- [ ] Create SHOPIFY_STG schema (10 staging tables per schema-layered.md)
- [ ] Create SHOPIFY_DWH schema (facts + dims per schema-layered.md)
- [ ] Build STG loaders:
  - [ ] stg_orders + stg_order_line_items + stg_order_transactions + stg_order_tax_lines + stg_order_discount_applications + stg_order_shipping_lines
  - [ ] stg_customers
  - [ ] stg_products + stg_product_variants
  - [ ] stg_discount_codes
  - [ ] stg_locations
- [ ] Build STG → DWH transforms:
  - [ ] Pivot payments/taxes/discounts → fact_order
  - [ ] Denormalize → fact_order_line_item
  - [ ] Aggregate LTV metrics → dim_customer
  - [ ] Build dim_product, dim_geography, dim_discount, dim_location
  - [ ] Generate dim_date, dim_time
- [ ] Configure systemd timers
- [ ] Add error handling & monitoring

### Other
- [ ] Market opportunity analysis

---

## Blocked

---

## Completed

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
