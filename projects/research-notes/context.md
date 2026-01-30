# Shopify DWH

**Project Type:** Work
**Status:** Active
**Priority:** HIGH
**Last Updated:** 2026-01-30

---

## Overview

Build a generic, productizable Shopify Data Warehouse with a custom layer for Dress Your Tech specifics. Transform Shopify's row-based transactional data into a columnar DWH optimized for analytics and reporting.

---

## Business Context

### Company Structure
- **Digital Planet** - Ecommerce enabler (tech and sales side)
- **Dress Your Tech (DYT)** - Mobile products & accessories website (Shopify)
- **Gamatek** - Product supplier and fulfillment partner

### Business Model (B2B2C)
```
Corporate Clients (e.g., Telecoms)
    ↓ attach vouchers to products/contracts
End Consumers
    ↓ redeem vouchers
Dress Your Tech (Shopify)
    ↓ order data
Gamatek (Fulfillment)
```

### Voucher System
- Vouchers created within Shopify (discount codes)
- Format: 15-16 digit alphanumeric (standard Shopify)
- Types: Rand value-based (fixed amount) and percentage-based
- Distribution mechanism: External, out of scope
- Corporate client attribution: Lives outside Shopify, out of scope for base layer

---

## Project Vision

### Two-Layer Architecture

**Layer 1: Generic Shopify DWH (Productizable)**
- Works for any Shopify store
- Maps cleanly to Shopify's native data model
- Standard ecommerce dimensions and facts
- Resellable to other Shopify merchants

**Layer 2: Custom Business Logic (DYT-specific)**
- Voucher complexity
- B2B2C attribution
- Gamatek integration
- Built on top of Layer 1

### Commercial Potential
- Target: Shopify merchants needing analytics beyond built-in reports
- Deployment model: TBD (self-hosted vs SaaS)
- Design thoroughly to support future customer conversations

---

## Technical Decisions

### Confirmed
| Decision | Detail |
|----------|--------|
| Target Platform | Exasol (columnar) |
| Source | Shopify Admin API (GraphQL) |
| Schema Type | Star schema (Exasol-optimized) |
| ETL | Custom Python + PyExasol |
| Scheduler | systemd timers (Linux) |
| History | Configurable import window (parameter-driven) |

### Decision Log

**2026-01-29: Star Schema Selected**

Evaluated: Star, Data Vault, Snowflake, OBT, Activity Schema

Star schema chosen because:
- Exasol optimized for this pattern (columnar + wide fact scans)
- Shopify maps naturally (Orders fact + dimensions)
- Productizable (BI tools expect it, customers understand it)
- Appropriate complexity for single-source DWH
- Solo developer friendly

Rejected alternatives:
- Data Vault: Over-engineered for single source, high build complexity
- Snowflake: No advantage over star, more joins
- OBT: Doesn't scale with scope
- Activity: Wrong paradigm for Shopify's data structure

**2026-01-29: Line Item Grain Selected**

Fact table grain: One row per line item (not per order)

Reasoning:
- More flexible - can aggregate up to order level
- Enables product-level analysis
- Standard approach for retail/ecommerce DWH

**2026-01-30: Custom Python ETL Selected**

Evaluated: Fivetran, Airbyte (Cloud/Self-hosted), Custom Python

Custom Python chosen because:
- Zero licensing cost (Fivetran $500-$10k+/mo)
- Runs on existing infrastructure (Exasol Linux server)
- Full control over logic and optimization
- Productizable as part of DWH offering

Stack: Python 3.10+, PyExasol 2.0, Shopify GraphQL bulk operations, systemd timers

**2026-01-30: Exasol Schema Optimization**

Added Exasol-specific optimizations:
- Distribution keys on JOIN columns (fact_order_line_item → order_key)
- Partition keys on WHERE columns (order_date_key)
- Replication border for small dimension tables
- Reduced VARCHAR sizing (titles 500→255)
- DDL reference with DISTRIBUTE BY / PARTITION BY

