# Tasks

**Project:** Shopify DWH POC
**Last Updated:** 2026-05-15

---

## Urgent (Due Today)

(none)

---

## High Priority

(none — Phase 0 complete, ready for Phase 1)

---

## Normal

### Phase 5 — Decision

- [x] 5.1 Write up findings: what worked, what was harder, what broke → `findings.md` §2
- [~] 5.2 Capture measurements: extraction time, query time, data volume → `findings.md` §4
  Done: data volume (15.45 MB raw total, ~0.008% of Community cap), query time (metric 79–143ms).
  Outstanding: precise per-table extraction timing (only observed sub-2-min, not benchmarked).
- [x] 5.3 Productisation notes — what would change for prod → `findings.md` §5
- [x] 5.4 Go / no-go / pivot decision documented → `findings.md` §7: **GO** (recommendation, pending sign-off)

### Phase 4 — The Metric + Reconciliation (2026-06-24)

- [x] 4.1 Metric "Revenue by product by day" — see Phase 3 block below
- [x] 4.2 Ran metric against Fivetran source (`shopify.order_line` ⋈ `shopify.order`), same window/definition
- [x] 4.3 Compared: **0.30% gap** (FT R2,184,381 vs ours R2,177,758), product count exact, Unknown bucket
  exact. Gap fully explained by the known 60-day cap (boundary-day morning orders). → `findings.md` §6
- [x] **Gate 4→5 PASSED:** numbers match within explainable tolerance (0.30%, traced to 60-day scope)

---

## Backlog

### Optional stretch

- [ ] 2.9 Convert one loader to use Shopify Bulk Operations API (async, polling, JSONL)
  Priority: LOW | Phase: 2 (stretch)

---

## Blocked

---

## Completed

### Phase 3 — Transform (DWH) + Phase 4.1 — Metric (2026-06-24)

- [x] 3.1 `SHOPIFY_DWH` schema created
- [x] 3.2 DDL for dim_date, dim_product, fact_order (minimal), fact_order_line_item
  → `code/poc/ddl/02_dwh_schema.sql`. POC subset: no payment/tax/discount pivots, no
  customer/geography dims, ROW_NUMBER() surrogate keys (not IDENTITY), -1 Unknown Product member.
- [x] 3.3 `dim_date` generated 2020–2030 (4,018 days) via digit cross-join → `ddl/03_dim_date.sql`
- [x] 3.4 `dim_product` transform (variant grain, 6,598 + 1 Unknown) → `ddl/04_transforms.sql`
- [x] 3.5 `fact_order` transform (3,226 rows)
- [x] 3.6 `fact_order_line_item` transform (5,791 rows)
- [x] **Gate 3→4 PASSED** (`ddl/verify_dwh.sql`): fact_order reconciles EXACTLY to STG
  (3,226 rows; R2,197,285.30 = R2,197,285.30). Line items 5,791 vs 5,793 — 2 orphan lines dropped
  (drift orders with no header; value gap R598 fully explained). **Zero NULL FKs.** 36 lines → Unknown.
  **Reserved words:** Exasol rejects `year`/`month`/`day`/`object`/`rows` as identifiers → renamed
  (`cal_year` etc). Added to findings.
- [x] 4.1 Metric "Revenue by product by day" → `ddl/metric_revenue_by_product_by_day.sql`
  (view `SHOPIFY_DWH.v_revenue_by_product_by_day`). 60-day total **R2,195,132**, 679 products,
  3,575 product-day rows. Top sellers sensible (Body Glove, LOOP'D, Snug, Havit); daily trend
  realistic (Sunday dips). Revenue def = SUM(line net_amount), refunds not netted.

### Phase 2 — Extraction (2026-06-24)

- [x] 2.1 Shopify GraphQL client wrapper → `code/poc/shopify_client.py` (auth, cursor
  pagination, retries, cost-based leaky-bucket backoff). Store bucket: 20000 pts / 1000-per-s.
- [x] 2.2 PyExasol load utility → `code/poc/exasol_loader.py` (column-align by name,
  NaN→NULL, `load_full` truncate-reload, `merge_upsert` idempotent MERGE, `to_naive_utc` helper)
- [x] 2.3 `stg_products` full load — 6,580 rows. UTF-8 round-trip verified clean (0 U+FFFD).
- [x] 2.4 `stg_product_variants` full load — 6,598 rows. read_products grants inventory fields
  (cost 2385/6598, weight + requires_shipping 6598/6598) — no read_inventory needed.
- [x] 2.5 `stg_orders` full load — 3,226 rows → `code/poc/load_orders.py`
- [x] 2.6 `stg_orders` incremental via `updatedAt` watermark (MERGE on id)
- [x] 2.7 Idempotency confirmed — re-ran incremental, count stable, **0 duplicate ids**
- [x] 2.8 `stg_order_line_items` full + incremental — 5,792 rows → `code/poc/load_line_items.py`
- [x] **Gate 2→3:** All 4 STG tables populated, idempotency confirmed (0 dups on every re-run).
  ⚠️ Row-count-vs-Admin spot check deferred (no Admin UI access this session).
  **KEY FINDING — 60-day order cap:** Shopify `orders` query returns only the last 60 days
  without the `read_all_orders` scope. We have 2026-04-25..2026-06-24 (60d). The headline metric
  asks for 90d → needs `read_all_orders` (app scope change + version/release + re-run oauth) OR
  narrow the metric window. **DECISION PENDING — see notes.md.**
  Other findings: `customer{}` needs read_customers (NULLed customer_id); landing_site/
  referring_site/checkout_id removed in 2026-04 API (NULLed); live-store drift between extractions.

### Phase 1 — STG Schema Deployed (2026-06-24)

- [x] 1.1 Create `SHOPIFY_STG` schema in Exasol
- [x] 1.2 Deploy DDL for `stg_orders`, `stg_order_line_items`, `stg_products`, `stg_product_variants`
  DDL authored from `research-notes/schema-layered.md` column specs → `code/poc/ddl/01_stg_schema.sql`
  Generic runner added: `code/poc/deploy_ddl.py` (reusable for Phase 3 DWH DDL)
- [x] **Gate 1→2:** All 4 STG tables exist and return COUNT=0 (verified via `ddl/verify_stg.sql`)
  **Finding:** Exasol unquoted identifiers cannot start with `_`, so the design's
  `_extracted_at` column was renamed `extracted_at`. Applies to all 17 STG + DWH tables for real build.

### Phase 0 — Foundations (2026-05-15)

- [x] **Stream A:** Install Docker Desktop + Exasol Community Edition image
- [x] **Stream A:** Start Exasol container, verify `SELECT 1` from PyExasol (Exasol v2025.2.1)
- [x] **Stream B:** Create `code/poc/` project + venv + dependencies (httpx, pandas, pyexasol, python-dotenv)
- [x] **Stream B:** `.env` populated, `.gitignore` excludes secrets and data
- [x] **Stream C:** Shopify "DataWarehouse" app — legacy install flow enabled, scopes `read_orders,read_products`, redirect `http://localhost:3001/callback`
- [x] **Stream C:** OAuth dance via `oauth_install.py` — offline token captured to `.env`
- [x] **Stream C:** `shopify_hello.py` confirmed connection — shop "Dress Your Tech" on garnishonline.myshopify.com, ZAR, Africa/Johannesburg
- [x] **Gate 0→1:** Both gates green simultaneously
