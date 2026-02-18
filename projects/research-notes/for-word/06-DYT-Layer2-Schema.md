# DYT Layer 2 - B2B2C Voucher & Channel Schema Design

**Version:** 1.0
**Last Updated:** 2026-02-18
**Author:** Digital Planet Analytics

---

## Executive Summary

This document defines the DYT-specific Layer 2 schema that sits on top of the generic Shopify DWH (Layer 1). Layer 2 adds B2B2C voucher tracking, channel attribution, and distribution analytics.

**Key Numbers:**
- 3 Staging tables (from SQL Server)
- 4 Data Warehouse tables (2 dimensions + 2 facts)
- 22 DYT-specific metrics defined
- Layer 1 is untouched (separate schemas: DYT_STG, DYT_DWH)

**Data Sources:**
- SQL Server (Azure) - Channel ownership, voucher allocation, distribution records
- Shopify (Layer 1) - Voucher redemption via orders

**Primary Analytics Lens:** Channel-centric - "How is Channel X performing?"

---

## Architecture Diagram

```
SQL Server (Azure)              Shopify (Layer 1)
Channel & Voucher DB            Orders & Redemptions
        |                              |
        v                              v
  +-----------+                +--------------+
  |  DYT_STG  |                | SHOPIFY_STG  |
  |           |                | SHOPIFY_DWH  |
  | 3 tables  |                | (read only)  |
  +-----------+                +--------------+
        |                              |
        +----------+-------------------+
                   |
                   v
            +------------+
            |  DYT_DWH   |
            |            |
            | 2 dims     |
            | 2 facts    |
            |            |
            | Join key:  |
            | voucher    |
            | code       |
            +------------+
```

---

## Business Context

### B2B2C Model

The Dress Your Tech business model operates as a B2B2C voucher-based value-added products solution:

1. **Corporate clients ("Channels")** such as telecoms and retailers instruct DYT to create and distribute vouchers
2. **DYT creates vouchers** in Shopify as gift cards (~50%) and discount codes (~50%)
3. **Distribution** happens via SMS (98% DYT distributes, 2% channel distributes directly)
4. **End consumers** receive voucher codes and redeem them at checkout on the Shopify store
5. **Gamatek** fulfills and ships the order

### Key Business Rules

- Gift cards and discount codes are bulk-created in Shopify and held in inventory
- SQL Server DB is source of truth for channel-to-voucher mapping
- Distribution can be one-off or subscription (recurring monthly)
- Redemption only happens in Shopify (consumer uses code at checkout)
- The voucher code is the join key linking Shopify redemption to SQL Server channel data

---

## Layer 1 Gap: Gift Cards

Layer 1 STG did not previously extract Shopify gift card objects. A new table has been added:

### stg_gift_cards (added to SHOPIFY_STG)

**Source:** Shopify `giftCards` GraphQL query

| Column | Shopify Field | Type | Description |
|--------|---------------|------|-------------|
| id | id | VARCHAR(50) | Gift card GID |
| code | lastCharacters | VARCHAR(10) | Last 4 chars only |
| initial_value | initialValue.amount | DECIMAL(18,2) | Original value |
| balance | balance.amount | DECIMAL(18,2) | Current balance |
| currency_code | initialValue.currencyCode | VARCHAR(5) | Currency |
| enabled | enabled | BOOLEAN | Active flag |
| expires_on | expiresOn | DATE | Expiry date |
| created_at | createdAt | TIMESTAMP | Creation time |
| updated_at | updatedAt | TIMESTAMP | Last update |
| disabled_at | disabledAt | TIMESTAMP | Disabled time |
| customer_id | customer.id | VARCHAR(50) | Customer GID |
| order_id | order.id | VARCHAR(50) | Order that created it |
| note | note | TEXT | Notes |
| _extracted_at | ETL | TIMESTAMP | Extraction timestamp |

**Important:** Shopify masks gift card codes. Only the last 4 characters are available via the API. The full code lives in the SQL Server database, making SQL Server the primary join source.

