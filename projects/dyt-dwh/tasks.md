# Tasks

**Project:** DYT DWH
**Last Updated:** 2026-05-15

---

## Urgent (Due Today)

---

## High Priority

(none — design phase complete, ready for ETL implementation)

---

## Normal

### Schema & Design
- [ ] Confirm with team: are both refund patterns in CampaignSegmentTbl still in use or is one legacy?
  Priority: NORMAL | Added: 2026-03-06
- [ ] Verify DYTSquad25, GETDRESSED, THANKYOU100 are customer tags in Shopify (during ETL build)
  Priority: NORMAL | Added: 2026-03-06
- [ ] Validate gift card join strategy with real data (Shopify GID vs last 4 chars)
  Priority: NORMAL | Added: 2026-03-06
- [ ] Assess which DYT elements could be productised for the core Shopify DWH
  Priority: NORMAL | Added: 2026-03-06

### ETL Implementation
- [ ] Set up SQL Server connection and extraction for DYT_STG
  Priority: NORMAL | Added: 2026-03-06
- [ ] Build DYT_STG loaders:
  - [ ] stg_channels (from SQL Server)
  - [ ] stg_voucher_inventory (from SQL Server)
  - [ ] stg_voucher_distributions (from SQL Server)
  Priority: NORMAL | Added: 2026-03-06
- [ ] Build DYT_DWH transforms:
  - [ ] dim_channel <- stg_channels
  - [ ] dim_voucher <- stg_voucher_inventory + distributions + Shopify data
  - [ ] fact_voucher_lifecycle <- all sources joined
  - [ ] fact_channel_daily <- aggregation of fact_voucher_lifecycle
  Priority: NORMAL | Added: 2026-03-06
- [ ] Build ref_commission_rate loader (from Finance spreadsheet CSV/Excel)
  Priority: NORMAL | Added: 2026-03-06

### Deferred (handle during ETL build)
- [ ] Promotional pricing (Reports 30/32) — may use Shopify compare_at_price
  Priority: LOW | Added: 2026-03-06
- [ ] Customer_Type classification (Report 25)
  Priority: LOW | Added: 2026-03-06

---

## Backlog

---

## Blocked

---

## Completed

### Week of 2026-05-11

- [x] Update schema design with confirmed findings from report mapping
  Priority: HIGH | Added: 2026-03-06 | Completed: 2026-05-15
  **Audit result:** 6 of 8 items were already in design.md from prior work.
  **New additions:**
  - `membership_tier` column on Layer 1 `dim_customer` (derived from `tags` at load time; SB-Gold/Silver/Platinum mapping documented)
  - `DYT_DWH.v_dyt_order_payment_split` view (gc/discount/cash split for Reports 8, 9, 14, 15)
  **Decisions:**
  - Membership tier derived at load time, raw `tags` retained (mapping is config-driven, extensible)
  - Payment split lives as a DYT_DWH view, not Layer 1 columns (keeps Layer 1 productisable)
  **Doc:** design.md bumped to v2.1

### Week of 2026-03-03

- [x] Resolve open questions from report mapping analysis (Q4, Q6, promo pricing, customer_type)
  Priority: HIGH | Added: 2026-03-06 | Completed: 2026-03-06
  Q4 Billing: Finance spreadsheet -> ref_commission_rate table
  Q6 Membership: Customer tags in Shopify -> membership_tier on dim_customer
  Promo Pricing + Customer_Type: Deferred to ETL build

- [x] Create dyt-dwh project with consolidated documentation
  Priority: HIGH | Added: 2026-03-06 | Completed: 2026-03-06
