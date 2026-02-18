# DYT Report Mapping Analysis

**Date:** 2026-02-18 (updated with SQL Server query results)
**Source:** DYT Report mapping.docx (38 reports), CampaignSegmentTbl query results
**Purpose:** Map existing reports against Layer 2 schema, identify gaps and open questions

---

## Report Coverage Summary

| Section | Reports | In Scope | Schema Coverage |
|---------|---------|----------|-----------------|
| Logistics | 1-6 | No (deferred) | N/A |
| Finance & Exco | 7-18 | Yes | Partial - gaps identified |
| Sales | 19-25 | Yes | Good - core lifecycle covered |
| Product | 26-35 | Yes | Mostly Layer 1 |
| Customer Service | 36 | No (deferred) | N/A |
| Membership | 37 | Yes | Gap - membership concept missing |
| Client-Specific | 38 | Yes | Covered by fact_channel_daily |

---

## What Our Schema Already Supports

### Well Covered

| Report | # | Maps To |
|--------|---|---------|
| DYT Order Summary | 10 | fact_channel_daily (orders, revenue by client) |
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

### Partially Covered (need enrichment)

| Report | # | Gap |
|--------|---|-----|
| DYT Financials (AR and AP) | 7 | Missing: Payment ID, Gammatek invoice link |
| DYT Order Details (MTD) | 8 | Missing: Campaign, Breakage Amount, payment gateway split |
| DYT Discount Details (drill-through) | 9 | Missing: Voucher Channel, Discount Target, Cash Amount split |
| DYT Revenue (Daily Exco Summary) | 14 | Missing: Payment type breakdown (GC/Discount/Cash) |
| DYT Revenue (Exco Summary) | 15 | Missing: Same as above, monthly |
| DYT Provisional Billing | 18 | Missing: Voucher base cost, margin calculation |
| DYT Redemptions (>1 redemption) | 23 | Missing: Dual-redemption detection flag |
| DYT Capitec (Skull Candy) | 35 | Need: Client filter on product reports (cross Layer 1+2) |

### Not Covered (new concepts needed)

| Report | # | Missing Concept | Status |
|--------|---|-----------------|--------|
| DYT Revenue by Client (In Process) | 17 | ~~"In Process" lifecycle status~~ | RESOLVED — "In Process" = pending refunds (Campaign="In Process", Client="Refund"). Filter on dim_voucher |
| DYT Missing Redemption Info | 20 | Data quality / exception tracking | Still needed — exception reporting pattern |
| STD Bank Membership Order Summary | 37 | Membership tiers and discount levels | PARTIALLY RESOLVED — tiers likely in Shopify discount code names, verify during ETL build |
| DYT Promo Pricing | 32 | Promotional pricing dimension | Still needed — may use Shopify's compare_at_price |
| New Product Update Result | 33, 34 | Product lifecycle tracking | Still needed — Shopify product status (DRAFT/ACTIVE) |

---

## Questions and Answers

### Q1: Campaign Hierarchy (CRITICAL) - ANSWERED

**Reports affected:** 8, 9, 10, 21, 22, 24, 25

**Question:** What is the relationship between Client, Campaign, and Discount Campaign?

**Answer (from Campaign-Client grouped query):**

**Client is the clean dimension** — these are the actual business clients/channels (~30+ real entities). Campaign is a sub-classification within each Client, representing product lines, programs, or voucher types.

**Real business clients:** African Bank, Bettabets, Betway, Blue Label, Capitec, Cell C, Clientele, CMH, DP, Dress Your Tech, EasyPay, eBucks, FNB, Glocell, iTalk, Jackpot City, Melon, Mondo, MTN, Net 1, OnAir, PayJoy, PhoneFast, Platinum Life, Samsung, Smarttrack, Standard Bank, SureX, Teljoy, Telkom, TFG, Unlimited, Vodacom

**Special/system values in Client column:**
- `Marketing` — internal/promotional vouchers (~150 sub-campaigns, typically small quantities 1-265). Campaign values here are recipient/partner names, not true campaigns. This is the "noise" that made Campaign appear to have 150+ values.
- `Refund` — refund tracking where Campaign = original client name (e.g., Campaign="Telkom", Client="Refund" means a refunded Telkom voucher)
- `B2C` — direct-to-consumer purchases
- `Historical data` — legacy/migrated records
- Refund reasons appearing as Client values (`Damaged`, `Missing items`, `Faulty / Damaged`, etc.) — data quality inconsistency

**Campaign encodes program structure for large clients:**

