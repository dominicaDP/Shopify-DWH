# DYT Layer 2 - B2B2C Voucher & Channel Schema Design

**Version:** 1.0
**Last Updated:** 2026-02-18

This document defines the DYT-specific Layer 2 schema that sits on top of the generic Shopify DWH (Layer 1). Layer 2 adds B2B2C voucher tracking, channel attribution, and distribution analytics using data from both Shopify and an external SQL Server database.

**Layer 1 is untouched** - Layer 2 uses separate schemas (DYT_STG, DYT_DWH) and joins to Layer 1 via voucher codes and Shopify IDs.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  SQL Server (Azure) - Channel & Voucher Source of Truth         │
│  External database tracking channel ownership, allocation,      │
│  and distribution                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  DYT_STG (Staging Schema)                                        │
│                                                                  │
│  • Mirrors SQL Server source structure                           │
│  • Channel, voucher, and distribution records                   │
│  • Column names illustrative (confirm against actual schema)    │
│  • Extracted via SQL Server connection                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ Transform + Join with Layer 1
┌─────────────────────────────────────────────────────────────────┐
│  DYT_DWH (Data Warehouse Schema)                                 │
│                                                                  │
│  • Channel-centric analytics (primary lens)                     │
│  • Joins SQL Server data with Shopify redemption data           │
│  • Voucher lifecycle tracking (create → distribute → redeem)   │
│  • Pre-aggregated channel daily metrics for dashboards          │
│                                                                  │
│  Join key: voucher_code                                          │
│  SQL Server voucher_code ←→ Shopify discount code / gift card   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ References
┌─────────────────────────────────────────────────────────────────┐
│  SHOPIFY_STG + SHOPIFY_DWH (Layer 1 - Read Only)                │
│                                                                  │
│  • stg_order_discount_applications (discount code redemptions)  │
│  • stg_gift_cards (gift card data, last 4 chars only)           │
│  • stg_order_transactions (gift card payment transactions)      │
│  • fact_order (order totals for redemption financials)           │
│  • dim_discount (discount code master data)                     │
│  • dim_date (conformed date dimension)                           │
│  • dim_product (product master for redeemed items)              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Business Context

### B2B2C Model

```
Corporate Clients ("Channels")
  e.g., Telecoms, Retailers
         │
         │ instruct DYT to create & distribute vouchers
         ▼
Dress Your Tech (DYT)
  Creates vouchers in Shopify (gift cards + discount codes)
  Distributes via SMS (98%) or channel distributes directly (2%)
         │
         │ consumer receives voucher code
         ▼
End Consumer
  Redeems voucher code at checkout on Shopify
         │
         │ order placed
         ▼
Gamatek (Fulfillment)
  Ships product to consumer
```

### Key Business Rules

1. **Voucher creation**: Gift cards and discount codes are bulk-created in Shopify and held in inventory
2. **Channel ownership**: SQL Server DB is the source of truth for which channel owns which vouchers
3. **Distribution**: Channels instruct DYT to distribute. 98% DYT distributes via SMS, 2% channel distributes directly
4. **Distribution types**: One-off or subscription (recurring monthly)
5. **Redemption**: Only happens in Shopify - consumer uses voucher code at checkout
6. **Voucher types**: ~50% gift cards, ~50% discount codes
7. **Analytics lens**: Channel-centric - "how is Channel X performing?" is the primary question

---

# DYT STAGING SCHEMA (DYT_STG)

Mirrors the SQL Server source structure. These tables are loaded from the Azure SQL Server database.

**Note:** Column names below are illustrative. Actual column names must be confirmed when the SQL Server schema is inspected.

---

## stg_channels

**Source:** SQL Server - Channel/client master table

| Column | Type | Description |
|--------|------|-------------|
| channel_id | VARCHAR(50) | Channel identifier |
| channel_name | VARCHAR(255) | Channel name |
| industry | VARCHAR(100) | Industry classification (Telecom, Retail, etc.) |
| contact_name | VARCHAR(255) | Primary contact |
| contact_email | VARCHAR(255) | Contact email |
| contract_start_date | DATE | Contract start |
| contract_end_date | DATE | Contract end |
| is_active | BOOLEAN | Active flag |
| _extracted_at | TIMESTAMP | Extraction timestamp |

