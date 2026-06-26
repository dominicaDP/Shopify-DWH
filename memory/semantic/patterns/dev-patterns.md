# Development Patterns

**Last Updated:** 2026-06-26

---

## Overview

Patterns extracted from development work across all projects. These are reusable solutions that have proven valuable.

### Confidence Levels

| Level | Meaning | Criteria |
|-------|---------|----------|
| **LOW** | New, untested | Just discovered |
| **MEDIUM** | Validated | Used 3+ times successfully |
| **HIGH** | Standard practice | Used 5+ times, well-documented |

---

## Architecture Patterns

### Two-Layer Architecture (Generic + Custom)

**Confidence:** LOW
**Uses:** 2
**Category:** architecture
**Last Used:** 2026-02-18

**When to use:**
Building a solution that needs to be both productizable (sellable to others) AND customizable for specific client needs.

**Structure:**
```
Layer 1: Generic Base (Productizable)
├── Works for any client/instance
├── Maps to standard data models
├── Resellable, documented
│
Layer 2: Custom Extensions (Client-specific)
├── Built ON TOP of Layer 1
├── Client-specific business logic
├── Custom integrations
```

**Benefits:**
- Clear separation of concerns
- Can sell Layer 1 independently
- Custom work doesn't pollute generic base
- Easier maintenance and upgrades

**Trade-offs:**
- More upfront design effort
- Must resist putting client-specific logic in Layer 1

**2026-02-18 Validation:**
Layer 2 (DYT-specific) successfully designed on top of Layer 1 (generic Shopify) using separate schemas (DYT_STG / DYT_DWH). Layer 1 was untouched. dim_voucher unifies Shopify gift cards and discount codes with SQL Server channel data. Confirms the pattern works for multi-source extensions too.

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

---

### Star Schema for Single-Source DWH

**Confidence:** MEDIUM
**Uses:** 3
**Category:** data-modeling
**Last Used:** 2026-06-26

**2026-06-26 full-build (LOW→MEDIUM, uses 2→3):** Scaled the POC's 4-object star to the **full
12-object** design — 7 dims + 5 facts — in pure-SQL transforms (`code/etl/ddl/05_transforms.sql`).
The grammar that held at 4 objects held at 12: ROW_NUMBER surrogate keys, sentinel/Unknown members
with fixed keys (-1 Unknown, 0 No-Discount) so fact FKs are never NULL, GID→numeric via
`REGEXP_SUBSTR`, and `INSERT…SELECT` dims-first-then-facts. No new structural surprises at scale —
the design generalised cleanly. Three uses, real builds → promote to MEDIUM.

**2026-06-24 build validation:** First time this was actually *built and run*, not just
designed. A minimal star (dim_date, dim_product, fact_order, fact_order_line_item) on Exasol
populated from real Shopify data, reconciled to STG to the cent, zero NULL FKs, and answered the
target metric in <150ms. The design held up in implementation.

**When to use:**
Building a data warehouse with a single primary source system (e.g., one SaaS platform like Shopify).

**Structure:**
```
        ┌─────────┐
        │ dim_*   │ (multiple dimensions)
        └────┬────┘
             │
     ┌───────┴───────┐
     │   fact_*      │ (fact tables at appropriate grain)
     └───────────────┘
```

**Benefits:**
- BI tools expect it (Tableau, Power BI, Looker)
- Customers/analysts understand it
- Columnar DBs (Exasol, Redshift) optimized for it
- Solo-developer friendly

**When NOT to use:**
- Multiple source systems with complex integration → consider Data Vault
- Rapidly changing schema → consider Data Vault
- Need full audit history → consider Data Vault

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md

---

### Variant-Level Grain for Retail Products

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-01-29

**When to use:**
Designing product dimensions for retail/ecommerce where products have variants (size, color, etc.).

**Decision:**
Model dim_product at **variant level** (one row per variant), not product level.

**Benefits:**
- Enables variant-level analysis ("which colors sell best?")
- Can always aggregate UP to product level
- Captures variant attributes (option1/2/3)
- Standard approach for retail DWH

**Trade-offs:**
- More rows than product-level grain
- Slightly more complex joins

**Key Fields to Include:**
- option1, option2, option3 (variant attributes)
- barcode (for inventory/fulfillment matching)
- Both product_id AND variant_id

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md

---

## Process Patterns

### Validate Schema Against Source API

**Confidence:** LOW
**Uses:** 1
**Category:** process
**Last Used:** 2026-01-29

**When to use:**
Designing a DWH schema that will be populated from an API source.

**Steps:**
1. Draft initial schema based on business requirements
2. Fetch actual API documentation
3. Map each schema field to API field
4. Identify gaps:
   - Fields in schema not available in API
   - Useful API fields missing from schema
   - Fields that come from DIFFERENT endpoints than expected
5. Update schema with findings
6. Document any fields requiring multiple API calls

**Benefits:**
- Catches design issues before implementation
- Discovers data that lives in unexpected places (e.g., cost in InventoryItem, not Product)
- Avoids costly schema changes during ETL development

**Example Finding:**
```
Expected: Product.cost
Reality:  Variant.inventory_item_id → InventoryItem.cost
Action:   Plan for additional API call in ETL
```

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md

---

### Check API Lifecycle Before Building

**Confidence:** LOW
**Uses:** 1
**Category:** process
**Last Used:** 2026-01-29

**When to use:**
Starting any integration project with an external API.

**Steps:**
1. Before writing any code, check:
   - Is this API version current or deprecated?
   - What's the sunset date?
   - Is there a newer API (REST → GraphQL)?
2. Check official changelog/announcements
3. Search for "[platform] API deprecation [year]"
4. Choose the forward-looking option

**Why it matters:**
- Avoids building on deprecated foundations
- Prevents forced migration 6-12 months later
- Example: Shopify REST API deprecated Oct 2024, GraphQL required April 2025

**Time saved:** Hours to days of rework avoided

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md

---

### Mid-Session Checkpointing

**Confidence:** HIGH
**Uses:** 6
**Category:** process
**Last Used:** 2026-06-26

**2026-06-26 reinforcement (use 6, the DWH+views+ops session):** Same rhythm, now across a
multi-phase build: committed C / D / E as three clean commits, refreshed ACTIONS.md + MEMORY +
both READMEs as each phase landed, then branched/merged at the end. The handoff stayed clean enough
that the whole thing could be reconstructed from disk alone. Holds firmly at HIGH.

**2026-06-26 promotion (MEDIUM→HIGH):** The Layer 1 STG build session committed after *every*
batch (scaffold, DDL, each loader group) — 9 commits — and refreshed build-plan/notes/MEMORY as it
went, then did an explicit "document everything" consolidation pass (ACTIONS.md) before pausing.
When the user asked "should we start fresh for more context?", the honest answer was "either works,
the handoff is clean" — *because* context lived on disk, not in the conversation. That's the payoff
of the pattern made concrete. 5th use across research + implementation; promoting to HIGH.

**2026-06-24 promotion (LOW→MEDIUM):** Used relentlessly through the longest session yet — after
every phase, updated tasks/notes/plan/findings/memory and committed. When the session detoured into
a long DataGrip connection debug, the work was never at risk because each phase was already
checkpointed. Confirms the pattern across both research and implementation work.

**When to use:**
Working on research or complex tasks in Claude Code sessions that might get interrupted.

**Steps:**
1. After completing a meaningful chunk of work:
   - Update tasks.md (mark complete, add new tasks)
   - Update notes.md with findings
   - Create episodic memory if significant
2. Before moving to next topic, ask: "If session dies now, can future Claude recover?"
3. If no → checkpoint first

**Trigger points:**
- Completed API research
- Made schema changes
- Made key decisions
- About to switch topics

**Benefits:**
- Context survives session interruptions
- Future sessions can `/recall` and continue
- Prevents "stuck at research" loops

**2026-01-30 Reinforcement:**
Applied this pattern across 4 research topics in one session:
- InventoryItem API → episodic + pattern + notes
- Discount API → episodic + pattern + notes
- ETL evaluation → episodic + pattern + ADR
- Exasol schema → episodic + pattern + schema.md

Result: Complete documentation trail, easy progress tracking, zero context loss.

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md
- memory/episodic/completed-work/2026-01-30-inventory-api-research.md
- memory/episodic/completed-work/2026-01-30-discount-api-research.md
- memory/episodic/completed-work/2026-01-30-etl-tooling-evaluation.md
- memory/episodic/completed-work/2026-01-30-exasol-schema-review.md

---

## Domain Knowledge (Shopify)

### Shopify Cost Data Location

**Confidence:** MEDIUM
**Uses:** 2
**Category:** shopify-api
**Last Used:** 2026-01-30

**Knowledge:**
Product cost (COGS) is NOT in the Product API.

**Actual location (GraphQL):**
```
Product
  └→ variants
       └→ inventoryItem
            └→ unitCost { amount, currencyCode }
```

**ETL implication:**
- Need to traverse ProductVariant.inventoryItem to get cost
- unitCost is MoneyV2 type (amount string + currency code)
- May need multi-currency handling

**Source:** Shopify GraphQL Admin API documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md
- memory/episodic/completed-work/2026-01-30-inventory-api-research.md

