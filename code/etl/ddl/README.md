# DDL — SHOPIFY_STG / SHOPIFY_DWH

SQL that builds and verifies the warehouse. Source of truth for every column is
[`schema-layered.md`](../../../projects/research-notes/schema-layered.md) (v1.1,
Exasol-safe); these files are its executable form. Run them with the DDL runner
(from `code/etl/`):

```bash
python -m shopify_dwh.ddl_runner ddl/01_stg_schema.sql   # build STG (Phase B.1)
python -m shopify_dwh.ddl_runner ddl/verify_stg.sql      # confirm 18 tables, all empty
```

## Files

| File | Phase | What |
|------|-------|------|
| `01_stg_schema.sql` | B.1 | `SHOPIFY_STG` schema + all **18** staging tables |
| `verify_stg.sql` | B.1 | existence/empty check + table/column-count tripwire |
| *(02_dwh_schema.sql, transforms, verify_dwh — Phase C, not yet written)* | C | |

Deploy order: `01_stg_schema.sql` → load STG (the loaders) → Phase C DWH DDL →
transforms → verify. The DWH files port from `code/poc/ddl/02_dwh_schema.sql` etc.

## Conventions (why the SQL looks the way it does)

These were validated by the POC (4 STG + 4 DWH tables deployed and loaded cleanly
on Exasol 8 / v2025.2.1) and are applied uniformly across all 18 tables.

- **STG mirrors the Shopify API** — row-based, one table per API object/connection,
  minimal transformation. Business logic lives in the DWH layer, not here.
- **GIDs stay raw** as `VARCHAR(50)` (`gid://shopify/Order/123`). Numeric-ID
  extraction happens in the DWH transforms, not at staging.
- **`extracted_at`** is the ETL load timestamp on every table (not a Shopify field).
  The design doc calls it `_extracted_at`, but Exasol unquoted identifiers can't
  start with `_`, so the prefix is dropped (a POC finding, baked into v1.1).
- **Idempotent DDL** — `CREATE SCHEMA/TABLE IF NOT EXISTS` throughout, so a re-deploy
  is a no-op rather than an error.
- **No keys/constraints** — Exasol doesn't enforce PK/FK by default and the POC
  didn't declare them; reconciliation (Gate C) catches integrity issues instead.
- **No distribution keys yet** — total volume is < single-digit GB. Phase E adds
  `DISTRIBUTE BY` where it helps (e.g. `order_id` on the order-grain tables).

### Type mapping: design doc → Exasol

| `schema-layered.md` says | DDL uses | Why |
|--------------------------|----------|-----|
| `TEXT` (JSON blobs, notes, URLs) | `VARCHAR(2000000)` | Exasol has no `TEXT` type; 2 MB never truncates a source value |
| `INT` | `INTEGER` | Exasol stores it as `DECIMAL(18,0)` |
| `DECIMAL(p,s)`, `BOOLEAN`, `TIMESTAMP`, `DATE`, `VARCHAR(n)` | as-is | native Exasol types |

### Identifiers & reserved words — **unquoted on purpose**

All identifiers are unquoted, so Exasol folds them to UPPERCASE. This is **required**,
not stylistic: the loaders align DataFrame columns by uppercased name against
`EXA_ALL_COLUMNS`. A quoted identifier (e.g. `"source"`) is stored case-sensitively
and would silently break column alignment at load time.

Consequence: if a column name collides with an Exasol reserved word, the CREATE
fails — and the fix is to **rename the column** (in the DDL, the loader's row mapping,
and `schema-layered.md`), exactly like the DWH layer's `year` → `cal_year`. Never
quote to dodge a reserved word.

**Reserved-word watch list** (couldn't be verified without the live instance — the
POC's 4 tables didn't exercise these). On the first deploy, if `01_stg_schema.sql`
fails on a CREATE, suspect one of these and rename it:

| Column | Table | Note |
|--------|-------|------|
| `source` | stg_order_shipping_lines | most likely of the three |
| `committed` | stg_inventory_levels | from `READ COMMITTED` lineage |
| `reserved` | stg_inventory_levels | literally the word "reserved" |

Names already proven safe by the POC (so *not* a risk): `name`, `status`, `title`,
`price`, `cost`, `quantity`, `taxable`, `description`, `note`, `tags`, `weight`,
`barcode`. The DWH-layer offenders (`year`, `month`, `day`, `object`, `rows`) do
**not** appear in any STG table.

## Expected after a clean deploy

- `verify_stg.sql` row 1: **18** tables, each `row_count = 0` (before loaders run).
- `verify_stg.sql` row 2: `table_count = 18`, `column_count = 234`.

### A note on "17 vs 18"

Several docs (MEMORY, build-plan, schema-layered intro) say "17 STG tables". The
actual count is **18** — `stg_gift_cards` was added later, during the DYT Layer 2
research, to support gift-card voucher joins. The "17" label predates it. All 18 are
real and built here; the label is just stale and worth reconciling in the design doc.