---

## stg_voucher_inventory

**Source:** SQL Server - Voucher creation and allocation records

This is the central staging table - it contains the full voucher code that bridges SQL Server and Shopify.

| Column | Type | Description |
|--------|------|-------------|
| voucher_id | VARCHAR(50) | Internal voucher ID |
| voucher_code | VARCHAR(50) | **Full voucher code (the join key)** |
| voucher_type | VARCHAR(20) | 'gift_card' or 'discount_code' |
| channel_id | VARCHAR(50) | Owning channel (FK to stg_channels) |
| face_value | DECIMAL(18,2) | Original value |
| currency_code | VARCHAR(5) | Currency |
| created_in_shopify_at | TIMESTAMP | When created in Shopify |
| shopify_id | VARCHAR(50) | Shopify discount/gift card ID (GID) |
| status | VARCHAR(20) | created / allocated / distributed / redeemed / expired |
| batch_id | VARCHAR(50) | Creation batch reference |
| _extracted_at | TIMESTAMP | Extraction timestamp |

---

## stg_voucher_distributions

**Source:** SQL Server - Distribution instructions and SMS delivery records

| Column | Type | Description |
|--------|------|-------------|
| distribution_id | VARCHAR(50) | Distribution record ID |
| voucher_id | VARCHAR(50) | FK to stg_voucher_inventory |
| voucher_code | VARCHAR(50) | Voucher code (denormalized for convenience) |
| channel_id | VARCHAR(50) | Instructing channel |
| instruction_date | DATE | Date channel instructed distribution |
| distribution_date | TIMESTAMP | When SMS was sent / voucher was distributed |
| distribution_method | VARCHAR(20) | 'sms_dyt' or 'direct_channel' |
| recipient_phone | VARCHAR(50) | Recipient phone number |
| recipient_name | VARCHAR(255) | Recipient name (if available) |
| sms_status | VARCHAR(20) | delivered / failed / pending |
| subscription_flag | BOOLEAN | Is this part of a subscription |
| subscription_month | INT | Which month in subscription (1, 2, 3...) |
| _extracted_at | TIMESTAMP | Extraction timestamp |

---

# DYT DATA WAREHOUSE SCHEMA (DYT_DWH)

Channel-centric analytics layer joining SQL Server channel/voucher data with Shopify redemption data.

---

## dim_channel

**Source:** stg_channels

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| channel_key | BIGINT | IDENTITY (0 = Unknown) | Surrogate key |
| channel_id | VARCHAR(50) | stg_channels.channel_id | Business key |
| channel_name | VARCHAR(255) | stg_channels.channel_name | Channel name |
| industry | VARCHAR(100) | stg_channels.industry | Industry classification |
| contract_start_date | DATE | stg_channels.contract_start_date | Contract start |
| contract_end_date | DATE | stg_channels.contract_end_date | Contract end |
| is_active | BOOLEAN | stg_channels.is_active | Active flag |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

**Unknown member (key = 0):** Used when a voucher cannot be mapped to a channel.

---

## dim_voucher

**Source:** stg_voucher_inventory + stg_voucher_distributions + Shopify redemption data

