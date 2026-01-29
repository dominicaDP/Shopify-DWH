# Shopify DWH

**Project Type:** Work
**Status:** Active
**Priority:** HIGH
**Last Updated:** 2026-01-29

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
| Source | Shopify Admin API |
| Schema Type | Star schema |
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

### To Research
- ETL/pipeline tooling options
- Competitive landscape (existing Shopify DWH products)

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

| Domain | Priority | Description |
|--------|----------|-------------|
| **Orders** | 1st | Core transactions, redemptions |
| **Finance** | 1st | Revenue, discounts, transaction values |
| Products | Later | Mobile accessories catalog |
| Inventory | Later | Stock levels, availability |
| Customers | Later | End consumers |
| Vouchers/Discounts | Later | Codes, values, usage |
| Fulfillment | Later | Gamatek handoff, shipping |

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
