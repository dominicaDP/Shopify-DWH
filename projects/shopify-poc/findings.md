# POC Findings & Decision

**Status:** Draft — Phases 0–3 + 4.1 complete. Reconciliation (4.2/4.3) and the final
go/no-go (5.4) are open, pending a comparison against the existing Fivetran source.
**Last updated:** 2026-06-24

This is the POC's capstone document: what we set out to prove, what actually happened,
what was harder than expected, and what would change for a real build. Detailed run-by-run
notes live in [notes.md](notes.md); the path is in [plan.md](plan.md).

---

## 1. What we set out to prove

Validate the Layer 1 (generic Shopify DWH) design end-to-end with **real DYT data** on a
**local, throwaway** Exasol Community Edition — before committing to a production ETL build.
The proving metric: **"revenue by product by day"** (narrowed from 90 to 60 days mid-POC, see §3).

Success = all five hold: Exasol runs locally and is reachable; 4 STG tables load with no
duplicates on re-run; 4 DWH tables reconcile to STG; the metric runs; and it reconciles to the
existing Fivetran number within an explainable tolerance.

---

## 2. What worked (5.1)

- **The whole pipeline runs end-to-end.** Shopify GraphQL → `SHOPIFY_STG` → `SHOPIFY_DWH` star
  schema → a business metric, on real DYT data. The core technical thesis is proven.
- **Idempotent incremental loading.** `updatedAt`-watermark + `MERGE`-on-id gives zero duplicates
  on re-run — demonstrated live, including against a store that was taking real orders mid-extraction.
- **Clean STG→DWH reconciliation.** `fact_order` matches `stg_orders` to the cent
  (R2,197,285.30). Zero NULL foreign keys. Every discrepancy (2 orphan lines, 36 unknown-product
  lines) is explained, not hand-waved.
- **The metric is believable.** R2,195,132 over 60 days, 679 products; top sellers and the daily
  trend (weekend dips) match intuition for DYT.
- **Exasol performance is a non-issue at this volume.** Whole warehouse = 15.45 MB raw
  (~0.008% of the Community cap); the metric query runs in 79–143 ms with no tuning.
- **Reusable building blocks.** `shopify_client.py` (auth/pagination/throttle) and
  `exasol_loader.py` (`load_full`, `merge_upsert`, type coercion) are written once and reused by
  every loader — these carry directly into a production build.

## 2b. What was harder than expected / what broke

- **Shopify's 60-day order cap.** The Order query silently returns only the last 60 days without
  the protected `read_all_orders` scope. This is the single biggest finding — it shaped the metric
  window and would shape any production history backfill.
- **Scope surprises.** `customer{}` on orders needs `read_customers` (we only had
  read_orders/read_products); `landing_site`/`referring_site`/`checkout_id` were removed from the
  Order object in API 2026-04. None blocked the metric, but all would matter for the full design.
- **Exasol identifier rules are stricter than the design doc assumed.** Leading underscores
  (`_extracted_at`) and reserved words (`year`, `month`, `day`, `object`, `rows`) all fail as
  identifiers. The design (`schema-layered.md`) uses several of these — needs a cleanup pass.
- **pyexasol/Exasol papercuts:** `{name}` (not `:name`) bind params; `UNICODECHR` not `CHR` above
  127; query results return TIMESTAMP as strings. All minor once known; all cost a few minutes each.
- **Live-store drift.** Orders/line items grew between extraction runs, briefly leaving line items
  whose order header hadn't landed yet. The inner-join transform correctly drops the orphans.

---

## 3. Key decision taken during the POC

**Metric window narrowed 90 → 60 days.** Rather than reconfigure the Shopify app for
`read_all_orders` (scope change → app version + release → re-OAuth → re-extract), we kept the
current scope and shortened the proving window. The pipeline is exercised identically; only the
lookback is shorter. Revisit `read_all_orders` if the production build needs deeper history.

