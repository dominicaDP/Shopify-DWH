# POC Notes

Findings, surprises, decisions, and observations captured during the POC. Append-only; date each entry.

Use this file for anything that doesn't belong in `plan.md` (the path) or `tasks.md` (the checklist):

- Things that took longer than expected
- API quirks (Shopify deprecations, rate-limit behaviour, undocumented response shapes)
- Exasol-specific surprises (load performance, type coercion edge cases, distribution key choices)
- Decisions made mid-flight that change the plan
- Out-of-scope questions worth coming back to
- Numbers worth keeping (row counts, durations, sizes)

---

## Log

### 2026-05-15 — POC scoped and planned

POC scope, plan, and tasks set up. Awaiting Phase 0 kickoff.

Key decisions: see `context.md` Decisions Made section.

---

### 2026-05-15 — Phase 0 complete

All three streams green. Findings:

**Shopify app creation — actual flow used:**
- App was created via `dev.shopify.com` (the modern unified dashboard) — not the in-admin "Develop apps" route. That route gives Client ID + Secret only; no static `shpat_` token shortcut.
- Required toggling **"Use legacy install flow"** ON in app settings. Without it Shopify uses managed installation and our standard OAuth flow fails.
- App config is versioned — every change requires Create version + Release to take effect. Worth knowing for any future scope/scope-bump.
- The shop's Shopify subdomain is `garnishonline.myshopify.com` even though the brand is "Dress Your Tech" and the customer URL is `dressyourtech.co.za`. Historic naming.

**Docker:**
- Docker Desktop required an update mid-session. Reinstall wiped local image cache, had to re-pull the ~3 GB Exasol image.
- Container started cleanly with `--privileged` flag on Windows / WSL2 backend.
- Exasol takes ~30s post-`docker run` to accept connections (faster than the expected 1-3 min from documentation).

**Exasol:**
- Default credentials `sys/exasol` work out of the box for the Community Edition Docker image.
- `pyexasol` needed `websocket_sslopt={"cert_reqs": 0}` to skip self-signed cert verification on the local container. Won't be needed against production Exasol with a real cert.
- **Reminder for future SQL work:** Exasol is NOT Oracle. Initial test used `DBMS_METADATA.GET_DATABASE_VERSION_NUMBER()` (Oracle) which doesn't exist. Correct Exasol equivalent: `SELECT PARAM_VALUE FROM EXA_METADATA WHERE PARAM_NAME = 'databaseProductVersion'`.
- Running version: **2025.2.1**

**Mid-session port juggle:**
- Started with `mirofish` container on port 3000 → moved OAuth callback to port 3001. After Docker reinstall the container is gone, port 3000 is free again, but no need to change anything now.

**Time to first green light:** Roughly one session of evening-equivalent work, paced by the Shopify app config tangents.

---

### 2026-06-24 — Phase 1 complete (STG schema deployed)

Resumed after a ~5-week gap. Environment came back cleanly:
- Docker Desktop was not running (machine rebooted since May). Started it; engine up in ~60s.
- `exasol-db` container existed but was stopped (`Exited 255`). `docker start exasol-db` → ready, accepting connections ~15s later. Still v2025.2.1.
- Shopify offline token still valid (no expiry on offline tokens) — `shopify_hello.py` green first try.

**Exasol identifier rule — leading underscore is illegal in unquoted identifiers.**
First `CREATE TABLE` failed with `syntax error, unexpected invalid token` pointing at the
`_extracted_at` column. Exasol regular (unquoted) identifiers must begin with a letter. Options
were (a) quote `"_extracted_at"` everywhere — forces case-sensitivity on every future reference,
or (b) drop the underscore. Chose (b): `_extracted_at` → `extracted_at`.
- **Impacts the real build:** `schema-layered.md` names this `_extracted_at` on all 17 STG tables,
  and any `_`-prefixed ETL-metadata columns in the DWH layer. They all need the same treatment.
  Recommend updating the design doc's convention to a letter-first prefix (e.g. `etl_extracted_at`)
  rather than relying on quoting.
- Note: `CREATE SCHEMA IF NOT EXISTS` and `CREATE TABLE IF NOT EXISTS` both work on Exasol 8
  (2025.2.1) — deploys are idempotent.

**TEXT mapping:** schema-layered.md "TEXT" columns (JSON addresses, tags, notes, landing/referring
site) mapped to `VARCHAR(2000000)` so the local POC never truncates a source value. Exasol is
columnar so an oversized VARCHAR declaration costs nothing until real data lands.

**Artifacts created this session:**
- `code/poc/ddl/01_stg_schema.sql` — the 4-table DDL (source of truth for the POC schema)
- `code/poc/ddl/verify_stg.sql` — Gate 1→2 count check
- `code/poc/deploy_ddl.py` — generic .sql runner (strips `--` comments, splits on `;`, prints
  SELECT results, fails loud). Reused for Phase 3 DWH DDL.

No distribution keys set (POC <10 GB; default distribution fine). Revisit for prod — likely
`DISTRIBUTE BY order_id` to co-locate `stg_order_line_items` with `stg_orders`.

