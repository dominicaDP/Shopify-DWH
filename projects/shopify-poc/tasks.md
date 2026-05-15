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

### Phase 1 — STG Schema Deployed

- [ ] 1.1 Create `SHOPIFY_STG` schema in Exasol
  Priority: NORMAL | Phase: 1
- [ ] 1.2 Deploy DDL for `stg_orders`, `stg_order_line_items`, `stg_products`, `stg_product_variants` (extract from `research-notes/schema-layered.md`)
  Priority: NORMAL | Phase: 1
- [ ] **Gate 1→2:** All 4 STG tables exist and return COUNT=0
  Priority: NORMAL | Phase: 1

### Phase 2 — Extraction

- [ ] 2.1 Build Shopify GraphQL client wrapper (auth, pagination, retries, rate-limit backoff)
  Priority: NORMAL | Phase: 2
- [ ] 2.2 Build PyExasol load utility (DataFrame → STG table with type coercion)
  Priority: NORMAL | Phase: 2
- [ ] 2.3 `stg_products` loader (full load only)
  Priority: NORMAL | Phase: 2
- [ ] 2.4 `stg_product_variants` loader (full load only)
  Priority: NORMAL | Phase: 2
- [ ] 2.5 `stg_orders` loader (full load only)
  Priority: NORMAL | Phase: 2
- [ ] 2.6 `stg_orders` loader — incremental via `updatedAt` watermark
  Priority: NORMAL | Phase: 2
- [ ] 2.7 Idempotency test — re-run 2.6, zero duplicates
  Priority: NORMAL | Phase: 2
- [ ] 2.8 `stg_order_line_items` loader (incremental)
  Priority: NORMAL | Phase: 2
- [ ] **Gate 2→3:** All 4 STG tables populated, idempotency confirmed, row counts match Shopify Admin
  Priority: NORMAL | Phase: 2

### Phase 3 — Transform (DWH)

- [ ] 3.1 Create `SHOPIFY_DWH` schema
  Priority: NORMAL | Phase: 3
- [ ] 3.2 Deploy DDL for `dim_date`, `dim_product`, `fact_order` (minimal), `fact_order_line_item`
  Priority: NORMAL | Phase: 3
- [ ] 3.3 Generate `dim_date` (10 years × 365 days)
  Priority: NORMAL | Phase: 3
- [ ] 3.4 Build `dim_product` transform from `stg_products` + `stg_product_variants`
  Priority: NORMAL | Phase: 3
- [ ] 3.5 Build `fact_order` transform from `stg_orders` (header level, no payment pivot)
  Priority: NORMAL | Phase: 3
- [ ] 3.6 Build `fact_order_line_item` transform (denormalised with product attributes)
  Priority: NORMAL | Phase: 3
- [ ] **Gate 3→4:** DWH tables populated, totals reconcile to STG, no NULL FKs
  Priority: NORMAL | Phase: 3

### Phase 4 — The Metric

- [ ] 4.1 Write report query: "Revenue by product by day, last 90 days"
  Priority: NORMAL | Phase: 4
- [ ] 4.2 Run the same metric against current Fivetran-based source
  Priority: NORMAL | Phase: 4
- [ ] 4.3 Compare outputs, document discrepancies and tolerance band
  Priority: NORMAL | Phase: 4
- [ ] **Gate 4→5:** Numbers match within explainable tolerance
  Priority: NORMAL | Phase: 4

### Phase 5 — Decision

- [ ] 5.1 Write up findings: what worked, what was harder than expected, what broke
  Priority: NORMAL | Phase: 5
- [ ] 5.2 Capture measurements: extraction time, query time, data volume
  Priority: NORMAL | Phase: 5
- [ ] 5.3 Productisation notes — what would change for prod
  Priority: NORMAL | Phase: 5
- [ ] 5.4 Go / no-go / pivot decision documented
  Priority: NORMAL | Phase: 5

---

## Backlog

### Optional stretch

- [ ] 2.9 Convert one loader to use Shopify Bulk Operations API (async, polling, JSONL)
  Priority: LOW | Phase: 2 (stretch)

---

## Blocked

---

## Completed

### Phase 0 — Foundations (2026-05-15)

- [x] **Stream A:** Install Docker Desktop + Exasol Community Edition image
- [x] **Stream A:** Start Exasol container, verify `SELECT 1` from PyExasol (Exasol v2025.2.1)
- [x] **Stream B:** Create `code/poc/` project + venv + dependencies (httpx, pandas, pyexasol, python-dotenv)
- [x] **Stream B:** `.env` populated, `.gitignore` excludes secrets and data
- [x] **Stream C:** Shopify "DataWarehouse" app — legacy install flow enabled, scopes `read_orders,read_products`, redirect `http://localhost:3001/callback`
- [x] **Stream C:** OAuth dance via `oauth_install.py` — offline token captured to `.env`
- [x] **Stream C:** `shopify_hello.py` confirmed connection — shop "Dress Your Tech" on garnishonline.myshopify.com, ZAR, Africa/Johannesburg
- [x] **Gate 0→1:** Both gates green simultaneously