This is the **central dimension** that unifies gift cards and discount codes with their channel ownership. It captures the full voucher lifecycle in a single row.

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Identity** |
| voucher_key | BIGINT | IDENTITY (0 = Unknown) | Surrogate key |
| voucher_code | VARCHAR(50) | stg_voucher_inventory.voucher_code | The code (primary join key) |
| voucher_type | VARCHAR(20) | stg_voucher_inventory.voucher_type | 'gift_card' or 'discount_code' |
| channel_key | BIGINT | channel_id → dim_channel lookup | FK to dim_channel |
| **Value** |
| face_value | DECIMAL(18,2) | stg_voucher_inventory.face_value | Original voucher value |
| currency_code | VARCHAR(5) | stg_voucher_inventory.currency_code | Currency |
| **Lifecycle** |
| status | VARCHAR(20) | stg_voucher_inventory.status | created / allocated / distributed / redeemed / expired |
| batch_id | VARCHAR(50) | stg_voucher_inventory.batch_id | Creation batch reference |
| created_in_shopify_at | TIMESTAMP | stg_voucher_inventory.created_in_shopify_at | When created in Shopify |
| shopify_discount_key | BIGINT | shopify_id → SHOPIFY_DWH.dim_discount lookup | FK to Layer 1 dim_discount (if discount code) |
| **Distribution Attributes** |
| is_distributed | BOOLEAN | stg_voucher_distributions record exists | Has been sent to consumer |
| distribution_date | TIMESTAMP | stg_voucher_distributions.distribution_date | When distributed |
| distribution_method | VARCHAR(20) | stg_voucher_distributions.distribution_method | 'sms_dyt' or 'direct_channel' |
| is_subscription | BOOLEAN | stg_voucher_distributions.subscription_flag | Part of a recurring subscription |
| subscription_month | INT | stg_voucher_distributions.subscription_month | Month in subscription sequence (1, 2, 3...) |
| **Redemption Attributes (from Shopify)** |
| is_redeemed | BOOLEAN | Matched to Shopify order via code | Used at checkout |
| redemption_date | TIMESTAMP | From Shopify order where code was used | When redeemed |
| redemption_order_id | VARCHAR(50) | From Shopify fact_order | Which Shopify order |
| **Timing Metrics** |
| days_in_inventory | INT | distribution_date - created_in_shopify_at | Days held before distribution |
| days_to_redemption | INT | redemption_date - distribution_date | Days from distribution to use |
| **Denormalized (for reporting)** |
| channel_name | VARCHAR(255) | dim_channel.channel_name | Channel name for quick reporting |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

### dim_voucher Population Logic

```
1. Base: One row per voucher from stg_voucher_inventory
2. Distribution: LEFT JOIN stg_voucher_distributions ON voucher_id
3. Redemption (discount codes):
   LEFT JOIN SHOPIFY_STG.stg_order_discount_applications
   ON voucher_code = code
4. Redemption (gift cards):
   LEFT JOIN SHOPIFY_STG.stg_gift_cards
   ON stg_voucher_inventory.shopify_id = stg_gift_cards.id
   (then check balance < initial_value to detect redemption)
   OR via stg_order_transactions WHERE gateway = 'gift_card'
5. Channel lookup: JOIN dim_channel ON channel_id
6. Layer 1 discount lookup: LEFT JOIN SHOPIFY_DWH.dim_discount ON shopify_id
```

---

## fact_voucher_lifecycle

**Source:** stg_voucher_inventory + stg_voucher_distributions + Shopify order data

