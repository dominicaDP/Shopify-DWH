# Projects Index

**Last Updated:** 2026-06-26

## Active Projects

| Project | Type | Status | Priority | Health |
|---------|------|--------|----------|--------|
| research-notes | Work | 🔨 Building Layer 1 (Phase A done, B underway) | HIGH | Healthy |
| shopify-poc | Experiment | ✅ Complete — verdict GO | HIGH | Healthy |
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
**Status:** 🔨 Building Layer 1 (active) — POC signed off GO, production build started
**Priority:** HIGH
**Health:** Healthy

**Quick Links:**
- [Actions](./research-notes/ACTIONS.md) ← consolidated next-steps / action register
- [Build plan](./research-notes/build-plan.md) ← live phase/gate tracker
- [Context](./research-notes/context.md)
- [Tasks](./research-notes/tasks.md)
- [Patterns](./research-notes/patterns.md)
- [Notes](./research-notes/notes.md)
- [ETL code](../code/etl/README.md)

**Current Focus:**
- Layer 1 production ETL build (Shopify → SHOPIFY_STG → SHOPIFY_DWH)
- Phase A scaffold ✅ · Phase B: STG DDL written + 4/17 loaders ported
- Next: remaining 13 STG loaders, then Gate A (infra) → deploy

**Recent Activity:**
- Layer 1 build started: scaffold + 4 loaders + full 18-table STG DDL (2026-06-26)
- Layer 1 build prerequisites resolved — host, scopes, ETL host, secrets, revenue model (2026-06-24)
- Exasol Xperts narrative + addendums drafted (2026-05-25)
- Defined two-layer architecture; scope Orders & Finance first (2026-01-29)

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
