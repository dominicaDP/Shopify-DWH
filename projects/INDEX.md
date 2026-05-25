# Projects Index

**Last Updated:** 2026-05-15

## Active Projects

| Project | Type | Status | Priority | Health |
|---------|------|--------|----------|--------|
| shopify-poc | Experiment | Active | HIGH | Healthy |
| research-notes | Work | On Hold | HIGH | Healthy |
| dyt-dwh | Work | On Hold | HIGH | Healthy |

## Project Health Legend

- **Healthy** - Tasks on track, context current, patterns documented
- **Warning** - Outdated context, stale tasks, or missing patterns
- **Critical** - Needs immediate attention, blocking issues

---

## Project Details

### shopify-poc (Layer 1 POC)

**Type:** Experiment
**Status:** Active — Phase 0 complete, Phase 1 next
**Priority:** HIGH
**Health:** Healthy

**Quick Links:**
- [Context](./shopify-poc/context.md)
- [Plan](./shopify-poc/plan.md)
- [Tasks](./shopify-poc/tasks.md)
- [Notes](./shopify-poc/notes.md)

**Current Focus:**
- ✅ Phase 0: Docker + Exasol + Python venv + Shopify OAuth token all working
- ⬅ Phase 1 next: Create `SHOPIFY_STG` schema + DDL for 4 POC tables

**Recent Activity:**
- Phase 0 complete (2026-05-15) — all three streams green, ready for Phase 1
- Project created with scope, plan, and tasks (2026-05-15)
- Decisions: Community Edition (not Personal), no anonymisation, no timeline

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
