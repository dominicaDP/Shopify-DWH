# Layer 1 STG Build — Scaffold + Full DDL + 16 Loaders — 2026-06-26

## Context
**Project:** research-notes (Layer 1 production Shopify DWH)
**Goal:** Start the real build after the POC's GO verdict — scaffold the production ETL and build
the staging extraction layer, keeping everything pre-Gate-A (no infra) so the code is ready the
moment the external prerequisites land.
**Duration:** one long session (9 commits on master).

## What Happened
Began from "let's plan the real DWH" and discovered the planning was already done
(`build-plan.md` complete, all decisions made). So the work was execution, not planning:

- **Phase A — scaffold** (`bb93616`): new `code/etl/` package `shopify_dwh/`. Ported the 3 shared
  POC modules (shopify_client, exasol_loader, ddl_runner) + oauth_install + a new Gate-A
  `healthcheck`. The one genuinely new piece: `config.py`, the single `os.environ` reader —
  everything else takes a `Settings` object. Production deltas vs POC: central config, configurable
  STG/DWH schema names (productisation), secure-by-default Exasol (encryption + cert validation on;
  POC bypassed both for its self-signed box). Caught + fixed a smell: oauth_install did config work
  at import time.
- **Phase B.1 — full STG DDL** (`e8c6b6d`): `ddl/01_stg_schema.sql` = all 18 staging tables / 234
  columns, extending the POC's 4. `verify_stg.sql` + `ddl/README.md`.
- **Phase B.2 — 16/18 loaders** (`6041c52`, `780c810`, `e461588`, `38763cf`): ported 4 POC loaders;
  added customers + locations; 8 order-children sharing `loaders/_orders_source.py`; inventory_levels
  (daily snapshot) + abandoned_checkouts.
- **Documentation passes** (`988640f`, `146fbf6`, `155ce7a`): refreshed build-plan/notes/INDEX/MEMORY
  throughout, then an explicit "document everything" consolidation → `ACTIONS.md` (action register +
  first-run checklist + dependency map).

## Solution / Approach
Port-then-extend: reuse what the POC proved verbatim, generalise where structure repeats (a shared
order-children helper at N=8, not at N=2), and verify everything verifiable without infra.

## Decisions Taken
- **Defer discount_codes + gift_cards** — need read_discounts / read_gift_cards, not in the decided
  scope set; gift_cards is Layer-2-motivated. Surfaced as a plain-language decision; user deferred.
- **Inventory = daily snapshot** — built productisation-aware (snapshot is the superset of
  current-stock; current-vs-history is a scheduling/retention/feature-flag choice).
- **Did NOT** silently fix the "17 vs 18 tables" doc label or guess reserved-word renames — flagged
  both for the user / first-deploy instead.

## Patterns Applied
- **Walking-Skeleton POC → full build** — the POC's reusable components ported straight in.
- **Idempotent Incremental Loading (Watermark + MERGE)** — generalised into the shared helper, incl.
  composite keys + a snapshot variant.
- **Mid-Session Checkpointing** — 9 commits + running doc refresh; promoted to HIGH on this session.
- **Store Atomic Components / push choices to a cheap layer** — echoed by the inventory snapshot call.

## Learnings Extracted
- **New: Verify Output Mapping Against the Target Schema Without Live Dependencies** — parse the DDL,
  feed a synthetic record through the mapper, assert keys == columns. Verified all 16 loaders pre-infra.
- **New: Snapshot Is the Productizable Superset of "Current State"** — build the snapshot, make
  current-vs-history a config/scheduling choice, not a code fork.
- **New: Surface Capability/Permission Gaps as Decisions** — reconcile a design's assumed scopes
  against the granted set; convert gaps into scoped decisions.
- **Reinforced:** Idempotent Loading (1→2), Exasol Identifier & Type Constraints (1→2),
  Mid-Session Checkpointing (4→5, MEDIUM→HIGH).

## Outcome
**Result:** SUCCESS — Phase A + Phase B (STG) code-complete and committed; 16/18 loaders, every one
column-verified against its DDL. Nothing deployed/run yet (gated on infra).
**Quality:** high — each batch verified statically and committed; full action register left for next steps.

## Next Time / Next Steps
- Phase C (DWH layer) is the next code-able chunk (no infra): `02_dwh_schema.sql` + transforms +
  the pivots/aggregations + metric views. Implement revenue as atomic components + view-layer measures.
- First-run checklist (ACTIONS.md §C) holds every GraphQL-shape/reserved-word risk that couldn't be
  tested without the live API — work through it when Gate A goes green.

## Linked Patterns
→ New: Verify Output Mapping (no live deps), Snapshot = Productizable Superset, Surface Permission Gaps
→ Reinforced: Idempotent Incremental Loading, Exasol Identifier & Type Constraints
→ Promoted: Mid-Session Checkpointing (MEDIUM → HIGH)
