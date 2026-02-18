# Development Patterns

**Last Updated:** 2026-02-18

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

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-01-29

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

**Confidence:** LOW
**Uses:** 2
**Category:** process
**Last Used:** 2026-01-30

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
**Uses:** 1
**Category:** infrastructure
**Last Used:** 2026-01-30

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

**Confidence:** LOW
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-01-30

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
**Uses:** 1
**Category:** data-modeling
**Last Used:** 2026-01-30

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
**Uses:** 3
**Category:** process
**Last Used:** 2026-02-18

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

**Validated three times:**
- Layer 1 (generic Shopify DWH): 17 STG + 12 DWH tables designed on paper, reviewed, then built
- Layer 2 (DYT B2B2C): 3 STG + 4 DWH tables designed on paper with join strategy and metrics
- Report mapping analysis: Mapping 38 reports against schema caught 8 gaps and data quality issues before any code

**Key insight:**
The design review catches things implementation never would - like the gift card code masking issue that affects join strategy. Better to discover this on paper than mid-ETL build.

**Related Episodes:**
- memory/episodic/completed-work/2026-01-30-schema-layered-design.md
- memory/episodic/completed-work/2026-02-18-dyt-layer2-schema-design.md

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
| Two-Layer DWH Architecture (STG + DWH) | LOW | 1 | data-modeling |
| Star Schema for Single Source | LOW | 1 | data-modeling |
| Pivot Transformation (Rows to Columns) | LOW | 1 | data-modeling |
| Variant-Level Grain | LOW | 1 | data-modeling |
| **Metrics-Driven Schema Design** | LOW | 1 | data-modeling |
| **Cross-System Join Strategy** | LOW | 1 | data-modeling |
| **Pre-Aggregated Fact for Dashboards** | LOW | 1 | data-modeling |
| **Data Investigation Before Schema Finalisation** | LOW | 1 | data-modeling |
| Validate Schema Against API | LOW | 1 | process |
| Check API Lifecycle First | LOW | 1 | process |
| Mid-Session Checkpointing | LOW | 3 | process |
| Follow Existing Conventions (Don't Duplicate) | LOW | 1 | process |
| Markdown-to-Word Pipeline | LOW | 2 | process |
| Design-on-Paper Before Building | LOW | 3 | process |
| Shopify Cost Data Location | MEDIUM | 2 | shopify-api |
| Shopify REST → GraphQL | HIGH | 1 | shopify-api |
| Shopify Deprecated Scalars → Object | MEDIUM | 1 | shopify-api |
| Shopify Plan vs Actual Pattern | LOW | 1 | shopify-api |
| Shopify Inventory Levels | LOW | 1 | shopify-api |
| Shopify Discount Code Structure | LOW | 1 | shopify-api |
| Shopify MoneyBag Multi-Currency | MEDIUM | 1 | shopify-api |
| Shopify Bulk Operations for ETL | LOW | 1 | shopify-api |
| systemd Timers for Production ETL | LOW | 1 | infrastructure |
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
