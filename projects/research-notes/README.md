# Shopify DWH - Generic Layer

**Status:** Research & Design Complete
**Version:** 1.0
**Last Updated:** 2026-01-30

---

## Overview

Generic, productizable Shopify Data Warehouse designed for Exasol. Transforms Shopify's transactional data into a star schema optimized for analytics and BI tools.

### Key Features

- **Star Schema** - Optimized for Exasol columnar storage
- **Line-Item Grain** - Flexible analysis at any level
- **GraphQL-Based ETL** - Future-proof (REST deprecated)
- **Multi-Currency Aware** - Supports international stores
- **Zero Licensing Cost** - Custom Python ETL

---

## Documentation

| Document | Purpose |
|----------|---------|
| [schema.md](schema.md) | Complete DWH schema definition with DDL |
| [api-mapping.md](api-mapping.md) | Shopify API → DWH field mappings |
| [implementation-guide.md](implementation-guide.md) | ETL implementation reference |
| [notes.md](notes.md) | Detailed research notes |
| [context.md](context.md) | Project context and decisions |
| [tasks.md](tasks.md) | Task tracking |

---

## Schema Summary

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴────────┐    ┌─────────────┐
│dim_customer │────┤                │────│ dim_product │
└─────────────┘    │ fact_order_    │    └─────────────┘
                   │  line_item     │
┌─────────────┐    │                │    ┌─────────────┐
│dim_geography│────┤                │────│ dim_discount│
└─────────────┘    └───────┬────────┘    └─────────────┘
                           │
                   ┌───────┴────────┐    ┌─────────────┐
                   │ fact_order_    │────│  dim_order  │
                   │   header       │    └─────────────┘
                   └────────────────┘
                                         ┌─────────────┐
                                         │dim_location │ (for future use)
                                         └─────────────┘
```

### Tables

| Type | Tables |
|------|--------|
| Facts | fact_order_line_item, fact_order_header |
| Dimensions | dim_date, dim_customer, dim_product, dim_geography, dim_order, dim_discount, dim_location |

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Source | Shopify GraphQL Admin API |
| ETL | Python 3.10+ with PyExasol |
| Scheduler | systemd timers |
| Target | Exasol (columnar) |

---

## Key Decisions

| Decision | Choice |
|----------|--------|
| Data Model | Star schema |
| Fact Grain | Line item level |
| Product Grain | Variant level |
| Currency | Shop currency (dim_order.currency) |
| Fulfillment | Flags only (fact_fulfillment backlogged) |
| Inventory | dim_location only (fact_inventory backlogged) |

---

## API Scopes Required

```
read_products
read_inventory
read_orders
read_customers
read_discounts
read_locations
```

---

## Next Steps

1. **ETL Implementation** - Build Python ETL per implementation guide
2. **DYT Layer** - Custom extensions for Dress Your Tech
3. **BI Integration** - Connect Tableau/Power BI

---

## Two-Layer Architecture

This is **Layer 1** (Generic). Works for any Shopify store.

**Layer 2** (Custom) will add:
- DYT-specific voucher tracking
- B2B2C corporate client attribution
- Gamatek fulfillment integration
