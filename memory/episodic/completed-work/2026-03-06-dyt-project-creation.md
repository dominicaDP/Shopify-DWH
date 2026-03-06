# 2026-03-06: DYT Project Creation, Elevator Pitch, Phase 4 NL Analytics

**Date:** 2026-03-06
**Project:** dyt-dwh (new), research-notes (updated)

## What Was Done

### 1. Resolved Open Questions from Report Mapping
- Q4 (Billing/Margin): Commission rates managed in Finance spreadsheets → add `ref_commission_rate` table to DYT_DWH
- Q6 (Membership Tiers): Standard Bank 15%-50% are customer-level tags in Shopify (not discount codes) → `membership_tier` on dim_customer
- Promo Pricing + Customer_Type: Deferred to ETL build phase
- Refund patterns: Need team confirmation (ETL handles both regardless)

### 2. Created `dyt-dwh` Project (Independent of Layer 1)
- `context.md` — business context, relationship to Layer 1
- `design.md` — consolidated single source of truth (schema + reports + Q&A + metrics)
- `tasks.md` — DYT-specific tasks moved from research-notes
- `patterns.md` — CampaignSegmentTbl, commission, membership, join strategy
- Schema changes: ref_commission_rate table, campaign_name parsing, breakage, overspend rename, 25 metrics

### 3. Elevator Pitch for Exasol Event
- Created elevator-pitch.md (60-90 seconds, mixed tech/business audience)
- Generated Word doc via convert_to_docx.py
- Key stats: 17 STG + 12 DWH tables, 57 metrics, zero licensing, hours-not-weeks deployment
- Conversation starters for follow-up questions

### 4. Phase 4: Natural Language Analytics Exploration
Created comprehensive nl-analytics-exploration.md covering three approaches:

**Tier 2 — Ollama (self-hosted, all data):**
- Exasol Python UDFs calling Mistral 7B via local HTTP
- 3 use cases: summarisation, NL-to-SQL, anomaly narration
- Zero cost, data stays on-prem, POPIA safe for PII

**Tier 1 — Claude MCP (cloud API, non-PII only):**
- MCP server (Python + PyExasol) exposes query tools to Claude
- Claude API MCP connector (beta: `mcp-client-2025-11-20`) — no separate MCP client needed
- POPIA tiered model: PII tables blocklisted, non-PII aggregated data only
- Role-based access: Exco/Finance see all channels, channel managers filtered
- Cost: ~$5-60/month (Sonnet, 10-200 queries/day)

**Web Interface — YF + Chat Panel:**
- Yellowfin reports embedded (iframe), collapsible chat panel below
- Report context passing: chat knows which report user is viewing (name, filters, metrics)
- FastAPI backend calls Claude API with MCP connector
- MCP server enforces PII blocklist and channel filtering server-side

**Yellowfin Native AI Assessment:**
- YF has Assisted Insights, Guided NLQ, Signals — some overlap with Claude MCP
- Key gaps: YF can't do conversational follow-up, cross-table reasoning, business-context-aware narratives, or advisory ("what should I focus on?")
- **Decision: Phased approach** — Ollama first, then evaluate YF native, then Claude MCP for proven gaps

## Key Decisions

1. **DYT independence:** Layer 2 requirements separated into own project (`dyt-dwh`)
2. **POPIA tiering:** Cloud API for non-PII aggregated data, on-prem for PII
3. **Phase 4 sequencing:** Ollama UDFs → YF native evaluation → Claude MCP (evidence-based, not speculative)
4. **Membership tiers are customer tags, not discount codes** — original assumption was wrong

## Patterns Identified

- **Evaluate Existing Tools Before Building** — Check what YF already does before building Claude MCP
- **POPIA-Compliant Tiered Architecture** — Split processing by data sensitivity
- **Evidence-Based Feature Building** — Gather gap evidence from real usage before building