| Client | Campaign | Voucher Count | Meaning |
|--------|----------|---------------|---------|
| Telkom | Virtual | 109,180 | One-off virtual vouchers |
| Telkom | Subscription 25% 24 Month Virtual | 42,024 | 25% discount, 24-month subscription |
| Telkom | Subscription 25% 36 Month Virtual | 56,940 | 25% discount, 36-month subscription |
| Telkom | Subscription 50% 24 Month Virtual | 16,200 | 50% discount, 24-month subscription |
| Telkom | Subscription 50% 36 Month Virtual | 15,304 | 50% discount, 36-month subscription |
| Blue Label | RCS Subscription Virtual | 134,696 | Subscription program |
| Vodacom | Rewards Co | 44,028 | Rewards program |
| Vodacom | Summer | 14,451 | Seasonal campaign |
| Vodacom | Kicka | 10,000 | Specific promotion |
| FNB | FNB | 24,399 | Main program |
| Net 1 | Net 1 | 24,982 | Main program |

**Key insight:** Subscription tiers are encoded in Campaign name as `Subscription {discount%} {term_months} Month Virtual`. This can be parsed into structured fields.

**Refund data inconsistency:**
- Pattern A: `Client = "Refund"` + `Campaign = client name` → 77 Vodacom refunds, 67 Telkom refunds, etc.
- Pattern B: `Campaign = "Refund"` + `Client = reason` → "Damaged" (1), "Missing items" (64), etc.
- Both patterns exist — needs normalisation in ETL

**Schema impact:**
- **`Client` → maps to `dim_channel`** (the clean business entity dimension)
- **`Campaign` → `campaign_name` VARCHAR on `dim_voucher`** (too varied for a standalone dimension, but essential for filtering/grouping)
- **Parse subscription info** from Campaign name into structured fields on dim_voucher: `subscription_discount_pct`, `subscription_term_months`
- **Add `is_marketing` flag** to distinguish internal/promotional vouchers from real client vouchers
- **Normalise refund rows** — ETL should standardise refund tracking regardless of which pattern was used in source

---

### Q2: Payment Type Revenue Breakdown (CRITICAL) - ANSWERED

**Reports affected:** 8, 9, 14, 15

**Answer:** Derived from Shopify data.
- **Gift Card Spend** = payment transactions where gateway = 'gift_card'
- **Discount Voucher Spend** = discount application amounts
- **Cash Spend** = payment transactions where gateway IN ('payfast', 'payflex', other cash gateways)
- **Cash % of Total** = Cash Spend / Total Revenue * 100

**Schema impact:** Layer 1 already has this data in `stg_order_transactions` (gateway, amount) and `stg_order_discount_applications`. We need a DYT-specific order view or additional columns on fact_order that surface:
- `gift_card_spend` (from transactions where gateway = 'gift_card')
- `discount_voucher_spend` (from discount applications)
- `cash_spend` (from transactions where gateway NOT IN ('gift_card'))
- `cash_pct` (derived)

This is an ORDER-level breakdown, not a voucher-level one. Could be a DYT view on top of Layer 1's fact_order.

---

### Q3: Breakage Amount (HIGH) - ANSWERED

**Reports affected:** 8, 10

**Answer:** Breakage = unredeemed gift card value (the portion that will never be used).

**Schema impact:** Derivable from:
- For individual gift cards: `face_value - amount_redeemed` (remaining balance)
- For expired/unused vouchers: full `face_value`
- Aggregate breakage per channel: SUM of unredeemed value for expired vouchers

Need to add breakage metrics to fact_channel_daily and fact_voucher_lifecycle. Already partially modeled via `is_expired` flag and `face_value`.

---

### Q4: Provisional Billing / Margin Calculation (HIGH) - OPEN (Team Discussion Needed)

**Reports affected:** 18

**Question:** Where does cost data live for voucher base cost, commission rates, and margin calculations?

**Finding:** The `commission_rate_id` field exists in CampaignSegmentTbl but appears to be unpopulated / "To be defined". The SQL Server database is primarily a Fivetran sync of Shopify data plus CampaignSegmentTbl — there are no separate billing or cost tables.

**Status:** OPEN — Billing/cost data does not appear to exist in the current SQL Server database. This may be:
- Managed outside the system (spreadsheets, finance system)
- A new capability that needs to be built into the DWH solution
- Derived from commission_rate_id once that field is populated

**Action needed:** Team to clarify where Report 18 (Provisional Billing) currently sources its cost data. If it's manual/spreadsheet-based, the DWH solution may need to introduce a commission/billing rate table as a new managed input.

**Schema impact (when clarified):**
- If rates are per-client: add commission fields to `dim_channel`
- If rates are per-campaign or per-voucher-type: may need a `dim_billing_rate` or fields on `dim_voucher`
- Margin calculation: Sales Revenue - (Voucher Face Value * Commission Rate)

---