**Grain:** One row per voucher code (tracks the full lifecycle from creation to redemption/expiry)

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| voucher_lifecycle_key | BIGINT | IDENTITY | Surrogate key |
| voucher_key | BIGINT | voucher_code → dim_voucher lookup | FK to dim_voucher |
| channel_key | BIGINT | channel_id → dim_channel lookup | FK to dim_channel |
| creation_date_key | INT | created_in_shopify_at → to_date_key() | FK to SHOPIFY_DWH.dim_date |
| distribution_date_key | INT | distribution_date → to_date_key() | FK to dim_date (NULL if not distributed) |
| redemption_date_key | INT | redemption_date → to_date_key() | FK to dim_date (NULL if not redeemed) |
| product_key | BIGINT | From redemption order line item | FK to SHOPIFY_DWH.dim_product (NULL if not redeemed) |
| **Identifiers** |
| voucher_code | VARCHAR(50) | stg_voucher_inventory.voucher_code | The voucher code |
| voucher_type | VARCHAR(20) | stg_voucher_inventory.voucher_type | gift_card / discount_code |
| batch_id | VARCHAR(50) | stg_voucher_inventory.batch_id | Creation batch |
| **Lifecycle Status** |
| lifecycle_status | VARCHAR(20) | Derived (see logic below) | created / distributed / redeemed / expired |
| is_distributed | BOOLEAN | Distribution record exists | Distributed flag |
| is_redeemed | BOOLEAN | Matched to Shopify order | Redeemed flag |
| is_expired | BOOLEAN | Past expiry and not redeemed | Expired flag |
| **Financial** |
| face_value | DECIMAL(18,2) | stg_voucher_inventory.face_value | Original voucher value |
| redemption_order_total | DECIMAL(18,2) | SHOPIFY_DWH.fact_order.total_amount | Total order value at redemption |
| redemption_discount_amount | DECIMAL(18,2) | Discount applied from this code | Amount actually discounted |
| additional_spend | DECIMAL(18,2) | order_total - discount_amount | Customer spend beyond voucher value |
| **Timing** |
| days_creation_to_distribution | INT | distribution_date - creation_date | Inventory holding time |
| days_distribution_to_redemption | INT | redemption_date - distribution_date | Time to redeem after receiving |
| days_creation_to_redemption | INT | redemption_date - creation_date | Total lifecycle days |
| **Subscription** |
| is_subscription | BOOLEAN | From distribution record | Subscription flag |
| subscription_month | INT | From distribution record | Month in sequence (1, 2, 3...) |
| **Denormalized (for reporting)** |
| channel_name | VARCHAR(255) | dim_channel.channel_name | Channel name |
| redemption_order_number | VARCHAR(20) | SHOPIFY_DWH.fact_order.order_number | Order # for lookup |
| **ETL** |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

### lifecycle_status Derivation Logic

```sql
CASE
  WHEN is_redeemed = TRUE THEN 'redeemed'
  WHEN is_expired = TRUE THEN 'expired'
  WHEN is_distributed = TRUE THEN 'distributed'
  ELSE 'created'
END AS lifecycle_status
```

### additional_spend Calculation

```sql
-- For discount codes:
additional_spend = redemption_order_total - redemption_discount_amount

-- For gift cards:
-- Gift cards are payment methods, not discounts
-- additional_spend = redemption_order_total - gift_card_amount_used
-- (from stg_order_transactions WHERE gateway = 'gift_card')
```

---

## fact_channel_daily

**Source:** Aggregation of fact_voucher_lifecycle + dim_date

**Grain:** One row per channel per day (pre-aggregated for fast dashboard queries)

This table enables the primary analytics question: **"How is Channel X performing?"**

| Column | Type | Description |
|--------|------|-------------|
| **Keys** |
| channel_daily_key | BIGINT | Surrogate key (IDENTITY) |
| channel_key | BIGINT | FK to dim_channel |
| date_key | INT | FK to SHOPIFY_DWH.dim_date |
| **Volume Metrics** |
| vouchers_created | INT | New vouchers created this day |
| vouchers_distributed | INT | Vouchers distributed this day |
| vouchers_redeemed | INT | Vouchers redeemed this day |
| vouchers_expired | INT | Vouchers that expired this day |
| **Financial Metrics** |
| face_value_created | DECIMAL(18,2) | Total face value of vouchers created |
| face_value_distributed | DECIMAL(18,2) | Total face value distributed |
| face_value_redeemed | DECIMAL(18,2) | Face value of redeemed vouchers |
| redemption_order_revenue | DECIMAL(18,2) | Total order revenue from redemptions |
| additional_spend_total | DECIMAL(18,2) | Spend beyond voucher value (upsell indicator) |
| **Running Totals** |
| cumulative_created | INT | Running total vouchers created |
| cumulative_distributed | INT | Running total vouchers distributed |
| cumulative_redeemed | INT | Running total vouchers redeemed |
| outstanding_distributed | INT | Distributed but not yet redeemed (liability) |
| **Rates** |
| distribution_rate | DECIMAL(5,2) | cumulative_distributed / cumulative_created * 100 |
| redemption_rate | DECIMAL(5,2) | cumulative_redeemed / cumulative_distributed * 100 |
| **Denormalized** |
| channel_name | VARCHAR(255) | Channel name for quick reporting |
| **ETL** |
| _loaded_at | TIMESTAMP | Load timestamp |