---

## DYT Staging Schema (DYT_STG)

These tables mirror the SQL Server source structure. Column names are illustrative and must be confirmed when the SQL Server schema is inspected.

### stg_channels

**Source:** SQL Server - Channel/client master table

| Column | Type | Description |
|--------|------|-------------|
| channel_id | VARCHAR(50) | Channel identifier |
| channel_name | VARCHAR(255) | Channel name |
| industry | VARCHAR(100) | Industry (Telecom, Retail, etc.) |
| contact_name | VARCHAR(255) | Primary contact |
| contact_email | VARCHAR(255) | Contact email |
| contract_start_date | DATE | Contract start |
| contract_end_date | DATE | Contract end |
| is_active | BOOLEAN | Active flag |
| _extracted_at | TIMESTAMP | Extraction timestamp |

---

### stg_voucher_inventory

**Source:** SQL Server - Voucher creation and allocation records

This is the central staging table containing the full voucher code that bridges SQL Server and Shopify.

| Column | Type | Description |
|--------|------|-------------|
| voucher_id | VARCHAR(50) | Internal voucher ID |
| voucher_code | VARCHAR(50) | Full voucher code (THE JOIN KEY) |
| voucher_type | VARCHAR(20) | 'gift_card' or 'discount_code' |
| channel_id | VARCHAR(50) | Owning channel |
| face_value | DECIMAL(18,2) | Original value |
| currency_code | VARCHAR(5) | Currency |
| created_in_shopify_at | TIMESTAMP | When created in Shopify |
| shopify_id | VARCHAR(50) | Shopify discount/gift card GID |
| status | VARCHAR(20) | created / allocated / distributed / redeemed / expired |
| batch_id | VARCHAR(50) | Creation batch reference |
| _extracted_at | TIMESTAMP | Extraction timestamp |

---

### stg_voucher_distributions

**Source:** SQL Server - Distribution instructions and SMS delivery records

| Column | Type | Description |
|--------|------|-------------|
| distribution_id | VARCHAR(50) | Distribution record ID |
| voucher_id | VARCHAR(50) | FK to stg_voucher_inventory |
| voucher_code | VARCHAR(50) | Voucher code (denormalized) |
| channel_id | VARCHAR(50) | Instructing channel |
| instruction_date | DATE | Date channel instructed distribution |
| distribution_date | TIMESTAMP | When SMS was sent |
| distribution_method | VARCHAR(20) | 'sms_dyt' or 'direct_channel' |
| recipient_phone | VARCHAR(50) | Recipient phone number |
| recipient_name | VARCHAR(255) | Recipient name |
| sms_status | VARCHAR(20) | delivered / failed / pending |
| subscription_flag | BOOLEAN | Part of a subscription |
| subscription_month | INT | Month in subscription (1, 2, 3...) |
| _extracted_at | TIMESTAMP | Extraction timestamp |

---

## DYT Data Warehouse Schema (DYT_DWH)

Channel-centric analytics layer joining SQL Server channel/voucher data with Shopify redemption data.

### dim_channel

**Source:** stg_channels

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| channel_key | BIGINT | IDENTITY (0=Unknown) | Surrogate key |
| channel_id | VARCHAR(50) | stg_channels.channel_id | Business key |
| channel_name | VARCHAR(255) | stg_channels.channel_name | Channel name |
| industry | VARCHAR(100) | stg_channels.industry | Industry classification |
| contract_start_date | DATE | stg_channels.contract_start_date | Contract start |
| contract_end_date | DATE | stg_channels.contract_end_date | Contract end |
| is_active | BOOLEAN | stg_channels.is_active | Active flag |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### dim_voucher

**Source:** stg_voucher_inventory + stg_voucher_distributions + Shopify data

This is the central dimension that unifies gift cards and discount codes with channel ownership. It captures the full voucher lifecycle in a single row.

