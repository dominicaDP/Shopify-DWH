# Schema Layered Design - 2026-01-30

## Context
**Project:** Shopify DWH
**Goal:** Redesign schema architecture for reporting optimization
**Duration:** ~2 hours

## What Happened
During design review, identified that the original star schema was still too row-based/normalized - essentially mirroring Shopify's transactional structure rather than being optimized for columnar reporting.

User raised the example: "If an order uses multiple payment methods and exists in Shopify as 2-3 separate rows, we want to see it in the DWH as 1 order row with multiple columns per payment method."

This led to a fundamental architecture revision.

## Key Insight
**Don't conflate staging with data warehouse.**

Original (overcomplicated) approach:
```
API → STG (raw) → DWH (normalized star) → RPT (denormalized)
```

Simplified (correct) approach:
```
API → STG (raw, mirrors source) → DWH (reporting-optimized, IS the reporting layer)
```

The DWH should be designed for reporting from the start - not normalized and then denormalized again.

## Solution
Created two-layer architecture:

**SHOPIFY_STG (Staging)**
- 10 tables mirroring Shopify API exactly
- Row-based (1 row per payment, per tax line, per discount)
- No business logic, no transformations
- Transient - can be truncated after DWH load

**SHOPIFY_DWH (Data Warehouse = Reporting)**
- Pivoted arrays to columns (payments, taxes, discounts)
- Denormalized dimension attributes on facts
- Pre-calculated fields (LTV, margins, flags)
- User-friendly field names
- ~70 columns on fact_order vs ~25 in staging

## Patterns Applied
- **Pivot transformation** for multi-value arrays (rows → columns)
- **Denormalization** for self-service reporting (no joins needed)
- **Two-layer ETL** (extract raw, transform for reporting)

## Artifacts Created
- `schema-layered.md` - Comprehensive schema definition
- `Shopify-DWH-Schema-Layered.docx` - Word document for review
- Updated `tasks.md` with refined ETL backlog

## Outcome
**Result:** SUCCESS
**Quality:** High - clear separation of concerns, reporting-optimized design

## Linked Patterns
→ New: Two-Layer DWH Architecture (STG mirrors source, DWH is reporting-optimized)
→ New: Pivot Transformation Pattern (rows to columns for multi-value data)

## Next Time
- Always ask early: "What does the reporting consumer need?"
- Design DWH for reporting first, not as a "clean" version of the source
- Challenge any intermediate layers - do they add value?