---

### 2026-06-24 — Phase 2 complete (extraction, all 4 STG tables loaded)

Built the reusable extraction stack and all four loaders in one session. Row counts
(as loaded, live store so drifting): products 6,580 · variants 6,598 · orders 3,226 ·
line_items 5,792. Idempotency proven on orders and line items (0 duplicate ids on re-run).

**Reusable components**
- `shopify_client.py` — `ShopifyClient`: auth, `execute()`, `paginate()` (cursor), retries on
  network/5xx/429, cost-based throttle handling. This store's leaky bucket is **20000 points,
  restore 1000/s** (much larger than the standard 1000/50 — newer/Plus allocation), so we
  effectively never throttle at POC volume.
- `exasol_loader.py` — `connect()`, `load_full()` (truncate+reload), `merge_upsert()` (temp
  table + MERGE on key, idempotent), `to_naive_utc()` (ISO→naive UTC for Exasol TIMESTAMP),
  `get_table_columns()` (align DataFrame to table by name, not DDL order).
- Loaders: `load_products.py`, `load_variants.py`, `load_orders.py`, `load_line_items.py`.
  Orders + line items support `full` / `incremental` / `auto` modes.

**KEY FINDING — Shopify `orders` returns only the last 60 days without `read_all_orders`.**
Loaded orders span exactly 2026-04-25 → 2026-06-24 (60 days). This is Shopify's documented
default: the Order query hides orders older than 60 days unless the app holds the protected
`read_all_orders` scope (granted via app config, then a version+release and a fresh OAuth token).
Impact: the POC headline metric is "revenue by product by day, **last 90 days**" — unreachable
on current scope.
**DECISION (2026-06-24): narrow the proving metric to the last 60 days.** Stay on the current
read_orders/read_products scope, no Shopify app reconfiguration. The 60-day window still exercises
the full pipeline (denormalisation, two grains, dimension build) — only the lookback shrinks.
Documented as a known constraint; revisit `read_all_orders` only if the real build needs deeper
history. Phase 4 metric + reconciliation will both use the 60-day window.

**Other Shopify API findings (2026-04)**
- `customer { id }` on orders needs `read_customers` (we have read_orders,read_products only).
  Errored with ACCESS_DENIED → dropped the field, `customer_id` loads NULL. Not needed for the
  revenue metric. Order-level PII (email, shipping/billing address) IS available under read_orders
  (email + shipping_addr 3226/3226 complete).
- `landing_site`, `referring_site`, `checkout_id` removed from Order in 2026-04 (replaced by
  `customerJourneySummary`). NULLed for the POC; not on the metric's critical path.
- `read_products` already exposes inventoryItem cost/weight/requiresShipping — no separate
  `read_inventory` scope was needed for those (cost is just sparsely populated in the data).

**Data observations**
- Line items reconcile close to order headers: SUM(line discounted_total) ≈ 2,195,431 vs
  SUM(order total_price) ≈ 2,197,285. Gap is shipping/tax (header-only) — expected.
- Live-store drift: distinct order_ids crept 3226 → 3228 across extraction runs as new orders
  landed mid-session. Resolves on next orders incremental; the DWH build should tolerate a line
  item whose header arrived in a later batch (or re-run orders incremental before transforming).
- The `�` seen in console output was the Windows code page failing to render an em-dash in our
  OWN print separators — NOT data corruption. Stored Unicode is clean (verified by codepoint).

**Exasol/pyexasol gotchas**
- Bind params use `{name}` formatting in `conn.execute(sql, {...})`, NOT `:name` (that raises
  "Feature not supported: host parameter specification").
- `CHR()` is ASCII-only (0–127); use `UNICODECHR()` for codepoints above 127.
- TIMESTAMP columns come back from queries as **strings**, not datetimes — `pd.Timestamp(x)` to
  parse before formatting (bit us in the watermark formatting).

---

### 2026-06-24 — Phase 3 complete (DWH transforms) + Phase 4.1 (metric runs)

Built the DWH layer as pure SQL (`ddl/02_dwh_schema.sql`, `03_dim_date.sql`, `04_transforms.sql`,
`verify_dwh.sql`, `metric_revenue_by_product_by_day.sql`) — all run through the same `deploy_ddl.py`.

**Design choices for the POC subset**
- Trimmed vs schema-layered.md: no payment/tax/discount pivots on fact_order, no customer/geography
  dims (out of scope), surrogate keys via deterministic `ROW_NUMBER()` (not IDENTITY) so rebuilds are
  repeatable, and a `product_key = -1` "Unknown Product" member so line items with deleted variants
  keep a non-NULL FK.
- GIDs reduced to trailing numeric id with `REGEXP_SUBSTR(x, '[0-9]+$')` consistently on both sides
  of every join.
- dim_date generated with a 4-digit cross join (Exasol has no generate_series); day-of-week anchored
  on 2024-01-01 (a Monday) with `+700000` to keep MOD non-negative.

