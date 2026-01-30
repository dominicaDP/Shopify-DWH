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

### Schema & Design
- [ ] Design Finance dimension/fact structures
- [ ] Define Products domain data model
- [ ] Define Fulfillment domain data model (fact_fulfillment - backlogged, current flags sufficient)
- [ ] Design DYT-specific customization layer
- [ ] Consider dim_discount schema enhancements (title, usage_limit, usage_count, dates)

### ETL Implementation
- [ ] Set up ETL project structure on Linux server
- [ ] Implement Shopify GraphQL client wrapper
- [ ] Implement PyExasol loader utilities
- [ ] Create Exasol staging schema (SHOPIFY_STG)
- [ ] Build full product sync job (bulk operation)
- [ ] Build incremental orders job
- [ ] Build incremental customers job
- [ ] Build discount codes sync job
- [ ] Implement staging → DWH transforms
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
