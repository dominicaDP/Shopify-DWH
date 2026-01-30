# Development Patterns

**Last Updated:** 2026-01-30

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
**Uses:** 1
**Category:** architecture
**Last Used:** 2026-01-29

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

**Related Episodes:**
- memory/episodic/completed-work/2026-01-29-product-api-research.md

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
| Two-Layer Architecture | LOW | 1 | architecture |
| Star Schema for Single Source | LOW | 1 | data-modeling |
| Variant-Level Grain | LOW | 1 | data-modeling |
| Validate Schema Against API | LOW | 1 | process |
| Check API Lifecycle First | LOW | 1 | process |
| Mid-Session Checkpointing | LOW | 2 | process |
| Shopify Cost Data Location | MEDIUM | 2 | shopify-api |
| Shopify REST → GraphQL | HIGH | 1 | shopify-api |
| Shopify Inventory Levels | LOW | 1 | shopify-api |
| Shopify Discount Code Structure | LOW | 1 | shopify-api |
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

### 2026-01-30
- Updated Shopify Cost Data Location pattern with GraphQL details (uses: 2)
- Added Shopify Inventory Levels pattern (multi-location stock tracking)
- Added Shopify Discount Code Structure pattern (4 types, redemption tracking)
- Added Shopify Bulk Operations for ETL pattern
- Added systemd Timers for Production ETL pattern
- Added Exasol Star Schema Optimization pattern
- **Reinforced Mid-Session Checkpointing** (uses: 1→2) - applied across 4 research topics

### 2026-01-29
- Added 6 new patterns from Shopify DWH project
- Added 2 Shopify domain knowledge items
- Added 1 anti-pattern (building on deprecated APIs)