### Running Total Calculation

```sql
-- Example: cumulative_created for channel X on date D
cumulative_created = SUM(vouchers_created)
  OVER (PARTITION BY channel_key ORDER BY date_key
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- outstanding_distributed (voucher liability)
outstanding_distributed = cumulative_distributed - cumulative_redeemed
```

### Sample Dashboard Queries

```sql
-- Channel performance summary (current month)
SELECT
  channel_name,
  SUM(vouchers_created) as created,
  SUM(vouchers_distributed) as distributed,
  SUM(vouchers_redeemed) as redeemed,
  SUM(face_value_redeemed) as value_redeemed,
  SUM(additional_spend_total) as upsell,
  MAX(redemption_rate) as current_redemption_rate
FROM DYT_DWH.fact_channel_daily fcd
JOIN SHOPIFY_DWH.dim_date d ON fcd.date_key = d.date_key
WHERE d.year = 2026 AND d.month = 2
GROUP BY channel_name
ORDER BY value_redeemed DESC;

-- Outstanding voucher liability by channel
SELECT
  channel_name,
  MAX(outstanding_distributed) as outstanding_vouchers,
  -- Estimate liability: outstanding * avg face value
  MAX(outstanding_distributed) * AVG(face_value_distributed / NULLIF(vouchers_distributed, 0)) as estimated_liability
FROM DYT_DWH.fact_channel_daily
WHERE date_key = (SELECT MAX(date_key) FROM DYT_DWH.fact_channel_daily)
GROUP BY channel_name;
```

---

# DATA FLOW

## Complete Data Flow Diagram

```
SQL Server (Azure)                          Shopify (Already in Layer 1)
===================                         ============================

Channel master ──────► DYT_STG.stg_channels

Voucher records ─────► DYT_STG.stg_voucher_inventory         SHOPIFY_STG.stg_discount_codes
                                                               SHOPIFY_STG.stg_gift_cards (NEW)

Distribution log ────► DYT_STG.stg_voucher_distributions     SHOPIFY_STG.stg_orders
                                                               SHOPIFY_STG.stg_order_discount_applications
                                                               SHOPIFY_STG.stg_order_transactions

                              │                                         │
                              ▼                                         ▼
                    ┌─────────────────────────────────────────────────────┐
                    │           DYT_DWH (Transform & Join)               │
                    │                                                     │
                    │  Join key: voucher_code                             │
                    │  SQL Server voucher_code ←→ Shopify discount code  │
                    │  SQL Server voucher_code ←→ Shopify gift card code │
                    │                                                     │
                    │  dim_channel ◄── stg_channels                      │
                    │  dim_voucher ◄── stg_voucher_inventory             │
                    │                  + stg_voucher_distributions        │
                    │                  + Shopify redemption data          │
                    │  fact_voucher_lifecycle ◄── All sources joined      │
                    │  fact_channel_daily ◄── Aggregation                 │
                    └─────────────────────────────────────────────────────┘
```

## ETL Dependency Order

```
Phase 1: Load DYT_STG (from SQL Server)
  1. stg_channels
  2. stg_voucher_inventory
  3. stg_voucher_distributions

Phase 2: Build DYT_DWH dimensions
  4. dim_channel ← stg_channels
  5. dim_voucher ← stg_voucher_inventory
                   + stg_voucher_distributions
                   + SHOPIFY_STG.stg_order_discount_applications
                   + SHOPIFY_STG.stg_gift_cards
                   + SHOPIFY_STG.stg_order_transactions
                   + SHOPIFY_DWH.dim_discount

Phase 3: Build DYT_DWH facts
  6. fact_voucher_lifecycle ← dim_voucher + dim_channel
                              + SHOPIFY_DWH.fact_order
                              + SHOPIFY_DWH.dim_date
                              + SHOPIFY_DWH.dim_product
  7. fact_channel_daily ← fact_voucher_lifecycle (aggregation)
```

