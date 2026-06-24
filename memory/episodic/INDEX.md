# Episodic Memory Index

**Purpose:** Records of completed work, decisions, and experiences.

---

## Structure

```
memory/episodic/
├── completed-work/          # Work records from /learn
│   └── YYYY-MM-DD-description.md
├── decisions/               # Major decisions made
│   └── YYYY-MM-DD-decision.md
└── INDEX.md                 # This file
```

---

## Recent Episodes

| Date | Type | Description | Project |
|------|------|-------------|---------|
| 2026-06-24 | implementation / validation | POC built & run end-to-end (Phases 1–5); metric reconciles to Fivetran at 0.30%; verdict **GO** | shopify-poc |
| 2026-05-15 | experiment / infrastructure | POC Phase 0 complete: Docker+Exasol+Shopify all green; dyt-dwh design v2.1 closed | shopify-poc (new), dyt-dwh, research-notes |
| 2026-03-06 | decision / scoping | DYT project creation, elevator pitch, Phase 4 NL analytics exploration | dyt-dwh (new), research-notes |
| 2026-02-18 | research | Report mapping analysis — 38 DYT reports mapped to Layer 2 schema | research-notes |
| 2026-02-18 | design | DYT Layer 2 B2B2C voucher & channel schema design | research-notes |
| 2026-02-04 | analysis | Metrics gap analysis vs standard ecommerce KPIs — 57 metrics defined | research-notes |
| 2026-01-30 | design | Layered schema redesign (STG + DWH) | Shopify DWH |
| 2026-01-30 | decision | Architecture decisions documented | Shopify DWH |
| 2026-01-30 | documentation | Generic layer documentation consolidated | Shopify DWH |
| 2026-01-30 | research | Fulfillment API research - plan vs actual pattern, design options | Shopify DWH |
| 2026-01-30 | validation | Customers API research - schema validated, deprecated fields noted | Shopify DWH |
| 2026-01-30 | validation | Orders API research - schema validated | Shopify DWH |
| 2026-01-30 | optimization | Exasol schema review - distribution/partition keys | Shopify DWH |
| 2026-01-30 | decision | ETL tooling evaluation - Custom Python + PyExasol | Shopify DWH |
| 2026-01-30 | research | Discount/voucher API research (codes, redemptions) | Shopify DWH |
| 2026-01-30 | research | InventoryItem API research (cost & stock data) | Shopify DWH |
| 2026-01-29 | research | Product API research & schema update | Shopify DWH |

---

## Episode Format

### completed-work/YYYY-MM-DD-description.md

```markdown
# [Description]

**Date:** YYYY-MM-DD
**Project:** [project-name]
**Type:** [feature / bugfix / refactor / research]

## What was completed
[Summary of work done]

## Key decisions
- [Decision 1 and reasoning]

## Patterns identified
- [Pattern and confidence level]

## Issues encountered
- [Issue and resolution]

## Time spent
[Actual time vs estimate]

## Links
- [PR or commit link]
- [Related documentation]
```

---

## Using Episodic Memory

### Recording (via /learn)
After completing significant work, run `/learn` to:
1. Capture what was done
2. Extract patterns
3. Document decisions
4. Create episodic record

### Recalling
Use `/recall [topic]` to search episodic memory for:
- Past solutions to similar problems
- Decisions and their outcomes
- Patterns discovered

### Context Restoration
Reference episodic memories to restore context in new conversations:
```
@memory/episodic/completed-work/YYYY-MM-DD-feature.md
```

---

## Maintenance

### Weekly
- Review recent episodes
- Link patterns to semantic memory
- Archive old, irrelevant episodes

### Monthly
- Clean up duplicate information
- Update pattern confidence based on reuse
- Archive completed project episodes