---

## 4. Measurements (5.2)

- **Data volume:** 15.45 MB raw across all 8 tables (~13.8 MB in memory). ~0.008% of the 200 GB
  Community cap. Even 10 years of full history across the complete 17-table design stays in the low
  single-digit GB — Exasol is heavily over-provisioned for DYT's volume.
- **Query performance:** the metric (3,575 rows) runs in 79–143 ms, untuned.
- **Extraction:** each loader finished in under ~2 minutes (observed, not formally benchmarked).

---

## 5. Productisation notes (5.3) — what would change for prod

- **History backfill:** add `read_all_orders` to get beyond 60 days (one-time scope + reinstall).
  Decide retention/backfill depth up front.
- **Full scope:** request `read_customers` (+ `read_inventory` if cost/inventory needed) so the
  full 17-table design can populate `customer_id`, LTV/RFM, etc.
- **Schema cleanup:** rename `_`-prefixed and reserved-word columns in `schema-layered.md` before
  generating production DDL (Exasol won't accept them unquoted).
- **Host & ops:** move off local Docker to the real Exasol (Linux host / managed), with proper
  secrets management (not a `.env` with `SYS`/`exasol`), TLS with a real cert (drop the
  `validateservercertificate=0` / fingerprint workaround), scheduling (systemd timers / cron), and
  monitoring.
- **Distribution keys:** none set for the POC. For prod, likely `DISTRIBUTE BY order_id` to
  co-locate `stg_order_line_items` with `stg_orders` (volume doesn't demand it yet, but cheap to set).
- **Nested pagination:** the line-items loader caps inner `lineItems(first: 100)` — fine for DYT,
  but a production loader should page the inner connection (or use Bulk Operations) for safety.
- **Revenue definition:** the POC sums line `net_amount` (post-discount, refunds NOT netted). The
  production metric layer must pin this definition explicitly and consistently.

---

## 6. Reconciliation vs Fivetran (4.2/4.3) — PASSED

Compared against the existing Fivetran/SQL Server source (`shopify.order_line` ⋈ `shopify.order`),
identical complete-days window (2026-04-25 → 2026-06-23, UTC), identical definition
(`Σ(price·qty − total_discount)`, refunds not netted, cancelled included, `_fivetran_deleted` excluded).

| Measure | Fivetran | POC (ours) | Δ |
|---------|---------:|-----------:|---|
| Revenue | R2,184,381 | R2,177,758 | +R6,623 (**0.30%**) |
| Orders  | 3,202 | 3,195 | +7 |
| Products | 678 | 678 | **exact** |
| Units | 6,016 | 5,997 | +19 |

- Per-product: the large majority match to the rand; the NULL/Unknown-product bucket is
  **R29,250 / 40 units on both sides (exact)**; remaining diffs are a few products off by 1 unit.
- **The 0.30% gap is fully explained by the known 60-day cap**, not a systematic error: our earliest
  order is 2026-04-25 12:46 UTC, so we miss that boundary day's morning orders, which Fivetran (long
  continuous sync) retains. That ≈ the 7 extra orders / R6,623. Everything inside the cleanly-covered
  range ties out. No missing category, no timezone/grain/double-count error.

## 7. Go / no-go (5.4) — **GO** (recommendation, pending Dom's sign-off)

The POC met its success criteria: local Exasol runs and is reachable; 4 STG tables load with proven
idempotency; 4 DWH tables reconcile to STG to the cent with zero NULL FKs; the metric runs; and it
**reconciles to the trusted Fivetran baseline within 0.30%, with the only gap traced to the
already-accepted 60-day scope limitation.**

**Recommendation: GO** — proceed to the production Layer 1 build (resume `research-notes` ETL), with
the productisation changes in §5 folded in from the start. The throwaway POC has done its job: the
Shopify → Exasol → star-schema → metric approach is validated on real DYT data.