---

### Shopify Inventory Levels (Multi-Location Stock)

**Confidence:** LOW
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-30

**Knowledge:**
Stock quantities are tracked per item per location via InventoryLevel.

**Structure:**
```
InventoryItem
  └→ inventoryLevels (per location)
       └→ quantities [
            { name: "available", quantity: X },
            { name: "on_hand", quantity: Y },
            { name: "committed", quantity: Z },
            ...
          ]
```

**Key states:** available, on_hand, committed, incoming, reserved, damaged, quality_control, safety_stock

**DWH implication:**
- If multi-location tracking needed: dim_location + fact_inventory_level
- Consider snapshot frequency (daily? hourly?)
- Normalized quantity states = need to pivot or store as rows

**Source:** Shopify GraphQL Admin API documentation

---

### Shopify Discount Code Structure

**Confidence:** LOW
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-30

**Knowledge:**
Shopify has 4 discount code types, all under DiscountCodeNode:

| Type | Purpose |
|------|---------|
| DiscountCodeBasic | Fixed amount or % off products |
| DiscountCodeBxgy | Buy X Get Y promotions |
| DiscountCodeFreeShipping | Waive shipping costs |
| DiscountCodeApp | Custom app-defined |

**Key Objects:**
- `DiscountRedeemCode` - Individual codes with `asyncUsageCount` for redemption tracking
- `DiscountApplication` - Interface showing how discount applied to order
- `PricingValue` - Union of MoneyV2 (fixed) or PricingPercentageValue (%)

**Redemption Tracking:**
```
DiscountCodeNode
  └→ codeDiscount (DiscountCodeBasic, etc.)
       └→ codes (DiscountRedeemCode)
            └→ asyncUsageCount (redemption count)
```

**On Orders:**
- `discountCodes` - Array of applied codes
- `discountApplications` - Details with allocationMethod, targetType, value

**Source:** Shopify GraphQL Admin API documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-discount-api-research.md

---

### Shopify MoneyBag for Multi-Currency

**Confidence:** MEDIUM
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-30

**When to use:**
Extracting any monetary values from Shopify GraphQL API.

**Structure:**
All `*Set` financial fields return MoneyBag:
```graphql
totalPriceSet {
  shopMoney {
    amount         # Decimal string (e.g., "99.99")
    currencyCode   # ISO code (e.g., "ZAR")
  }
  presentmentMoney {
    amount         # Customer's currency amount
    currencyCode   # Customer's currency code
  }
}
```

