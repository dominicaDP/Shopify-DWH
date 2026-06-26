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
| `02_dwh_schema.sql` | C | `SHOPIFY_DWH` schema + all **12** objects (7 dims + 5 facts) |
| `03_dim_date.sql` | C | generate `dim_date` (4018 days, 2020–2030) |
| `04_dim_time.sql` | C | generate `dim_time` (24 rows, one per hour) |
| `05_transforms.sql` | C | STG → DWH transforms (dims first, then facts) |
| `06_verify_dwh.sql` | C | Gate C: row counts, reconciliation, FK/sentinel checks |

Deploy order (run each with the DDL runner, from `code/etl/`):

```bash
python -m shopify_dwh.ddl_runner ddl/02_dwh_schema.sql   # build SHOPIFY_DWH (Phase C)
python -m shopify_dwh.ddl_runner ddl/03_dim_date.sql     # generate dim_date
python -m shopify_dwh.ddl_runner ddl/04_dim_time.sql     # generate dim_time
python -m shopify_dwh.ddl_runner ddl/05_transforms.sql   # STG -> DWH (dims then facts)
python -m shopify_dwh.ddl_runner ddl/06_verify_dwh.sql   # Gate C verification
```

Full pipeline: `01_stg_schema.sql` → load STG (the loaders) → `02`→`06` above.
The DWH files port the POC's `code/poc/ddl/02_dwh_schema.sql` / `03_dim_date.sql` /
`04_transforms.sql` patterns (ROW_NUMBER keys, sentinel members, GID extraction,
digit cross-join dim_date) and widen them to the full design (`schema-layered.md`).

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

**DWH-layer reserved-word watch** (Phase C, same rule — rename, never quote, if a
CREATE fails): `address` (dim_location), `region` (dim_geography). The POC already
proved `year`/`month`/`day` need avoiding, so dim_date uses `cal_year` / `cal_month`
/ `day_of_month` and dim_time has no offenders.

## Expected after a clean deploy

- `verify_stg.sql` row 1: **18** tables, each `row_count = 0` (before loaders run).
- `verify_stg.sql` row 2: `table_count = 18`, `column_count = 234`.
- `06_verify_dwh.sql`: dim_date = 4018, dim_time = 24; every sentinel count = 1;
  fact_order reconciles exactly to stg_orders (rows + total); fact_order_line_item
  rows ≤ stg lines (orphan drift dropped); all NULL-FK checks = 0. The `*_unknown_*`
  columns are informational, not failures (e.g. `order_unknown_customer` is the full
  count until `read_customers` + the customers loader land).

## Phase C (DWH) — first-run verification

The transforms reuse POC-validated SQL, but two things couldn't be tested without
the live instance — check them on the first real run:

- **Address JSON parsing** (dim_geography, dim_customer.default_*, fact_order geo).
  Addresses are stored as the JSON our loaders wrote with `json.dumps` (keys: `city`,
  `province`, `provinceCode`, `countryCodeV2`, `country`, `zip`). The transforms pull
  a value with `REGEXP_SUBSTR(json, '"key": "[^"]*')` then strip the `"key": "` prefix
  with `REGEXP_REPLACE` — no JSON functions, no lookbehind, so it runs on any Exasol
  build. Confirm `dim_geography` has real city/country rows and `fact_order.shipping_city`
  is populated on a sample. The pattern assumes `json.dumps`' `": "` spacing; a value
  containing an escaped quote would truncate (rare for addresses).
- **`HOURS_BETWEEN` / `WEEK` / `LAST_DAY` / `NTILE`** — standard Exasol functions used
  by fact_fulfillment timing, dim_date, and dim_customer RFM. The POC didn't exercise
  them; if any errors, it's a function-name/signature swap, not a logic change.

Sentinel/Unknown members are inserted with fixed keys (`-1` Unknown, `0` No-Discount)
that `ROW_NUMBER()` (which starts at 1) never collides with, so fact FKs are never NULL.
`dim_discount` lands only its `0` sentinel until `read_discounts` is granted and the
deferred `stg_discount_codes` loader runs — the table and transform are already wired.

### A note on "17 vs 18"

Several docs (MEMORY, build-plan, schema-layered intro) say "17 STG tables". The
actual count is **18** — `stg_gift_cards` was added later, during the DYT Layer 2
research, to support gift-card voucher joins. The "17" label predates it. All 18 are
real and built here; the label is just stale and worth reconciling in the design doc.