---

# JOIN STRATEGY

The **voucher code** is the bridge between SQL Server and Shopify. The join approach differs between discount codes and gift cards.

## Discount Codes (Simple Join)

```sql
-- Discount code redemption join
SELECT
  vi.voucher_code,
  vi.channel_id,
  oda.order_id,
  o.total_price as order_total
FROM DYT_STG.stg_voucher_inventory vi
JOIN SHOPIFY_STG.stg_order_discount_applications oda
  ON vi.voucher_code = oda.code
JOIN SHOPIFY_STG.stg_orders o
  ON oda.order_id = o.id
WHERE vi.voucher_type = 'discount_code'
```

**Confidence: HIGH** - Direct string match on voucher code.

## Gift Cards (Complex Join - Multiple Options)

Shopify masks gift card codes (only last 4 chars via API). Three potential join strategies:

### Option A: Join via Shopify GID (Preferred)

```sql
-- If SQL Server stores the Shopify gift card GID
SELECT
  vi.voucher_code,
  vi.channel_id,
  gc.id as shopify_gift_card_id,
  gc.balance,
  gc.initial_value
FROM DYT_STG.stg_voucher_inventory vi
JOIN SHOPIFY_STG.stg_gift_cards gc
  ON vi.shopify_id = gc.id
WHERE vi.voucher_type = 'gift_card'
```

**Confidence: MEDIUM** - Depends on SQL Server storing the Shopify GID at creation time.

### Option B: Join via Transaction Records

```sql
-- Gift card payments appear as transactions with gateway = 'gift_card'
SELECT
  vi.voucher_code,
  vi.channel_id,
  ot.order_id,
  ot.amount as gift_card_amount_used
FROM DYT_STG.stg_voucher_inventory vi
JOIN SHOPIFY_STG.stg_gift_cards gc
  ON vi.shopify_id = gc.id
JOIN SHOPIFY_STG.stg_order_transactions ot
  ON ot.gateway = 'gift_card'
  AND ot.kind = 'SALE'
  AND ot.status = 'SUCCESS'
  -- Additional matching logic needed here
WHERE vi.voucher_type = 'gift_card'
```

**Confidence: LOW** - Transaction records don't directly link to specific gift card IDs. Needs investigation.

### Option C: Last 4 Characters + Shopify ID Cross-Reference

```sql
-- Use last 4 chars as validation, Shopify ID as primary join
SELECT
  vi.voucher_code,
  vi.channel_id,
  gc.id as shopify_gift_card_id,
  RIGHT(vi.voucher_code, 4) as code_last4,
  gc.code as shopify_last4
FROM DYT_STG.stg_voucher_inventory vi
JOIN SHOPIFY_STG.stg_gift_cards gc
  ON vi.shopify_id = gc.id
  AND RIGHT(vi.voucher_code, 4) = gc.code  -- Validation check
WHERE vi.voucher_type = 'gift_card'
```

**Confidence: MEDIUM** - Good for data quality validation even if Option A is primary.

### Gift Card Join Decision

**Recommended approach:** Option A (Shopify GID) as primary, with Option C (last 4 chars) as validation. Must confirm that SQL Server records the Shopify GID when gift cards are created.

**Action required:** Inspect SQL Server schema to confirm `shopify_id` field exists and is populated for gift cards.

---

# KEY DESIGN DECISIONS

## 1. Separate Schemas (DYT_STG / DYT_DWH)

**Decision:** Layer 2 uses its own schemas, not modifying Layer 1.

**Reasoning:**
- Keeps Layer 1 clean and portable (can be deployed to any Shopify store)
- Clear boundary between generic and custom
- DYT-specific ETL can be developed and deployed independently
- If Layer 1 is productized, Layer 2 doesn't ship with it

## 2. dim_voucher as Central Dimension

**Decision:** Unify gift cards and discount codes into a single dimension with channel ownership.

**Reasoning:**
- From a business perspective, both are "vouchers" regardless of Shopify implementation
- Channel managers don't care about Shopify's internal distinction
- Enables "all vouchers for Channel X" queries without UNION
- Distribution and redemption attributes apply to both types

