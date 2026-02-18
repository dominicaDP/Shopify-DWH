# Shopify DWH

**Project Type:** Work
**Status:** Active
**Priority:** HIGH
**Last Updated:** 2026-02-18

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

**2026-01-30: Inventory Domain - Minimal Approach (Option C)**

Decision: Add dim_location now, backlog fact_inventory_snapshot.

Reasoning:
- dim_location is low-cost, enables future fulfillment and inventory analytics
- fact_inventory_snapshot requires daily snapshot ETL and grows storage
- No clear use case yet for stock-level tracking in generic layer
- Can add fact_inventory_snapshot when specific need emerges

Backlogged for future:
- fact_inventory_snapshot (stock levels per location per day)
- Inventory turnover metrics
- Stock-out analysis

**2026-01-30: Multi-Currency Handling (Option B)**

Decision: Store currency code via dim_order.currency, use shopMoney amounts consistently.

Implementation:
- All financial amounts use `shopMoney.amount` (merchant's base currency)
- Currency code stored in `dim_order.currency` (already in schema)
- No currency fields needed on fact tables (join to dim_order)
- For multi-currency shops: filter/group by dim_order.currency

Reasoning:
- Low cost (field already exists)
- Validates data integrity
- Supports multi-currency Shopify stores
- Can upgrade to dual-currency or normalized if needed later

Not implemented (backlogged):
- presentmentMoney storage (customer's currency)
- Exchange rate dimension
- Normalized currency conversion

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
| **Customers** | Later | ✓ Schema validated | End consumers (note: use new object patterns for email/phone/marketing) |
| **Inventory** | Later | ✓ Decision made | dim_location added; fact_inventory_snapshot backlogged |
| **Vouchers/Discounts** | Later | ✓ API researched | Codes, values, usage tracking (asyncUsageCount) |
| **Fulfillment** | Later | ✓ API researched | Current flags sufficient; fact_fulfillment backlogged for carrier analytics |

**Legend:** ✓ Complete | ◐ Partial | ○ Pending

### What's Built

**Fact Tables:**
- `fact_order_line_item` (line-item grain)
- `fact_order_header` (order grain)

**Dimensions:**
- `dim_date` - Conformed date dimension
- `dim_time` - Time-of-day analysis (24 rows)
- `dim_customer` - End consumers
- `dim_product` - Products at variant level
- `dim_geography` - Shipping/billing locations
- `dim_order` - Order attributes
- `dim_discount` - Discount codes (enhanced with usage tracking)
- `dim_location` - Fulfillment locations (for future use)

**Finance Measures:**
- Revenue (Gross, Net, Total, Refund)
- Discount metrics (Rate %, Penetration)
- Profitability (COGS, Margin)
- Averages (AOV, Units per Order)
- Volume metrics

### Layer 2 (DYT-Specific) - Schema Design Complete

**Schema designed (2026-02-18):** See [schema-dyt.md](schema-dyt.md)

**DYT_STG (3 tables from SQL Server):**
- `stg_channels` - Channel/client master
- `stg_voucher_inventory` - Voucher creation and allocation (contains full voucher code)
- `stg_voucher_distributions` - Distribution instructions and SMS delivery

**DYT_DWH (2 dimensions + 2 facts):**
- `dim_channel` - Channel dimension with contract dates
- `dim_voucher` - Central dimension unifying gift cards + discount codes with channel ownership
- `fact_voucher_lifecycle` - Full lifecycle per voucher (create → distribute → redeem)
- `fact_channel_daily` - Pre-aggregated channel metrics for dashboards

**Layer 1 gap filled:**
- `stg_gift_cards` added to SHOPIFY_STG (needed for gift card voucher joins)

**Key design decisions:**
- Separate schemas (DYT_STG / DYT_DWH) - Layer 1 untouched
- voucher_code is the join key between SQL Server and Shopify
- Channel-centric analytics lens
- 22 DYT-specific metrics defined

**Report mapping analysis complete (2026-02-18):** See [report-mapping-analysis.md](report-mapping-analysis.md)
- Mapped all 38 existing DYT reports against Layer 2 schema
- 13 reports well covered, 8 partially covered, 5 need new concepts
- 11 questions identified and answered (8 resolved, 3 partially open)
- CampaignSegmentTbl fully analysed: Client = dim_channel, Campaign = attribute on dim_voucher
- Schema refinements identified: campaign_name, subscription parsing, is_marketing flag, breakage, overspend, is_dual_redemption

**Open items (before implementation):**
- Clarify billing/cost data source for Report 18 (Provisional Billing) — team discussion needed
- Verify membership tiers (Standard Bank) in Shopify discount code names during ETL build
- Validate gift card join strategy with real data
- Update schema-dyt.md with confirmed report mapping findings
- Gamatek fulfillment integration (future phase)

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

### Project Documentation
- [README.md](README.md) - Project overview
- [schema-layered.md](schema-layered.md) - Two-layer schema (STG + DWH)
- [api-mapping.md](api-mapping.md) - Shopify API → DWH mapping with transformations
- [productization-strategy.md](productization-strategy.md) - Configuration-driven deployment
- [implementation-guide.md](implementation-guide.md) - ETL implementation reference
- [notes.md](notes.md) - Research notes
- [schema-dyt.md](schema-dyt.md) - DYT Layer 2 B2B2C voucher & channel schema
- [report-mapping-analysis.md](report-mapping-analysis.md) - 38 DYT reports mapped against Layer 2 schema with Q&A
- [schema.md](schema.md) - Original schema (superseded by schema-layered.md)

### External
- **Shopify GraphQL Docs:** https://shopify.dev/docs/api/admin-graphql
- **PyExasol:** https://github.com/exasol/pyexasol
- **Shopify Bulk Operations:** https://shopify.dev/docs/api/usage/bulk-operations
