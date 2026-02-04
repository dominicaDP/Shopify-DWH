# Shopify DWH - Architecture Overview

**Version:** 2.0
**Last Updated:** 2026-02-04
**Author:** Digital Planet Analytics

---

## Executive Summary

This document describes the two-layer architecture for the Shopify Data Warehouse, designed to support comprehensive ecommerce analytics for Dress Your Tech and future clients.

**Key Numbers:**
- 16 Staging (STG) tables
- 12 Data Warehouse (DWH) tables (7 dimensions + 5 facts)
- 57 ecommerce metrics fully supported
- 100% coverage of standard ecommerce KPIs

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Shopify GraphQL API                                            │
│  POST /admin/api/2024-01/graphql.json                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SHOPIFY_STG (Staging Schema)                                   │
│                                                                 │
│  • Raw data, mirrors Shopify API structure                      │
│  • Row-based, normalized (1 row per transaction, tax line, etc)│
│  • Field names match Shopify API (camelCase → snake_case)      │
│  • No business logic, no transformations                        │
│  • Transient - can be truncated after DWH load                 │
│                                                                 │
│  Tables: 16                                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ Transform + Pivot + Denormalize
┌─────────────────────────────────────────────────────────────────┐
│  SHOPIFY_DWH (Data Warehouse Schema)                            │
│                                                                 │
│  • Reporting-optimized, columnar-friendly                       │
│  • Pivoted arrays → columns (payments, taxes, discounts)       │
│  • Denormalized dimension attributes on facts                   │
│  • User-friendly field names                                    │
│  • Business logic applied (derived flags, calculations)        │
│  • Permanent storage, historical                                │
│                                                                 │
│  Tables: 7 dimensions + 5 facts                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### Staging Layer (SHOPIFY_STG)

| Aspect | Description |
|--------|-------------|
| **Purpose** | Mirror Shopify API structure exactly |
| **Data Format** | Row-based, normalized |
| **Transformations** | None - raw data only |
| **Field Names** | Match API (camelCase → snake_case) |
| **Retention** | Transient (can truncate after DWH load) |
| **Table Count** | 16 tables |

**STG Tables:**
1. stg_orders
2. stg_order_line_items
3. stg_order_transactions
4. stg_order_tax_lines
5. stg_order_discount_applications
6. stg_order_shipping_lines
7. stg_fulfillments
8. stg_fulfillment_line_items
9. stg_refunds
10. stg_refund_line_items
11. stg_customers
12. stg_products
13. stg_product_variants
14. stg_discount_codes
15. stg_locations
16. stg_inventory_levels
17. stg_abandoned_checkouts

### Data Warehouse Layer (SHOPIFY_DWH)

| Aspect | Description |
|--------|-------------|
| **Purpose** | Reporting-optimized analytics |
| **Data Format** | Star schema, denormalized |
| **Transformations** | Pivots, aggregations, calculations |
| **Field Names** | User-friendly, business terms |
| **Retention** | Permanent, historical |
| **Table Count** | 7 dimensions + 5 facts |

**Dimension Tables:**
1. dim_date - Calendar dimension
2. dim_time - Hour-of-day dimension (24 rows)
3. dim_customer - Customer master with RFM segmentation
4. dim_product - Product/variant catalog
5. dim_geography - Shipping/billing locations
6. dim_discount - Discount code definitions
7. dim_location - Fulfillment locations

**Fact Tables:**
1. fact_order - Order-level metrics with pivoted payments/taxes/discounts
2. fact_order_line_item - Line item detail with margins
3. fact_fulfillment - Fulfillment performance metrics
4. fact_refund - Refund and return analytics
5. fact_inventory_snapshot - Inventory tracking over time

---

## Design Principles

### 1. Separation of Concerns

**STG Layer:**
- Handles data extraction complexity
- Deals with API pagination, rate limits
- Stores raw JSON structures
- No business logic

**DWH Layer:**
- Handles reporting complexity
- Applies business rules
- Optimizes for query performance
- Contains all calculations

### 2. Pivot Pattern

Arrays in Shopify (payments, taxes, discounts) are pivoted to columns:

| Before (STG - Rows) | After (DWH - Columns) |
|---------------------|----------------------|
| payment row 1 | payment_1_gateway, payment_1_amount |
| payment row 2 | payment_2_gateway, payment_2_amount |
| payment row 3 | payment_3_gateway, payment_3_amount |

**Benefits:**
- Single row per order for easy reporting
- No joins needed for common analysis
- Columnar DB optimized

### 3. Denormalization

Dimension attributes copied to fact tables for reporting:

```
fact_order includes:
  - customer_email (from dim_customer)
  - customer_name (from dim_customer)
  - shipping_country (from dim_geography)
  - shipping_city (from dim_geography)
```

**Benefits:**
- Fewer joins in reports
- Better query performance
- Self-contained fact rows

### 4. Pre-Calculated Metrics

Complex calculations done during ETL:

| Metric | Pre-Calculated In |
|--------|-------------------|
| Customer LTV | dim_customer.lifetime_revenue |
| RFM Scores | dim_customer.rfm_recency/frequency/monetary_score |
| Gross Margin | fact_order_line_item.gross_margin |
| Fulfillment Time | fact_fulfillment.fulfillment_time_hours |
| Days Since Last Order | dim_customer.days_since_last_order |

---

## Metrics Coverage

The schema supports 57 standard ecommerce metrics across 6 categories:

| Category | Metrics | Coverage |
|----------|---------|----------|
| Sales & Revenue | 8 | 100% |
| Customer Analytics | 11 | 100% |
| Product Performance | 10 | 100% |
| Marketing & Promotions | 9 | 100% |
| Operations & Fulfillment | 11 | 100% |
| Financial | 8 | 100% |
| **Total** | **57** | **100%** |

See "Metrics Reference" document for complete metric definitions and lineage.

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Source System | Shopify GraphQL Admin API |
| Data Warehouse | Exasol (columnar) |
| ETL | Custom Python + PyExasol |
| Scheduling | systemd timers |
| API Method | Bulk Operations for large datasets |

---

## Schema Summary

| Layer | Tables | Columns (Est.) | Purpose |
|-------|--------|----------------|---------|
| STG | 16 | ~200 | Raw API mirror |
| DWH Dims | 7 | ~120 | Master data |
| DWH Facts | 5 | ~180 | Transactional metrics |
| **Total** | **28** | **~500** | Complete analytics |

---

## Document Set

This architecture overview is part of a 5-document set:

1. **Architecture Overview** (this document) - Design principles and structure
2. **Staging Schema** - All 16 STG table definitions
3. **Warehouse Schema** - All dimension and fact table definitions
4. **Data Lineage** - Transformation details and examples
5. **Metrics Reference** - 57 metrics with complete lineage
