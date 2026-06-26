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

- **Shopify scopes:** ✅ DECIDED (2026-06-24) — add `read_all_orders` (history beyond 60 days),
  `read_customers` (customer_id → dim_customer, LTV/RFM), AND `read_inventory` (stock-on-hand →
  stg_inventory_levels, fact_inventory_snapshot). All three granted in one app-config pass:
  add scopes → create version → release → re-run `oauth_install.py` for a fresh token.
  `read_customers` and `read_inventory` are both part of the full Layer 1 design.
  Rationale for `read_inventory`: this is a **foundational, productisable** build (proving the
  broader Shopify-DWH concept, not just DYT), so build the design complete rather than trimmed —
  even though margin already works via `read_products` unit cost.
- **Historical backfill:** ✅ DECIDED (2026-06-24) — backfill straight from Shopify via
  `read_all_orders`, **not** by seeding from the existing Fivetran/SQL Server data. Rationale:
  reuses the proven POC loaders as-is (vs. writing throwaway Fivetran→our-schema mapping + a
  cross-system SQL-Server→Exasol pull), and makes a clean break from the Fivetran stack this
  project replaces. The 60-day cap is an *initial-ingestion* concern only — once the ETL runs
  daily, the warehouse accumulates its own history (we own retention), so `read_all_orders` is a
  one-time backfill enabler, not an ongoing requirement.
- **Backfill depth:** ✅ DECIDED (2026-06-24) — pull **all** available history on the first run.
  Volume is trivial (full design = low single-digit GB), so there's no reason to limit it.
- **ETL host:** ✅ DECIDED (2026-06-24) — a **basic dedicated Linux VM** for the ETL, on the same
  network as Exasol. **Not** co-located on the Exasol server: keep the DB node dedicated to the DB
  (Exasol owns its RAM/CPU), keep the internet-facing extraction + API secrets off the DB host, and
  keep ETL deploy/patch/restart independent of the database. Volume is tiny, so a modest VM suffices;
  it just needs Python + a scheduler (systemd timers / cron) + network reach to the instance.
- **Secrets management:** ✅ DECIDED (2026-06-24) — **locked-down env file** on the ETL VM: secrets
  in a file outside the repo, owned by a dedicated ETL OS user, perms `600`, loaded by the systemd
  service at runtime. Secrets never in git. The Exasol credential is a **dedicated least-privilege
  user** scoped to the two new schemas, **not** `SYS` (also answers the ETL user/role quick-check).
  **Azure Key Vault explicitly ruled out.** Can graduate to systemd `LoadCredential` later without
  rework if tighter handling is ever wanted.
- **Target host:** ✅ DECIDED (2026-06-24) — Dom's existing production Exasol instance (the one
  already running his other DWH). Shopify DWH lands as new schemas (`SHOPIFY_STG`, `SHOPIFY_DWH`)
  on that same instance. No new instance/edition to stand up; Community-Edition limits were
  POC-only. Volume is negligible (POC = 15.45 MB; full design = low single-digit GB).

---

## Phase A — Production project scaffold

**Status (2026-06-26):** code-complete. `code/etl/` package built and verified
(all 8 modules import clean, config self-test passes). **Gate A still pending** —
it needs the three external prerequisites executed (Shopify scopes re-OAuth, ETL
VM, Exasol ETL user/schemas), then `python -m shopify_dwh.healthcheck` → GREEN.

| Step | What | Gate | Done |
|------|------|------|------|
| A.1 | Production code layout `code/etl/` (package `shopify_dwh/`) separate from `code/poc/` | structure exists | ✅ |
| A.2 | Port `shopify_client.py`, `exasol_loader.py`, `deploy_ddl.py`→`ddl_runner.py` as shared modules | importable, self-tests pass | ✅ |
| A.3 | Central `config.py` — all connection/run settings from env, the only `os.environ` reader; secure-by-default Exasol (encryption + cert validation); configurable schema names | no secrets in source | ✅ |

Also added beyond the original A-scope: `oauth_install.py` (re-OAuth for the new
scopes) and `healthcheck.py` (the Gate A two-ended smoke test: `SELECT 1` + Shopify
shop). What changed from POC code: central config, configurable STG/DWH schema
names (productisation), secure-by-default TLS. Extraction/load logic ported verbatim.

**Gate A:** shared modules run against the target Exasol; `SELECT 1` + Shopify hello
both green → `python -m shopify_dwh.healthcheck` prints **Gate A: GREEN**.
*(Blocked on the three Prerequisites above being executed, not on code.)*

