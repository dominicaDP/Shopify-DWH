# Layer 1 Build — Action Register

**As of:** 2026-06-26
**Purpose:** the single "what to do next" list. Phase/gate detail lives in
[`build-plan.md`](build-plan.md); this consolidates every outstanding action pulled
from the plan, the scope decisions, and the verify-at-first-run notes scattered
through the loader docstrings.

**One-line status:** Phases **A–E are all code-complete** — scaffold, STG (DDL +
16/18 loaders), DWH (12 objects + transforms + verify), metric views (57 metrics) +
reconcile queries, and ops (orchestrator + systemd units + distribution keys +
runbook). **Nothing has been deployed or run** — everything downstream waits on the
3 infra prerequisites in §A. What's left is execution, not code: infra → Gate A →
deploy → load → Gate B/C → runtime Fivetran reconcile (Gate D) → enable the timer.

---

## A. Infra prerequisites — Dom (these gate Gate A, and everything downstream)

All three are decided on paper (see build-plan Prerequisites); none is executed yet.
Gate A = `python -m shopify_dwh.healthcheck` prints **GREEN** (reaches both Exasol
and Shopify).

1. **Shopify scopes + token.** In the app config add `read_all_orders`,
   `read_customers`, `read_inventory` → Create version → Release. Set `SHOPIFY_SCOPES`
   in `.env` to match, then run `python -m shopify_dwh.oauth_install` for a fresh
   token. (Only add `read_discounts` / `read_gift_cards` if reversing the §B deferral.)
2. **ETL host.** Provision the basic dedicated Linux VM on the Exasol network. Install
   Python + venv + `requirements.txt`; deploy `code/etl/`; place `.env` outside the
   repo, owned by the ETL user, perms `600`.
3. **Exasol user + schemas.** Create the dedicated least-privilege ETL user owning
   `SHOPIFY_STG` + `SHOPIFY_DWH` (NOT `SYS`). Confirm the instance version matches the
   POC (Exasol 8 / v2025.2.1, for the reserved-word + `IF NOT EXISTS` assumptions) and
   the two schema names are free. Set `EXASOL_*` in `.env`.

---

## B. Open decisions

1. **discount_codes + gift_cards scope** — *deferred 2026-06-26.* Both loaders are
   unwritten pending a scope decision: `stg_discount_codes` needs `read_discounts`,
   `stg_gift_cards` needs `read_gift_cards` (and gift_cards is Layer-2-motivated).
   Neither blocks a sales metric — discount *amounts* already flow via
   `Order.discountApplications`. Revisit when the discount catalogue dim or gift-card
   reporting is actually needed.

