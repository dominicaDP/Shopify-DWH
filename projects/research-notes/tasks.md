# Tasks

**Project:** Shopify DWH
**Last Updated:** 2026-01-29

---

## Urgent (Due Today)

---

## High Priority

- [ ] Review and refine schema.md for Exasol-specific considerations
  **Priority:** HIGH | **Added:** 2026-01-29

- [ ] Define Finance-specific measures and calculations
  **Priority:** HIGH | **Added:** 2026-01-29

---

## Normal

- [ ] Document Shopify discount/voucher data structures
  **Priority:** NORMAL | **Added:** 2026-01-29

- [ ] Evaluate ETL/pipeline tooling options for Shopify → Exasol
  **Priority:** NORMAL | **Added:** 2026-01-29

---

## Backlog

- [ ] Design Finance dimension/fact structures
- [ ] Define Products domain data model
- [ ] Define Customers domain data model
- [ ] Define Inventory domain data model
- [ ] Define Fulfillment domain data model
- [ ] Design DYT-specific customization layer
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