**Decision for DWH:**
- Use `shopMoney.amount` consistently (merchant's base currency)
- Store `currencyCode` if multi-currency reporting needed
- Avoid deprecated scalar fields (totalPrice → totalPriceSet)

**Fields affected:**
- Order: subtotalPriceSet, totalPriceSet, totalDiscountsSet, totalTaxSet, totalShippingPriceSet, totalRefundedSet, netPaymentSet
- LineItem: originalUnitPriceSet, originalTotalSet, discountedTotalSet, totalDiscountSet
- InventoryItem: unitCost (uses MoneyV2, similar pattern)

**Source:** Shopify GraphQL Admin API documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-orders-api-research.md

---

### Shopify Bulk Operations for ETL

**Confidence:** LOW
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-30

**When to use:**
Extracting large datasets from Shopify (full product catalog, historical orders).

**Workflow:**
```
1. Submit bulkOperationRunQuery mutation
2. Poll or use webhook for completion
3. Download JSONL from url field
4. Parse line-by-line (memory efficient)
5. Load to staging tables
```

**Constraints:**
- Max 5 connections in query
- Max 2 levels of nesting
- Results expire after 7 days
- Must complete within 10 days
- API 2026-01+: Up to 5 concurrent operations

**JSONL Output:**
- One JSON object per line
- Child objects have `__parentId` field
- Stream-parseable (no memory issues)

**Source:** Shopify GraphQL Admin API documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-etl-tooling-evaluation.md

---

### systemd Timers for Production ETL

**Confidence:** LOW
**Uses:** 2
**Category:** infrastructure
**Last Used:** 2026-06-26

**2026-06-26 authored-for-real (uses 1→2):** Moved from research note to actual unit files
(`code/etl/deploy/shopify-dwh.{service,timer}`). Concrete choices worth keeping: `Type=oneshot` +
enable the **timer** not the service; `OnCalendar` daily 02:30 with `Persistent=true` +
`RandomizedDelaySec=300`; secrets via `EnvironmentFile` *outside the repo* (config.py reads
`os.environ`, its `load_dotenv` no-ops when the in-repo `.env` is absent — so the same code runs
dev and prod with zero change); plus sandbox hardening (`NoNewPrivileges`, `ProtectSystem=strict`,
`PrivateTmp`). The timer cadence *is* the daily-inventory-snapshot cadence — one knob, not two.

**When to use:**
Scheduling Python ETL jobs on Linux servers in production.

**Why over cron:**
- Single instance guarantee (no overlapping runs)
- `Persistent=true` catches up on missed runs after reboot
- Resource limits (CPUQuota, MemoryLimit)
- journald integration for structured logging
- EnvironmentFile for credentials

**Setup:**
Two files required:
1. `/etc/systemd/system/job.service` - What to run
2. `/etc/systemd/system/job.timer` - When to run

**Key directives:**
```ini
# In .timer
Persistent=true          # Run if missed
RandomizedDelaySec=300   # Avoid thundering herd

# In .service
Type=oneshot             # For batch jobs
MemoryMax=2G             # Resource limit
```

**Commands:**
```bash
systemctl daemon-reload
systemctl enable job.timer
systemctl start job.timer
journalctl -u job.service  # View logs
```

**Source:** systemd documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-etl-tooling-evaluation.md

---

### Two-Layer DWH Architecture (STG + DWH)

**Confidence:** MEDIUM
**Uses:** 2
**Category:** data-modeling
**Last Used:** 2026-06-24

**2026-06-24 build validation (LOW→MEDIUM):** Built for real in the POC. STG mirrored the Shopify
API (row-based, raw GIDs, minimal transform); DWH was the reporting layer (surrogate keys, GID
extraction, denormalised product attributes on the fact, a metric view). The clean STG→DWH
boundary made the transforms simple pure-SQL `INSERT…SELECT`s and made reconciliation trivial
(fact_order = stg_orders to the cent). The separation paid off exactly as designed.

**When to use:**
Building a data warehouse from a transactional source (API, database) for reporting purposes.

**Key Insight:**
Don't conflate staging with data warehouse. The DWH should be designed for reporting from the start.

**Wrong approach (overcomplicated):**
```
API → STG (raw) → DWH (normalized) → RPT (denormalized)
```

**Right approach (simpler):**
```
API → STG (raw, mirrors source) → DWH (reporting-optimized = IS the reporting layer)
```

**Staging Layer (STG):**
- Mirrors source structure exactly
- Row-based (1 row per payment, per tax line, per discount)
- No business logic, no transformations
- Transient - can be truncated after DWH load

**Data Warehouse Layer (DWH = Reporting):**
- Pivoted arrays to columns (payments, taxes, discounts)
- Denormalized dimension attributes on facts
- Pre-calculated fields (LTV, margins, flags)
- User-friendly field names
- Wider tables, fewer joins

**Benefits:**
- Simple architecture (no intermediate layer)
- DWH optimized for actual use case (reporting)
- Clear transformation boundary (raw → reporting)

**Source:** Shopify DWH schema redesign

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-schema-layered-design.md

---

### Pivot Transformation Pattern (Rows to Columns)

**Confidence:** LOW
**Uses:** 2
**Category:** data-modeling
**Last Used:** 2026-06-26

**2026-06-26 build validation (uses 1→2):** Designed 2026-01-30, **built for real** in the Layer 1
`fact_order` transform — payments (3), tax lines (2), discount applications (2) all pivoted with the
exact `MAX(CASE WHEN rn = N THEN ... END)` + `ROW_NUMBER() OVER (PARTITION BY order_id ...)` shape
below, plus the `COUNT(*) AS total_payment_count` overflow flag. Confirmed the "pick a realistic max
+ keep a count column" guidance is enough; the SQL is mechanical once `rn` is assigned.

**When to use:**
Transforming multi-value arrays from transactional systems into columnar format for reporting.

**Examples:**
- Multiple payment methods per order → payment_1_gateway, payment_1_amount, payment_2_gateway, payment_2_amount
- Multiple tax lines → tax_1_name, tax_1_rate, tax_2_name, tax_2_rate
- Multiple discounts applied → discount_1_code, discount_1_amount, discount_2_code, discount_2_amount

**SQL Pattern:**
```sql
SELECT
    order_id,
    MAX(CASE WHEN rn = 1 THEN gateway END) AS payment_1_gateway,
    MAX(CASE WHEN rn = 1 THEN amount END) AS payment_1_amount,
    MAX(CASE WHEN rn = 2 THEN gateway END) AS payment_2_gateway,
    MAX(CASE WHEN rn = 2 THEN amount END) AS payment_2_amount,
    COUNT(*) AS total_payment_count
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY created_at) AS rn
    FROM stg_order_transactions
    WHERE kind = 'SALE' AND status = 'SUCCESS'
) t
GROUP BY order_id
```

**Benefits:**
- Single row per entity (order) for easy reporting
- No joins needed for common analysis
- Self-documenting column names
- Columnar DB optimized (Exasol, Redshift, BigQuery)

**Trade-offs:**
- Fixed number of columns (payment_1, payment_2, payment_3)
- Need to decide max columns upfront
- Rare edge cases (>3 payments) may need special handling

**Guidance:**
- Start with realistic max (e.g., 3 payments, 2 taxes, 2 discounts)
- Add total_count column to flag edge cases
- Monitor for outliers in production

**Source:** Shopify DWH schema redesign

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-schema-layered-design.md

---

### Architecture Selection: Warehouse vs Lakehouse

**Confidence:** LOW
**Uses:** 1
**Category:** architecture
**Last Used:** 2026-01-30

**When to use:**
Deciding between data warehouse and data lakehouse architectures for a new analytics project.

**Decision Framework:**

| Factor | Warehouse | Lakehouse |
|--------|-----------|-----------|
| Data types | Structured only | Structured + unstructured |
| Primary use | BI/reporting | ML/AI + BI |
| Scale | Small to large | Large to massive |
| Team size | Any | Usually larger teams |
| Existing infra | Leverage existing DB | Cloud-native, new stack |

**Choose Warehouse when:**
- Single source system (e.g., one SaaS platform)
- Structured data only
- BI/reporting is primary use case
- Have existing columnar DB (Exasol, Redshift, Snowflake)
- Solo developer or small team
- Don't need ML/AI on raw data

**Choose Lakehouse when:**
- Multiple diverse sources
- Mix of structured + unstructured data
- ML/AI model training is a primary use case
- Massive scale (petabytes)
- Need to store raw data for future unknown use cases

**Key Insight:**
Lakehouse adds complexity. Don't adopt it because it's trendy - adopt it when you have problems that warehouse can't solve (usually ML on unstructured data at scale).

**Source:** Shopify DWH architecture decision

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-architecture-decisions.md

---

### Exasol Star Schema Optimization

**Confidence:** LOW
**Uses:** 1
**Category:** exasol
**Last Used:** 2026-01-30

**When to use:**
Designing star schema for Exasol columnar database.

**Key Principles:**

| Principle | Implementation |
|-----------|----------------|
| Distribution keys | On JOIN columns (not WHERE) |
| Partition keys | On WHERE filter columns |
| Replication | Small dims auto-replicate (<100k rows) |
| Indexes | Auto-created, don't create manually |
| Data types | BIGINT/INT joins faster than VARCHAR |

**Distribution Key Selection:**
```sql
-- Fact table: distribute on most common join column
CREATE TABLE fact_orders (...)
DISTRIBUTE BY customer_key;

-- Dimension: distribute on PK to match fact
CREATE TABLE dim_customer (...)
DISTRIBUTE BY customer_key;
```

**Partition Key Selection:**
```sql
-- Partition on date for time-based filtering
CREATE TABLE fact_orders (...)
DISTRIBUTE BY customer_key
PARTITION BY order_date_key;
```

**Replication Border:**
```sql
-- Increase for star schema (default 100k)
ALTER SYSTEM SET REPLICATION_BORDER = 500000;
```

**Anti-patterns:**
- Don't distribute on WHERE columns (disables MPP)
- Don't create manual indexes
- Don't join on VARCHAR columns (use surrogate keys)

**Source:** Exasol Performance Best Practices documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-exasol-schema-review.md

---

### Shopify Plan vs Actual Pattern

**Confidence:** LOW
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-30

**When to use:**
Understanding Shopify's data model for operations that have intent and execution phases.

**Knowledge:**
Shopify distinguishes between planned operations and actual executions:

| Domain | Plan Object | Actual Object |
|--------|-------------|---------------|
| Fulfillment | FulfillmentOrder (what should ship) | Fulfillment (what did ship) |
| Discounts | DiscountCode (configured offer) | DiscountApplication (applied to order) |

**DWH Implication:**
- Plan objects have lifecycle states (OPEN → IN_PROGRESS → CLOSED)
- Actual objects have outcome states (SUCCESS, FAILURE, CANCELLED)
- Analytics often needs both (e.g., "planned vs actual delivery time")

**Source:** Shopify GraphQL Admin API documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-fulfillment-api-research.md

---

### Shopify Deprecated Scalars → Object Pattern

**Confidence:** MEDIUM
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-30

**When to use:**
Extracting Customer data from Shopify GraphQL API.

**Knowledge:**
Shopify has deprecated scalar fields in favor of typed object patterns:

| Deprecated | New Pattern |
|------------|-------------|
| `email` | `defaultEmailAddress.emailAddress` |
| `phone` | `defaultPhoneNumber.phoneNumber` |
| `emailMarketingConsent` | `defaultEmailAddress.marketingState` |
| `smsMarketingConsent` | `defaultPhoneNumber.marketingState` |
| `addresses` | `defaultAddress` |

**Marketing State Values:**
- `NOT_SUBSCRIBED`, `PENDING`, `SUBSCRIBED`, `UNSUBSCRIBED`, `REDACTED`, `INVALID`

**ETL Derivation:**
```
accepts_marketing = TRUE when marketingState IN ('SUBSCRIBED', 'PENDING')
```

**Why it matters:**
- Deprecated fields may be removed in future API versions
- New objects provide richer data (marketing opt-in level, validation)
- Consistent with Shopify's pattern of moving to typed objects

**Source:** Shopify GraphQL Admin API documentation

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-customers-api-research.md

---

### Shopify API Migration (REST → GraphQL)

**Confidence:** HIGH
**Uses:** 1
**Category:** shopify-api
**Last Used:** 2026-01-29

**Knowledge:**
- REST Admin API is **legacy** as of October 2024
- GraphQL Admin API **required** for new apps from April 2025
- Build all new integrations on GraphQL

**Benefits of GraphQL:**
- Cost-based rate limiting (more predictable)
- Single request for nested data
- Future-proof

**Source:** Official Shopify announcement

---

### Metrics-Driven Schema Design

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-02-04

**When to use:**
Designing or validating a data warehouse schema to ensure it can support all required business metrics.

**Process:**
```
1. Catalog Required Metrics
   ├── List all business reports needed
   ├── Define each metric (formula, granularity, dimensions)
   └── Group by business function

2. Trace Lineage Backwards
   ├── Metric → DWH table(s) needed
   ├── DWH table → STG table(s) source
   └── STG table → API field(s) source

3. Gap Analysis
   ├── Missing STG tables (data not being extracted)
   ├── Missing STG fields (extracted but not all fields)
   ├── Missing DWH calculations (data available but not computed)
   └── Missing dimensions for slicing

4. Prioritize Gaps
   ├── CRITICAL: Blocks must-have metrics
   ├── HIGH: Blocks important metrics
   ├── MEDIUM: Enables nice-to-have metrics
   └── LOW: Future consideration

5. Document Lineage
   ├── Metric → DWH → STG → API mapping table
   ├── Update schema documentation
   └── Create data dictionary
```

**Benefits:**
- Ensures schema covers all business requirements
- Identifies gaps BEFORE implementation (cheaper to fix)
- Creates traceable lineage for debugging/auditing
- Validates that source data exists for each metric
- Produces documentation as a byproduct

**Example Gap Analysis Output:**

| Gap Type | Missing Item | Metrics Blocked | Priority |
|----------|--------------|-----------------|----------|
| STG Table | stg_fulfillments | Fulfillment Time | HIGH |
| STG Field | orders.source_name | Revenue by Channel | HIGH |
| DWH Field | dim_customer.rfm_segment | RFM Segmentation | MEDIUM |
| DWH Table | fact_inventory_snapshot | Sell-Through Rate | MEDIUM |

**Key Insight:**
"Start with metrics, work backwards to data" is more effective than "start with available data, figure out metrics later."

**Source:** Shopify DWH gap analysis project

**Related Episodes:**
- memory/episodic/completed-work/2026-02-04-metrics-gap-analysis.md

---

### Cross-System Join Strategy (Shared Business Key)

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-02-18

**When to use:**
Building a DWH that needs to join data from two or more independent systems that share a common business entity but have different data models.

**Pattern:**
Identify a shared business key that exists in both systems and design the join around it.

**Example (Shopify + SQL Server):**
```
SQL Server                    Shopify
==========                    =======
voucher_code (full)    ←→     discount_applications.code
shopify_id             ←→     gift_cards.id
```

**Key Considerations:**
1. **Data quality of the key** - Is it reliably populated in both systems? Formatted consistently?
2. **Key masking** - One system may mask the key (Shopify masks gift card codes to last 4 chars)
3. **Fallback joins** - If primary key is unreliable, identify secondary join paths
4. **Confidence rating** - Rate each join path (HIGH/MEDIUM/LOW) and document assumptions

**Join Confidence Framework:**
| Confidence | Criteria | Example |
|------------|----------|---------|
| HIGH | Direct string match, always populated | Discount code → order discount application |
| MEDIUM | System ID cross-reference, usually populated | Shopify GID stored in SQL Server |
| LOW | Indirect matching, may have gaps | Transaction gateway matching, partial code |

**Benefits:**
- Forces explicit documentation of integration assumptions
- Identifies data quality risks before implementation
- Enables validation queries to verify join integrity

**Trade-offs:**
- Multiple join strategies add ETL complexity
- May need data quality monitoring in production
- Fallback joins can be slower

**Source:** DYT Layer 2 schema design (Shopify + SQL Server integration)

**Related Episodes:**
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

---

### Pre-Aggregated Fact for Dashboard Performance

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-02-18

**When to use:**
Building dashboards that need fast aggregations with running totals, rates, or cumulative metrics over a high-volume detail table.

**Pattern:**
Create a pre-aggregated fact table at a coarser grain (e.g., entity + day) alongside the detail fact table.

**Structure:**
```
fact_voucher_lifecycle    (detail: 1 row per voucher)
        ↓ aggregate
fact_channel_daily        (summary: 1 row per channel per day)
```

**What to pre-aggregate:**
- Daily counts (created, distributed, redeemed)
- Daily financial sums (face value, revenue)
- Running totals (cumulative created, distributed, redeemed)
- Derived rates (distribution rate, redemption rate)
- Outstanding balances (distributed - redeemed)

**Benefits:**
- Dashboard queries avoid scanning millions of detail rows
- Running totals computed once during ETL, not on every query
- Enables fast "Channel X performance" dashboards
- Reduces BI tool compute requirements

**When NOT to use:**
- Detail table is small enough for real-time aggregation
- Requirements change frequently (pre-agg is rigid)
- No clear primary aggregation grain

**Source:** DYT Layer 2 schema design

**Related Episodes:**
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

---

### Follow Existing Project Conventions (Don't Duplicate)

**Confidence:** LOW
**Uses:** 1
**Category:** process
**Last Used:** 2026-02-18

**When to use:**
Adding new artifacts (files, documents, configs) to an existing project.

**Rule:**
Before creating a new file, check how similar files are already organized. Follow the existing pattern - don't create duplicates in a "more convenient" location.

**Anti-pattern (what happened):**
```
for-word/06-DYT-Layer2-Schema.docx    ← correct (follows convention)
DYT-Layer2-Schema-Design.docx         ← duplicate (unnecessary copy)
```

**Correct approach:**
1. Check existing file organization (`ls`, `Glob`)
2. Identify the convention (naming, folder structure, numbering)
3. Add your file following that convention
4. Don't create "convenience copies" elsewhere

**Key insight:**
One file in the right place is always better than two files in two places. Duplicates create confusion about which is canonical and drift over time.

**Related Episodes:**
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

---

### Markdown-to-Word Pipeline for Design Review

**Confidence:** LOW
**Uses:** 2
**Category:** process
**Last Used:** 2026-02-18

**When to use:**
Producing Word documents for stakeholder review from technical design work that's authored in markdown.

**Workflow:**
```
1. Author content in markdown (version-controlled, diff-friendly)
2. Use python-docx conversion script to generate .docx
3. Review/share the Word document
4. Edits go back into the markdown source (source of truth)
```

**Project setup:**
```
for-word/
├── 01-Architecture-Overview.md     ← source files
├── 02-Staging-Schema.md
├── ...
├── convert_to_docx.py              ← conversion script
├── 01-Architecture-Overview.docx   ← generated output
├── ...
```

**Benefits:**
- Markdown is the source of truth (version-controlled)
- Word docs are generated artifacts, not hand-authored
- Consistent formatting across all documents
- Easy to regenerate after edits

**Key detail:**
When adding a new document, update both the markdown source AND the `md_files` list in `convert_to_docx.py`.

**Related Episodes:**
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

---

### Data Investigation Before Schema Finalisation

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-02-18

**When to use:**
Designing a schema that depends on understanding source data relationships, especially when source data has been described secondhand or via CSV exports.

**Rule:**
Before finalising dimension vs attribute decisions, query the actual source data to understand real cardinality, value distributions, and column relationships.

**Example:**
CampaignSegmentTbl CSV showed 150+ unique Campaign values, suggesting a standalone dimension. But querying actual rows revealed:
- ~100 of those "campaigns" were internal Marketing sub-entries (small quantities)
- For real clients, Campaign is a sub-classification (product lines, subscription tiers)
- Too varied for a dimension → better as `campaign_name` VARCHAR on dim_voucher
- Subscription tiers can be parsed from Campaign name into structured fields

**Anti-pattern:**
Designing schema from data dictionaries or CSV column summaries without querying actual row-level data combinations.

**Benefits:**
- Reveals true cardinality and relationships
- Prevents over-engineering (creating unnecessary dimensions)
- Catches data quality issues early (refund pattern inconsistency)
- Informs ETL parsing logic (subscription tier encoding)

**Related Episodes:**
- memory/episodic/completed-work/2026-02-18-report-mapping-analysis.md

---

### Design-on-Paper Before Building

**Confidence:** LOW
**Uses:** 4
**Category:** process
**Last Used:** 2026-03-06

**When to use:**
Building data infrastructure (schemas, ETL, APIs) where the design has significant downstream impact.

**Approach:**
1. Document the full schema design in markdown/Word
2. Include table definitions, data flows, join strategies, metrics
3. Review with stakeholders before writing any code
4. Iterate on paper (cheap) not in code (expensive)

**Benefits:**
- Catches design issues before implementation
- Stakeholder alignment on scope and approach
- Creates documentation as a byproduct (not an afterthought)
- Changes on paper are free; changes in code are costly

**Validated four times:**
- Layer 1 (generic Shopify DWH): 17 STG + 12 DWH tables designed on paper, reviewed, then built
- Layer 2 (DYT B2B2C): 3 STG + 4 DWH tables designed on paper with join strategy and metrics
- Report mapping analysis: Mapping 38 reports against schema caught 8 gaps and data quality issues before any code
- Phase 4 NL Analytics: Full architecture (Ollama + Claude MCP + Web Interface + POPIA tiers) designed on paper with code examples, cost estimates, and YF assessment — before writing any production code

**Key insight:**
The design review catches things implementation never would - like the gift card code masking issue that affects join strategy. Better to discover this on paper than mid-ETL build.

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-schema-layered-design.md
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

---

### Evaluate Existing Tools Before Building New Ones

**Confidence:** LOW
**Uses:** 1
**Category:** process
**Last Used:** 2026-03-06

**When to use:**
Planning to build a new capability (e.g., NL analytics, dashboarding, alerting) in a system where existing tools may already cover part of the need.

**Steps:**
1. Inventory what your existing tools already do (even features you haven't enabled)
2. Enable and test those features with real users (2-4 weeks)
3. Log the specific questions/tasks the existing tools can't handle
4. Build only for the proven gaps — not speculative ones

**Example (Yellowfin vs Claude MCP):**
- YF has Assisted Insights, Guided NLQ, Signals — covers "what changed?"
- YF can't do: conversational follow-up, cross-table reasoning, business-context narratives, advisory
- Decision: Enable YF native first, log gaps, then build Claude MCP for proven gaps only

**Benefits:**
- Avoids building features that already exist
- Evidence-based scope (build what's needed, not what's cool)
- Lower risk — existing tools are already deployed and understood
- Saves weeks of development on features users might not need

**Key insight:**
"Will this be useful?" is the wrong question. "What specific questions can't be answered today?" is the right one. Gather evidence first.

**Related Episodes:**
- memory/episodic/completed-work/2026-03-06-dyt-project-creation.md

---

### POPIA-Compliant Tiered Architecture (Cloud + On-Prem)

**Confidence:** LOW
**Uses:** 1
**Category:** architecture
**Last Used:** 2026-03-06

**When to use:**
Building AI/analytics features that process data with mixed sensitivity levels, where some data contains PII and regulatory constraints (POPIA, GDPR) apply.

**Pattern:**
Split processing into tiers based on data sensitivity:

```
Tier 1: Cloud API (e.g., Claude)
├── Non-PII data only
├── Aggregated metrics (channel/product/day level)
├── Business entity data (companies, not people)
├── PII table blocklist enforced server-side
│
Tier 2: On-premises (e.g., Ollama)
├── All data including PII
├── Customer records, personal contact info
├── Order-level data with customer references
├── Data never leaves infrastructure
```

**Enforcement:**
- PII table blocklist in MCP server / API layer (not client-side)
- SELECT-only validation (no writes via cloud path)
- Role-based access controls
- Query logging for audit

**Benefits:**
- Unlocks cloud AI capabilities for non-sensitive analytics
- PII stays on-prem (POPIA/GDPR compliant)
- Best of both worlds: Claude quality for exploration, Ollama for PII data
- Clear boundary — easy to audit and explain to compliance

**Trade-offs:**
- Two systems to maintain (Ollama + Claude API)
- Users need to understand which questions go where (or abstract it away)
- Blocklist must be maintained as schema evolves

**Related Episodes:**
- memory/episodic/completed-work/2026-03-06-dyt-project-creation.md

---

### Evidence-Based Feature Building

**Confidence:** LOW
**Uses:** 1
**Category:** process
**Last Used:** 2026-03-06

**When to use:**
Deciding whether to build a new feature or capability, especially when the need is based on assumption rather than observed user behaviour.

**Rule:**
Don't build for speculative gaps. Gather evidence of the gap first, then build to fill it.

**Process:**
```
1. Hypothesise the gap ("users can't answer 'why' questions")
2. Enable existing alternatives (YF Assisted Insights)
3. Observe and log failures (2-4 weeks)
4. Analyse: Which questions genuinely can't be answered?
5. Build only for the proven, logged gaps
```

**Anti-pattern:**
Building a full Claude MCP chat interface because "it would be cool" before confirming that Yellowfin's native NLQ doesn't already cover 80% of the need.

**Benefits:**
- Builds only what's needed (no wasted effort)
- Users help define scope by showing you the gaps
- Easier to justify investment (evidence, not speculation)
- Often reveals the gap is smaller (or different) than assumed

**Key insight:**
The architecture can be designed speculatively (cheap). The implementation should be evidence-based (expensive). Design the full solution on paper, but build it in phases driven by real usage gaps.

**Related Episodes:**
- memory/episodic/completed-work/2026-03-06-dyt-project-creation.md

---

## Implementation Patterns (Build Stage)

> First populated 2026-06-24 when the project moved from design-on-paper to actually
> building and running code (the shopify-poc). These are execution patterns.

### Idempotent Incremental Loading (Watermark + MERGE-on-id)

**Confidence:** LOW
**Uses:** 2
**Category:** data-engineering
**Last Used:** 2026-06-26

**2026-06-26 reinforcement (uses 1→2):** The POC's watermark+MERGE pattern generalised cleanly
into the production build's shared `loaders/_orders_source.py`, reused across 8 order-child
loaders — including with **composite merge keys** (e.g. `(order_id, line_number)` for index-keyed
tax/discount lines, `(fulfillment_id, line_item_id)` for parent-child lines) and a **snapshot
variant** (inventory_levels merges on `(item, location, snapshot_date)`). The same idempotency
property held across all shapes. One documented edge: index-keyed children can orphan-on-shrink in
incremental mode — benign here because those collections are fixed at order creation.

**When to use:**
Loading data from a source that changes over time, where re-running a load must never
create duplicates (the single most important property of a production ETL loader).

**Pattern:**
1. Store the source's last-modified field on each row (e.g. Shopify `updatedAt`).
2. On each run, read the high-water mark: `SELECT MAX(updated_at) FROM target`.
3. Fetch only source rows with `updated_at >= watermark` (>=, not >, so the boundary row
   is re-fetched and safely re-merged rather than skipped).
4. Load via `MERGE` on the natural key (id): update on match, insert on no-match —
   instead of plain INSERT.

**Why >= and MERGE together:**
The `>=` guarantees no row is missed at the boundary; the MERGE makes re-fetching that
boundary row (or an entire overlapping window) harmless. Belt and braces.

**Proven:** Re-ran an incremental load repeatedly against a **live** store taking real
orders mid-extraction — 0 duplicate ids every time, counts stable. The merge absorbed
genuine concurrent updates cleanly.

**Implementation note (Exasol):** MERGE into target from a temp table loaded via
`import_from_pandas`; `CREATE OR REPLACE TABLE tmp LIKE target`, import, MERGE, drop.

**Related Episodes:**
- memory/episodic/completed-work/2026-06-24-shopify-poc-implementation.md

---

### Cost-Based GraphQL Throttling (Leaky Bucket)

**Confidence:** LOW
**Uses:** 1
**Category:** shopify-api

**When to use:**
Paginating large extracts from an API that rate-limits by **query cost** (a points bucket),
not by request count — Shopify Admin GraphQL being the canonical example.

**Knowledge:**
Each response carries `extensions.cost.throttleStatus`:
```
{ maximumAvailable, currentlyAvailable, restoreRate }   # points, points/second
```

**Client strategy:**
1. After each request, record `throttleStatus`.
2. **Proactively** sleep when `currentlyAvailable` drops below a buffer:
   `sleep = (buffer - currentlyAvailable) / restoreRate`. Keeps the bucket healthy rather
   than sprinting into a 429.
3. On an explicit `THROTTLED` error (or HTTP 429), back off using the same maths, then retry.
4. Separately retry transient network/5xx with exponential backoff.

**Observed:** the DYT store's bucket is **20,000 points / 1,000-per-second** (much larger than
the standard 1,000/50) — a newer/Plus allocation — so at POC volume we never actually throttled.
But the handling is essential for production-scale backfills.

**Related Episodes:**
- memory/episodic/completed-work/2026-06-24-shopify-poc-implementation.md

---

### Reconcile by Aligning Window + Definition First

**Confidence:** LOW
**Uses:** 2
**Category:** process
**Last Used:** 2026-06-26

**2026-06-26 productionised (uses 1→2):** The POC's reconciliation became a permanent artifact —
`code/etl/ddl/08_reconcile.sql`, with the headline view `v_revenue_by_product_by_day` ported
**verbatim** from the POC so the comparison stays like-for-like. The only change was removing the
60-day window floor (production has `read_all_orders`). The method is now a re-runnable Gate-D step,
not a one-off — the alignment discipline (pin window + confirm definition) is baked into the file's
header so whoever runs it can't skip it.

**When to use:**
Validating a new pipeline's numbers against an existing trusted source (here: our Exasol
metric vs the incumbent Fivetran/SQL Server data).