## 3. fact_voucher_lifecycle at Voucher Grain

**Decision:** One row per voucher code, tracking the full lifecycle.

**Reasoning:**
- Each voucher code is used exactly once (single-use)
- Natural grain matches the business process
- Enables lifecycle funnel analysis: created → distributed → redeemed
- Timing metrics (days to distribute, days to redeem) are per-voucher

## 4. fact_channel_daily Pre-Aggregated

**Decision:** Maintain a pre-aggregated daily channel fact for dashboard performance.

**Reasoning:**
- Primary analytics question is "how is Channel X performing?"
- Running totals (cumulative created/distributed/redeemed) are expensive to compute on the fly
- Outstanding voucher liability is a key financial metric
- Dashboard queries hit this table directly without scanning full lifecycle table

## 5. Channel-Centric Analytics Lens

**Decision:** All DYT Layer 2 tables are designed around the channel as the primary dimension.

**Reasoning:**
- B2B2C model: channels are the customers (not end consumers)
- Revenue attribution is to channels, not individuals
- Contract management requires channel-level reporting
- Subscription tracking is per channel

## 6. Illustrative Column Names (STG)

**Decision:** DYT_STG column names are illustrative and must be confirmed.

**Reasoning:**
- SQL Server schema has not been inspected yet
- Schema design captures the conceptual model correctly
- Column names will be updated to match actual source when confirmed
- No impact on DWH design (transformation logic adapts)

---

# DYT-SPECIFIC METRICS

## Voucher Funnel Metrics

| # | Metric | Formula | DWH Source |
|---|--------|---------|------------|
| 1 | **Vouchers Created** | COUNT(*) | fact_voucher_lifecycle |
| 2 | **Vouchers Distributed** | COUNT(*) WHERE is_distributed = TRUE | fact_voucher_lifecycle |
| 3 | **Vouchers Redeemed** | COUNT(*) WHERE is_redeemed = TRUE | fact_voucher_lifecycle |
| 4 | **Vouchers Expired** | COUNT(*) WHERE is_expired = TRUE | fact_voucher_lifecycle |
| 5 | **Distribution Rate** | Distributed / Created * 100 | fact_channel_daily.distribution_rate |
| 6 | **Redemption Rate** | Redeemed / Distributed * 100 | fact_channel_daily.redemption_rate |
| 7 | **Outstanding Vouchers** | Distributed - Redeemed | fact_channel_daily.outstanding_distributed |

## Channel Financial Metrics

| # | Metric | Formula | DWH Source |
|---|--------|---------|------------|
| 8 | **Face Value Distributed** | SUM(face_value) WHERE is_distributed | fact_voucher_lifecycle |
| 9 | **Face Value Redeemed** | SUM(face_value) WHERE is_redeemed | fact_voucher_lifecycle |
| 10 | **Redemption Order Revenue** | SUM(redemption_order_total) | fact_voucher_lifecycle |
| 11 | **Additional Spend (Upsell)** | SUM(additional_spend) | fact_voucher_lifecycle |
| 12 | **Upsell Rate** | Additional Spend / Face Value Redeemed * 100 | Derived |
| 13 | **Outstanding Liability** | Outstanding * Avg Face Value | fact_channel_daily |

## Timing Metrics

| # | Metric | Formula | DWH Source |
|---|--------|---------|------------|
| 14 | **Avg Days in Inventory** | AVG(days_creation_to_distribution) | fact_voucher_lifecycle |
| 15 | **Avg Days to Redeem** | AVG(days_distribution_to_redemption) | fact_voucher_lifecycle |
| 16 | **Avg Total Lifecycle** | AVG(days_creation_to_redemption) | fact_voucher_lifecycle |

## Subscription Metrics

| # | Metric | Formula | DWH Source |
|---|--------|---------|------------|
| 17 | **Subscription Vouchers** | COUNT(*) WHERE is_subscription = TRUE | fact_voucher_lifecycle |
| 18 | **Subscription Redemption Rate** | Redeemed / Distributed WHERE is_subscription | fact_voucher_lifecycle |
| 19 | **Avg Subscription Tenure** | MAX(subscription_month) per channel | fact_voucher_lifecycle |

