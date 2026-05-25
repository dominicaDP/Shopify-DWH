# Addendum B — Shopify reporting problems

**Companion to:** [exasol-xperts-narrative.md](exasol-xperts-narrative.md)
**Audience:** Exasol Product & Engineering team
**Last updated:** 2026-05-25

This addendum documents *why* Shopify merchants need a warehouse in the first place — the gaps in native reporting that drove an $85M+ VC dashboard category to fill (incompletely). All claims sourced inline. Structured around what's documented in Shopify's own materials, what merchants say in public, and what implementers hit during a build.

## Native reporting limits by tier

The Shopify Help Center plus Bybtraction's per-tier breakdown give the authoritative picture:

| Tier | Price | Reporting capability |
|---|---|---|
| **Basic** | $39/mo | Dashboard + Live View + finance + basic acquisition. **No sales, customer, or order reports. No custom report creation.** |
| **Shopify** | $105/mo | Adds inventory and behaviour reports |
| **Advanced** | $399/mo | Adds custom report creation, profit reports, ShopifyQL, scheduled exports |
| **Plus** | $2,300+/mo | Adds ShopifyQL Notebooks, full API access |

Sources: https://bybtraction.com/shopify-plan-differences-analytics-reports-attribution/ and https://help.shopify.com/en/manual/reports-and-analytics/shopify-reports/report-types

**Hard caps that apply to every tier including Plus:**
- **In-admin display: 1,000 rows max**
- **Export: 10,000 rows max per report**
- **Session/analytics history: only back to October 2022**

**For an engineering audience, the 10K export cap on a $2,300/mo Plus plan is the killer claim.** A Plus merchant doing 100K+ orders/month literally cannot export a year of orders from the admin. The platform forces you to the API or a warehouse the moment the business scales.

## Merchant complaints (community-sourced)

Documented, recurring pain — these are not cherry-picked:

- **"Major Problem with New Reports / Analytics"** — Shopify Community thread documenting business standstill — https://community.shopify.com/t/major-problem-with-new-reports-analytics/387818
- **"Shopify analytics report for already more than 2 years poorly"** — title alone is evidence — https://community.shopify.com/t/shopify-analytics-report-for-already-more-than-2-years-poorly/397696
- **General reporting problems thread** — https://community.shopify.com/t/reporting-problems/573811
- **12–24 hour analytics refresh delay during peak sales** documented across multiple analyses — https://www.putler.com/shopify-analytics-limitations
- **G2 Shopify review tags:** "Limited Customization" mentioned in 98 reviews, "Limited Features" 60, "Limitations" 20 — https://www.g2.com/products/shopify/reviews

## Use cases that force merchants off Shopify

These are the analytics jobs Shopify either does badly or not at all — evidenced from the category vendors that exist to fill each gap:

**LTV / cohort analysis.** Shopify shows a customer's purchase count but not their lifetime value, and the cohort report does not segment by acquisition source — so you cannot compare Meta-acquired vs Google-acquired LTV cohorts.
- https://www.sarasanalytics.com/blog/shopify-ltv
- https://www.sarasanalytics.com/blog/shopify-cohort-analysis

**Multi-touch attribution.** Shopify uses last-click only. It "cannot tell you which channel introduced the customer, how many touches happened in between... does not track cross-device journeys, does not stitch anonymous sessions to identified customers, does not support configurable attribution models."
- https://layerfive.com/blog/multi-touch-attribution-for-shopify-brands/

**Multi-store / multi-currency consolidation.** Multi-store reporting only recently landed for Plus organisations — https://changelog.shopify.com/posts/multi-store-reporting-is-now-available-in-analytics — but reports default to primary currency, "hide how your business really behaves in each market," and *"you can't collapse or consolidate rates across existing B2B shops into a multi-entity structure"* — https://www.ontapgroup.com/blog/shopify-plus-multiple-stores

**Profit / COGS reporting.** Advanced tier minimum, still limited. The entire Lifetimely / BeProfit / TrueProfit category exists to fill this gap.

## API quirks that bite warehouse implementers

Beyond REST deprecation, MoneyBag, deprecated customer scalars, and gift card masking (already in my notes), three more architectural gotchas every Shopify-warehouse implementer hits:

**Bulk operations concurrency.** Until API version 2026-01, **only one bulk operation per shop at a time**. 2026-01+ raised this to five concurrent. Until very recently you could not parallelise a historical extract across entity types — https://shopify.dev/docs/api/usage/bulk-operations/queries

**Calculated query cost rate limiting.** GraphQL Admin uses cost-per-query, not request-per-minute. *"If you treat it like a REST endpoint and fire concurrent paginated requests, your application will hit a wall of 429 errors."* — https://no7software.co.uk/blog/shopify-graphql-admin-api-rate-limits-production

**Webhook reliability gaps.** Production warehouses can't rely on webhooks alone:
- **5-second response window** or the webhook is marked failed
- **Up to 19 retries over 48 hours**, then the subscription is auto-degraded
- **No ordering guarantee** within or across topics — `products/update` can arrive before `products/create` for the same resource
- **Intermittent missing fields** on API 2025-10 orders webhooks (shipping_address, note_attributes) — https://community.shopify.dev/t/orders-webhooks-api-2025-10-shipping-address-and-note-attributes-intermittently-missing-when-using-theme-app-extensions/27446
- Sources: https://shopify.dev/docs/apps/build/webhooks/troubleshooting-webhooks and https://eventdock.app/blog/shopify-webhook-reliability-orders-missing

**Engineering implication:** any production Shopify warehouse must run a reconciliation extract alongside webhook ingestion. This is a real, recurring architectural cost the merchant pays whether they build it themselves or pay Fivetran to do it.

## The ecosystem-as-evidence argument

The cleanest framing for a product/engineering audience:

- **Triple Whale + Polar combined: ~$85M raised, ~54,000 merchants served**
- **Polar's Nov 2024 $19M Series A** was pitched as *"restoring marketing signals for DTC brands in the post-cookie era"* — explicitly a bet that Shopify's native attribution is insufficient — https://www.polaranalytics.com/post/polar-analytics-announces-18m-series-a-funding
- **Lifetimely's own marketing:** *"fills a critical gap in Shopify's native analytics... predictive lifetime value modeling, and cohort analysis that would otherwise require a full-time data analyst and a dozen spreadsheets"* — vendor's own framing of the gap — https://easyappsecom.com/guides/shopify-lifetimely-guide

Every VC dollar in this category is a vote that the platform owner has chosen not to solve this in-house. **And every one of these tools stops at dashboards, not warehouses.** That's the meaningful difference for an Exasol-positioned offering — the analytics-app category proved demand, then declined to ship the layer Exasol is actually good at.

## Acknowledged gaps

1. **Reddit-specific complaints** — not well-indexed by search; r/shopify and r/ShopifyPlus pain points would need manual browsing. Not included.
2. **Quantified "merchants who have built their own warehouse"** — no public source.
3. **Exasol Shopify case studies** — none exist publicly (see Addendum A).

These don't change the case. The case is: native reporting has documented hard limits at every tier; merchants complain in public; key analytics use cases force them off-platform; an $85M+ VC category exists to plug the gap with dashboards; nobody has packaged a warehouse-grade play on Exasol. That last point is the opening.