_Already decided (no action): inventory = daily snapshot; revenue = atomic components
+ view-layer measures (confirm the headline label against current reporting whenever
convenient — it's a one-line view default, reversible)._

---

## C. First-run verification checklist (when the pipeline first runs post-Gate-A)

These are the things that **couldn't be tested without the live API/instance** — the
loaders' column mappings are verified, but GraphQL field-shapes and Exasol
reserved-words are not. Check each when it first runs; the documented fix for a
field-shape miss is to drop/NULL it (POC precedent), and for a reserved word to
**rename** (never quote — quoting breaks the loaders' column alignment).

- [ ] **DDL deploy** — reserved-word watch: `source` (stg_order_shipping_lines),
      `committed` + `reserved` (stg_inventory_levels). If a CREATE fails, rename.
- [ ] **verify_stg.sql** — expect 18 tables / 234 columns, all row_count 0.
- [ ] **fulfillments** — `location { id }`, `service { serviceName }`,
      `trackingInfo(first: 1)` shapes against the live API version.
- [ ] **fulfillment_line_items** — `discountedTotalSet` (we use this) vs the design
      doc's `discountedTotalPriceSet`; align schema-layered.md once confirmed.
- [ ] **discount_applications** — inline-fragment field names per API version.
- [ ] **abandoned_checkouts** — scope (expected `read_orders`; if it errors,
      `read_checkouts` is a new scope decision). email/phone are NULL by design.
- [ ] **inventory_levels** — which `quantities(names: …)` the store actually exposes;
      watch the inner-pagination truncation warning (items stocked at >20 locations).
- [ ] **line_items** — inner `lineItems(first: 100)` truncation warning (>100 lines/order).
- [ ] **customers** — `numberOfOrders` string→int coercion; the new
      `defaultEmailAddress`/`defaultPhoneNumber` objects return data.
- [ ] **Row-count spot-check vs Shopify Admin** for a few tables (deferred in the POC).
- [ ] **Idempotency (B.3)** — re-run each incremental loader, expect 0 duplicate keys.

**DWH layer (Phase C, when transforms first run — see `code/etl/ddl/README.md`):**
- [ ] **DWH DDL deploy** — reserved-word watch: `address` (dim_location), `region`
      (dim_geography). If a CREATE fails, rename.
- [ ] **Address JSON parsing** — confirm `dim_geography` has real city/country rows
      and `fact_order.shipping_city` is populated (regexp parse of the json.dumps
      address; assumes `": "` spacing).
- [ ] **Exasol functions** — `HOURS_BETWEEN` (fulfillment timing), `WEEK`/`LAST_DAY`
      (dim_date), `NTILE` (RFM) weren't exercised by the POC; swap name/signature if any errors.
- [ ] **Gate C reconcile** — `06_verify_dwh.sql`: fact_order = stg_orders exactly,
      sentinels all present, NULL-FK checks all 0.

---

## D. Remaining code work — mostly no infra needed

- [x] **Phase C — DWH layer** ✅ *code-complete 2026-06-26.* `ddl/02_dwh_schema.sql`
      (7 dims + 5 facts), `03_dim_date.sql` + `04_dim_time.sql` (generated),
      `05_transforms.sql` (dims→facts), `06_verify_dwh.sql`. Reused POC patterns
      (GID extraction, ROW_NUMBER keys, Unknown members, digit-cross-join dim_date);
      NEW: payment/tax/discount **pivots** → fact_order, LTV/RFM **aggregations** →
      dim_customer, address-JSON parse → dim_geography. Revenue stored as **atomic
      components** in the facts; named measures deferred to the Phase D view layer
      (decided). First-run checks folded into §C above. Not yet deployed (needs Gate A).
- [x] **Phase D — metric layer** ✅ *code-complete 2026-06-26.* `ddl/07_metric_views.sql`
      — all 57 metrics as named measures across ~14 reporting views (atomic components in
      facts, measures defined here per the decision); `v_revenue_by_product_by_day` ported
      verbatim from the POC as the reconciliation anchor. `ddl/08_reconcile.sql` = our-side
      reconcile queries (POC method, 60-day floor removed). **Runtime reconcile vs Fivetran
      still pending** (needs the live pipeline — a Gate-D activity, not code). Documented gaps:
      metrics 28/3.9 (product return rate), 29 (sell-through), 36/37 (landing/referring — API-removed).
- [x] **Phase E — productionisation** ✅ *code-complete 2026-06-26.*
      `shopify_dwh/pipeline.py` — one orchestrator (healthcheck → 16 STG loaders →
      DWH 02–07) with fail-fast, per-step timing/logging, a run summary, and
      `--mode`/`--stg-only`/`--dwh-only` flags. `deploy/` — systemd timer + service
      (daily 02:30, least-priv user, secrets via EnvironmentFile, hardened).
      `ddl/09_distribution_keys.sql` — opt-in `DISTRIBUTE BY order_id` (not warranted
      at current volume; reversible). `RUNBOOK.md` — operate/recover/backfill/monitor.
- [ ] **(deferred)** discount_codes + gift_cards loaders — only if §B reverses.

---

## E. Doc reconciliation (cosmetic, low priority)

- [ ] "17 STG tables" → **18** in: MEMORY.md, build-plan.md intro, schema-layered.md
      intro. (stg_gift_cards was added during DYT research after the label was set.)
- [ ] schema-layered.md: align `stg_fulfillment_line_items.discounted_total` source
      field name once the live API confirms `discountedTotalSet`.

---

## Dependency map (what unblocks what)

```
§A infra (Dom) ───────────────► Gate A (healthcheck GREEN)
                                     │
                                     ▼
                         deploy ddl/01_stg_schema.sql ──► §C DDL/reserved-word checks
                                     │
                                     ▼
                         run 16 loaders ──► Gate B (§C field-shape + idempotency checks)
                                     │
   §D Phase C (DWH) ── code-able now, in parallel ──┐
                                     ▼               ▼
                         run DWH transforms ──► Gate C (reconcile to STG)
                                     ▼
                         §D Phase D (metrics + reconcile vs Fivetran) ──► Phase E (ops)
                                     ▼
                              Layer 2 (dyt-dwh)
```
