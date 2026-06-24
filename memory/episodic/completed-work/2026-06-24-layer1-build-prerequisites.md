# Layer 1 Build Prerequisites — Decision Session

**Date:** 2026-06-24
**Project:** research-notes (Layer 1 production build)
**Type:** Planning / decision-making

---

## What happened

Dom opened with a worry that he'd lost the thread ("have we proved the local version works so we
need to start moving to the cloud?"). Grounded the answer in `findings.md` (POC = GO, reconciled
to Fivetran at 0.30%) and `build-plan.md`, then worked through every open pre-build decision **one
at a time** (his explicit preference, stated twice). All real decisions are now closed; only
live-instance checks remain.

## Decisions made (all logged in `build-plan.md`, committed `8223d91`)

- **Host:** existing Exasol instance (new schemas alongside his other DWH). The big "where does prod
  live" question collapsed the moment he said he already runs an Exasol — Community-Edition limits
  were POC-only.
- **Scopes:** `read_all_orders` + `read_customers` + `read_inventory` (one app-config pass).
  `read_inventory` included on the reasoning that this is a **foundational/productisable** build —
  build complete, not trimmed.
- **Backfill:** from Shopify via `read_all_orders`, not by seeding from Fivetran (reuses proven POC
  loaders, clean break from the stack being replaced). Full history on first run.
- **ETL host:** dedicated basic Linux VM, not co-located on the DB node.
- **Secrets:** locked-down env file + least-privilege Exasol user. Azure Key Vault explicitly ruled
  out by Dom.
- **Revenue:** store atomic components, derive measures in the view layer; net sales as a
  provisional/reversible headline.

## Key reframes

- **The 60-day order cap is an initial-ingestion concern only.** Dom caught me over-framing it as
  ongoing. Once the ETL runs daily, the warehouse owns retention and accumulates its own history —
  the cap only ever bites the one-time backfill.
- **Definitional uncertainty isn't a blocker.** When Dom wasn't sure whether reporting leads with
  gross or net, the fix was architectural (store components, derive in views), not a forced choice.

## Learnings extracted

- New pattern: **Store Atomic Components, Derive Measures in the View Layer** (dev-patterns.md).
- New feedback memory: **decision pacing** — one decision at a time, don't manufacture complexity.
- New project memory: **production host decided**.

## Next

Phase A of `build-plan.md` (production scaffold) whenever Dom starts building. First-hour checks:
schema names free, Exasol version match.
