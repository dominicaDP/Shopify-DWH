# Layer 1 Production Build Plan

**Status:** Not started — POC complete (GO), schema cleaned to v1.1.
**Approach:** Sequence-driven, gated. Mirrors the POC's phase/gate structure (which worked).
Each phase has a clear "you know it worked because…" gate; pick up at the right step after any break.

> **Why this exists:** the `shopify-poc` validated the approach end-to-end (Shopify → Exasol →
> star schema → metric, reconciled to Fivetran at 0.30%). This plan scales that thin slice to the
> full Layer 1 generic Shopify DWH. The POC's reusable components port directly — see "Carry over".

---

## Carry over from the POC (don't rebuild)

| POC artifact | Reuse as |
|--------------|----------|
| `code/poc/shopify_client.py` | Production GraphQL client (auth, pagination, throttle) — generalises as-is |
| `code/poc/exasol_loader.py` | Production load utility (`load_full`, `merge_upsert`, `to_naive_utc`) |
| `code/poc/deploy_ddl.py` | DDL/SQL runner |
| `code/poc/ddl/*.sql` | DDL patterns (digit-cross-join dim_date, GID extraction, ROW_NUMBER keys) |
| Idempotent watermark+MERGE loading | The loader pattern for every incremental table |

Source of truth for the schema: `schema-layered.md` (v1.1, Exasol-safe).

---

## Prerequisites (do first — external, possibly needs others)

- **Shopify scopes:** add `read_all_orders` (history beyond 60 days) and `read_customers`
  (customer_id, LTV/RFM). App config → add scopes → create version → release → re-run
  `oauth_install.py` for a fresh token. *(read_inventory too if cost/stock is in scope.)*
- **Decide retention/backfill depth** (how much order history to load on first run).
- **Target host:** decide where production Exasol lives (the POC was throwaway local Docker).

---

## Phase A — Production project scaffold

| Step | What | Gate |
|------|------|------|
| A.1 | Create a production code layout (e.g. `code/etl/`) separate from `code/poc/` | structure exists |
| A.2 | Port `shopify_client.py`, `exasol_loader.py`, `deploy_ddl.py` as shared modules | importable, self-tests pass |
| A.3 | Config: connection + run settings out of code (env / config file), real secrets management | no secrets in source |

**Gate A:** shared modules run against the target Exasol; `SELECT 1` + Shopify hello both green.

## Phase B — Full STG layer (17 tables)

| Step | What |
|------|------|
| B.1 | Generate + deploy DDL for all 17 STG tables from `schema-layered.md` |
| B.2 | Build loaders, reusing the POC pattern. Group by extraction shape: |
|     | • simple full-load dims: products, variants, customers, locations, discount_codes |
|     | • watermark-incremental + MERGE: orders, line_items, transactions, tax_lines, discount_apps, shipping_lines, fulfillments, fulfillment_line_items, refunds, refund_line_items, inventory_levels, abandoned_checkouts, gift_cards |
| B.3 | Idempotency test on every incremental loader (re-run → 0 dups) |

**Gate B:** all 17 STG tables populated; re-runs produce 0 duplicates; row counts sane vs Admin.

## Phase C — Full DWH layer (7 dims + 5 facts)

| Step | What |
|------|------|
| C.1 | Deploy DWH DDL: dim_date, dim_time, dim_product, dim_customer, dim_geography, dim_discount, dim_location; fact_order, fact_order_line_item, fact_fulfillment, fact_refund, fact_inventory_snapshot |
| C.2 | Transforms — reuse POC patterns (GID extraction, ROW_NUMBER keys, Unknown members). New work: the **pivots** (payments/taxes/discounts → fact_order columns) and **aggregations** (LTV/RFM → dim_customer) |
| C.3 | Verify: reconcile facts to STG, zero NULL FKs (extend `verify_dwh.sql`) |

**Gate C:** all 12 DWH tables populated; totals reconcile to STG; no NULL FKs.

## Phase D — Validation & metrics

| Step | What |
|------|------|
| D.1 | Build the 57-metric layer (views) per `metrics-lineage-reference.md` |
| D.2 | Reconcile a sample of metrics against Fivetran (reuse the window+definition-alignment method) |
| D.3 | Spot-check vs Shopify Admin for a handful of orders/products |

**Gate D:** key metrics reconcile within explainable tolerance.

## Phase E — Productionisation

| Step | What |
|------|------|
| E.1 | Scheduling (systemd timers / cron) — see the systemd pattern in dev-patterns.md |
| E.2 | Error handling, logging, run monitoring/alerting |
| E.3 | Distribution keys where volume warrants (e.g. `DISTRIBUTE BY order_id` on line items) |
| E.4 | Runbook + operational docs |

**Gate E:** unattended scheduled runs complete cleanly and are observable.

---

## Then: Layer 2 (dyt-dwh)

Once Layer 1 is solid, resume `dyt-dwh` (DYT B2B2C voucher/channel layer) on top — its design (v2.1)
is already complete. Keep Layer 1 generic/productisable; Layer 2 joins via `voucher_code`.

---

## Open decisions to confirm before/early in the build

- Backfill depth (full history vs N months) once `read_all_orders` is granted.
- Production host + secrets management approach.
- Whether `read_inventory` (cost/stock) is in Layer 1 scope now or deferred.
- Revenue definition for the canonical metric (POC used line `net_amount`, refunds not netted) —
  pin it to match the agreed Fivetran/business definition.
