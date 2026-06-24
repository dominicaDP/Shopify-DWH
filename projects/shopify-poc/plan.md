# POC Execution Plan

**Last Updated:** 2026-05-15
**Approach:** Sequence-driven, not calendar-driven. Each phase has a clear gate that says "you know it worked because…" — pick up at the right step after any break.

---

## Resume Here (next session start)

**Status:** ✅ Phases 0–3 + 4.1 complete. The pipeline works end to end: Shopify → STG → DWH →
metric. **Next is Phase 4.2/4.3 (reconcile vs Fivetran) — needs Dom**, then Phase 5 (go/no-go).

**To resume / rebuild from scratch:**
1. Start Docker Desktop, then `docker start exasol-db`. Check: `python exasol_hello.py`.
2. Refresh STG from live store (optional): `python load_orders.py incremental` then
   `python load_line_items.py incremental`. (Products/variants: re-run `load_products.py` /
   `load_variants.py` for a full refresh.)
3. Rebuild DWH + metric (all idempotent, run in order):
   `python deploy_ddl.py ddl/02_dwh_schema.sql`
   `python deploy_ddl.py ddl/03_dim_date.sql`
   `python deploy_ddl.py ddl/04_transforms.sql`
   `python deploy_ddl.py ddl/verify_dwh.sql`
   `python deploy_ddl.py ddl/metric_revenue_by_product_by_day.sql`

**Phase 4.2/4.3 — the open task (Dom):** run "revenue by product by day, last 60 days" against the
existing Fivetran/SQL Server source and compare to the POC's **R2,195,132**. First align the revenue
definition (POC sums line `net_amount`, post-discount, refunds not netted). Document the tolerance band.

**Metric window: 60 days, not 90** (Shopify 60-day order cap without `read_all_orders` — decided 2026-06-24).

**Artifacts:** extraction — `shopify_client.py`, `exasol_loader.py`, `load_{products,variants,orders,
line_items}.py`. DWH/metric — `ddl/02_dwh_schema.sql`, `03_dim_date.sql`, `04_transforms.sql`,
`verify_dwh.sql`, `metric_revenue_by_product_by_day.sql`.

---

## Phase 0 — Foundations ✅ COMPLETE (2026-05-15)

Three independent streams. Can be done in any order, but all three must pass before Phase 1.

### Stream A — Exasol

1. Install Exasol Community Edition on Windows
   - Option 1: VM image via VirtualBox/VMware
   - Option 2: Docker Desktop with WSL2
2. Verify the DB starts and is reachable on `localhost`
3. Connect with a SQL client (Exasol Admin UI or DBeaver) and run `SELECT 1`
4. Note the connection string, port, user, password — will go in `.env`

### Stream B — Python

