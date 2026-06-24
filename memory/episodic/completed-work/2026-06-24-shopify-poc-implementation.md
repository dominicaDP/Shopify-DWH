# Shopify POC — first implementation (build, run, reconcile, GO)

**Date:** 2026-06-24
**Project:** shopify-poc
**Type:** implementation / validation

## What was completed

In a single (long) session, took the standalone Layer 1 POC from "Phase 0 done, can't remember
where we were" all the way through **Phases 1–5** to a documented **GO** decision. This was the
project's first move from design-on-paper to running code.

- **Phase 1 — STG schema:** `SHOPIFY_STG` + 4 staging tables; generic `deploy_ddl.py` SQL runner.
- **Phase 2 — Extraction:** reusable `shopify_client.py` (auth, cursor pagination, retries,
  cost-based throttle) and `exasol_loader.py` (`load_full`, idempotent `merge_upsert`, name-based
  column alignment, ISO→naive-UTC). Four loaders. Loaded products 6,580 / variants 6,598 /
  orders 3,226 / line_items 5,792. Idempotency proven (0 dup ids on re-run, against a live store).
- **Phase 3 — DWH:** dim_date (generated), dim_product, fact_order, fact_order_line_item (POC
  subset, ROW_NUMBER surrogate keys, -1 Unknown member). Reconciled to STG to the cent, zero NULL FKs.
- **Phase 4 — Metric + reconciliation:** `v_revenue_by_product_by_day`; reconciled to the existing
  Fivetran source at **0.30%**, gap fully explained by the known 60-day cap.
- **Phase 5 — Decision:** findings doc, measurements (15.45 MB total, metric 79–143ms), verdict **GO**.

## Key decisions

- **Metric window narrowed 90→60 days** rather than reconfigure the Shopify app for `read_all_orders`
  (scope change + reinstall). Pipeline exercised identically; only the lookback shrank.
- **Stayed local/throwaway** (Docker Exasol, DB1) as designed — surfaced late when the user couldn't
  see the data in their *cloud* DataGrip connection; the POC data was always in the local container.
- **ROW_NUMBER surrogate keys** over IDENTITY — deterministic, repeatable rebuilds.
- **Lightweight reconciliation, not the formal report** — aligned window + definition, compared, explained.

## Patterns identified

New (build stage): Idempotent Incremental Loading (Watermark + MERGE); Cost-Based GraphQL Throttling;
Reconcile by Aligning Window + Definition First; Walking-Skeleton POC Before Full Build; Exasol
Identifier & Type Constraints. All LOW (uses 1).

Reinforced: Two-Layer DWH (STG+DWH) LOW→MEDIUM; Star Schema for Single-Source (uses 1→2);
Mid-Session Checkpointing LOW→MEDIUM (uses 3→4).

## Issues encountered

- **Exasol identifier rules:** leading underscore (`_extracted_at`) and reserved words
  (`year`/`month`/`day`/`object`/`rows`) rejected → renamed. Action: clean `schema-layered.md`
  before the real build.
- **Shopify scope/version surprises:** 60-day order cap without `read_all_orders`; `customer{}`
  needs `read_customers`; `landing_site`/`referring_site`/`checkout_id` removed in API 2026-04.
- **pyexasol:** `{name}` not `:name` bind params; TIMESTAMP returns as strings; `CHR` ASCII-only.
- **DataGrip connection:** local self-signed cert rejected by the modern driver → pin the
  fingerprint in the host (`localhost/<fingerprint>`), not `validateservercertificate=0`.

## Outcome

**Result:** SUCCESS — all POC gates passed, verdict GO.
**Reconciliation:** Fivetran R2,184,381 vs POC R2,177,758 = 0.30%, gap = the known 60-day cap.
**Artifacts:** 6 commits on branch `shopify-poc-local-pipeline`; `findings.md`; `code/poc/README.md`.

## Next time / for the real build

- Resume `research-notes` (full Layer 1) with the productisation changes from `findings.md` §5.
- Reuse `shopify_client.py` + `exasol_loader.py` directly — they generalise.
- Request `read_all_orders` + `read_customers` up front; clean reserved-word/underscore identifiers.

## Links

- findings: projects/shopify-poc/findings.md
- run-book: code/poc/README.md
- Reinforced patterns: memory/semantic/patterns/dev-patterns.md (Implementation Patterns section)