**Exasol reserved-word identifiers** — `year`, `month`, `day`, `object`, `rows` are all reserved and
fail as unquoted column names/aliases. Renamed dim_date columns to `cal_year/cal_quarter/cal_month/
cal_day` and verification aliases to `obj`/`n`. (Companion to the leading-underscore rule from Phase 1
— Exasol's identifier rules are stricter than the design doc assumed; worth a pass over schema-layered.md
before the real build.)

**Gate 3→4 — PASSED**
- fact_order reconciles EXACTLY to stg_orders: 3,226 rows, SUM(total_amount) = SUM(total_price) =
  R2,197,285.30.
- fact_order_line_item: 5,791 rows vs 5,793 in STG. The 2-row gap is the orphan lines whose order
  header never landed in stg_orders (the live-store drift). Their value (R598) accounts for the
  net_amount gap exactly. Dropping them is correct — an inner join to fact_order keeps FKs valid.
- Zero NULL FKs (order_date_key, order_key, product_key all resolve). 36 line items map to the
  Unknown Product member (deleted variants / gift-card lines).

**Phase 4.1 — metric works end to end.** `v_revenue_by_product_by_day` over the last 60 days:
- Total revenue **R2,195,132**, 679 distinct products, 3,575 product-day rows, 61 calendar days.
- Top products are coherent for DYT (Body Glove backpack/headphones, LOOP'D & Snug powerbanks,
  Havit speakers). Daily revenue R14k–R102k with Sunday dips — passes the eyeball test.
- Revenue definition used: SUM(line `net_amount`) = discounted line total, refunds NOT netted out.
  **This definition must be matched to the Fivetran report before 4.2/4.3 reconciliation.**

**What's left (needs Dom):** Phase 4.2/4.3 — run the same metric against the existing Fivetran/SQL
Server source and compare. I can't reach that system. Once Dom provides the comparison numbers (or
access), we close the tolerance band and move to the Phase 5 go/no-go write-up.

**Note on metric vs raw STG:** the metric total (R2,195,132) equals fact_order_line_item net, not the
order-header total (R2,197,285). They differ because the metric is at line/product grain (excludes
shipping, and excludes the 2 orphan lines). For an apples-to-apples Fivetran check, compare at the
same grain and with the same revenue definition.

---

### 2026-06-24 — Connecting DataGrip to the local POC instance (operational)

Lost time to a false alarm: the POC data appeared "missing" because DataGrip was pointed at the
**cloud** Exasol, while all POC data is in the **local Docker** container. They are two separate
servers. The POC is deliberately local (see context.md decisions) — nothing was ever written to cloud.

To browse the local POC data in DataGrip, create an Exasol data source:
- Host `localhost`, Port `8563`, User `SYS`, Password `exasol`
- Database name internally is `DB1`; the Exasol JDBC driver exposes it as catalog **`EXA_DB`** (so
  "EXA_DB" in the tree is correct — schemas SHOPIFY_STG / SHOPIFY_DWH live under it, uppercase).
- **TLS:** the modern Exasol JDBC driver does NOT honour `validateservercertificate=0` by default and
  rejects the container's self-signed cert (PKIX path error). Fix: pin the fingerprint in the host —
  `Host = localhost/<FINGERPRINT>` (the failed Test Connection error prints the exact fingerprint to
  paste). The fingerprint changes only if the container is destroyed+recreated, not on stop/start.
- Container must be running: `docker start exasol-db`.

---

### 2026-06-24 — Phase 5.2 measurements (data volume + query performance)

Captured against the live local instance (`SYS.EXA_ALL_OBJECT_SIZES` + timed query runs).

**Data volume — the whole warehouse is tiny:**
| Table | Raw (on-disk, compressed) |
|-------|---------------------------|
| STG_PRODUCTS | 4.9 MB |
| DIM_PRODUCT | 3.0 MB |
| STG_ORDERS | 2.4 MB |
| STG_ORDER_LINE_ITEMS | 1.6 MB |
| FACT_ORDER_LINE_ITEM | 1.5 MB |
| STG_PRODUCT_VARIANTS | 1.4 MB |
| FACT_ORDER | 0.7 MB |
| DIM_DATE | 0.3 MB |
| **TOTAL** | **15.45 MB raw** (~13.8 MB in memory) |

- Against the Community Edition 200 GB cap that's **~0.008%**. Even scaling to 10 years of full
  order history (vs the current 60 days) and the complete 17-table design, DYT's footprint stays in
  the low single-digit GB — Community capacity is a non-issue for this workload. Strong signal that
  Exasol is over-provisioned for DYT volume (a cost/fit point for the productisation write-up).

**Query performance:**
- "Revenue by product by day, last 60 days" (3,575 rows via the view): **79–143 ms** (cold ~143ms,
  warms to ~80ms). No tuning, no distribution keys, default everything. Plenty fast for interactive use.

**Extraction timing (observed, NOT formally benchmarked):** each loader completed in well under two
minutes; orders + line items were slowest due to nested pagination (line items pull 50 orders/page ×
up to 100 lines). If precise per-table extraction timings are needed for the Phase 5 write-up, re-run
the loaders with wall-clock instrumentation — current runs only logged progress, not totals.
