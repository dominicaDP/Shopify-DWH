# DYT Layer 2 Schema Design

**Date:** 2026-02-18
**Project:** Shopify DWH
**Type:** Schema Design
**Duration:** ~1 session

---

## What Was Done

Designed the complete DYT-specific Layer 2 schema for B2B2C voucher and channel analytics. This sits on top of the generic Shopify DWH (Layer 1) without modifying it.

### Deliverables

1. **Layer 1 gap filled:** Added `stg_gift_cards` (14 columns) to SHOPIFY_STG in `schema-layered.md`
2. **Created `schema-dyt.md`:** Full Layer 2 schema design document
   - 3 DYT_STG tables (from SQL Server): stg_channels, stg_voucher_inventory, stg_voucher_distributions
   - 2 DYT_DWH dimensions: dim_channel, dim_voucher (central, unifies gift cards + discount codes)
   - 2 DYT_DWH facts: fact_voucher_lifecycle (per-voucher grain), fact_channel_daily (pre-aggregated)
   - Data flow diagram and ETL dependency order
   - Join strategy with 3 gift card options rated by confidence
   - 22 DYT-specific metrics across 5 categories
   - 6 key design decisions with reasoning
   - 8 open items for future work
3. **Word document:** `DYT-Layer2-Schema-Design.docx` for review
4. **Updated tracking:** context.md, tasks.md

### Key Design Decisions

- **Separate schemas** (DYT_STG / DYT_DWH) - Layer 1 untouched and portable
- **dim_voucher as central dimension** - unifies gift cards and discount codes with channel ownership
- **voucher_code as join key** - bridges SQL Server (full code) and Shopify (discount code or masked gift card)
- **Channel-centric analytics** - primary lens is "how is Channel X performing?"
- **fact_channel_daily pre-aggregated** - running totals and rates for fast dashboards
- **Illustrative STG columns** - must confirm against actual SQL Server schema

### Gift Card Join Challenge

Shopify masks gift card codes (only last 4 chars via API). Three join strategies identified:
- Option A (Preferred): Join via Shopify GID stored in SQL Server
- Option B: Join via transaction records (gateway = 'gift_card')
- Option C: Last 4 chars cross-reference for validation

Needs validation with real data.

---

## Patterns Identified

1. **Two-Layer Architecture validated** (uses: 1→2) - Layer 2 successfully designed on top of Layer 1 without modification
2. **Cross-System Join Strategy** (NEW) - Using a shared business key (voucher code) to bridge systems with different data models
3. **Pre-aggregated fact for dashboards** (NEW) - fact_channel_daily provides fast channel reporting without scanning full lifecycle table
4. **Follow Existing Conventions** (NEW) - Created unnecessary duplicate docx; should have followed existing for-word/ folder pattern
5. **Markdown-to-Word Pipeline** (NEW) - Author in markdown, generate via convert_to_docx.py, Word is generated artifact not source
6. **Design-on-Paper Before Building** (uses: 2) - Validated again: designing on paper caught the gift card masking issue before any code was written

---

## Issues Encountered

- Shopify gift card API limitation (masked codes) complicates the join strategy
- SQL Server schema not yet inspected - column names are illustrative
- Gift card redemption tracking is ambiguous (payment transaction vs balance change)

---

## What's Next

1. Inspect SQL Server schema to confirm actual column names
2. Validate gift card join strategy with real data
3. Add DYT-specific metrics from report descriptions (pending from Dominic)
4. Begin ETL implementation (Layer 1 first, then Layer 2)

---

## Files Modified

- `projects/research-notes/schema-layered.md` - Added stg_gift_cards, updated lineage/coverage
- `projects/research-notes/schema-dyt.md` - Created (full Layer 2 schema)
- `projects/research-notes/DYT-Layer2-Schema-Design.docx` - Created (Word doc for review)
- `projects/research-notes/for-word/06-DYT-Layer2-Schema.md` - Created (Word source)
- `projects/research-notes/for-word/06-DYT-Layer2-Schema.docx` - Created (Word output)
- `projects/research-notes/for-word/convert_to_docx.py` - Updated (added file 06)
- `projects/research-notes/context.md` - Updated Layer 2 status
- `projects/research-notes/tasks.md` - Updated completed/backlog
