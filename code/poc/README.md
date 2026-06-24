# Shopify DWH POC — code

Standalone, **local** proof-of-concept: extract real DYT Shopify data into a local
Exasol Community Edition (Docker), transform it into a star schema, and compute
"revenue by product by day." Throwaway validation for the Layer 1 design.

**Status (2026-06-24): COMPLETE — verdict GO.** All phases passed; the metric reconciles
to the existing Fivetran source within 0.30% (gap explained by the 60-day order cap).
Full write-up: [`../../projects/shopify-poc/findings.md`](../../projects/shopify-poc/findings.md).

> This is local and disposable by design. The DB holds real customer PII; keep it on this
> machine only (see `projects/shopify-poc/context.md` for the security posture).

## Prerequisites

- **Docker Desktop** running, with the Exasol container:
  ```sh
  docker start exasol-db      # container already exists from Phase 0
  ```
- **Python venv** (already created in `venv/`); dependencies in `requirements.txt`
  (`httpx`, `pyexasol`, `pandas`, `python-dotenv`).
- **`.env`** (gitignored) with Shopify token + Exasol creds. See `.env.example`.
  - Exasol: `localhost:8563`, user `SYS`, password `exasol`
  - Shopify: offline token for `garnishonline.myshopify.com`, scopes `read_orders,read_products`

## Files

| File | Purpose |
|------|---------|
| `exasol_hello.py` | Phase 0 check — connect to Exasol, print version |
| `shopify_hello.py` | Phase 0 check — Shopify token works, print shop |
| `oauth_install.py` | One-shot Shopify OAuth to mint the offline token into `.env` |
| `shopify_client.py` | **Reusable** — Admin GraphQL client: auth, cursor pagination, retries, cost-based throttle backoff |
| `exasol_loader.py` | **Reusable** — `load_full` (truncate+reload), `merge_upsert` (idempotent MERGE), name-based column alignment, `to_naive_utc` |
| `load_products.py` | Loader → `stg_products` (full) |
| `load_variants.py` | Loader → `stg_product_variants` (full) |
| `load_orders.py` | Loader → `stg_orders` (`full` / `incremental` / `auto`) |
| `load_line_items.py` | Loader → `stg_order_line_items` (`full` / `incremental` / `auto`) |
| `deploy_ddl.py` | Generic `.sql` runner (strips comments, splits on `;`, prints SELECTs, fails loud) |
| `ddl/*.sql` | Schema, transforms, verification, metric — see below |

## Run the whole pipeline

All commands from `code/poc/` using the venv Python (`./venv/Scripts/python.exe` on Windows).

```sh
# 0. Sanity checks
python exasol_hello.py
python shopify_hello.py

# 1. STG schema (idempotent)
python deploy_ddl.py ddl/01_stg_schema.sql
python deploy_ddl.py ddl/verify_stg.sql          # expect 4 tables at count 0

# 2. Extract (loaders). Products/variants are full; orders/line_items auto-pick
#    full on first run, incremental after.
python load_products.py
python load_variants.py
python load_orders.py
python load_line_items.py

# 3. Transform to DWH (idempotent — safe to re-run anytime)
python deploy_ddl.py ddl/02_dwh_schema.sql
python deploy_ddl.py ddl/03_dim_date.sql
python deploy_ddl.py ddl/04_transforms.sql
python deploy_ddl.py ddl/verify_dwh.sql          # gate: reconciles to STG, no NULL FKs

# 4. The metric
python deploy_ddl.py ddl/metric_revenue_by_product_by_day.sql
python deploy_ddl.py ddl/recon_our_side.sql      # numbers for Fivetran reconciliation
```

To refresh from the live store later: re-run `load_orders.py incremental` then
`load_line_items.py incremental`, then re-run the step-3 transforms.

## Viewing the data (DataGrip)

The data is in the **local** container, not any cloud Exasol. Create a data source:
`localhost:8563`, `SYS`/`exasol`. The local cert is self-signed — pin the fingerprint
in the host field (`localhost/<fingerprint>`; the failed Test Connection error prints it),
since the modern driver ignores `validateservercertificate=0`. Schemas appear under the
`EXA_DB` catalog as `SHOPIFY_STG` / `SHOPIFY_DWH` (uppercase).

## Key gotchas (full list in `projects/shopify-poc/notes.md`)

- Shopify caps the `orders` query at **60 days** without `read_all_orders`.
- `customer{}` on orders needs `read_customers` (we don't have it → `customer_id` is NULL).
- Exasol rejects leading-underscore and reserved-word identifiers (`_extracted_at`→`extracted_at`,
  `year`/`month`/`day`→`cal_*`).
- pyexasol bind params use `{name}` not `:name`; query results return TIMESTAMP as strings.
