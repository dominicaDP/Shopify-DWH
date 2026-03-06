# DYT Data Warehouse

**Project Type:** Work
**Status:** Active
**Priority:** HIGH
**Last Updated:** 2026-03-06

---

## Overview

DYT-specific data warehouse design and implementation for Dress Your Tech's B2B2C voucher and channel analytics. This project is **independent** of the productised generic Shopify DWH in Exasol — it covers only the custom reporting, schema, and ETL needed for DYT's unique business model.

---

## Relationship to Shopify DWH (Layer 1)

| Aspect | Shopify DWH (Layer 1) | DYT DWH (This Project) |
|--------|----------------------|------------------------|
| Scope | Generic Shopify analytics | DYT B2B2C voucher & channel |
| Productisable | Yes | No — DYT-specific |
| Schemas | SHOPIFY_STG, SHOPIFY_DWH | DYT_STG, DYT_DWH |
| Data Sources | Shopify GraphQL API | SQL Server (Azure) + Layer 1 references |
| Primary Lens | Orders, products, customers | Channels, vouchers, redemptions |

DYT DWH **reads from** Layer 1 (joins via voucher_code) but **never modifies** it.

---

## Business Context

### B2B2C Model

```
Corporate Clients ("Channels")
  e.g., Telecoms, Retailers (~30+ clients)
         |
         | instruct DYT to create & distribute vouchers
         v
Dress Your Tech (DYT)
  Creates vouchers in Shopify (gift cards + discount codes)
  Distributes via SMS (98%) or channel distributes directly (2%)
         |
         | consumer receives voucher code
         v
End Consumer
  Redeems voucher code at checkout on Shopify
         |
         | order placed
         v
Gamatek (Fulfillment)
  Ships product to consumer
```

### Key Business Rules

1. **Voucher creation**: Gift cards and discount codes are bulk-created in Shopify
2. **Channel ownership**: SQL Server DB is the source of truth for which channel owns which vouchers
3. **Distribution**: 98% DYT distributes via SMS, 2% channel distributes directly
4. **Distribution types**: One-off or subscription (recurring monthly)
5. **Redemption**: Only happens in Shopify — consumer uses voucher code at checkout
6. **Voucher types**: ~50% gift cards, ~50% discount codes
7. **Analytics lens**: Channel-centric — "how is Channel X performing?" is the primary question
8. **Commission rates**: Managed in Finance spreadsheets (not in any database)
9. **Membership tiers**: Stored as customer-level tags in Shopify (e.g. Standard Bank 15%-50%)

### Major Clients (by volume)

Telkom (~244K), Blue Label (~138K), Vodacom (~116K), FNB (~24K), Net 1 (~25K), Cell C (~23K), PayJoy (~15K), Teljoy (~12K), Standard Bank (~10K), plus ~20 more

---

## Technical Stack

| Component | Detail |
|-----------|--------|
| Source DB | SQL Server (Azure) — CampaignSegmentTbl is the only DYT-specific table |
| Target DB | Exasol (columnar) |
| ETL | Custom Python + PyExasol |
| Join Key | voucher_code (SQL Server <-> Shopify discount/gift card code) |
| Layer 1 Dependency | SHOPIFY_STG + SHOPIFY_DWH (read-only references) |

---

## Key Files

| File | Description |
|------|-------------|
| [design.md](design.md) | Consolidated schema, report mapping, and decisions |
| [tasks.md](tasks.md) | Task tracking |
| [patterns.md](patterns.md) | Project-specific patterns |

### Source Research (in research-notes project)

| File | Description |
|------|-------------|
| `research-notes/schema-dyt.md` | Original Layer 2 schema design |
| `research-notes/report-mapping-analysis.md` | 38-report analysis with Q&A |
| `research-notes/for-word/DYT Reporting/` | Report mapping docs + CampaignSegmentTbl data |
