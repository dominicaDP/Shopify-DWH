# Layer 1 DWH + Metric Views + Productionisation (Phases C/D/E) — 2026-06-26

## Context
**Project:** research-notes (Layer 1 production build)
**Goal:** Build every code-able layer above STG — the DWH star, the metric layer, and the ops
scaffolding — so that once the infra prerequisites land, deployment is execution-only.
**Duration:** one session (same day as, and following, the STG build).
**Branch:** `phase-c-dwh` → fast-forward merged to `master` (3 commits: 733bd00, ec35dd2, 2acf320).

## What Happened
Picked up at Gate A blocked on infra (Shopify scopes, ETL VM, Exasol user/schemas — all Dom's).
Rather than wait, built the entire remaining code surface, none of which needs infra:

- **Phase C — DWH** (`ddl/02`–`06`): all 12 objects (7 dims + 5 facts), generated dim_date/dim_time,
  STG→DWH transforms (dims-first-then-facts), and a Gate-C verify (reconciliation + sentinel + NULL-FK
  checks). Scaled the POC's 4-object star to the full 12. New work vs the POC: payment/tax/discount
  **pivots** → fact_order, LTV/RFM **aggregations** → dim_customer, and address-JSON parsing → dim_geography.
- **Phase D — metric views** (`ddl/07`–`08`): all 57 metrics as named measures across ~14 reporting
  views (not 57 trivial views — grouped by grain, each header lists the metrics it serves, with a
  full 1→57 coverage map). `v_revenue_by_product_by_day` ported verbatim from the POC as the Fivetran
  reconciliation anchor; `08_reconcile.sql` is the POC's recon method made permanent.
- **Phase E — ops** (`pipeline.py`, `deploy/`, `ddl/09`, `RUNBOOK.md`): a single orchestrator over the
  existing entry points, systemd timer+service, opt-in distribution keys, and an operational runbook.

## Solution / Key Decisions
- **Surrogate keys = ROW_NUMBER + fixed sentinel keys** (-1 Unknown, 0 No-Discount) so fact FKs are
  never NULL — same grammar as the POC, generalised to all 7 dims.
- **Atomic components in facts, named measures in the view layer** — the revenue-definition decision,
  built. Headline "Revenue" is a default in one view, flippable with no ETL re-run.
- **Address JSON parsed with `REGEXP_SUBSTR` + `REGEXP_REPLACE`** — no JSON functions / no lookbehind,
  safe because our own loader wrote the JSON with `json.dumps` (keys + spacing known). The one
  genuinely untestable-without-infra thing → flagged front-and-centre on the first-run checklist.
- **Grouped reporting views, not 57 atomic ones** — the engineering-sound reading of "named measures
  in the view layer"; every metric still delivered + mapped, 3 honest gaps documented (product return
  rate, sell-through, landing/referring — the last is API-removed).
- **Orchestrator runs steps as subprocesses**, not import+call — single source of truth, isolation.
- **Distribution keys opt-in** — not warranted at DYT's volume; provided + documented, not forced.

## Patterns Applied / Extracted
- **NEW:** In-Warehouse JSON Field Extraction (REGEXP, no JSON functions) — exasol
- **NEW:** Thin Subprocess Orchestrator Over Existing Entry Points — data-engineering
- **Promoted:** Star Schema for Single-Source DWH LOW→MEDIUM (uses 3); Exasol Identifier & Type
  Constraints LOW→MEDIUM (uses 3)
- **Reinforced:** Pivot Transformation (built, uses 2); Store Atomic Components → View Layer (built,
  uses 2); Reconcile by Window+Definition (productionised, uses 2); systemd Timers (real units, uses 2);
  Mid-Session Checkpointing (HIGH, use 6)

## Outcome
**Result:** SUCCESS — all of Phases A–E are now code-complete and on master.
**Verification:** column lists balanced per transform; `pipeline.py` byte-compiles; SQL written to
the runner's parsing rules (full-line comments stripped, split on `;`, no inner semicolons). Not yet
run end-to-end — gated on infra. First-run-verify items (JSON parse, Exasol funcs, reserved words)
documented in `ddl/README.md` + `ACTIONS.md §C`.
**What's left:** execution only — infra → Gate A → deploy → load → Gate B/C → Fivetran reconcile
(Gate D) → enable the timer. Plus the 2 deferred loaders if those scopes are added.

## Next Time
- The address-JSON regex parse is the highest-risk untested piece; verify it on a real sample first.
- If a DWH `CREATE` fails on first deploy, suspect `address`/`region` (reserved-word watch) — rename.
- Consider a refund-line fact (product_key on refunds) to close the product-return-rate metric gap.

## Linked Patterns
→ memory/semantic/patterns/dev-patterns.md (Pattern Review Log 2026-06-26 — Phases C/D/E)
