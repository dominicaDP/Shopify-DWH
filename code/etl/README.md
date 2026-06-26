# Layer 1 Production ETL — Shopify → Exasol

Production build of the generic Shopify Data Warehouse. Extracts the Shopify Admin
GraphQL API into `SHOPIFY_STG`, transforms into the `SHOPIFY_DWH` star schema, and
exposes a metric/view layer.

This is the real build that the [`shopify-poc`](../poc/) validated (Shopify → Exasol
→ star schema → metric, reconciled to Fivetran at 0.30%). The phased plan and all
the decisions behind it live in
[`projects/research-notes/build-plan.md`](../../projects/research-notes/build-plan.md);
the schema is [`schema-layered.md`](../../projects/research-notes/schema-layered.md) (v1.1, Exasol-safe).

## Layout

```
code/etl/
├── shopify_dwh/            # the importable package
│   ├── config.py           # ALL config from env (the only os.environ reader)
│   ├── shopify_client.py   # GraphQL client: auth, pagination, cost-throttle, retries
│   ├── exasol_loader.py    # DB load utility: load_full, merge_upsert, type coercion
│   ├── ddl_runner.py       # runs .sql files (DDL + verification queries)
│   ├── oauth_install.py    # one-shot OAuth — re-run when scopes change
│   ├── healthcheck.py      # Gate A: SELECT 1 + Shopify shop, both ends green
│   ├── pipeline.py         # Phase E: end-to-end orchestrator (one entry point)
│   └── loaders/            # Phase B STG loaders (one per extraction shape)
├── ddl/                    # Phase B/C/D SQL (STG + DWH DDL, transforms, views)
├── deploy/                 # Phase E: systemd timer + service units
├── RUNBOOK.md              # Phase E: operational runbook
├── .env.example            # copy to .env, fill in (gitignored)
└── requirements.txt
```

What changed from the POC: a central `config.py` (so nothing else reads the
environment and secrets stay in one place), configurable schema names (for
productisation), and a secure-by-default Exasol connection (encryption + cert
validation on; the POC bypassed both for its self-signed Docker box). The
extraction/loading logic itself is ported verbatim — it was validated end-to-end.

## Setup

```bash
cd code/etl
python -m venv venv && source venv/bin/activate   # or venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env        # then fill in real values
```

## Run

```bash
# 1. Mint a Shopify token for the configured scopes (re-run after any scope change):
python -m shopify_dwh.oauth_install

# 2. Gate A — confirm both ends are reachable (Exasol SELECT 1 + Shopify shop):
python -m shopify_dwh.healthcheck

# 3. Deploy + verify the staging schema:
python -m shopify_dwh.ddl_runner ddl/01_stg_schema.sql
python -m shopify_dwh.ddl_runner ddl/verify_stg.sql        # expect 18 tables, all empty

# 4. Load staging. Full-load entities first (no dependency), then orders + children.
python -m shopify_dwh.loaders.products
python -m shopify_dwh.loaders.variants
python -m shopify_dwh.loaders.customers
python -m shopify_dwh.loaders.locations
python -m shopify_dwh.loaders.orders            # establishes the updated_at watermark
python -m shopify_dwh.loaders.line_items
python -m shopify_dwh.loaders.transactions      # order-children (each re-reads orders)
python -m shopify_dwh.loaders.tax_lines
python -m shopify_dwh.loaders.discount_applications
python -m shopify_dwh.loaders.shipping_lines
python -m shopify_dwh.loaders.fulfillments
python -m shopify_dwh.loaders.fulfillment_line_items
python -m shopify_dwh.loaders.refunds
python -m shopify_dwh.loaders.refund_line_items
python -m shopify_dwh.loaders.inventory_levels  # daily snapshot
python -m shopify_dwh.loaders.abandoned_checkouts

# Incremental loaders accept a mode arg: [full | incremental] (default: auto).

# 5. Build the DWH + metric views (after STG is loaded):
python -m shopify_dwh.ddl_runner ddl/02_dwh_schema.sql    # then 03..07 (see ddl/README.md)

# --- OR, in one shot: the orchestrator runs steps 2-5 in dependency order ---
python -m shopify_dwh.pipeline --check       # healthcheck -> STG loaders -> DWH build
# (--mode full|incremental|auto, --stg-only, --dwh-only; see RUNBOOK.md)

# Module self-tests:
python -m shopify_dwh.shopify_client     # paginates a few products
python -m shopify_dwh.exasol_loader      # round-trips dummy rows through stg_products
```

For day-to-day operation (scheduling, failure recovery, backfills, monitoring) see
[`RUNBOOK.md`](RUNBOOK.md); for the systemd install see [`deploy/README.md`](deploy/README.md).

## Status

**Phases A–E are code-complete** (the entire pipeline is built; nothing deployed yet).
See [`../../projects/research-notes/ACTIONS.md`](../../projects/research-notes/ACTIONS.md)
for the full action register.

- **A scaffold / B STG:** all 18 staging tables (`ddl/01_stg_schema.sql`) + 16/18
  loaders. Deferred pending a scope decision: `discount_codes` (read_discounts),
  `gift_cards` (read_gift_cards).
- **C DWH:** all 12 objects + transforms + verify (`ddl/02`–`06`, see `ddl/README.md`).
- **D metric views:** all 57 metrics as named measures (`ddl/07`) + reconcile queries
  (`ddl/08`).
- **E ops:** the `pipeline.py` orchestrator, systemd units (`deploy/`), opt-in
  distribution keys (`ddl/09`), and `RUNBOOK.md`.

**Gate A is not green yet** — it waits on three external prerequisites (decided, not
executed; ACTIONS.md §A): Shopify scopes re-OAuth, the ETL Linux VM, and the Exasol
ETL user + schemas. Once green: deploy DDL → load STG → build DWH (or just
`python -m shopify_dwh.pipeline`) → reconcile vs Fivetran → enable the timer. First-run
field-shape/reserved-word checks are unverified against the live API (ACTIONS.md §C).