### Q5: "In Process" Status (MEDIUM) - ANSWERED

**Reports affected:** 17

**Answer:** "In Process" appears in CampaignSegmentTbl as `Campaign = "In Process"`, `Client = "Refund"` (10 rows). These are **refunds that haven't been completed yet** — not a general voucher lifecycle status.

**Schema impact:** No special lifecycle status needed. "In Process" rows are part of the refund tracking pattern and can be filtered via Campaign + Client fields on dim_voucher. Report 17 ("Revenue by Client - In Process") likely shows vouchers in this state.

---

### Q6: Membership Tiers (MEDIUM) - PARTIALLY ANSWERED

**Reports affected:** 37

**Finding from CampaignSegmentTbl query:**

Standard Bank has these Campaign values:
| Campaign | Voucher Count |
|----------|---------------|
| Virtual | 9,138 |
| Migration Virtual | 417 |
| Membership | 6 |
| O Week Activation | 1 |

Only 6 rows are tagged "Membership". The membership tiers referenced in Report 37 (DYTSquad25, GETDRESSED, Standard Bank 15%/20%/30%/40%/50%, THANKYOU100) are **not visible in CampaignSegmentTbl Campaign names**.

**Status:** PARTIALLY OPEN — Membership tier names likely come from **Shopify discount code names** rather than CampaignSegmentTbl. The tiers probably map to specific discount codes created in Shopify with names like "DYTSquad25", "GETDRESSED", etc. This can be verified during ETL build when we have access to the actual Shopify discount code data.

**Schema impact:** Membership tiers can likely be derived from the discount code name in Shopify (`stg_discount_codes.title`). No separate membership dimension needed — the tier is an attribute parseable from the voucher/discount code name, similar to how subscription tiers are encoded in Campaign names for Telkom.

---

### Q7: Dual-Redemption Detection (MEDIUM) - ANSWERED

**Reports affected:** 23

**Answer:** Legitimate but tracked. Orders with both a voucher AND a discount code can happen and are valid, but the business wants visibility.

**Schema impact:** Add `is_dual_redemption` flag to fact_voucher_lifecycle or create as a DYT order-level attribute. Derivable from Layer 1: orders where `stg_order_transactions` has gift_card gateway AND `stg_order_discount_applications` has a code.

---

### Q8: Overspend vs Additional Spend (LOW) - ANSWERED

**Reports affected:** 21

**Answer:** Business uses the term **"Overspend"**, not "Additional Spend".

**Schema impact:** Rename `additional_spend` to `overspend` in DYT_DWH tables for business alignment. Keep `additional_spend` in Layer 1 if it exists there.

---

### Q9: Payfast vs Payflex Classification (LOW) - ANSWERED

**Reports affected:** 8, 14

**Answer:** Exco reports need total Cash Spend only. Finance is more interested in individual payment gateway breakdown.

**Schema impact:**
- Exco view: aggregate all non-gift-card, non-discount payments as "Cash Spend"
- Finance view: use Layer 1's pivoted payment columns (payment_1_gateway, payment_2_gateway) for gateway detail
- No new schema elements needed; this is a reporting/view concern

---

### Q10: Ebucks / Promo Pricing (LOW) - ANSWERED

**Reports affected:** 30, 32

**Answer:** Ebucks is a channel/client (like Telkom, Capitec).

**Schema impact:** Ebucks will be a row in dim_channel. Promo pricing for Ebucks products may be tracked via the Campaign field or Shopify's compare_at_price. Lower priority.

---

### Q11: SQL Server as Current Reporting Platform (LOW) - ANSWERED

**Reports affected:** 31 (and all reports)

**Answer:** Fivetran currently syncs Shopify data to SQL Server. The SQL Server instance has BOTH Shopify data (via Fivetran) AND DYT-specific channel/voucher data (CampaignSegmentTbl). All 38 existing reports run off this SQL Server. Our DWH project replaces this entire setup.

**Schema impact:** Major architectural insight:
- SQL Server is the CURRENT unified reporting database (Shopify via Fivetran + DYT channel data)
- Our Exasol DWH replaces Fivetran + SQL Server reporting layer
- **CampaignSegmentTbl is the only DYT-specific table** in SQL Server — all other tables are Fivetran mirrors of Shopify data (which our Layer 1 schema already covers)
- Fivetran subscription can be cancelled once our custom ETL is running
- No additional SQL Server tables need inspection — CampaignSegmentTbl is fully understood

---

## CampaignSegmentTbl Structure (from SQL Server Query)

The only DYT-specific table in SQL Server. All other tables are Fivetran mirrors of Shopify data.

**Columns:** Segment_ID, Note, Serial, Code, Campaign, Client, Refund_Reason, commission_rate_id