#### Identity & Value

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| voucher_key | BIGINT | IDENTITY (0=Unknown) | Surrogate key |
| voucher_code | VARCHAR(50) | stg_voucher_inventory.voucher_code | The code (join key) |
| voucher_type | VARCHAR(20) | stg_voucher_inventory.voucher_type | gift_card / discount_code |
| channel_key | BIGINT | channel_id lookup | FK to dim_channel |
| face_value | DECIMAL(18,2) | stg_voucher_inventory.face_value | Original value |
| currency_code | VARCHAR(5) | stg_voucher_inventory.currency_code | Currency |
| status | VARCHAR(20) | stg_voucher_inventory.status | Lifecycle status |
| batch_id | VARCHAR(50) | stg_voucher_inventory.batch_id | Creation batch |
| created_in_shopify_at | TIMESTAMP | stg_voucher_inventory | Shopify creation |
| shopify_discount_key | BIGINT | shopify_id lookup | FK to Layer 1 dim_discount |

#### Distribution Attributes

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| is_distributed | BOOLEAN | Distribution record exists | Sent to consumer |
| distribution_date | TIMESTAMP | stg_voucher_distributions | When distributed |
| distribution_method | VARCHAR(20) | stg_voucher_distributions | sms_dyt / direct_channel |
| is_subscription | BOOLEAN | stg_voucher_distributions | Recurring subscription |
| subscription_month | INT | stg_voucher_distributions | Month in sequence |

#### Redemption Attributes (from Shopify)

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| is_redeemed | BOOLEAN | Matched to Shopify order | Used at checkout |
| redemption_date | TIMESTAMP | Shopify order date | When redeemed |
| redemption_order_id | VARCHAR(50) | Shopify fact_order | Which order |

#### Timing Metrics

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| days_in_inventory | INT | distribution - creation | Days before distribution |
| days_to_redemption | INT | redemption - distribution | Days to redeem |
| channel_name | VARCHAR(255) | dim_channel.channel_name | Denormalized |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

---

### fact_voucher_lifecycle

**Source:** stg_voucher_inventory + stg_voucher_distributions + Shopify order data

**Grain:** One row per voucher code (tracks full lifecycle)

#### Keys

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| voucher_lifecycle_key | BIGINT | IDENTITY | Surrogate key |
| voucher_key | BIGINT | voucher_code lookup | FK to dim_voucher |
| channel_key | BIGINT | channel_id lookup | FK to dim_channel |
| creation_date_key | INT | to_date_key() | FK to dim_date |
| distribution_date_key | INT | to_date_key() | FK to dim_date (nullable) |
| redemption_date_key | INT | to_date_key() | FK to dim_date (nullable) |
| product_key | BIGINT | From redemption order | FK to dim_product (nullable) |

#### Identifiers

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| voucher_code | VARCHAR(50) | stg_voucher_inventory | The voucher code |
| voucher_type | VARCHAR(20) | stg_voucher_inventory | gift_card / discount_code |
| batch_id | VARCHAR(50) | stg_voucher_inventory | Creation batch |

#### Lifecycle Status

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| lifecycle_status | VARCHAR(20) | Derived | created / distributed / redeemed / expired |
| is_distributed | BOOLEAN | Distribution exists | Distributed flag |
| is_redeemed | BOOLEAN | Shopify order match | Redeemed flag |
| is_expired | BOOLEAN | Past expiry, not redeemed | Expired flag |

#### Financial

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| face_value | DECIMAL(18,2) | stg_voucher_inventory | Original voucher value |
| redemption_order_total | DECIMAL(18,2) | fact_order.total_amount | Order value at redemption |
| redemption_discount_amount | DECIMAL(18,2) | Discount from this code | Amount discounted |
| additional_spend | DECIMAL(18,2) | order_total - discount | Spend beyond voucher |

#### Timing

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| days_creation_to_distribution | INT | Calculated | Inventory holding time |
| days_distribution_to_redemption | INT | Calculated | Time to redeem |
| days_creation_to_redemption | INT | Calculated | Total lifecycle days |