## Distribution Method Metrics

| # | Metric | Formula | DWH Source |
|---|--------|---------|------------|
| 20 | **SMS Distribution Count** | COUNT(*) WHERE distribution_method = 'sms_dyt' | dim_voucher |
| 21 | **Direct Distribution Count** | COUNT(*) WHERE distribution_method = 'direct_channel' | dim_voucher |
| 22 | **SMS Delivery Rate** | delivered / total SMS * 100 | stg_voucher_distributions |

---

# SCHEMA SUMMARY

## Table Counts

| Schema | Table | Type | Columns | Description |
|--------|-------|------|---------|-------------|
| DYT_STG | stg_channels | Staging | ~9 | Channel master data |
| DYT_STG | stg_voucher_inventory | Staging | ~11 | Voucher creation and allocation |
| DYT_STG | stg_voucher_distributions | Staging | ~12 | Distribution instructions and SMS delivery |
| DYT_DWH | dim_channel | Dimension | ~8 | Channel dimension |
| DYT_DWH | dim_voucher | Dimension | ~22 | Central voucher dimension (unified gift cards + discount codes) |
| DYT_DWH | fact_voucher_lifecycle | Fact | ~26 | Full voucher lifecycle (one row per code) |
| DYT_DWH | fact_channel_daily | Fact | ~18 | Pre-aggregated channel daily metrics |

**Total: 7 tables (3 STG + 2 dimensions + 2 facts)**

## Layer 1 Dependencies

| Layer 1 Table | Used By | Purpose |
|---------------|---------|---------|
| SHOPIFY_STG.stg_order_discount_applications | dim_voucher, fact_voucher_lifecycle | Discount code redemption matching |
| SHOPIFY_STG.stg_gift_cards | dim_voucher | Gift card data and Shopify GID join |
| SHOPIFY_STG.stg_order_transactions | dim_voucher, fact_voucher_lifecycle | Gift card payment detection |
| SHOPIFY_DWH.fact_order | fact_voucher_lifecycle | Redemption order financials |
| SHOPIFY_DWH.dim_discount | dim_voucher | Discount code master data lookup |
| SHOPIFY_DWH.dim_date | fact_voucher_lifecycle, fact_channel_daily | Conformed date dimension |
| SHOPIFY_DWH.dim_product | fact_voucher_lifecycle | Product redeemed |

## Cross-Layer Join Map

```
DYT_STG.stg_voucher_inventory
  │
  ├──► voucher_code ──────► SHOPIFY_STG.stg_order_discount_applications.code
  │                          (discount code redemptions)
  │
  ├──► shopify_id ────────► SHOPIFY_STG.stg_gift_cards.id
  │                          (gift card data)
  │
  ├──► channel_id ────────► DYT_STG.stg_channels.channel_id
  │                          (channel ownership)
  │
  └──► voucher_id ────────► DYT_STG.stg_voucher_distributions.voucher_id
                             (distribution records)
```

---

# OPEN ITEMS

Items to resolve before implementation:

1. **Inspect SQL Server schema** - Confirm actual table and column names for DYT_STG
2. **Validate gift card join strategy** - Confirm that `shopify_id` is stored and populated in SQL Server for gift cards
3. **Gift card redemption tracking** - Determine best approach to detect which order redeemed a specific gift card
4. **DYT-specific metrics definitions** - Pending report descriptions from Dominic to refine metric list
5. **Subscription model details** - Confirm how subscription months are tracked and whether subscription_month resets per contract
6. **Productization assessment** - Evaluate which Layer 2 elements could be generalized for the core product (e.g., channel/partner attribution pattern)
7. **SMS delivery tracking** - Confirm whether SMS delivery status is reliably tracked in SQL Server
8. **Voucher expiry logic** - Confirm how expiry dates are managed (in Shopify, SQL Server, or both)
