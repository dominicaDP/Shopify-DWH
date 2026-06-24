# Projects Index

**Last Updated:** 2026-06-24

## Active Projects

| Project | Type | Status | Priority | Health |
|---------|------|--------|----------|--------|
| shopify-poc | Experiment | ✅ Complete — verdict GO | HIGH | Healthy |
| research-notes | Work | Next up (Layer 1 build) | HIGH | Healthy |
| dyt-dwh | Work | On Hold (after Layer 1) | HIGH | Healthy |

## Project Health Legend

- **Healthy** - Tasks on track, context current, patterns documented
- **Warning** - Outdated context, stale tasks, or missing patterns
- **Critical** - Needs immediate attention, blocking issues

---

## Project Details

### shopify-poc (Layer 1 POC)

**Type:** Experiment
**Status:** ✅ Complete (2026-06-24) — all phases passed, verdict **GO**
**Priority:** HIGH
**Health:** Healthy

**Quick Links:**
- [Findings + decision](./shopify-poc/findings.md)
- [Context](./shopify-poc/context.md)
- [Plan](./shopify-poc/plan.md)
- [Tasks](./shopify-poc/tasks.md)
- [Notes](./shopify-poc/notes.md)
- [Code + run-book](../code/poc/README.md)

**Outcome:**
- Full pipeline built & validated: Shopify → SHOPIFY_STG → SHOPIFY_DWH star schema → metric
- Metric reconciles to the Fivetran source within **0.30%** (gap = the known 60-day order cap)
- Recommendation: **GO** — proceed to the production Layer 1 build

**Recent Activity:**
- Phases 1–5 completed in one session (2026-06-24); reconciliation passed
- Phase 0 complete (2026-05-15) — Docker + Exasol + Python + Shopify OAuth

---

### research-notes (Shopify DWH Research)

**Type:** Work
**Status:** On Hold (resumes after POC outcome)
**Priority:** HIGH
**Health:** Healthy

**Quick Links:**
- [Context](./research-notes/context.md)
- [Tasks](./research-notes/tasks.md)
- [Patterns](./research-notes/patterns.md)
- [Notes](./research-notes/notes.md)

**Current Focus:**
- Research data modeling approaches (Star vs Data Vault)
- Map Shopify Orders data model
- Define generic DWH structure

**Recent Activity:**
- Exasol Xperts narrative + market-sizing and reporting-problems addendums drafted (2026-05-25)
- Consolidated project context and vision (2026-01-29)
- Defined two-layer architecture (generic + custom)
- Established scope: Orders & Finance first

---

### dyt-dwh (DYT Data Warehouse)

**Type:** Work
**Status:** On Hold (resumes after Layer 1 POC outcome)
**Priority:** HIGH
**Health:** Healthy

**Quick Links:**
- [Context](./dyt-dwh/context.md)
- [Design](./dyt-dwh/design.md)
- [Tasks](./dyt-dwh/tasks.md)
- [Patterns](./dyt-dwh/patterns.md)

**Current Focus:**
- Consolidated DYT-specific DWH design (independent of productised Shopify DWH)
- Schema updates with resolved report mapping findings
- ETL implementation planning

**Recent Activity:**
- Created project with consolidated design document (2026-03-06)
- Resolved Q4 (billing), Q6 (membership), deferred promo pricing (2026-03-06)

---

## Archived Projects

| Project | Archived | Reason |
|---------|----------|--------|
| | | |

---

## Multi-Project Strategies

### Time Blocking
Dedicate specific hours to each project:
- Morning: Project A
- Afternoon: Project B

### Priority-Based
Switch based on urgency from `/overview`

### Batching
Group similar tasks across projects:
- All meetings together
- All coding together
- All reviews together

---

## Creating New Projects

Use `/new-project [name]` or manually create:

```
projects/[name]/
├── context.md
├── tasks.md
├── patterns.md
└── notes.md (optional)
```
