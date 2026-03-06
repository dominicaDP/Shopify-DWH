# DYT DWH — Consolidated Design

**Version:** 2.0
**Last Updated:** 2026-03-06
**Status:** Design complete, pending schema update with resolved findings

This is the single source of truth for the DYT-specific data warehouse design. It consolidates the schema design, report mapping analysis, and all resolved questions into one document.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Staging Schema (DYT_STG)](#dyt-staging-schema-dyt_stg)
3. [Warehouse Schema (DYT_DWH)](#dyt-data-warehouse-schema-dyt_dwh)
4. [Reference Tables](#reference-tables)
5. [Report Coverage](#report-coverage)
6. [CampaignSegmentTbl Analysis](#campaignsegmenttbl-analysis)
7. [Resolved Design Questions](#resolved-design-questions)
8. [Data Flow & Join Strategy](#data-flow--join-strategy)
9. [Metrics](#dyt-specific-metrics)
10. [Open Items](#open-items)

---

# Architecture Overview

```
SQL Server (Azure)                          Shopify (Layer 1 - Read Only)
===================                         ============================

Channel master -------> DYT_STG.stg_channels

Voucher records ------> DYT_STG.stg_voucher_inventory     SHOPIFY_STG.stg_discount_codes
                                                            SHOPIFY_STG.stg_gift_cards

Distribution log -----> DYT_STG.stg_voucher_distributions  SHOPIFY_STG.stg_orders
                                                            SHOPIFY_STG.stg_order_discount_applications
                                                            SHOPIFY_STG.stg_order_transactions
                                                            SHOPIFY_STG.stg_customers (tags)

Finance Spreadsheet --> DYT_DWH.ref_commission_rate

                              |                                         |
                              v                                         v
                    +-----------------------------------------------------------+
                    |           DYT_DWH (Transform & Join)                      |
                    |                                                            |
                    |  Join key: voucher_code                                    |
                    |                                                            |
                    |  dim_channel     <-- stg_channels                         |
                    |  dim_voucher     <-- stg_voucher_inventory                |
                    |                      + stg_voucher_distributions           |
                    |                      + Shopify redemption data             |
                    |  fact_voucher_lifecycle <-- All sources joined             |
                    |  fact_channel_daily     <-- Aggregation                    |
                    |  ref_commission_rate    <-- Finance spreadsheet            |
                    +-----------------------------------------------------------+
```

**Key principle:** DYT DWH uses separate schemas (DYT_STG, DYT_DWH) and **never modifies** Layer 1.

---

# DYT STAGING SCHEMA (DYT_STG)

Source: SQL Server (Azure). CampaignSegmentTbl is the **only** DYT-specific table — all other SQL Server tables are Fivetran mirrors of Shopify data (which Layer 1 already covers).

**Note:** Column names are illustrative. Actual names to be confirmed when SQL Server schema is inspected.

---

## stg_channels

**Source:** SQL Server — Channel/client master table

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

**Source:** SQL Server — Voucher creation and allocation records (maps to CampaignSegmentTbl)

| Column | Type | Description |
|--------|------|-------------|
| voucher_id | VARCHAR(50) | Internal voucher ID |
| voucher_code | VARCHAR(50) | **Full voucher code (the cross-system join key)** |
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

**Source:** SQL Server — Distribution instructions and SMS delivery records

| Column | Type | Description |
|--------|------|-------------|
| distribution_id | VARCHAR(50) | Distribution record ID |
| voucher_id | VARCHAR(50) | FK to stg_voucher_inventory |
| voucher_code | VARCHAR(50) | Voucher code (denormalized) |
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

Central dimension unifying gift cards and discount codes with channel ownership.

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Identity** |
| voucher_key | BIGINT | IDENTITY (0 = Unknown) | Surrogate key |
| voucher_code | VARCHAR(50) | stg_voucher_inventory.voucher_code | The code (primary join key) |
| voucher_type | VARCHAR(20) | stg_voucher_inventory.voucher_type | 'gift_card' or 'discount_code' |
| channel_key | BIGINT | channel_id -> dim_channel lookup | FK to dim_channel |
| **Campaign Attributes** |
| campaign_name | VARCHAR(255) | CampaignSegmentTbl.Campaign | Sub-classification within channel (too varied for dimension) |
| subscription_discount_pct | DECIMAL(5,2) | Parsed from campaign_name | Subscription discount % (e.g. 25, 50) |
| subscription_term_months | INT | Parsed from campaign_name | Subscription term (e.g. 24, 36) |
| is_marketing | BOOLEAN | Client = 'Marketing' in source | Internal/promotional voucher flag |
| **Value** |
| face_value | DECIMAL(18,2) | stg_voucher_inventory.face_value | Original voucher value |
| currency_code | VARCHAR(5) | stg_voucher_inventory.currency_code | Currency |
| **Lifecycle** |
| status | VARCHAR(20) | stg_voucher_inventory.status | created / allocated / distributed / redeemed / expired |
| batch_id | VARCHAR(50) | stg_voucher_inventory.batch_id | Creation batch reference |
| created_in_shopify_at | TIMESTAMP | stg_voucher_inventory.created_in_shopify_at | When created in Shopify |
| shopify_discount_key | BIGINT | shopify_id -> Layer 1 dim_discount | FK to Layer 1 dim_discount (if discount code) |
| **Distribution Attributes** |
| is_distributed | BOOLEAN | stg_voucher_distributions record exists | Has been sent to consumer |
| distribution_date | TIMESTAMP | stg_voucher_distributions.distribution_date | When distributed |
| distribution_method | VARCHAR(20) | stg_voucher_distributions.distribution_method | 'sms_dyt' or 'direct_channel' |
| is_subscription | BOOLEAN | stg_voucher_distributions.subscription_flag | Part of a recurring subscription |
| subscription_month | INT | stg_voucher_distributions.subscription_month | Month in subscription sequence |
| **Redemption Attributes (from Shopify)** |
| is_redeemed | BOOLEAN | Matched to Shopify order via code | Used at checkout |
| redemption_date | TIMESTAMP | From Shopify order where code was used | When redeemed |
| redemption_order_id | VARCHAR(50) | From Shopify fact_order | Which Shopify order |
| **Timing Metrics** |
| days_in_inventory | INT | distribution_date - created_in_shopify_at | Days held before distribution |
| days_to_redemption | INT | redemption_date - distribution_date | Days from distribution to use |
| **Denormalized** |
| channel_name | VARCHAR(255) | dim_channel.channel_name | Channel name for quick reporting |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

### Campaign Name Parsing Logic

```sql
-- Extract subscription tier from Campaign name
-- Pattern: 'Subscription {pct}% {months} Month Virtual'
CASE
  WHEN campaign_name LIKE 'Subscription %'
  THEN CAST(REGEXP_SUBSTR(campaign_name, '(\d+)%', 1, 1, '', 1) AS DECIMAL(5,2))
END AS subscription_discount_pct,

CASE
  WHEN campaign_name LIKE 'Subscription %'
  THEN CAST(REGEXP_SUBSTR(campaign_name, '(\d+) Month', 1, 1, '', 1) AS INT)
END AS subscription_term_months,

-- Marketing flag
CASE WHEN source_client = 'Marketing' THEN TRUE ELSE FALSE END AS is_marketing
```

### Refund Row Normalisation (ETL)

Source data has two inconsistent refund patterns:
- **Pattern A:** `Client = "Refund"`, `Campaign = client name` (e.g. "Telkom")
- **Pattern B:** `Campaign = "Refund"`, `Client = reason` (e.g. "Damaged", "Missing items")

ETL must normalise both into a consistent structure. **Team to confirm** whether both are still in active use or if one is legacy.

---

## fact_voucher_lifecycle

**Source:** stg_voucher_inventory + stg_voucher_distributions + Shopify order data
**Grain:** One row per voucher code

| Column | Type | Source/Transformation | Description |
|--------|------|----------------------|-------------|
| **Keys** |
| voucher_lifecycle_key | BIGINT | IDENTITY | Surrogate key |
| voucher_key | BIGINT | voucher_code -> dim_voucher | FK to dim_voucher |
| channel_key | BIGINT | channel_id -> dim_channel | FK to dim_channel |
| creation_date_key | INT | created_in_shopify_at -> to_date_key() | FK to dim_date |
| distribution_date_key | INT | distribution_date -> to_date_key() | FK to dim_date (NULL if not distributed) |
| redemption_date_key | INT | redemption_date -> to_date_key() | FK to dim_date (NULL if not redeemed) |
| product_key | BIGINT | From redemption order line item | FK to dim_product (NULL if not redeemed) |
| **Identifiers** |
| voucher_code | VARCHAR(50) | stg_voucher_inventory.voucher_code | The voucher code |
| voucher_type | VARCHAR(20) | stg_voucher_inventory.voucher_type | gift_card / discount_code |
| batch_id | VARCHAR(50) | stg_voucher_inventory.batch_id | Creation batch |
| **Lifecycle Status** |
| lifecycle_status | VARCHAR(20) | Derived | created / distributed / redeemed / expired |
| is_distributed | BOOLEAN | Distribution record exists | Distributed flag |
| is_redeemed | BOOLEAN | Matched to Shopify order | Redeemed flag |
| is_expired | BOOLEAN | Past expiry and not redeemed | Expired flag |
| is_dual_redemption | BOOLEAN | Order has both gift card + discount code | Dual redemption flag |
| **Financial** |
| face_value | DECIMAL(18,2) | stg_voucher_inventory.face_value | Original voucher value |
| redemption_order_total | DECIMAL(18,2) | fact_order.total_amount | Total order value at redemption |
| redemption_discount_amount | DECIMAL(18,2) | Discount applied from this code | Amount actually discounted |
| overspend | DECIMAL(18,2) | order_total - discount_amount | Customer spend beyond voucher value |
| breakage_amount | DECIMAL(18,2) | face_value - amount_redeemed (or full face_value if expired) | Unredeemed voucher value |
| **Timing** |
| days_creation_to_distribution | INT | distribution_date - creation_date | Inventory holding time |
| days_distribution_to_redemption | INT | redemption_date - distribution_date | Time to redeem after receiving |
| days_creation_to_redemption | INT | redemption_date - creation_date | Total lifecycle days |
| **Subscription** |
| is_subscription | BOOLEAN | From distribution record | Subscription flag |
| subscription_month | INT | From distribution record | Month in sequence |
| **Denormalized** |
| channel_name | VARCHAR(255) | dim_channel.channel_name | Channel name |
| redemption_order_number | VARCHAR(20) | fact_order.order_number | Order # for lookup |
| _loaded_at | TIMESTAMP | ETL | Load timestamp |

### Key Derivations

```sql
-- lifecycle_status
CASE
  WHEN is_redeemed = TRUE THEN 'redeemed'
  WHEN is_expired = TRUE THEN 'expired'
  WHEN is_distributed = TRUE THEN 'distributed'
  ELSE 'created'
END AS lifecycle_status

-- overspend (business term, not "additional_spend")
-- For discount codes:
overspend = redemption_order_total - redemption_discount_amount
-- For gift cards:
overspend = redemption_order_total - gift_card_amount_used

-- breakage (unredeemed value)
CASE
  WHEN is_expired AND NOT is_redeemed THEN face_value
  WHEN is_redeemed THEN face_value - redemption_discount_amount
  ELSE NULL  -- still active, breakage unknown
END AS breakage_amount

-- is_dual_redemption
-- Order has BOTH gift_card gateway transaction AND discount application
EXISTS(SELECT 1 FROM stg_order_transactions WHERE gateway='gift_card' AND order_id=X)
AND EXISTS(SELECT 1 FROM stg_order_discount_applications WHERE order_id=X)
```

---

## fact_channel_daily

**Source:** Aggregation of fact_voucher_lifecycle + dim_date
**Grain:** One row per channel per day

| Column | Type | Description |
|--------|------|-------------|
| **Keys** |
| channel_daily_key | BIGINT | Surrogate key (IDENTITY) |
| channel_key | BIGINT | FK to dim_channel |
| date_key | INT | FK to dim_date |
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
| overspend_total | DECIMAL(18,2) | Spend beyond voucher value (upsell indicator) |
| breakage_total | DECIMAL(18,2) | Unredeemed value (expired vouchers) |
| **Running Totals** |
| cumulative_created | INT | Running total vouchers created |
| cumulative_distributed | INT | Running total vouchers distributed |
| cumulative_redeemed | INT | Running total vouchers redeemed |
| outstanding_distributed | INT | Distributed but not yet redeemed (liability) |
| **Rates** |
| distribution_rate | DECIMAL(5,2) | cumulative_distributed / cumulative_created * 100 |
| redemption_rate | DECIMAL(5,2) | cumulative_redeemed / cumulative_distributed * 100 |
| **Denormalized** |
| channel_name | VARCHAR(255) | Channel name |
| _loaded_at | TIMESTAMP | Load timestamp |

---

# Reference Tables

## ref_commission_rate

**Source:** Finance-maintained spreadsheet (CSV/Excel upload)
**Purpose:** Enable Report 18 (Provisional Billing) and margin calculations

| Column | Type | Description |
|--------|------|-------------|
| commission_rate_key | BIGINT | Surrogate key (IDENTITY) |
| channel_key | BIGINT | FK to dim_channel |
| rate_type | VARCHAR(50) | e.g. 'commission', 'base_cost' |
| rate_value | DECIMAL(8,4) | Rate as decimal (e.g. 0.15 for 15%) |
| effective_from | DATE | Rate effective start date |
| effective_to | DATE | Rate effective end date (NULL = current) |
| _loaded_at | TIMESTAMP | Load timestamp |

**Margin calculation:** Revenue - (Face Value x Commission Rate)

**Loading:** ETL reads from a designated CSV/Excel file maintained by Finance. SCD Type 2 — new rates create new rows with effective dates, old rows get effective_to populated.

---

# Report Coverage

## Summary (38 existing DYT reports)

| Section | Reports | In Scope | Coverage |
|---------|---------|----------|----------|
| Logistics | 1-6 | No (deferred) | N/A |
| Finance & Exco | 7-18 | Yes | Partial — gaps identified |
| Sales | 19-25 | Yes | Good — core lifecycle covered |
| Product | 26-35 | Yes | Mostly Layer 1 |
| Customer Service | 36 | No (deferred) | N/A |
| Membership | 37 | Yes | Covered — customer tags |
| Client-Specific | 38 | Yes | Covered by fact_channel_daily |

## Well Covered (13 reports)

| Report | # | Maps To |
|--------|---|---------|
| DYT Order Summary | 10 | fact_channel_daily |
| DYT Order Volume (MTD/Summary) | 11, 12 | fact_order + dim_date |
| DYT Orders (Line-Item Level) | 13 | fact_order_line_item |
| DYT Revenue by Client (Exco) | 16 | fact_channel_daily |
| DYT Gift Card Redemptions | 19 | fact_voucher_lifecycle + dim_voucher |
| DYT Redemptions (6 Months Trend) | 21 | fact_voucher_lifecycle + dim_date |
| DYT Redemptions Summary | 22 | fact_voucher_lifecycle aggregated |
| DYT Redemptions (MTD Campaign) | 24 | fact_voucher_lifecycle filtered |
| DYT Virtual Subscription Vouchers | 25 | fact_voucher_lifecycle (subscription fields) |
| Popular/Least Products | 26-29 | fact_order_line_item + dim_product |
| Product Catalogue | 30 | dim_product |
| Product Levels | 31 | fact_inventory_snapshot |
| Teljoy Daily Summary | 38 | fact_channel_daily filtered |

## Partially Covered (8 reports — need enrichment)

| Report | # | Gap | Resolution |
|--------|---|-----|------------|
| DYT Financials (AR and AP) | 7 | Payment ID, Gammatek invoice | Deferred — external data |
| DYT Order Details (MTD) | 8 | Campaign, Breakage, payment split | campaign_name on dim_voucher, breakage metric, payment type view |
| DYT Discount Details | 9 | Voucher Channel, Discount Target, Cash split | dim_voucher.channel_name, payment type view |
| DYT Revenue (Daily Exco) | 14 | Payment type breakdown (GC/Discount/Cash) | DYT order view on Layer 1 |
| DYT Revenue (Exco Summary) | 15 | Same as above, monthly | DYT order view on Layer 1 |
| DYT Provisional Billing | 18 | Voucher base cost, margin | ref_commission_rate table |
| DYT Redemptions (>1 redemption) | 23 | Dual-redemption detection | is_dual_redemption flag |
| DYT Capitec (Skull Candy) | 35 | Client filter on product reports | Cross Layer 1+2 join |

## Gaps Resolved

| Report | # | Original Gap | Resolution |
|--------|---|-------------|------------|
| DYT Revenue by Client (In Process) | 17 | "In Process" status | Filter on Campaign="In Process", Client="Refund" — pending refunds |
| STD Bank Membership Order Summary | 37 | Membership tiers | Customer tags in Shopify -> membership_tier on dim_customer |

## Deferred

| Report | # | Reason |
|--------|---|--------|
| DYT Missing Redemption Info | 20 | Exception/data quality reporting pattern — handle during ETL |
| DYT Promo Pricing | 32 | May use Shopify compare_at_price — verify during ETL build |
| New Product Update Result | 33, 34 | Product lifecycle tracking — Shopify product status (DRAFT/ACTIVE) |

---

# CampaignSegmentTbl Analysis

**Columns:** Segment_ID, Note, Serial, Code, Campaign, Client, Refund_Reason, commission_rate_id

## Client Column = dim_channel

Real business clients (~30+): African Bank, Bettabets, Betway, Blue Label, Capitec, Cell C, Clientele, CMH, DP, Dress Your Tech, EasyPay, eBucks, FNB, Glocell, iTalk, Jackpot City, Melon, Mondo, MTN, Net 1, OnAir, PayJoy, PhoneFast, Platinum Life, Samsung, Smarttrack, Standard Bank, SureX, Teljoy, Telkom, TFG, Unlimited, Vodacom

**Special/system values:**
- `Marketing` — internal/promotional vouchers (~150 sub-campaigns, small quantities)
- `Refund` — refund tracking (Campaign = original client name)
- `B2C` — direct-to-consumer purchases
- `Historical data` — legacy/migrated records
- Refund reasons as Client values (`Damaged`, `Missing items`, etc.) — data quality issue

## Campaign Column = campaign_name on dim_voucher

**Large client examples:**

| Client | Campaign | Voucher Count | Meaning |
|--------|----------|---------------|---------|
| Telkom | Virtual | 109,180 | One-off virtual vouchers |
| Telkom | Subscription 25% 24 Month Virtual | 42,024 | 25% discount, 24-month sub |
| Telkom | Subscription 50% 36 Month Virtual | 15,304 | 50% discount, 36-month sub |
| Blue Label | RCS Subscription Virtual | 134,696 | Subscription program |
| Vodacom | Rewards Co | 44,028 | Rewards program |
| FNB | FNB | 24,399 | Main program |

## Volume by Client (top 10)

| Client | Total Vouchers |
|--------|---------------|
| Telkom | ~244,000 |
| Blue Label | ~138,000 |
| Vodacom | ~116,000 |
| Net 1 | ~25,000 |
| FNB | ~24,400 |
| Cell C | ~23,200 |
| PayJoy | ~15,000 |
| Teljoy | ~12,350 |
| Standard Bank | ~9,560 |
| Marketing | ~1,700 |

---

# Resolved Design Questions

| # | Question | Answer | Schema Impact |
|---|----------|--------|---------------|
| Q1 | Campaign hierarchy | Client = dim_channel, Campaign = VARCHAR attribute | campaign_name on dim_voucher |
| Q2 | Payment type breakdown | Derived from Shopify transactions (gateway type) | DYT order view on Layer 1 |
| Q3 | Breakage amount | Unredeemed gift card value | breakage_amount on fact_voucher_lifecycle |
| Q4 | Billing / margin data | Finance spreadsheets | ref_commission_rate table |
| Q5 | "In Process" status | Pending refunds (Campaign="In Process", Client="Refund") | Filter on dim_voucher |
| Q6 | Membership tiers | Customer tags in Shopify (not discount codes) | membership_tier on dim_customer (Layer 1) |
| Q7 | Dual-redemption | Legitimate but tracked | is_dual_redemption flag |
| Q8 | Overspend naming | Business uses "Overspend" | Renamed from additional_spend |
| Q9 | Payfast vs Payflex | Exco = total Cash; Finance = gateway detail | Reporting/view concern only |
| Q10 | Ebucks | A channel/client like Telkom | Row in dim_channel |
| Q11 | SQL Server platform | Fivetran + CampaignSegmentTbl; we replace it all | No additional SQL Server tables needed |

---

# Data Flow & Join Strategy

## ETL Dependency Order

```
Phase 1: Load DYT_STG (from SQL Server)
  1. stg_channels
  2. stg_voucher_inventory
  3. stg_voucher_distributions

Phase 2: Load Reference Data
  4. ref_commission_rate (from Finance CSV/Excel)

Phase 3: Build DYT_DWH dimensions
  5. dim_channel <- stg_channels
  6. dim_voucher <- stg_voucher_inventory
                    + stg_voucher_distributions
                    + SHOPIFY_STG.stg_order_discount_applications
                    + SHOPIFY_STG.stg_gift_cards
                    + SHOPIFY_STG.stg_order_transactions
                    + SHOPIFY_DWH.dim_discount

Phase 4: Build DYT_DWH facts (requires Layer 1 to be loaded first)
  7. fact_voucher_lifecycle <- dim_voucher + dim_channel
                               + SHOPIFY_DWH.fact_order
                               + SHOPIFY_DWH.dim_date
                               + SHOPIFY_DWH.dim_product
  8. fact_channel_daily <- fact_voucher_lifecycle (aggregation)
```

## Cross-System Join Strategy

### Discount Codes (HIGH confidence — direct string match)

```sql
SELECT vi.voucher_code, vi.channel_id, oda.order_id, o.total_price
FROM DYT_STG.stg_voucher_inventory vi
JOIN SHOPIFY_STG.stg_order_discount_applications oda
  ON vi.voucher_code = oda.code
JOIN SHOPIFY_STG.stg_orders o ON oda.order_id = o.id
WHERE vi.voucher_type = 'discount_code'
```

### Gift Cards (MEDIUM confidence — needs validation)

Shopify masks gift card codes (only last 4 chars via API). **Preferred:** Join via Shopify GID stored in SQL Server.

```sql
SELECT vi.voucher_code, vi.channel_id, gc.balance, gc.initial_value
FROM DYT_STG.stg_voucher_inventory vi
JOIN SHOPIFY_STG.stg_gift_cards gc ON vi.shopify_id = gc.id
WHERE vi.voucher_type = 'gift_card'
```

**Action:** Confirm shopify_id is populated in SQL Server for gift cards.

---

# DYT-Specific Metrics

## Voucher Funnel (7)

| # | Metric | Formula | Source |
|---|--------|---------|--------|
| 1 | Vouchers Created | COUNT(*) | fact_voucher_lifecycle |
| 2 | Vouchers Distributed | COUNT(*) WHERE is_distributed | fact_voucher_lifecycle |
| 3 | Vouchers Redeemed | COUNT(*) WHERE is_redeemed | fact_voucher_lifecycle |
| 4 | Vouchers Expired | COUNT(*) WHERE is_expired | fact_voucher_lifecycle |
| 5 | Distribution Rate | Distributed / Created * 100 | fact_channel_daily |
| 6 | Redemption Rate | Redeemed / Distributed * 100 | fact_channel_daily |
| 7 | Outstanding Vouchers | Distributed - Redeemed | fact_channel_daily |

## Channel Financial (7)

| # | Metric | Formula | Source |
|---|--------|---------|--------|
| 8 | Face Value Distributed | SUM(face_value) WHERE is_distributed | fact_voucher_lifecycle |
| 9 | Face Value Redeemed | SUM(face_value) WHERE is_redeemed | fact_voucher_lifecycle |
| 10 | Redemption Order Revenue | SUM(redemption_order_total) | fact_voucher_lifecycle |
| 11 | Overspend (Upsell) | SUM(overspend) | fact_voucher_lifecycle |
| 12 | Upsell Rate | Overspend / Face Value Redeemed * 100 | Derived |
| 13 | Outstanding Liability | Outstanding * Avg Face Value | fact_channel_daily |
| 14 | Breakage | SUM(breakage_amount) | fact_voucher_lifecycle |

## Timing (3)

| # | Metric | Formula | Source |
|---|--------|---------|--------|
| 15 | Avg Days in Inventory | AVG(days_creation_to_distribution) | fact_voucher_lifecycle |
| 16 | Avg Days to Redeem | AVG(days_distribution_to_redemption) | fact_voucher_lifecycle |
| 17 | Avg Total Lifecycle | AVG(days_creation_to_redemption) | fact_voucher_lifecycle |

## Subscription (3)

| # | Metric | Formula | Source |
|---|--------|---------|--------|
| 18 | Subscription Vouchers | COUNT(*) WHERE is_subscription | fact_voucher_lifecycle |
| 19 | Subscription Redemption Rate | Redeemed / Distributed WHERE is_subscription | fact_voucher_lifecycle |
| 20 | Avg Subscription Tenure | MAX(subscription_month) per channel | fact_voucher_lifecycle |

## Distribution (3)

| # | Metric | Formula | Source |
|---|--------|---------|--------|
| 21 | SMS Distribution Count | COUNT(*) WHERE method = 'sms_dyt' | dim_voucher |
| 22 | Direct Distribution Count | COUNT(*) WHERE method = 'direct_channel' | dim_voucher |
| 23 | SMS Delivery Rate | delivered / total SMS * 100 | stg_voucher_distributions |

## Billing (2 — new, from ref_commission_rate)

| # | Metric | Formula | Source |
|---|--------|---------|--------|
| 24 | Provisional Billing | SUM(face_value * commission_rate) per channel | fact_voucher_lifecycle + ref_commission_rate |
| 25 | Margin | Revenue - Provisional Billing | Derived |

**Total: 25 DYT-specific metrics**

---

# Open Items

## Before Implementation

1. **Inspect SQL Server schema** — Confirm actual table and column names for DYT_STG
2. **Validate gift card join** — Confirm shopify_id is stored and populated for gift cards
3. **Refund patterns** — Team to confirm if both Pattern A and B are still in use (LOW priority, ETL handles both)
4. **Verify customer tags** — Confirm DYTSquad25, GETDRESSED, THANKYOU100 are customer tags in Shopify
5. **Subscription model** — Confirm how subscription months are tracked and whether they reset per contract
6. **SMS delivery tracking** — Confirm reliability of SMS delivery status in SQL Server
7. **Voucher expiry logic** — How are expiry dates managed (Shopify, SQL Server, or both)?

## Deferred to ETL Build

- Promotional pricing (compare_at_price)
- Customer_Type classification
- Exception/data quality reporting (Report 20)
- Product lifecycle tracking (Reports 33-34)

## Schema Summary

| Schema | Table | Type | Description |
|--------|-------|------|-------------|
| DYT_STG | stg_channels | Staging | Channel master data |
| DYT_STG | stg_voucher_inventory | Staging | Voucher creation and allocation |
| DYT_STG | stg_voucher_distributions | Staging | Distribution and SMS delivery |
| DYT_DWH | dim_channel | Dimension | Channel dimension |
| DYT_DWH | dim_voucher | Dimension | Central voucher dimension |
| DYT_DWH | fact_voucher_lifecycle | Fact | Full voucher lifecycle |
| DYT_DWH | fact_channel_daily | Fact | Pre-aggregated channel daily |
| DYT_DWH | ref_commission_rate | Reference | Commission rates from Finance |

**Total: 8 tables (3 STG + 2 dimensions + 2 facts + 1 reference)**
