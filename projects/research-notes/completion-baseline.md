# Layer 1 Build — Completion Baseline

**Purpose:** a fixed yardstick to measure build progress against across sessions. The
weights below are **frozen** so that a "% done" computed later is comparable to this
baseline — re-score by changing only each workstream's *status*, never the weights.
(If the weights ever need to change, note it explicitly in the log and re-baseline.)

---

## Scoring method (frozen)

Layer 1 end-to-end, weighted by effort. `% done = Σ (weight × fraction complete)`.

| # | Workstream | Weight | What "done" means |
|---|-----------|:------:|-------------------|
| 1 | Architecture + schema design | 25% | 18 STG / 12 DWH / 57 metrics + lineage, Exasol-safe |
| 2 | POC (build thin slice, run, reconcile) | 15% | end-to-end slice reconciled to a trusted source |
| 3 | Production code A–E | 35% | scaffold + loaders + DWH transforms + metric views + orchestrator/ops |
| 4 | Infra prerequisites | 5% | Shopify scopes/re-OAuth, ETL VM, Exasol user + schemas |
| 5 | Deploy → first full run → Gate A/B/C + first-run fixes | 12% | DDL deployed, STG loaded, DWH built, verify passes on live data |
| 6 | Fivetran reconcile (Gate D) + cutover | 8% | sample reconciled; timer enabled, monitored; deferred loaders if scopes added |

**Risk-retired %** is a *separate* judgment overlay (not a formula): how much of the
live-integration uncertainty is actually resolved. It lags "% done" because the
unknowns (address-JSON parse, Exasol functions, GraphQL field-shapes, reserved words)
are concentrated in workstreams 5–6 and untested until first contact with live infra.

**All-in % (incl. Layer 2)** uses a fixed split: `0.70 × L1% + 0.30 × L2%`.
Layer 2 (`dyt-dwh`) is a separate ~9-object build; its design (v2.1) being complete
counts as ~10% of L2's own effort.

---

## Baseline — 2026-06-26

| Workstream | Status | Credit |
|-----------|--------|:------:|
| 1 Design | ✅ done | 25 / 25 |
| 2 POC | ✅ done (reconciled 0.30%) | 15 / 15 |
| 3 Code A–E | ✅ done (code-complete, committed) | 35 / 35 |
| 4 Infra prereqs | ◻ not started | 0 / 5 |
| 5 Deploy + first run + Gate A/B/C | ◻ not started | 0 / 12 |
| 6 Reconcile (Gate D) + cutover | ◻ not started | 0 / 8 |

- **Layer 1 % done: ≈ 75%**
- **Risk retired: ≈ 60%** (core proven by POC; live-integration unknowns still open)
- **All-in incl. Layer 2: ≈ 55%** (L1 75%, L2 ~10% design-only → 0.70×75 + 0.30×10)

**Remaining shape:** of the last ~25% of Layer 1, only ~5% is code (2 deferred
loaders + first-run patches); the rest is infra (yours) + execution + validation.

---

## Measurement log

Append a row each time we re-score. Keep the same weights; move only the statuses.

| Date | L1 % done | Risk retired | All-in % | What moved / notes |
|------|:---------:|:------------:|:--------:|--------------------|
| 2026-06-26 | 75% | 60% | 55% | Baseline set. Phases A–E code-complete; nothing deployed. |

---

## How to re-measure (next session)

1. For each workstream 1–6, set status to done / partial (with a fraction) / not started.
2. Recompute `Σ(weight × fraction)` → new L1 %.
3. Re-judge risk-retired (did a first run actually happen? did Gate C/D pass?).
4. Recompute all-in with the L2 fraction.
5. Append a log row with what moved. Don't touch the weights.

Live phase/gate detail lives in [`build-plan.md`](build-plan.md); the next-actions
list in [`ACTIONS.md`](ACTIONS.md). This file is only the scorecard.
