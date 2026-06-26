# Runbook — Layer 1 Shopify → Exasol ETL

Operational guide for the daily pipeline. Architecture/decisions live in
[`projects/research-notes/`](../../projects/research-notes/); this is "what do I do
when X". Assumes the host is set up per [`deploy/README.md`](deploy/README.md).

## What runs, and when

`shopify-dwh.timer` fires once a day (02:30) → `shopify-dwh.service` →
`python -m shopify_dwh.pipeline --check`. One run does, in order:

1. **healthcheck** — Exasol `SELECT 1` + Shopify shop reachable (fails fast).
2. **STG loaders** (16) — extract Shopify → `SHOPIFY_STG`. `auto` mode: full load if
   the table is empty, else incremental by the `stg_orders.updated_at` watermark.
3. **DWH build** — `02`→`07`: schema (idempotent), regenerate dim_date/dim_time,
   rebuild all dims+facts from STG, verify, refresh metric views.

Everything is **idempotent** — re-running a whole pipeline is always safe. The DWH
transforms do a **full rebuild from STG** each run (correct and cheap at this volume).

## Run it by hand

```bash
# from code/etl/ (dev), or via systemd on the host (deploy/README.md)
python -m shopify_dwh.pipeline                 # full pipeline, auto mode, fail-fast
python -m shopify_dwh.pipeline --check         # + healthcheck first
python -m shopify_dwh.pipeline --mode full     # force full reload of every STG table
python -m shopify_dwh.pipeline --stg-only      # extract + load only
python -m shopify_dwh.pipeline --dwh-only      # rebuild DWH from existing STG
python -m shopify_dwh.pipeline --continue-on-error   # don't stop at first failure (debug)
```

The run ends with a SUMMARY block (per-step OK/FAIL + seconds) and a non-zero exit if
anything failed.

## When a run fails

The pipeline is fail-fast: it aborts at the first failed step and names it in the
summary. Because every step is idempotent, **fix the cause and re-run the pipeline** —
already-loaded STG tables no-op or merge cleanly, and the DWH rebuild is wholesale.

| Symptom (in the journal) | Likely cause | Fix |
|--------------------------|--------------|-----|
| healthcheck fails on Exasol | host/cred/cert issue, or DB down | check `EXASOL_*`; `EXASOL_ENCRYPTION`/`_CERTIFICATE_VALIDATION` must match the server |
| healthcheck fails on Shopify | token expired/revoked, or scope change | re-run `python -m shopify_dwh.oauth_install` |
| a `stg:*` step fails with an auth/scope error | missing scope on the app | add the scope → Create version → Release → re-OAuth (ACTIONS.md §A.1) |
| `dwh:02_dwh_schema.sql` fails on a CREATE | reserved-word collision (`address`, `region`) | rename the column in DDL + transform + schema doc — never quote (ddl/README.md) |
| `dwh:05_transforms.sql` runs but geo/`shipping_city` is empty | address-JSON parse mismatch | verify the `json.dumps` `": "` spacing assumption (ddl/README.md Phase C) |
| `dwh:06_verify_dwh.sql` shows fact_order ≠ stg_orders | a transform regression | inspect; reconciliation is the gate — don't ship a mismatch |

A single STG loader can also be re-run in isolation, e.g.
`python -m shopify_dwh.loaders.orders incremental`.

## Common operations

- **Full backfill / rebuild from scratch:** `python -m shopify_dwh.pipeline --mode full`.
  Reloads every STG table from Shopify (full history needs `read_all_orders`) and
  rebuilds the DWH.
- **Schema change:** edit the DDL in `ddl/`, then `--dwh-only` (CREATE IF NOT EXISTS
  won't alter an existing table — drop it first if a column changed).
- **Scope change:** update the app scopes (Create version → Release), set
  `SHOPIFY_SCOPES`, re-run `oauth_install`, then a `--mode full` to backfill the
  newly-available fields. Adding `read_discounts`/`read_gift_cards` also means writing
  the two deferred loaders (ACTIONS.md §B).
- **Reconcile vs Fivetran:** edit the window in `ddl/08_reconcile.sql`, run it, and
  compare against the matching Fivetran query (method in that file's header).
- **Distribution keys:** only if the order joins get slow at scale —
  `ddl/09_distribution_keys.sql` (opt-in; reversible).

## Monitoring

```bash
systemctl list-timers shopify-dwh.timer    # next/last run
journalctl -u shopify-dwh.service -e       # last run incl. the SUMMARY block
journalctl -u shopify-dwh.service --since today
```

A failed run leaves `shopify-dwh.service` in a failed state (`systemctl status`),
which is the signal to check the journal. The last run's data freshness is also
visible as `MAX(updated_at)` in `SHOPIFY_STG.stg_orders` and `loaded_at` on any
DWH table.
