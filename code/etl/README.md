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
# Mint a Shopify token for the configured scopes (re-run after any scope change):
python -m shopify_dwh.oauth_install

# Gate A — confirm both ends are reachable:
python -m shopify_dwh.healthcheck

# Module self-tests (need the hosts + Phase B schema for the loader one):
python -m shopify_dwh.shopify_client     # paginates a few products
python -m shopify_dwh.exasol_loader      # round-trips dummy rows through stg_products

# Deploy / verify SQL (Phase B onward):
python -m shopify_dwh.ddl_runner ddl/01_stg_schema.sql
```

## Status — Phase A (scaffold)

Done: package layout, the three shared modules ported, central config + secrets
handling, OAuth helper, and the Gate A healthcheck.

**Gate A is not green yet** — it depends on three external prerequisites (decided,
not yet executed; see build-plan.md):

1. **Shopify scopes** — add `read_all_orders` + `read_customers` + `read_inventory`
   in the app config (create version → release), then `oauth_install` for a fresh token.
2. **ETL host** — the dedicated Linux VM on the Exasol network.
3. **Exasol user + schemas** — the dedicated least-privilege ETL user owning
   `SHOPIFY_STG` / `SHOPIFY_DWH`.

Once those are in place, `python -m shopify_dwh.healthcheck` should print
**Gate A: GREEN**, and Phase B (the 17 STG loaders) begins.