**Rule:**
Before comparing any totals, make the two queries **identical** on the two things that silently
cause false discrepancies:
1. **Window** — pin explicit date bounds (and the same timezone) on both sides. Don't use
   "last 60 days" (drifts by run date); use literal dates and complete days only.
2. **Definition** — confirm the measure means the same thing on both sides
   (e.g. our `net_amount` = Fivetran `price*quantity - total_discount`; refunds netted or not;
   cancelled included or not).

**Then** compare, and treat any residual gap as a *finding to explain*, not a pass/fail.

**Proven:** Fivetran vs POC came out **0.30% apart**; the gap traced entirely to the known
60-day extraction cap clipping the boundary day's morning orders — not a pipeline error.
Product count matched exactly; the NULL/Unknown bucket matched to the cent. Aligning window +
definition first is what made the 0.30% interpretable instead of alarming.

**Tip:** prove the definitions match structurally before running — e.g. we confirmed our
`gross_amount` equalled `price*quantity` exactly, so the discount subtraction was guaranteed
to mean the same thing.

**Related Episodes:**
- memory/episodic/completed-work/2026-06-24-shopify-poc-implementation.md

---

### Walking-Skeleton POC Before Full Build

**Confidence:** LOW
**Uses:** 1
**Category:** process

**When to use:**
Before committing to a large data-infrastructure build (here: the full 17-table Layer 1 DWH),
when the core technical approach is unproven on real data.

