# Tasks

**Project:** DYT DWH
**Last Updated:** 2026-03-06

---

## Urgent (Due Today)

---

## High Priority

- [ ] Update schema design with confirmed findings from report mapping
  Priority: HIGH | Added: 2026-03-06 | Est: 2h
  Items: ref_commission_rate table, membership_tier on dim_customer, campaign_name + subscription parsing on dim_voucher, is_marketing flag, breakage metrics, overspend rename, is_dual_redemption flag, payment type split view

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

### Week of 2026-03-03

- [x] Resolve open questions from report mapping analysis (Q4, Q6, promo pricing, customer_type)
  Priority: HIGH | Added: 2026-03-06 | Completed: 2026-03-06
  Q4 Billing: Finance spreadsheet -> ref_commission_rate table
  Q6 Membership: Customer tags in Shopify -> membership_tier on dim_customer
  Promo Pricing + Customer_Type: Deferred to ETL build

- [x] Create dyt-dwh project with consolidated documentation
  Priority: HIGH | Added: 2026-03-06 | Completed: 2026-03-06
