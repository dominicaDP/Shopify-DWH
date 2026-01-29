# Notes

**Project:** Shopify DWH Research
**Last Updated:** 2026-01-29

---

## Research Log

### 2026-01-29 - Project Setup & Business Context

**Topic:** Dress Your Tech Business Model

**Key Understanding:**
- B2B2C model, NOT traditional ecommerce
- Primary revenue: voucher-based value-added products
- Corporate clients (e.g., telecoms) attach vouchers to their products
- End consumers redeem vouchers on Dress Your Tech
- Gamatek handles fulfillment

**Data Flow:**
```
Corporate Client → Issues Voucher → Consumer → Redeems on DYT → Order → Gamatek Fulfills
```

**Implications for DWH:**
- Need to track voucher issuance (from where?)
- Track redemption (Shopify orders with discount codes?)
- Attribution back to corporate clients
- Standard ecommerce metrics (AOV, conversion) less relevant

**Open Questions:**
- How are vouchers issued and tracked?
- What data comes from Shopify vs. other systems?
- How to identify which corporate client a redemption belongs to?

---

### 2026-01-29 - Second Brain Setup

**Topic:** Knowledge Management System

**What I learned:**
- Three-layer architecture: Commands → Skills → Memory
- Progressive disclosure pattern for managing complexity
- Pattern confidence levels (LOW → MEDIUM → HIGH)

**Key Commands:**
- `/overview` - Daily dashboard
- `/switch [project]` - Context switching
- `/learn` - Extract patterns from work
- `/recall [topic]` - Search memory
- `/grow` - Brain health metrics

---

### 2026-01-29 - Competitive Landscape Research

**Topic:** Shopify Analytics & DWH Market

#### Market Segments

| Layer | What It Does | Examples |
|-------|--------------|----------|
| ETL/ELT Tools | Move data from Shopify → Warehouse | Fivetran, Airbyte, Stitch, Skyvia |
| Pre-built Data Models | Transform raw data into analytics-ready schema | Fivetran dbt packages, dlt-hub |
| Analytics Platforms | End-user dashboards and reporting | Triple Whale, Polar Analytics, Lifetimely |

#### ETL/ELT Tools

| Tool | Type | Pricing | Notes |
|------|------|---------|-------|
| Fivetran | Managed SaaS | Free tier (500k rows), Enterprise $10k+/mo | Market leader. 2025 pricing changes increased costs 40-70%. |
| Airbyte | Open-source + Cloud | Self-hosted free, Cloud ~$2.50/credit | 550+ connectors. More technical effort required. |
| Stitch | Managed SaaS | Volume-based | Owned by Talend. High-speed processing. |
| Panoply | ETL + Warehouse | SaaS pricing | Includes built-in warehouse. |
| Skyvia | Cloud platform | Tiered | Supports reverse ETL. |

#### Pre-built Data Models (dbt)

| Source | What It Provides |
|--------|------------------|
| Fivetran Shopify dbt | Source models, transform models, `shopify__line_item_enhanced` fact table |
| Fivetran Holistic | Combines Shopify with Klaviyo for marketing attribution |
| dlt-hub Shopify dbt | Staging + mart models (dimensions/facts) |

**Key insight:** Fivetran's model uses denormalized `line_item_enhanced` - similar to our approach.

#### Analytics Platforms

| Platform | Focus | Pricing | Target |
|----------|-------|---------|--------|
| Triple Whale | Attribution, first-party pixel, LTV | ~$429/mo for $1M GMV | DTC brands, agencies |
| Polar Analytics | BI tool, custom metrics | ~$720/mo+ | Data-savvy teams |
| Lifetimely | Customer LTV, cohort analysis | Lower tier | Retention-focused |
| BeProfit | Profit tracking | Budget-friendly | Small merchants |

#### Gap Analysis

| Gap | Opportunity |
|-----|-------------|
| Exasol not supported | Most tools target Snowflake/BigQuery/Redshift. Exasol = differentiation. |
| Expensive at scale | Fivetran pricing jumps significantly. Lower-cost alternative could win mid-market. |
| Generic, not customizable | Pre-built models are opinionated. Modular, extensible base appeals to technical teams. |
| No B2B2C focus | All solutions assume B2C. Voucher/corporate attribution unaddressed. |
| Bundled solutions | ETL, models, warehouse often sold separately. All-in-one could simplify. |

#### Recommended Positioning

1. **Exasol-native** - First Shopify DWH optimized for Exasol (genuine differentiation)
2. **Generic base** - Productizable foundation (what we're building)
3. **B2B2C/voucher module** - DYT-specific layer proves extensibility
4. **Price below Fivetran + analytics bundles** - Mid-market appeal

#### Sources

- https://www.fivetran.com/connectors/shopify
- https://airbyte.com/top-etl-tools-for-sources/shopify
- https://fivetran.com/docs/transformations/data-models/shopify-data-model
- https://github.com/dlt-hub/dlt-dbt-shopify
- https://www.polaranalytics.com/compare/triplewhale-alternative-for-shopify
- https://reportgenix.com/top-10-shopify-analytics-apps/

---

## Shopify Data Notes

<!-- Capture Shopify-specific findings here -->

### Key Entities to Research
- Orders (redemptions)
- Products (mobile accessories)
- Customers (end consumers)
- Discount Codes (vouchers)
- Metafields (custom data?)

### API Considerations
- REST API vs GraphQL
- Rate limits
- Historical data access

---

## Code Snippets

<!-- Add useful code snippets here with context -->

### Template
```
### [Snippet Name]

**Language:**
**Use Case:**
**Source:**

\```[language]
// code
\```

**Notes:**
```

---

## Research Topics

### Active
- [ ] Voucher/discount code tracking in Shopify
- [ ] Exasol-specific optimizations

### Completed
- [x] Initial system setup
- [x] Business context documentation
- [x] Data modeling approach (star schema selected)
- [x] Shopify Orders data model mapping
- [x] DWH schema design (facts + dimensions)
- [x] Competitive landscape research

### Future
- [ ] ETL tool evaluation (Airbyte vs custom)
- [ ] BI platform selection
- [ ] Data quality monitoring

---

## Ideas & Future Improvements

- [ ] Create Shopify API query templates
- [ ] Build voucher lifecycle tracking dashboard
- [ ] Develop corporate client attribution logic

---

## External References

- **Shopify API Docs:** https://shopify.dev/docs/api
- **Shopify Admin API:** https://shopify.dev/docs/api/admin
- **Second Brain system:** See CLAUDE.md

---

## Quick Capture

<!-- Use this section for quick notes during research sessions -->
<!-- Move organized content to appropriate sections above -->