**Pattern:**
Build the **thinnest possible end-to-end slice** that exercises every layer, on **real** data,
in a **throwaway** local environment — then reconcile it to a trusted baseline.

For this POC: 4 STG tables → 4 DWH objects → one metric ("revenue by product by day"), chosen
specifically because it forces one-to-many denormalisation, a dimension build, and two fact grains.

**Why it pays off (the build has "lots of code" ahead):**
- A *systematic* extraction/transform error is invisible until reconciled, and poisons everything
  built on top. Finding it on 4 tables is cheap; finding it after 17 + Layer 2 is not.
- The thin slice surfaces the real constraints early: here the **60-day order cap**, the
  **read_customers scope** gap, and **Exasol identifier rules** — all now known before the build.
- The reusable components written for the skeleton (`shopify_client.py`, `exasol_loader.py`)
  carry straight into the real build.

**Key insight:** the lightweight reconciliation cost ~1 hour of the user's time and converted
"we think this works" into "this works within 0.30%, gap explained." That confidence is the
whole point of the POC.

**Related Episodes:**
- memory/episodic/completed-work/2026-06-24-shopify-poc-implementation.md

---

### Exasol Identifier & Type Constraints

**Confidence:** MEDIUM
**Uses:** 3
**Category:** exasol

**2026-06-26 DWH-layer reinforcement (LOW→MEDIUM, uses 2→3):** Held across the whole DWH layer too.
Two more reserved-word offenders surfaced and were documented for first-deploy rather than guessed:
`address` (dim_location), `region` (dim_geography) — same "rename, never quote" rule. New Exasol
functions exercised by the transforms (each a first-run-verify item since the POC didn't touch them):
`NTILE(5)` for RFM quintiles, `WEEK`/`LAST_DAY` for dim_date, `HOURS_BETWEEN` for fulfillment timing.
And the digit-cross-join row generator (no `generate_series`) extended from dim_date to dim_time.
Three uses across STG + DWH → MEDIUM. See also [[In-Warehouse JSON Field Extraction]].

**Confidence note:** uses 1→2 — applied across the full 18-table production STG DDL (2026-06-26),
not just the POC's 4. The `TEXT → VARCHAR(2000000)` and `INT → INTEGER` mappings and unquoted-
identifier rule held for all 234 columns; a **reserved-word watch list** (`source`, `committed`,
`reserved`) was documented for first-deploy rather than guessed, since it can't be verified without
the instance. Reinforced the "rename, don't quote" rule: quoting forces case-sensitivity, which
would break the loaders' uppercase column alignment.

**When to use:**
Writing Exasol DDL/SQL, especially when generating it from a design doc authored without Exasol
in mind (e.g. `schema-layered.md`).

**Constraints learned the hard way (each cost a failed statement):**
- **No leading underscore** in unquoted identifiers — `_extracted_at` fails. Drop the prefix
  (`extracted_at`) rather than quoting (quoting forces case-sensitivity forever).
- **Reserved words can't be identifiers** — `year`, `month`, `day`, `object`, `rows` all fail as
  column names/aliases. Rename (`cal_year`, `cal_month`, `cal_day`, `obj`, `n`).
- `CHR()` is ASCII-only (0–127); use `UNICODECHR()` above 127.
- No `generate_series` — generate N rows with a digit cross-join
  (`digits d1,d2,d3,d4` → 0..9999) then `ADD_DAYS`.
- `CREATE SCHEMA/TABLE IF NOT EXISTS` both work on Exasol 8 → idempotent deploys.

**pyexasol specifics:**
- Bind params use `{name}` formatting in `conn.execute(sql, {...})`, **not** `:name`.
- Query results return TIMESTAMP columns as **strings** — `pd.Timestamp(x)` before formatting.
- `import_from_pandas` for bulk load; needs `websocket_sslopt={"cert_reqs": 0}` against the
  local self-signed container.

**Action for the real build:** do a cleanup pass over `schema-layered.md` to rename
underscore-prefixed and reserved-word columns before generating production DDL.

**Related Episodes:**
- memory/episodic/completed-work/2026-06-24-shopify-poc-implementation.md

---

### Store Atomic Components, Derive Measures in the View Layer

**Confidence:** LOW
**Uses:** 2
**Category:** data-modelling
**Last Used:** 2026-06-26

**2026-06-26 build validation (uses 1→2):** The principle from the revenue-definition decision was
**built** in Phase D. The facts (`fact_order`, `fact_order_line_item`) store only atomic components
(gross/discount/net/tax/refund); all 57 named measures live in `ddl/07_metric_views.sql` as view
expressions. The headline "Revenue" is one default in `v_revenue_by_product_by_day`, flippable with
no ETL re-run. Confirmed the payoff: the unresolved gross-vs-net question never blocked the build —
it sat in the cheap, reversible view layer exactly as predicted.

**When to use:**
When a "headline" business measure has a contested or uncertain definition (revenue net-vs-gross,
which costs to include, etc.) and you risk locking the warehouse into one answer before the business
has settled on it.

**Pattern:**
Never store a single pre-computed answer (e.g. one `revenue` column) in the fact table. Store the
**atomic, additive components** at grain — `gross_sales`, `discount`, `refund`, `tax`, `shipping` —
each a plain number that just sums. Then **define every named measure in the metric/view layer**
on top of those columns (gross sales = Σ gross; net sales = Σ(gross − refund); net-of-tax; …).

**Why it pays off:**
- Every possible definition is *derivable*, so contradictory requirements (finance wants net, ops
  wants gross) are served **side by side** from the same warehouse.
- The "headline" is just a default label in a view — changeable in minutes with **no ETL re-run,
  no schema change, no reload**. The architecture absorbs the uncertainty.
- Turns a blocking decision ("which is revenue?") into a non-blocker ("pick a provisional default,
  confirm with the business whenever, flip later for free").

**Key insight:** an unresolved definitional question is not a reason to stall the build — it's a
signal to push the choice up into the (cheap, reversible) semantic layer and keep the (expensive,
immutable) storage layer definition-free.

**Origin:** resolving the canonical revenue definition for the Layer 1 build when the user wasn't
sure whether current reporting leads with gross or net. See `research-notes/build-plan.md`.

---

### Verify Output Mapping Against the Target Schema Without Live Dependencies

**Confidence:** LOW
**Uses:** 1
**Category:** data-engineering
**Last Used:** 2026-06-26

**When to use:**
Writing code that maps source records into a fixed target schema (ETL loaders → DB tables,
serializers → API contracts) when you **can't run it end-to-end yet** (no live API, no DB,
gated on infra). The highest-frequency real bug in this code is silent column-name drift
between the mapper and the target — and it normally only surfaces at first run.

**Pattern:**
Close the loop statically. Parse the **target schema** (the DDL, the proto, the JSON schema)
to get its exact field set, build a **synthetic source record** covering every nested shape,
run it through the mapper, and assert `set(mapper_output.keys()) == set(schema_fields)` —
no missing, no extras. An "extra" key is one the load would silently **drop**; a "missing"
one is a column that never populates.

**Proven:** across all 16 Layer 1 STG loaders, this caught mapping correctness before any
infra existed — every loader verified `extract_rows` keys == its `CREATE TABLE` columns
(e.g. 16/16, 13/13). It also caught a real gotcha in the verifier itself: a `[a-z_]+` column
regex silently skipped `option1`/`address1` (digits), proving the meta-point — verify your
verifier's numbers too (parsed counts beat hand counts).

**What it does and doesn't cover:**
- ✅ Column/field-name alignment, presence, drops — the cheap, high-frequency error.
- ❌ NOT semantic correctness of values or the upstream field *names* (GraphQL shapes etc.).
  Those still need the live source — document them separately as a first-run checklist.

**Key insight:** "can't run it" is not "can't test it." Separate the part you can verify
statically (does my output fit the contract?) from the part you genuinely can't (does the live
source return what I assumed?), and close the first loop now.