#### Subscription & Denormalized

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| is_subscription | BOOLEAN | Distribution record | Subscription flag |
| subscription_month | INT | Distribution record | Month in sequence |
| channel_name | VARCHAR(255) | dim_channel | Channel name |
| redemption_order_number | VARCHAR(20) | fact_order | Order number |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

#### Lifecycle Status Derivation

```
CASE
  WHEN is_redeemed = TRUE  THEN 'redeemed'
  WHEN is_expired = TRUE   THEN 'expired'
  WHEN is_distributed = TRUE THEN 'distributed'
  ELSE 'created'
END AS lifecycle_status
```

---

### fact_channel_daily

**Source:** Aggregation of fact_voucher_lifecycle + dim_date

**Grain:** One row per channel per day (pre-aggregated for dashboards)

This table enables the primary question: "How is Channel X performing?"

#### Keys

| Column | Type | Description |
|--------|------|-------------|
| channel_daily_key | BIGINT | Surrogate key |
| channel_key | BIGINT | FK to dim_channel |
| date_key | INT | FK to dim_date |

#### Volume Metrics

| Column | Type | Description |
|--------|------|-------------|
| vouchers_created | INT | New vouchers created this day |
| vouchers_distributed | INT | Vouchers distributed this day |
| vouchers_redeemed | INT | Vouchers redeemed this day |
| vouchers_expired | INT | Vouchers expired this day |

#### Financial Metrics

| Column | Type | Description |
|--------|------|-------------|
| face_value_created | DECIMAL(18,2) | Face value of vouchers created |
| face_value_distributed | DECIMAL(18,2) | Face value distributed |
| face_value_redeemed | DECIMAL(18,2) | Face value redeemed |
| redemption_order_revenue | DECIMAL(18,2) | Order revenue from redemptions |
| additional_spend_total | DECIMAL(18,2) | Spend beyond voucher value |

#### Running Totals

| Column | Type | Description |
|--------|------|-------------|
| cumulative_created | INT | Running total created |
| cumulative_distributed | INT | Running total distributed |
| cumulative_redeemed | INT | Running total redeemed |
| outstanding_distributed | INT | Distributed but not yet redeemed |

#### Rates & Denormalized

| Column | Type | Description |
|--------|------|-------------|
| distribution_rate | DECIMAL(5,2) | cumul_distributed / cumul_created * 100 |
| redemption_rate | DECIMAL(5,2) | cumul_redeemed / cumul_distributed * 100 |
| channel_name | VARCHAR(255) | Channel name |
| _loaded_at | TIMESTAMP | Load timestamp |

---

## Data Flow

```
SQL Server (Azure)                Shopify (Layer 1)
==================                ====================
Channel master                    stg_discount_codes
  -> DYT_STG.stg_channels        stg_gift_cards (NEW)
                                  stg_orders
Voucher records                   stg_order_discount_apps
  -> DYT_STG.stg_voucher_inv     stg_order_transactions
                                  fact_order
Distribution log                  dim_discount
  -> DYT_STG.stg_voucher_dist    dim_date, dim_product
         |                              |
         v                              v
   +-------------------------------------------+
   |        DYT_DWH (Join on voucher_code)     |
   |                                           |
   |  dim_channel  <-- stg_channels            |
   |  dim_voucher  <-- stg_voucher_inventory   |
   |                 + distributions            |
   |                 + Shopify redemption data  |
   |  fact_voucher_lifecycle <-- all joined     |
   |  fact_channel_daily <-- aggregation        |
   +-------------------------------------------+
```

---

## ETL Dependency Order

1. Load DYT_STG from SQL Server: stg_channels, stg_voucher_inventory, stg_voucher_distributions
2. Build dim_channel from stg_channels
3. Build dim_voucher from stg_voucher_inventory + distributions + Shopify data
4. Build fact_voucher_lifecycle from all sources joined
5. Build fact_channel_daily as aggregation of fact_voucher_lifecycle