## Phase B — Full STG layer (17 tables)

**Status (2026-06-26):** the 4 POC loaders are ported into
`code/etl/shopify_dwh/loaders/` (products, variants, orders, line_items) as the
proven base — config-driven schema, secure connection, `customer_id` now populated
(read_customers). **Full STG DDL written** — `code/etl/ddl/01_stg_schema.sql` builds
all 18 tables (234 cols), with `verify_stg.sql` + a `ddl/README.md` documenting
type mappings and the reserved-word watch list. 13 STG loaders remain. Nothing
deploys/runs until Gate A.

> **Count note:** the staging layer is **18** tables, not 17 — `stg_gift_cards` was
> added during DYT research after the "17" label was set. Worth reconciling the
> label in MEMORY/schema-layered.md intro. See `code/etl/ddl/README.md`.

| Step | What | Status |
|------|------|--------|
| B.1 | Generate + deploy DDL for all STG tables from `schema-layered.md` | ◐ written, not deployed |
| B.2 | Build loaders, reusing the POC pattern. Group by extraction shape: | ◐ 14/18 (+2 deferred) |
|     | • simple full-load dims: ✅ products, ✅ variants, ✅ customers, ✅ locations · ⏸ discount_codes† | |
|     | • watermark-incremental + MERGE: ✅ orders, ✅ line_items, ✅ transactions, ✅ tax_lines, ✅ discount_apps, ✅ shipping_lines, ✅ fulfillments, ✅ fulfillment_line_items, ✅ refunds, ✅ refund_line_items · ⬜ inventory_levels, ⬜ abandoned_checkouts‡ · ⏸ gift_cards† | |
|     | _8 order-children share `loaders/_orders_source.py` (orders-pagination + watermark + merge). Each loader's output keys verified == its DDL columns. Remaining GraphQL-shape risk documented inline (verify at first run)._ | |
| B.3 | Idempotency test on every incremental loader (re-run → 0 dups) | ⬜ |

**Gate B:** all 18 STG tables populated; re-runs produce 0 duplicates; row counts sane vs Admin.

> **† SCOPE GAP — DECISION NEEDED (2026-06-26).** Two STG tables need Shopify scopes
> **not** in the decided set (`read_orders, read_products, read_all_orders,
> read_customers, read_inventory`):
> - `stg_discount_codes` (`codeDiscountNodes` query) needs **`read_discounts`**.
> - `stg_gift_cards` (`giftCards` query) needs **`read_gift_cards`** — and it's a
>   Layer-2 / DYT-voucher-motivated table, not core generic Layer 1.
>
> Options: (a) add both scopes for full design fidelity; (b) add `read_discounts`
> only (discount catalogue is genuinely generic; gift_cards is Layer-2); (c) defer
> both — discount *amounts* already flow via `Order.discountApplications`
> (read_orders), so the discount *catalogue* dim is enrichment, not a metric blocker.
> Loaders for these two are deferred until this is decided.
>
> **‡** `stg_abandoned_checkouts` (`abandonedCheckouts` query) — scope to confirm at
> first run (likely read_orders; possibly needs read_checkouts). Built but flagged.

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

- ~~Backfill depth~~ ✅ full history from Shopify on first run, via `read_all_orders` (see Prerequisites).
- ~~Production host~~ ✅ existing Exasol instance (same one as the other DWH).
- ~~Secrets management~~ ✅ locked-down env file, dedicated least-privilege Exasol user (see Prerequisites).
- ~~ETL host~~ ✅ dedicated basic Linux VM (see Prerequisites).
- ~~Revenue definition~~ ✅ DECIDED (2026-06-24) — **store atomic components, define measures in the
  view layer.** The fact table stores separate additive columns (`gross_sales`, `discount`, `refund`,
  `tax`, `shipping`) — never a single baked-in "revenue." The metric/view layer derives every named
  measure from them (gross sales, net sales = gross − refund, net-of-tax, etc.), so all definitions
  are serviceable side by side. **Headline = net sales (provisional, reversible label only)** — it's a
  one-line view default, changeable in minutes with no ETL re-run / schema change / reload. Therefore
  **not a blocker**: confirm what current business reporting leads with whenever convenient and flip
  the default if needed. Conventions: ex-tax / ex-shipping / post-discount, cancelled included.
- ~~Whether `read_inventory` is in Layer 1 scope~~ ✅ IN — foundational/productisable build, build complete (see Prerequisites).