---

### Snapshot Is the Productizable Superset of "Current State"

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-06-26

**When to use:**
Modelling a source whose data has a "right now" value (stock levels, prices, statuses,
balances) and you're tempted to choose between storing **current state** vs **history** —
especially in a productizable / multi-tenant build where different customers want different things.

**Pattern:**
Don't fork the code. Build the **snapshot** (one row per entity per snapshot_date, idempotent
MERGE on the date-bearing key). Then "current vs history" becomes a **deployment** choice, not a
code path:
- run **daily** → history accumulates (trend/sell-through analysis)
- run **once** / **retention = 1** → effectively current-state only (`query MAX(snapshot_date)`)

Gate the whole module behind a **feature flag** (default off) and govern depth with a **retention**
config. Current-state is just a query over the latest snapshot — a strict subset.

**Why it pays off for a product:**
- One artifact serves every customer preference via config (cadence + retention + flag), instead of
  two code paths to maintain and a per-tenant decision baked into the build.
- "Which do you want?" stops being a build-blocking question — ship the superset, let scheduling
  and config decide.

**Proven:** the Layer 1 `inventory_levels` loader — built as a daily snapshot (MERGE on
item+location+snapshot_date) behind `features.include_inventory_levels`, with current-stock falling
out as the latest-date query. Reframed a "snapshot vs current?" decision into a non-fork.

**Key insight:** when a productizable design forces an either/or, check whether one side is a
*superset* of the other reachable by config. If so, build the superset and push the choice into
the (cheap, reversible) deployment layer. Generalises the "store atomic components, derive in the
view layer" idea from measures to *grain over time*.

---

### Surface Capability / Permission Gaps as Decisions (Don't Silently Assume)

**Confidence:** LOW
**Uses:** 1
**Category:** process
**Last Used:** 2026-06-26

**When to use:**
Building from a design doc that assumes access to external resources (API scopes, permissions,
credentials, paid tiers) — where the design was written before the access was actually provisioned.

**Pattern:**
Before mass-producing the artifacts, **map each one to the specific capability it requires** and
check that capability is in the *decided* set. For any gap: stop, name it as a one-at-a-time
decision with the trade-off, and **don't** either (a) silently assume the access will exist or
(b) build code that can't run. Let the owner decide scope; defer the affected artifacts cleanly.

**Proven:** the Layer 1 STG design assumed 18 tables, but `stg_discount_codes` needs
`read_discounts` and `stg_gift_cards` needs `read_gift_cards` — neither in the decided scope set
(`read_orders/products/all_orders/customers/inventory`). Surfaced as one plain-language decision;
the user deferred both. The remaining 16 loaders proceeded unblocked. Building those two loaders
speculatively would have produced unrunnable code against undecided permissions.

**Key insight:** a design doc is a *claim* about required capabilities, not a guarantee they're
granted. Reconcile the claim against reality early, and convert each gap into an explicit, scoped
decision — which fits the user's one-decision-at-a-time preference (`[[feedback_decision-pacing]]`).

---

### In-Warehouse JSON Field Extraction (REGEXP, No JSON Functions)

**Confidence:** LOW
**Uses:** 1
**Category:** exasol
**Last Used:** 2026-06-26

**When to use:**
You stored a JSON blob in a column (an address, a settings bag) and need a couple of scalar fields
out of it in pure SQL — on a database whose JSON-path support is absent, weak, or version-dependent
(Exasol being the case here). Reaching for a JSON function or a UDF is the obvious move; often you
don't need either.

**Pattern:**
Extract a value with two standard regex calls — grab the key+value, then strip the key prefix:
```sql
REGEXP_REPLACE(REGEXP_SUBSTR(j, '"city": "[^"]*'), '^"city": "', '')   -- -> the city value, or NULL
```
`REGEXP_SUBSTR` returns the matched `"city": "Cape Town` (NULL if the key is absent or the value is
`null`/numeric — no opening quote to match); `REGEXP_REPLACE` removes the literal prefix. No
lookbehind, no capture groups, no JSON engine — so it runs on any build.

