# DYT Report Mapping Analysis

**Date:** 2026-02-18
**Project:** Shopify DWH
**Type:** Requirements Analysis / Data Investigation
**Duration:** ~1 session

---

## What Was Done

Mapped all 38 existing DYT reports against the Layer 2 schema design, identified gaps, formulated 11 questions, answered them interactively with Dominic, and queried CampaignSegmentTbl to understand Campaign-Client data relationships.

### Deliverables

1. **Report mapping analysis:** `report-mapping-analysis.md`
   - Coverage summary: 13 well covered, 8 partially covered, 5 need new concepts
   - 11 questions (Q1-Q11) with answers and schema impact
   - CampaignSegmentTbl structure and data summary
   - Updated concepts table (8 resolved, 4 open)
   - Open items for team discussion
2. **Word document:** `for-word/07-Report-Mapping-Analysis.docx` for team review
3. **Converted report source:** `for-word/DYT Reporting/DYT-Report-mapping.md`
4. **Updated tracking:** context.md, tasks.md

### Key Findings

**CampaignSegmentTbl is the only DYT-specific table in SQL Server.** All other tables are Fivetran mirrors of Shopify data.

**Campaign-Client relationship resolved:**
- Client = clean business dimension (~30+ real entities) → maps to dim_channel
- Campaign = sub-classification within Client → campaign_name VARCHAR on dim_voucher
- Marketing = internal/promotional catch-all (~150 sub-campaigns, small quantities)
- Refund tracking has two inconsistent patterns (needs ETL normalisation)
- Subscription tiers encoded in Campaign name: `Subscription {%} {months} Month Virtual`

**Questions answered:**
- Payment type split: from Shopify transaction data (gift_card gateway vs others)
- Breakage: unredeemed gift card value
- "In Process": pending refunds (Campaign="In Process", Client="Refund")
- Overspend: business term for customer spend beyond voucher
- Ebucks: a channel/client
- SQL Server: Fivetran sync being replaced by our solution

**Still open:**
- Q4: Billing/cost data source for Report 18 (team discussion needed)
- Q6: Membership tiers likely in Shopify discount code names (verify during ETL)

---

## Patterns Identified

1. **Data Investigation Before Schema Finalisation** (NEW) - Querying actual data revealed that Campaign is not a clean dimension (too varied), which changes the schema approach from dim_campaign to campaign_name VARCHAR
2. **Markdown-to-Word Pipeline** (uses: 2) - Created 07-Report-Mapping-Analysis.md → .docx via convert_to_docx.py
3. **Design-on-Paper Before Building** (uses: 3) - Report mapping caught 8 schema gaps and data quality issues before any code was written
4. **Mid-Session Checkpointing** (uses: 3) - Updated tracking docs and memory after completing analysis

---

## Issues Encountered

- CampaignSegmentTbl CSV export distorted relationships (unique values per column side-by-side)
- Needed actual SQL query to understand Campaign-Client combinations
- Billing/cost data source unknown — may not exist in current systems

---

## What's Next

1. Team review of report mapping analysis (Word doc)
2. Clarify billing/cost data source (Q4)
3. Update schema-dyt.md with confirmed findings
4. Begin ETL implementation

---

## Files Created/Modified

- `projects/research-notes/report-mapping-analysis.md` - Created and updated with Q&A
- `projects/research-notes/for-word/07-Report-Mapping-Analysis.md` - Created (Word source)
- `projects/research-notes/for-word/07-Report-Mapping-Analysis.docx` - Generated
- `projects/research-notes/for-word/DYT Reporting/DYT-Report-mapping.md` - Created (converted from docx)
- `projects/research-notes/for-word/convert_to_docx.py` - Updated (added file 07)
- `projects/research-notes/context.md` - Updated with report mapping status
- `projects/research-notes/tasks.md` - Updated completed/backlog