**Row counts by Client (top 10 by volume):**

| Client | Total Vouchers | Key Campaigns |
|--------|---------------|---------------|
| Telkom | ~244,000 | Virtual, Subscription 25%/50% x 24/36 Month |
| Blue Label | ~138,000 | RCS Subscription Virtual (134,696) |
| Vodacom | ~116,000 | Rewards Co (44K), Vodacom (44K), Summer (14K) |
| FNB | ~24,400 | FNB |
| Net 1 | ~25,000 | Net 1 |
| PayJoy | ~15,000 | Virtual |
| Teljoy | ~12,350 | Teljoy (9K), Subscription Virtual (3K) |
| Cell C | ~23,200 | Summer Virtual (15.6K), Cell C (7.5K) |
| Standard Bank | ~9,560 | Virtual (9.1K), Migration Virtual (417) |
| Marketing | ~1,700 | 150+ sub-campaigns (internal/promotional) |

**Client categories:**
- **Real business clients** (~30+): Telkom, Vodacom, FNB, Cell C, Capitec, Standard Bank, etc.
- **Internal/Marketing**: Campaign = partner/recipient name, small quantities
- **Refund tracking**: Dual pattern — Client="Refund" with Campaign=client name, OR Campaign="Refund" with Client=reason
- **System**: B2C, Historical data, NULL values (97 rows)

---

## Concepts Not in Current Schema (Updated)

| Concept | Where It Appears | Resolution | Schema Element |
|---------|-----------------|------------|----------------|
| Campaign (below Client level) | Reports 8-10, 21-25 | RESOLVED — sub-classification within Client | `campaign_name` VARCHAR on dim_voucher |
| Subscription tiers | Reports 21, 24, 25 | RESOLVED — encoded in Campaign name | Parse into `subscription_discount_pct`, `subscription_term_months` on dim_voucher |
| Payment type split (GC/Discount/Cash) | Reports 8, 9, 14, 15 | RESOLVED — from Shopify transaction data | DYT order view on Layer 1's fact_order |
| Breakage | Reports 8, 10 | RESOLVED — unredeemed gift card value | Derived metric on fact_voucher_lifecycle and fact_channel_daily |
| Overspend | Report 21 | RESOLVED — customer spend beyond voucher | Rename `additional_spend` → `overspend` in DYT_DWH |
| Dual-redemption flag | Report 23 | RESOLVED — legitimate but tracked | `is_dual_redemption` flag on fact_voucher_lifecycle |
| Marketing voucher flag | N/A (data quality) | NEW — distinguish internal from client vouchers | `is_marketing` flag on dim_voucher |
| Refund normalisation | N/A (data quality) | NEW — inconsistent refund patterns in source | ETL normalisation logic |
| Voucher base cost / margin | Report 18 | OPEN — source unknown | Team to clarify; may need new billing rate input |
| Membership tiers | Report 37 | PARTIALLY OPEN — likely in Shopify discount code names | Verify during ETL build |
| Promotional pricing | Reports 30, 32 | OPEN — lower priority | May use Shopify compare_at_price |
| Customer_Type | Report 25 | OPEN — lower priority | Classification on dim_voucher |

---

## Open Items for Team Discussion

### 1. Provisional Billing / Margin (Q4) — HIGH PRIORITY
**Report 18** needs voucher base cost, commission rates, and margin calculations. The `commission_rate_id` field in CampaignSegmentTbl is unpopulated. **Where does Report 18 currently get its cost data?** If it's manual/spreadsheet-based, the DWH solution needs a commission rate table as a new managed input.

### 2. Membership Tiers (Q6) — MEDIUM PRIORITY
**Report 37** shows Standard Bank membership tiers (DYTSquad25, GETDRESSED, 15%-50% discount levels). Only 6 rows in CampaignSegmentTbl are tagged "Membership". **Are these tiers defined by Shopify discount code names?** Can be verified during ETL build when we access actual discount code data.

### 3. Refund Data Quality — LOW PRIORITY
CampaignSegmentTbl has two inconsistent patterns for tracking refunds. The ETL will need to normalise this, but the team should confirm whether both patterns are still in use or if one is legacy.

---

## Recommended Next Steps

1. **Team to clarify billing/cost data source** (Q4) — blocks Report 18 schema design
2. **Update Layer 2 schema** (`schema-dyt.md`) with confirmed findings:
   - Add `campaign_name`, subscription parsing fields, `is_marketing` flag to dim_voucher
   - Add breakage metrics to fact tables
   - Rename `additional_spend` → `overspend`
   - Add `is_dual_redemption` flag
   - Add payment type split as DYT order view
3. **Verify membership tiers** during ETL build (check Shopify discount code names)
4. **Generate Word document** for team review