**What makes it *safe* (not a hack):**
The decisive enabler is **you control the JSON shape** — your own loader wrote it with `json.dumps`,
so the keys and the `": "` separator spacing are known exactly, not guessed. That turns "parsing
arbitrary JSON with regex" (fragile, don't) into "reading a fixed serialisation you emitted" (fine).

**Limits — document as first-run-verify:**
- Assumes the serialiser's spacing (`json.dumps` default `": "`). A different writer → adjust the
  literal.
- A value containing an escaped `\"` truncates at the escape (rare for addresses; flag it).
- Scalars only — not arrays/nested objects.

**Proven (on paper):** Layer 1 `dim_geography`, `dim_customer.default_*`, and `fact_order`'s shipping
denormalisation all parse `city/province/provinceCode/countryCodeV2/country/zip` this way, with a
concatenated `address_hash` (lower(city|province|country|zip)) as the dedup + join key computed
identically on both sides so the geography_key join matches. Flagged for first-run verification since
it's the one thing untestable without the live instance. Generalises [[Exasol Identifier & Type Constraints]].

---

### Thin Subprocess Orchestrator Over Existing Entry Points

**Confidence:** LOW
**Uses:** 1
**Category:** data-engineering
**Last Used:** 2026-06-26

**When to use:**
You have a pile of already-working CLI entry points (per-table loaders, a DDL runner, a healthcheck)
and need a *single* command a scheduler can call that runs them in dependency order with one
observable result. The tempting move is to import them and call their `main()`s; resist it.

**Pattern:**
Make the orchestrator a thin conductor that runs each step as its **own `python -m` subprocess** —
the same invocation you'd type by hand — and collects exit codes:
```python
proc = subprocess.run([sys.executable, "-m", f"shopify_dwh.loaders.{name}", mode], cwd=ETL_ROOT)
```
Then: **fail-fast** by default (downstream depends on upstream; `--continue-on-error` for debugging),
per-step timing + logging, and a SUMMARY block with a non-zero overall exit so `systemctl`/journald
reflect run health. Add selectors (`--stg-only`/`--dwh-only`) and pass-through args (`--mode`).

**Why subprocess beats import-and-call:**
- **Single source of truth** — each step's logic (incl. its own `sys.argv` mode handling) stays in
  one place; the orchestrator doesn't re-implement or re-wire it.
- **Isolation** — a step that crashes or calls `sys.exit()` can't take the orchestrator's state with
  it; you get a clean exit code instead of a half-torn-down process.
- **No import-time surprises** — entry points that read argv / env at import don't fight the parent.
- Cost is negligible for a batch job (process spawn ≪ the I/O each step does).

**Requirement that makes it clean:** every step must be **idempotent** (safe to re-run), so recovery
is just "fix cause, re-run the whole pipeline." Here the DWH steps are CREATE…IF NOT EXISTS /
TRUNCATE+INSERT / CREATE OR REPLACE, and the loaders are watermark+MERGE — so the orchestrator never
needs partial-resume logic. ([[Idempotent Incremental Loading (Watermark + MERGE-on-id)]] is what buys this.)

**Proven (on paper):** `code/etl/shopify_dwh/pipeline.py` — healthcheck → 16 STG loaders → DWH
02–07, one entry point the systemd service calls. Syntax-validated; full run gated on infra.

---

## Anti-Patterns

### Building on Deprecated APIs

**Discovered:** 2026-01-29
**Severity:** MEDIUM

**What it looks like:**
- Using REST API because examples are easier to find
- Ignoring deprecation notices
- "We'll migrate later"

**Why it's bad:**
- Forced migration within 6-12 months
- Technical debt from day one
- May lose access entirely

**Better approach:**
- Check API lifecycle FIRST (see process pattern above)
- Accept slightly higher learning curve for current API
- Build on GraphQL/newer versions from start

---

## Pattern Index