---

## Join Strategy

The voucher code is the bridge between SQL Server and Shopify.

### Discount Codes (Simple - High Confidence)

Direct string match:

```
DYT_STG.stg_voucher_inventory.voucher_code
  = SHOPIFY_STG.stg_order_discount_applications.code
```

### Gift Cards (Complex - Needs Validation)

Shopify masks gift card codes (only last 4 chars via API). Three options:

**Option A: Join via Shopify GID (Preferred)**

```
DYT_STG.stg_voucher_inventory.shopify_id
  = SHOPIFY_STG.stg_gift_cards.id
```

- Confidence: MEDIUM
- Depends on SQL Server storing the Shopify GID at creation

**Option B: Join via Transaction Records**

```
Match gift card payments in stg_order_transactions
  WHERE gateway = 'gift_card'
```

- Confidence: LOW
- Transactions don't directly link to specific gift card IDs

**Option C: Last 4 Characters + GID Cross-Reference**

```
Join on shopify_id AND validate with
  RIGHT(voucher_code, 4) = stg_gift_cards.code
```

- Confidence: MEDIUM
- Good for data quality validation

**Recommendation:** Option A as primary join, Option C as validation. Must confirm shopify_id is populated in SQL Server.

---

## DYT-Specific Metrics (22)

### Voucher Funnel Metrics (7)

| # | Metric | Formula |
|---|--------|---------|
| 1 | Vouchers Created | COUNT(*) from fact_voucher_lifecycle |
| 2 | Vouchers Distributed | COUNT(*) WHERE is_distributed = TRUE |
| 3 | Vouchers Redeemed | COUNT(*) WHERE is_redeemed = TRUE |
| 4 | Vouchers Expired | COUNT(*) WHERE is_expired = TRUE |
| 5 | Distribution Rate | Distributed / Created * 100 |
| 6 | Redemption Rate | Redeemed / Distributed * 100 |
| 7 | Outstanding Vouchers | Distributed - Redeemed |

### Channel Financial Metrics (6)

| # | Metric | Formula |
|---|--------|---------|
| 8 | Face Value Distributed | SUM(face_value) WHERE is_distributed |
| 9 | Face Value Redeemed | SUM(face_value) WHERE is_redeemed |
| 10 | Redemption Order Revenue | SUM(redemption_order_total) |
| 11 | Additional Spend (Upsell) | SUM(additional_spend) |
| 12 | Upsell Rate | Additional Spend / Face Value Redeemed * 100 |
| 13 | Outstanding Liability | Outstanding * Avg Face Value |

### Timing Metrics (3)

| # | Metric | Formula |
|---|--------|---------|
| 14 | Avg Days in Inventory | AVG(days_creation_to_distribution) |
| 15 | Avg Days to Redeem | AVG(days_distribution_to_redemption) |
| 16 | Avg Total Lifecycle | AVG(days_creation_to_redemption) |

### Subscription Metrics (3)

| # | Metric | Formula |
|---|--------|---------|
| 17 | Subscription Vouchers | COUNT(*) WHERE is_subscription = TRUE |
| 18 | Subscription Redemption Rate | Redeemed / Distributed WHERE subscription |
| 19 | Avg Subscription Tenure | MAX(subscription_month) per channel |

### Distribution Method Metrics (3)

| # | Metric | Formula |
|---|--------|---------|
| 20 | SMS Distribution Count | COUNT(*) WHERE method = 'sms_dyt' |
| 21 | Direct Distribution Count | COUNT(*) WHERE method = 'direct_channel' |
| 22 | SMS Delivery Rate | delivered / total SMS * 100 |

---

## Key Design Decisions

### 1. Separate Schemas (DYT_STG / DYT_DWH)

Layer 2 uses its own schemas. Layer 1 is untouched and portable.