### To Research
- ~~ETL/pipeline tooling options~~ ✓ Decided: Custom Python + PyExasol
- ~~Competitive landscape~~ ✓ Gap identified for Exasol-native solution

### Design Principles
- Scale-agnostic (current: 2-4k orders/month, design for 100x)
- Generic base, custom extensions
- Configurable historical depth
- "As if cash" transaction recording

---

## Scope

### Phase 1: Foundation
- Spec and define data structures by business function
- Starting domains: **Orders** and **Finance**
- Research data modeling approaches

### Later Phases
- Reporting definitions
- Additional domains (Products, Inventory, Customers, Fulfillment)
- DYT-specific customization layer
- Market/competitive analysis

### Current Scope Boundaries
| In Scope | Out of Scope (for now) |
|----------|------------------------|
| Shopify data extraction | Voucher distribution mechanism |
| Orders, Finance domains | Corporate client attribution |
| Generic DWH design | Reporting layer |
| Data modeling research | ETL implementation |

---

## Business Domains

All to be included in holistic design, worked sequentially:

| Domain | Priority | Status | Description |
|--------|----------|--------|-------------|
| **Orders** | 1st | ✓ Schema defined | Core transactions, redemptions |
| **Finance** | 1st | ✓ Measures defined | Revenue, discounts, transaction values |
| **Products** | Later | ✓ Dimension defined | Mobile accessories catalog |
| **Customers** | Later | ◐ Dimension drafted | End consumers |
| **Inventory** | Later | ◐ API researched | Stock levels, cost data (InventoryItem/InventoryLevel) |
| **Vouchers/Discounts** | Later | ✓ API researched | Codes, values, usage tracking (asyncUsageCount) |
| **Fulfillment** | Later | ○ Pending | Gamatek handoff, shipping |

**Legend:** ✓ Complete | ◐ Partial | ○ Pending

### What's Built

**Fact Tables:**
- `fact_order_line_item` (line-item grain)
- `fact_order_header` (order grain)

**Dimensions:**
- `dim_date` - Conformed date dimension
- `dim_customer` - End consumers
- `dim_product` - Products at variant level
- `dim_geography` - Shipping/billing locations
- `dim_order` - Order attributes
- `dim_discount` - Discount codes

**Finance Measures:**
- Revenue (Gross, Net, Total, Refund)
- Discount metrics (Rate %, Penetration)
- Profitability (COGS, Margin)
- Averages (AOV, Units per Order)
- Volume metrics

### Still To Define
- Inventory domain schema (API researched - dim_location + fact_inventory_level if multi-location)
- Fulfillment domain (Gamatek integration)
- Voucher complexity (Layer 2 / DYT-specific)

### Finance Approach
- Transaction value "as if cash"
- Cleanly capture: Gross → Discounts (voucher + %) → Net
- Base level correct before tackling voucher complexity

---

## Volume & Scale

| Metric | Current | Design For |
|--------|---------|------------|
| Orders/month | 2-4k | Scale-agnostic |
| Store history | ~5 years | Configurable |
| Products (SKUs) | TBD | - |

---

## Team

| Role | Name | Notes |
|------|------|-------|
| Head of Analytics | Dominic | Owner, technically strong |
| Fulfillment Partner | Gamatek | - |

**Timeline:** No hard deadline - "do it right" pace

---

## Working Style

- Methodical, collaborative approach
- Step-by-step, not big-bang
- Slow and steady - no mass content generation
- Technical depth OK (Dominic is analytically comfortable)
- Strategy guidance needed for commercial/business side

---

## Infrastructure

| Component | Status |
|-----------|--------|
| Shopify Admin access | Available |
| API credentials | Can create |
| Exasol instance | Available |

---

## Links & Resources

- **Shopify API Docs:** https://shopify.dev/docs/api
- **Shopify Admin API:** https://shopify.dev/docs/api/admin