| Pattern | Confidence | Uses | Category |
|---------|------------|------|----------|
| Two-Layer Architecture (Generic + Custom) | LOW | 2 | architecture |
| Architecture Selection (Warehouse vs Lakehouse) | LOW | 1 | architecture |
| Two-Layer DWH Architecture (STG + DWH) | MEDIUM | 3 | data-modeling |
| **Idempotent Incremental Loading (Watermark + MERGE)** | LOW | 2 | data-engineering |
| **Verify Output Mapping Against Target Schema (no live deps)** | LOW | 1 | data-engineering |
| **Thin Subprocess Orchestrator Over Existing Entry Points** | LOW | 1 | data-engineering |
| **Snapshot Is the Productizable Superset** | LOW | 1 | data-modeling |
| **Store Atomic Components, Derive Measures in View Layer** | LOW | 2 | data-modeling |
| **Surface Capability/Permission Gaps as Decisions** | LOW | 1 | process |
| **Cost-Based GraphQL Throttling (Leaky Bucket)** | LOW | 1 | shopify-api |
| **Reconcile by Aligning Window + Definition First** | LOW | 2 | process |
| **Walking-Skeleton POC Before Full Build** | LOW | 1 | process |
| **Exasol Identifier & Type Constraints** | MEDIUM | 3 | exasol |
| **In-Warehouse JSON Field Extraction (REGEXP, no JSON funcs)** | LOW | 1 | exasol |
| Star Schema for Single Source | MEDIUM | 3 | data-modeling |
| Pivot Transformation (Rows to Columns) | LOW | 2 | data-modeling |
| Variant-Level Grain | LOW | 1 | data-modeling |
| **Metrics-Driven Schema Design** | LOW | 1 | data-modeling |
| **Cross-System Join Strategy** | LOW | 1 | data-modeling |
| **Pre-Aggregated Fact for Dashboards** | LOW | 1 | data-modeling |
| **Data Investigation Before Schema Finalisation** | LOW | 1 | data-modeling |
| Validate Schema Against API | LOW | 1 | process |
| Check API Lifecycle First | LOW | 1 | process |
| Mid-Session Checkpointing | HIGH | 6 | process |
| Follow Existing Conventions (Don't Duplicate) | LOW | 1 | process |
| Markdown-to-Word Pipeline | LOW | 2 | process |
| Design-on-Paper Before Building | LOW | 4 | process |
| Shopify Cost Data Location | MEDIUM | 2 | shopify-api |
| Shopify REST → GraphQL | HIGH | 1 | shopify-api |
| Shopify Deprecated Scalars → Object | MEDIUM | 1 | shopify-api |
| Shopify Plan vs Actual Pattern | LOW | 1 | shopify-api |
| Shopify Inventory Levels | LOW | 1 | shopify-api |
| Shopify Discount Code Structure | LOW | 1 | shopify-api |
| Shopify MoneyBag Multi-Currency | MEDIUM | 1 | shopify-api |
| Shopify Bulk Operations for ETL | LOW | 1 | shopify-api |
| **Evaluate Existing Tools Before Building** | LOW | 1 | process |
| **POPIA-Compliant Tiered Architecture** | LOW | 1 | architecture |
| **Evidence-Based Feature Building** | LOW | 1 | process |
| systemd Timers for Production ETL | LOW | 2 | infrastructure |
| Exasol Star Schema Optimization | LOW | 1 | exasol |

---

## Promoting Patterns

When to promote from LOW → MEDIUM:
- [ ] Used successfully 3+ times
- [ ] No major issues encountered
- [ ] Works across different contexts

When to promote from MEDIUM → HIGH:
- [ ] Used successfully 5+ times
- [ ] Documented with clear examples
- [ ] Team/others have adopted it
- [ ] Consider adding to project templates

---

## Pattern Review Log

### 2026-06-26 (Layer 1 DWH + metric views + productionisation — Phases C/D/E)

The code-able remainder of the build, in one session: the full DWH (12 objects + transforms +
verify), the metric view layer (57 metrics), and ops (orchestrator + systemd + runbook). Three
commits (C/D/E), fast-forward-merged to master. All still pre-Gate-A (no infra). Two new patterns:
- **In-Warehouse JSON Field Extraction (REGEXP, no JSON functions)** — `REGEXP_SUBSTR` + `REGEXP_REPLACE`
  to pull scalars from a JSON column without any JSON engine. Safe *because* our own loader wrote the
  JSON (`json.dumps`), so keys + spacing are known, not guessed. Used for dim_geography + order geo.
- **Thin Subprocess Orchestrator Over Existing Entry Points** — `pipeline.py` runs each step as its own
  `python -m` subprocess (not import+call): single source of truth per step, process isolation,
  fail-fast + summary. Clean because every step is already idempotent.

Reinforcements & promotions:
- **Star Schema for Single-Source DWH** LOW→**MEDIUM** (uses 2→3) — POC's 4-object star scaled to the
  full 12 with no structural surprises; the surrogate-key/sentinel/GID-extraction grammar held.
- **Exasol Identifier & Type Constraints** LOW→**MEDIUM** (uses 2→3) — DWH reserved words (`address`,
  `region`) documented for first-deploy; new functions (`NTILE`/`WEEK`/`LAST_DAY`/`HOURS_BETWEEN`).
- **Pivot Transformation (Rows to Columns)** (uses 1→2) — designed Jan, *built* now in fact_order.
- **Store Atomic Components, Derive Measures in the View Layer** (uses 1→2) — the decision, built: 57
  measures as views over atomic fact components; the gross-vs-net question stayed a non-blocker.
- **Reconcile by Aligning Window + Definition First** (uses 1→2) — POC recon → permanent `08_reconcile.sql`.
- **systemd Timers for Production ETL** (uses 1→2) — research note → real unit files (secrets via
  EnvironmentFile so the same code runs dev + prod).
- **Mid-Session Checkpointing** (HIGH, use 6) — C/D/E committed + docs refreshed per phase, clean merge.
- Created episodic: 2026-06-26-layer1-dwh-build.md

### 2026-06-26 (Layer 1 STG build — scaffold + full DDL + 16 loaders)

The production build began: `code/etl/` package, the full 18-table STG DDL, and 16/18 STG loaders,
all pre-Gate-A (no infra), in one long session (9 commits). Three new patterns:
- **Verify Output Mapping Against the Target Schema Without Live Dependencies** — parse the DDL,
  feed a synthetic record through the mapper, assert keys == columns. Caught correctness across all
  16 loaders before any infra existed. "Can't run it" ≠ "can't test it."
- **Snapshot Is the Productizable Superset of "Current State"** — build the snapshot, make
  current-vs-history a scheduling/retention/feature-flag choice, not a code fork. From the inventory
  design decision; generalises "store atomic components" from measures to grain-over-time.
- **Surface Capability/Permission Gaps as Decisions** — map each design artifact to the scope it
  needs, surface gaps (read_discounts/read_gift_cards) as one-at-a-time decisions; deferred 2 loaders.

Reinforcements & promotions:
- **Mid-Session Checkpointing** MEDIUM→**HIGH** (uses 4→5) — 9 commits + running doc refresh + an
  explicit "document everything" pass made the session's handoff clean enough that starting fresh
  was optional, not necessary. The pattern's payoff made concrete.
- **Idempotent Incremental Loading (Watermark + MERGE)** (uses 1→2) — generalised into the shared
  `_orders_source.py`, reused across 8 order-children incl. composite keys + a snapshot variant.
- **Exasol Identifier & Type Constraints** (uses 1→2) — applied across all 234 columns; reserved-word
  watch list documented (rename, don't quote) rather than guessed.
- Production-hardening when porting POC code: central `config.py` as the single `os.environ` reader,
  secure-by-default connection, configurable schema names (noted in episodic, not a standalone pattern).
- Created episodic: 2026-06-26-layer1-stg-build.md

### 2026-06-24 (Shopify POC — first implementation: build, run, reconcile)

The project crossed from design-on-paper to **running code**. Five new implementation patterns:
- **Idempotent Incremental Loading (Watermark + MERGE-on-id)** — proven 0-dup on a live store
- **Cost-Based GraphQL Throttling (Leaky Bucket)** — Shopify points-bucket handling
- **Reconcile by Aligning Window + Definition First** — what made the Fivetran diff a clean 0.30%
- **Walking-Skeleton POC Before Full Build** — thin end-to-end slice on real data before the big build
- **Exasol Identifier & Type Constraints** — leading-underscore/reserved-word/no-generate_series gotchas

Reinforcements & promotions:
- **Two-Layer DWH (STG + DWH)** LOW→**MEDIUM** (uses 1→2) — built for real, clean transform boundary
- **Star Schema for Single-Source DWH** (uses 1→2) — first actual build+reconcile, design held up
- **Mid-Session Checkpointing** LOW→**MEDIUM** (uses 3→4) — survived a long session + a debugging detour
- Live-confirmed earlier *design* findings: 60-day order cap, MoneyBag extraction, variant-grain dim_product
- Key insight: a ~1-hour lightweight reconciliation (aligned window+definition) converts "we think it
  works" into "0.30%, gap explained" — cheap insurance before a large build.
- Created episodic: 2026-06-24-shopify-poc-implementation.md

### 2026-03-06 (Elevator Pitch + Phase 4 NL Analytics Exploration)
- Added **Evaluate Existing Tools Before Building** pattern — check YF native AI before building Claude MCP
- Added **POPIA-Compliant Tiered Architecture** pattern — cloud for non-PII, on-prem for PII
- Added **Evidence-Based Feature Building** pattern — gather gap evidence before building features
- **Reinforced Design-on-Paper Before Building** pattern (uses: 3→4) — full Phase 4 architecture designed on paper before any code
- Key insight: "Design speculatively (cheap), implement evidence-based (expensive)"
- Key insight: YF has Assisted Insights + NLQ + Signals — evaluate before building parallel capabilities
- Key insight: Claude API MCP connector (beta) lets Claude connect to remote MCP server directly — no separate client needed
- Key insight: Report context passing (active report name + filters + visible metrics) makes chat feel contextual without user having to explain what they're looking at
- Created episodic: 2026-03-06-dyt-project-creation.md (expanded with Phase 4 work)

### 2026-02-18 (Report Mapping Analysis)
- **Reinforced Design-on-Paper Before Building** pattern (uses: 2→3) - report mapping caught 8 schema gaps before code
- **Reinforced Markdown-to-Word Pipeline** pattern (uses: 1→2) - 07-Report-Mapping-Analysis via convert_to_docx.py
- **Reinforced Mid-Session Checkpointing** pattern (uses: 2→3) - updated tracking after completing analysis
- Added **Data Investigation Before Schema Finalisation** pattern - querying CampaignSegmentTbl revealed Campaign is too varied for dim_campaign
- Key insight: CSV exports can distort data relationships — always query actual rows to understand column combinations
- Key insight: "Client" in source data maps cleanly to dim_channel; "Campaign" is a sub-classification (VARCHAR attribute, not a dimension)
- Key insight: Subscription tiers encoded in Campaign name can be parsed into structured fields
- Created episodic: 2026-02-18-report-mapping-analysis.md

### 2026-02-18 (DYT Layer 2 Schema Design)
- **Validated Two-Layer Architecture** pattern (uses: 1→2) - Layer 2 designed successfully on top of Layer 1 using separate schemas
- Added **Cross-System Join Strategy** pattern - using shared business keys to bridge SQL Server and Shopify
- Added **Pre-Aggregated Fact for Dashboards** pattern - fact_channel_daily for fast channel reporting
- Added **Follow Existing Conventions** pattern - learned from creating unnecessary duplicate docx file
- Added **Markdown-to-Word Pipeline** pattern - author in markdown, generate docx via python-docx
- Added **Design-on-Paper Before Building** pattern (uses: 2) - validated across both Layer 1 and Layer 2
- Key insight: When systems mask data (Shopify gift card codes), document multiple join strategies with confidence levels
- Key insight: One file in the right place beats two files in two places
- Created episodic: 2026-02-18-dyt-layer2-schema-design.md

### 2026-02-04 (Metrics Gap Analysis)
- Added **Metrics-Driven Schema Design** pattern - work backwards from metrics to data
- Applied pattern to Shopify DWH: identified 6 missing STG tables, 3 missing DWH tables
- Enhanced schema-layered.md with 57 metrics fully documented with lineage
- Created episodic: 2026-02-04-metrics-gap-analysis.md
- Key insight: "Start with metrics, work backwards to data" is more effective than the reverse

### 2026-01-30 (Evening - /learn session)
- Added **Architecture Selection (Warehouse vs Lakehouse)** pattern - decision framework
- Confirmed warehouse is correct choice for Shopify DWH (no unstructured data, no ML needs)
- Key insight reinforced: "Don't adopt trendy architecture without clear problem it solves"
- Updated brain-health metrics with actual counts (19 patterns, 10 episodic entries)
- Created episodic: 2026-01-30-architecture-decisions.md

### 2026-01-30 (Evening)
- Added **Two-Layer DWH Architecture (STG + DWH)** pattern - key insight: don't conflate staging with warehouse
- Added **Pivot Transformation (Rows to Columns)** pattern - payments, taxes, discounts as columns
- Redesigned Shopify DWH schema with reporting-first mindset
- Created schema-layered.md with 10 STG tables + optimized DWH tables
- Updated pattern index with new data-modeling patterns

### 2026-01-30
- Updated Shopify Cost Data Location pattern with GraphQL details (uses: 2)
- Added Shopify Inventory Levels pattern (multi-location stock tracking)
- Added Shopify Discount Code Structure pattern (4 types, redemption tracking)
- Added Shopify Bulk Operations for ETL pattern
- Added systemd Timers for Production ETL pattern
- Added Exasol Star Schema Optimization pattern
- **Reinforced Mid-Session Checkpointing** (uses: 1→2) - applied across 4 research topics
- Added Shopify MoneyBag Multi-Currency pattern (Orders API research)
- Added Shopify Deprecated Scalars → Object pattern (Customer API - email, phone, marketing consent)
- Added Shopify Plan vs Actual pattern (FulfillmentOrder vs Fulfillment)

### 2026-01-29
- Added 6 new patterns from Shopify DWH project
- Added 2 Shopify domain knowledge items
- Added 1 anti-pattern (building on deprecated APIs)
