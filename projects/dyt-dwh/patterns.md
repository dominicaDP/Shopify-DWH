# DYT DWH Patterns

**Last Updated:** 2026-03-06

---

## CampaignSegmentTbl Interpretation

**Confidence: HIGH** (validated against SQL Server data)

- `Client` column = clean business entity dimension (~30+ real clients) -> maps to `dim_channel`
- `Campaign` column = sub-classification within Client -> `campaign_name` VARCHAR on `dim_voucher` (too varied for standalone dimension)
- Subscription tiers encoded in Campaign name: `Subscription {%} {months} Month Virtual` -> parse into structured fields
- `Marketing` Client = internal/promotional vouchers (~150 sub-campaigns, small quantities) -> `is_marketing` flag
- `Refund` tracking uses two inconsistent patterns -> ETL must normalise both

## Commission / Billing Data

**Confidence: HIGH** (confirmed by Dominic 2026-03-06)

- Commission rates managed manually in Finance spreadsheets
- Not in SQL Server or any database
- DWH needs `ref_commission_rate` reference table loaded from CSV/Excel
- Rates are per-client with effective dates (SCD Type 2)

## Membership Tiers

**Confidence: HIGH** (confirmed by Dominic 2026-03-06)

- Standard Bank membership tiers (15%/20%/30%/40%/50%) are **customer-level tags in Shopify**
- NOT discount codes, NOT in CampaignSegmentTbl
- Parse from `stg_customers.tags` -> `membership_tier` on `dim_customer`
- DYTSquad25, GETDRESSED, THANKYOU100 likely also customer tags (verify during ETL)

## Cross-System Join Strategy

**Confidence: MEDIUM** (needs validation with real data)

- `voucher_code` is the bridge between SQL Server and Shopify
- Discount codes: direct string match (HIGH confidence)
- Gift cards: Shopify masks codes (last 4 only) -> join via Shopify GID stored in SQL Server (MEDIUM confidence)
- Business uses "Overspend" not "Additional Spend"