1. POC code location: `C:\Users\dominica\source\repos\Shopify-DWH\code\poc\` (inside this repo)
2. Create virtualenv (`python -m venv venv`) inside `code/poc/`
3. Install `pyexasol`, `httpx`, `python-dotenv`, `pandas`
4. Create `.env` file with placeholder credentials. Update the repo `.gitignore` to exclude `.env`, `venv/`, `__pycache__/`, raw extracts, and any local data dumps.

### Stream C — Shopify

1. In DYT Shopify Admin → Apps → Develop apps → Create custom app
2. Grant **read-only** Admin API scopes for: `read_orders`, `read_products`, `read_inventory`, `read_customers`
3. Install the app on the store, copy the Admin API access token
4. Test from Python — fetch shop name via GraphQL:
   ```graphql
   query { shop { name email } }
   ```

### Gate to Phase 1

- ✅ `SELECT 1` runs in Exasol from Python via PyExasol
- ✅ Shopify hello-world query returns shop name

---

## Phase 1 — STG Schema Deployed ⬅ NEXT

| Step | What | Output |
|------|------|--------|
| 1.1 | Create `SHOPIFY_STG` schema in Exasol | `CREATE SCHEMA SHOPIFY_STG;` |
| 1.2 | Deploy DDL for the 4 POC STG tables | Source: `research-notes/schema-layered.md`. Extract DDL for `stg_orders`, `stg_order_line_items`, `stg_products`, `stg_product_variants` only. |

### Gate

- ✅ `SELECT COUNT(*) FROM SHOPIFY_STG.stg_orders` returns 0 (table exists, empty)
- ✅ Same for the other 3 tables

---

## Phase 2 — Extraction (the proving ground)

This is where most learning happens. Order matters — each step builds on the previous.

| Step | What | Why |
|------|------|-----|
| 2.1 | Shopify GraphQL client wrapper | One place to handle auth, pagination, retries, rate-limit backoff. Reused by every loader. |
| 2.2 | PyExasol load utility | DataFrame → STG table with type coercion. Reused by every loader. |
| 2.3 | `stg_products` loader (full load only) | Smallest table. Proves the round-trip. |
| 2.4 | `stg_product_variants` loader (full load only) | Same pattern. Confirms 2.3 wasn't a fluke. |
| 2.5 | `stg_orders` loader — **full load** | Bigger table, harder pagination. Don't add incremental yet. |
| 2.6 | `stg_orders` loader — **incremental** via `updatedAt` watermark | The single hardest pattern in ETL. Get this right once, reuse everywhere. |
| 2.7 | Idempotency test — re-run 2.6, prove zero duplicates | Without this, the rest is a sandcastle. Use MERGE or DELETE+INSERT per batch. |
| 2.8 | `stg_order_line_items` loader (incremental) | Confirms the pattern generalises. Lines extracted alongside their parent orders. |

### Gate

- ✅ All 4 STG tables populated with real data
- ✅ Re-running any loader produces zero duplicates (idempotency confirmed)
- ✅ Row counts roughly match what Shopify Admin UI reports (e.g. total orders count)
- ✅ A spot check of 3-5 individual order IDs shows STG data matches Shopify Admin display

### Optional stretch (only if Phase 2 was easy)

- **2.9** — Convert one loader to use Shopify Bulk Operations API. Async pattern, polling, JSONL download. Worth knowing for production scale, not required to prove correctness.

---

## Phase 3 — Transform (DWH)

Pure SQL from here. No more external dependencies — can be done from anywhere you can reach Exasol.

| Step | What |
|------|------|
| 3.1 | Create `SHOPIFY_DWH` schema |
| 3.2 | Deploy DDL for `dim_date`, `dim_product`, `fact_order` (minimal — no payment pivot), `fact_order_line_item` |
| 3.3 | Generate `dim_date` (pure SQL — generate 10 years × 365 days, no source data needed) |
| 3.4 | Build `dim_product` transform from `stg_products` + `stg_product_variants` |
| 3.5 | Build `fact_order` transform from `stg_orders` (header level, no payment pivot for POC) |
| 3.6 | Build `fact_order_line_item` transform — denormalised with product attributes via `dim_product` lookup |

### Gate

- ✅ All 4 DWH tables populated
- ✅ Row counts and totals reconcile to STG (e.g. `SUM(fact_order.total_amount) ≈ SUM(stg_orders.total_price)`)
- ✅ Zero NULL foreign keys to `dim_date` or `dim_product`

---

## Phase 4 — The Actual Metric

| Step | What |
|------|------|
| 4.1 | Write report query: "Revenue by product by day, last 60 days" (window narrowed from 90 — see Phase 2 decision) using `fact_order_line_item + dim_date + dim_product` |
| 4.2 | Run the same metric against the current Fivetran-based source |
| 4.3 | Compare outputs. Investigate any discrepancies. Document the tolerance band you accept. |

### Gate

- ✅ Numbers match the existing source within an explainable tolerance (typically <1% from rounding / timezone / cancelled-order handling differences)
- ✅ Discrepancies that can't be explained are documented as findings

---

## Phase 5 — Decision

| Step | What |
|------|------|
| 5.1 | Write up: what worked, what was harder than expected, what broke (use `notes.md` throughout the POC and finalise here) |
| 5.2 | Measurements: extraction time per table, query time for the report, total data volume |
| 5.3 | Productisation notes — what would change for prod (Linux host, secrets management, monitoring, scheduling, scale) |
| 5.4 | Go / no-go / pivot decision |

---

## Dependency Graph

```
Phase 0
 ├── Stream A (Exasol) ──┐
 ├── Stream B (Python) ──┼──> Phase 1 ──> Phase 2 ──> Phase 3 ──> Phase 4 ──> Phase 5
 └── Stream C (Shopify) ─┘
```

Inside Phase 2, steps 2.1-2.8 are strictly sequential.
Everything else within a phase can be done in flexible order as long as gate criteria are met.
