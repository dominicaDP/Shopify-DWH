# Shopify DWH Research

**Project Type:** Work
**Status:** Active
**Priority:** HIGH
**Last Updated:** 2026-01-29

---

## Overview

Knowledge base and research project for building the Shopify Data Warehouse for Dress Your Tech. Captures analytics patterns, Shopify data structures, voucher/redemption tracking approaches, and B2B2C metrics.

---

## Business Context

### Company Structure
- **Digital Planet** - Ecommerce enabler (tech and sales side)
- **Dress Your Tech** - Mobile products & accessories website (Shopify)
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

### Key Insight
- NOT traditional ecommerce - primary revenue is voucher-based
- Need to track voucher issuance, redemption, and fulfillment
- Metrics differ from standard ecommerce (AOV, conversion less relevant)

---

## Tech Stack

### Core
- **Platform:** Windows
- **Ecommerce:** Shopify
- **Data Warehouse:** (To be determined)

### Potential Tools
- Shopify APIs / GraphQL
- ETL tools (TBD)
- Analytics/BI platform (TBD)

---

## Architecture

### Data Flow (Conceptual)
```
Shopify Store Data
    ↓ Extract
Staging Layer
    ↓ Transform
Data Warehouse
    ↓ Serve
Analytics / Reporting
```

### Key Data Entities
1. **Orders** - Voucher redemptions
2. **Products** - Mobile accessories catalog
3. **Customers** - End consumers (from corporate clients)
4. **Vouchers** - Tracking codes/discounts (primary business driver)

---

## Current Focus

### Active Work
- Setting up knowledge management system
- Understanding Shopify data model
- Researching DWH approaches for Shopify

### Next Up
- Map Shopify data entities
- Define key metrics for B2B2C model
- Evaluate ETL/data pipeline options

### Blocked
- None

---

## Key Questions to Answer

1. How to track voucher lifecycle (issued → redeemed → fulfilled)?
2. What Shopify data is available via APIs?
3. How to attribute redemptions back to corporate clients?
4. What metrics matter for a voucher-based business vs traditional ecommerce?

---

## Team / Stakeholders

| Role | Name | Notes |
|------|------|-------|
| Head of Analytics | Dominic | Owner |
| Product Supplier | Gamatek | Fulfillment partner |

---

## Links & Resources

- **Second Brain Documentation:** See CLAUDE.md in root
- **Shopify Admin:** (add URL)
- **Shopify API Docs:** https://shopify.dev/docs/api

---

## Notes

This project focuses on building analytics infrastructure for a non-traditional ecommerce model. Standard ecommerce DWH patterns may need adaptation for the voucher-based B2B2C flow.
