# Episodic Memory: Ecommerce Metrics Gap Analysis

**Date:** 2026-02-04
**Project:** Shopify DWH
**Type:** Schema Enhancement
**Duration:** ~2 hours

---

## What Was Done

Comprehensive gap analysis of the Shopify DWH schema against standard ecommerce metrics, followed by schema enhancements to close all identified gaps.

### Gap Analysis Results

**Starting Point:**
- 10 STG tables
- ~150 STG fields
- 2 DWH fact tables
- 0 metrics formally documented

**Gaps Identified:**

| Gap Type | Count | Examples |
|----------|-------|----------|
| Missing STG Tables | 6 | fulfillments, refunds, inventory_levels, abandoned_checkouts |
| Missing STG Fields | 5 | source_name, landing_site, referring_site, fulfillable_quantity |
| Missing DWH Tables | 3 | fact_fulfillment, fact_refund, fact_inventory_snapshot |
| Missing DWH Fields | 5 | RFM scores, channel attribution |

### Schema Enhancements Made

**New STG Tables Added (6):**
1. `stg_fulfillments` - Shipment tracking
2. `stg_fulfillment_line_items` - Item-level fulfillment
3. `stg_refunds` - Refund headers
4. `stg_refund_line_items` - Refunded items with restock info
5. `stg_inventory_levels` - Stock quantities by location
6. `stg_abandoned_checkouts` - Cart abandonment data

**New DWH Tables Added (3):**
1. `fact_fulfillment` - Fulfillment performance metrics (time to ship, on-time rate)
2. `fact_refund` - Refund analytics (refund rate, return reasons)
3. `fact_inventory_snapshot` - Inventory tracking over time

**Existing Tables Enhanced:**
- `stg_orders` + 4 fields (source_name, landing_site, referring_site, checkout_id)
- `stg_order_line_items` + 1 field (fulfillable_quantity)
- `dim_customer` + 5 RFM fields (recency/frequency/monetary scores, segment)
- `fact_order` + channel attribution fields

**Metrics Lineage Documentation:**
- Created comprehensive lineage section in schema-layered.md
- Documented 57 metrics with complete traceability:
  - Report → Metric → Formula → DWH Table → STG Table → API Field
- Organized by 6 business functions

---

## Metrics Coverage Summary

| Category | Metrics | Coverage |
|----------|---------|----------|
| Sales & Revenue | 8 | 100% |
| Customer Analytics | 11 | 100% |
| Product Performance | 10 | 100% |
| Marketing & Promotions | 9 | 100% |
| Operations & Fulfillment | 11 | 100% |
| Financial | 8 | 100% |
| **Total** | **57** | **100%** |

---

## Key Decisions Made

1. **Include inventory from day one** - Added stg_inventory_levels and fact_inventory_snapshot for sell-through, turnover, and stock-out metrics

2. **Include abandoned checkouts** - Added stg_abandoned_checkouts for funnel metrics (cart abandonment rate, recovery)

3. **Embedded documentation** - Put metrics lineage in schema-layered.md rather than separate file (single source of truth)

4. **RFM implementation** - Added 11 RFM segments with clear definitions in dim_customer

5. **Channel attribution fields** - Added source_name, landing_site, referring_site to enable marketing attribution

---

## Files Modified

| File | Changes |
|------|---------|
| `projects/research-notes/schema-layered.md` | +6 STG tables, +3 DWH tables, +fields, +metrics lineage section (~400 lines added) |
| `projects/research-notes/schema.md` | +3 fact tables, +dim_customer RFM fields |
| `memory/semantic/patterns/dev-patterns.md` | +Metrics-Driven Schema Design pattern |
| `memory/episodic/completed-work/2026-02-04-metrics-gap-analysis.md` | This file |

---

## Patterns Applied

1. **Metrics-Driven Schema Design** - NEW PATTERN
   - Started with required metrics, worked backwards to data
   - Identified gaps before implementation
   - Created traceable lineage as documentation

2. **Two-Layer DWH Architecture** - Applied
   - STG mirrors API structure
   - DWH optimized for reporting
   - Clear transformation boundary

3. **Mid-Session Checkpointing** - Applied
   - Updated schema docs as work progressed
   - Created episodic record immediately after

---

## Lessons Learned

### What Worked Well
- Starting with metrics reference document (ecommerce-metrics-reference.md) gave clear requirements
- Gap analysis table format made prioritization easy
- Lineage documentation catches field mapping errors early

### Challenges
- Fulfillment and refund data lives in nested objects in Orders API (not separate endpoints)
- Inventory levels are per-location - need snapshot strategy for trends

### For Next Time
- Consider adding fact_abandoned_checkout if checkout funnel analysis becomes priority
- May need stg_order_fulfillment_line_items for item-level fulfillment tracking

---

## Related Files

- `projects/research-notes/schema-layered.md` - Main schema documentation
- `projects/research-notes/schema.md` - DWH-focused schema
- `projects/research-notes/ecommerce-metrics-reference.md` - Metrics definitions source
- `memory/semantic/patterns/dev-patterns.md` - Pattern library

---

## Time Tracking

| Activity | Time |
|----------|------|
| Gap analysis | 30 min |
| STG table design | 30 min |
| DWH table design | 30 min |
| Metrics lineage documentation | 45 min |
| Pattern extraction | 15 min |
| **Total** | ~2.5 hours |

---

## Word Documentation Created

Split schema documentation into 5 logical Word documents for stakeholder review:

| Document | Purpose |
|----------|---------|
| 01-Architecture-Overview.docx | Executive summary, design principles |
| 02-Staging-Schema.docx | All 16 STG table definitions |
| 03-Warehouse-Schema.docx | 7 dims + 5 facts with RFM segments |
| 04-Data-Lineage.docx | Transformation examples, ETL load order |
| 05-Metrics-Reference.docx | 57 metrics with full lineage |

Location: `projects/research-notes/for-word/`
Conversion: Used python-docx script (committed for reuse)

---

## Next Steps

1. [ ] Verify Shopify GraphQL queries for new tables (fulfillments, refunds, inventory)
2. [ ] Design ETL scripts for new extractions
3. [ ] Create RFM calculation SQL for dim_customer load
4. [x] Export schema-layered.md to Word for stakeholder review