- Clear boundary between generic Shopify DWH and DYT-specific logic
- If Layer 1 is productized, Layer 2 doesn't ship with it
- DYT ETL can be developed and deployed independently

### 2. dim_voucher as Central Dimension

Unifies gift cards and discount codes into a single dimension with channel ownership.

- From a business perspective, both are "vouchers" regardless of Shopify type
- Channel managers don't care about Shopify's internal distinction
- Enables "all vouchers for Channel X" queries without UNION

### 3. fact_voucher_lifecycle at Voucher Grain

One row per voucher code tracking the full lifecycle.

- Each voucher code is single-use (natural grain)
- Enables lifecycle funnel: created -> distributed -> redeemed
- Timing metrics (days to distribute, days to redeem) are per-voucher

### 4. fact_channel_daily Pre-Aggregated

Pre-aggregated daily channel metrics for dashboard performance.

- Primary question is "how is Channel X performing?"
- Running totals are expensive to compute on the fly
- Outstanding voucher liability is a key financial metric
- Dashboard queries hit this table directly

### 5. Channel-Centric Analytics Lens

All Layer 2 tables are designed around the channel as the primary dimension.

- B2B2C model: channels are the customers (not end consumers)
- Revenue attribution is to channels, not individuals
- Contract management requires channel-level reporting

### 6. Illustrative Column Names

DYT_STG column names must be confirmed against the actual SQL Server schema before implementation. The conceptual model is correct; column names will adapt.

---

## Schema Summary

| Schema | Table | Type | Columns | Description |
|--------|-------|------|---------|-------------|
| DYT_STG | stg_channels | Staging | ~9 | Channel master |
| DYT_STG | stg_voucher_inventory | Staging | ~11 | Voucher allocation |
| DYT_STG | stg_voucher_distributions | Staging | ~12 | Distribution records |
| DYT_DWH | dim_channel | Dimension | ~8 | Channel dimension |
| DYT_DWH | dim_voucher | Dimension | ~22 | Central voucher dim |
| DYT_DWH | fact_voucher_lifecycle | Fact | ~26 | Per-voucher lifecycle |
| DYT_DWH | fact_channel_daily | Fact | ~18 | Daily channel metrics |

**Total: 7 tables (3 STG + 2 dimensions + 2 facts) + 22 metrics**

---

## Layer 1 Dependencies

| Layer 1 Table | Used By | Purpose |
|---------------|---------|---------|
| stg_order_discount_applications | dim_voucher, fact_lifecycle | Discount code redemptions |
| stg_gift_cards | dim_voucher | Gift card data and GID join |
| stg_order_transactions | dim_voucher, fact_lifecycle | Gift card payments |
| fact_order | fact_voucher_lifecycle | Redemption order financials |
| dim_discount | dim_voucher | Discount code master data |
| dim_date | fact_lifecycle, fact_channel_daily | Conformed dates |
| dim_product | fact_voucher_lifecycle | Redeemed product |

---

## Open Items

Items to resolve before implementation:

1. **Inspect SQL Server schema** - Confirm actual table and column names
2. **Validate gift card join** - Confirm shopify_id is stored for gift cards
3. **Gift card redemption tracking** - Best approach to link gift card to specific order
4. **DYT metric definitions** - Pending report descriptions from Dominic
5. **Subscription model** - Confirm how subscription months are tracked
6. **Productization assessment** - Which Layer 2 elements could generalize
7. **SMS delivery tracking** - Confirm reliability of SMS status in SQL Server
8. **Voucher expiry logic** - Where expiry dates are managed

---

## Document Set

This document is part of the Shopify DWH documentation:

**Layer 1 (Generic Shopify DWH):**
1. Architecture Overview
2. Staging Schema (17 STG tables)
3. Warehouse Schema (7 dims + 5 facts)
4. Data Lineage
5. Metrics Reference (57 metrics)

**Layer 2 (DYT-Specific):**
6. **DYT Layer 2 Schema Design** (this document)
