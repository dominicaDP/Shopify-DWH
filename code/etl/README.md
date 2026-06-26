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
│   └── loaders/            # Phase B STG loaders (one per extraction shape)
├── ddl/                    # Phase B/C SQL (STG + DWH DDL, verification)
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

# Module self-tests:
python -m shopify_dwh.shopify_client     # paginates a few products
python -m shopify_dwh.exasol_loader      # round-trips dummy rows through stg_products
```

## Status

**Phase A (scaffold) + Phase B (STG: DDL + loaders) are code-complete.** See
[`../../projects/research-notes/ACTIONS.md`](../../projects/research-notes/ACTIONS.md)
for the full action register.

- **DDL:** all 18 staging tables in `ddl/01_stg_schema.sql` (see `ddl/README.md`).
- **Loaders:** 16/18 built (`shopify_dwh/loaders/`). Deferred pending a scope
  decision: `discount_codes` (read_discounts), `gift_cards` (read_gift_cards).
- **Verified:** every loader's output columns match its DDL columns. Not yet run —
  GraphQL field-shapes are unverified against the live API (see the first-run
  checklist in ACTIONS.md §C).

**Gate A is not green yet** — it waits on three external prerequisites (decided, not
executed; ACTIONS.md §A): Shopify scopes re-OAuth, the ETL Linux VM, and the Exasol
ETL user + schemas. Once green, deploy the DDL and run the loaders above. Next code
work (no infra needed): **Phase C — the DWH layer** (`ddl/02_dwh_schema.sql` +
transforms).
