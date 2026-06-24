# Shopify DWH POC

**Project Type:** Experiment
**Status:** Active
**Priority:** HIGH
**Created:** 2026-05-15

---

## Purpose

Validate the Layer 1 (Generic Shopify DWH) design end-to-end with **real DYT Shopify data** on a **standalone, local Exasol Community Edition instance**, before committing to a production ETL build.

This is a **throwaway experiment**. The artifact is a learnings document and a go/no-go decision, not production code. Anything kept after the POC is a bonus.

---

## Relationship to Other Projects

| Project | Relationship |
|---------|-------------|
| `research-notes` | Source of truth for the Layer 1 design being validated |
| `dyt-dwh` | Out of scope for POC. Layer 2 work resumes after Layer 1 is proven. |

---

## Scope

### In Scope

- 4 STG tables: `stg_orders`, `stg_order_line_items`, `stg_products`, `stg_product_variants`
- 4 DWH objects: `dim_date`, `dim_product`, `fact_order` (minimal — no payment pivot), `fact_order_line_item`
- One report query: **"Revenue by product by day, last 90 days"**
- Reconciliation against the existing Fivetran-based number

### Out of Scope

- All other STG / DWH tables (13 STG, 5 DWH)
- Payment pivot in `fact_order`
- Refunds, fulfillments, inventory, abandoned checkouts, gift cards
- `dim_customer` LTV/RFM aggregations
- Layer 2 (DYT-specific) tables
- Productisation (config-driven generators)
- Phase 4 (NL Analytics)
- Production deployment concerns (monitoring, alerting, HA, scheduling beyond `cron`)

If a question is interesting but outside scope, capture it in `notes.md` and keep moving.

---

## Success Criteria

The POC succeeds if **all five** of these are true at the end:

1. Exasol Community Edition runs locally, is reachable from Python on the same machine
2. All 4 STG tables populated with real DYT data, incremental re-runs produce no duplicates
3. All 4 DWH tables populated, row counts and totals reconcile to STG
4. "Revenue by product by day, last 90 days" runs and returns sensible numbers
5. Output reconciles to the current Fivetran-based number within an explainable tolerance

If any of these fails, that's a **finding** that informs the production design — not necessarily a project failure.

---

## Security Posture

DYT customer data (orders, customers, line items) is real PII under POPIA. Controls for working locally:

| Control | How |
|---------|-----|
| Encrypted at rest | BitLocker enabled on the laptop |
| Not publicly accessible | Exasol bound to localhost / private VM network — no external listeners |
| Credentials secured | Shopify token in `.env`, never committed; DB password not in source |
| Not synced to cloud | Project folder outside OneDrive / Dropbox |
| Not in git | `.gitignore` excludes `.env`, raw extracts, dump files, Exasol data volume |
| Bounded lifetime | Delete data volume + revoke Shopify token at end of POC |

Anonymisation is **not** required — purpose (analytics) is consistent with original collection, access is legitimate, environment is secured.

---

## Decisions Made

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Standalone POC, not on Digital Planet infrastructure | Removes IT coordination dependencies, lets POC start immediately |
| 2 | Exasol **Community Edition** (not Personal) | Community is local VM/ISO with non-commercial license — fits evaluation framing. Personal is BYOC, reintroduces cloud setup. |
| 3 | 200 GB Community cap is fine | DYT total volume across 4 POC tables estimated <10 GB even with 5 years history |
| 4 | "Revenue by product by day" as the proving metric | Forces exercising one-to-many denormalisation, dimension build, fact at two grains. More meaningful than "revenue by day". |
| 5 | No timeline | Work happens when there's time. Sequence-driven, not calendar-driven. |
| 6 | PII handled in place, not anonymised | Legitimate access + secure environment + same processing purpose |
| 7 | Proving metric window narrowed 90→60 days (2026-06-24) | Shopify caps the Order query at 60 days without `read_all_orders`; chose to narrow the metric rather than reconfigure the app + reinstall. Revisit if real build needs deeper history. |

---

## Technical Stack

| Component | Detail |
|-----------|--------|
| Database | Exasol Community Edition via Docker Desktop on Windows |
| ETL Language | Python 3.11+ |
| Key libraries | `pyexasol`, `httpx`, `python-dotenv`, `pandas` |
| Source | DYT Shopify store, Admin GraphQL API, read-only custom app |
| POC code location | `code/poc/` (inside this repo, gitignored secrets) |
| Source DB Schema | `SHOPIFY_STG` (subset) |
| Target DB Schema | `SHOPIFY_DWH` (subset) |

---

## Key Files

| File | Description |
|------|-------------|
| [plan.md](plan.md) | 5-phase execution path with gates |
| [tasks.md](tasks.md) | Tickable steps |
| [notes.md](notes.md) | Findings, surprises, decisions made during the work |
