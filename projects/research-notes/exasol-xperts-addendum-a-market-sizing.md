# Addendum A — Market sizing

**Companion to:** [exasol-xperts-narrative.md](exasol-xperts-narrative.md)
**Audience:** Exasol Product & Engineering team
**Last updated:** 2026-05-25

This addendum is the evidence base behind the "Exasol-for-Shopify-mid-market" framing in the main narrative. All claims are sourced inline. Where data isn't publicly available, I flag it explicitly rather than guess — engineering peers will trust gaps acknowledged more than numbers asserted.

## Total Shopify merchants

Shopify stopped disclosing merchant counts after 2021 ("millions of merchants"). Current figures are third-party estimates:

- **~2.1 million active merchants across 175 countries** — https://uptek.com/shopify-statistics/merchant-revenue/
- **~5.8 million live stores** (note: stores ≠ merchants; one merchant can run multiple stores) — https://grabon.com/blog/shopify-statistics/

Conservative number to lead with: **2M+ active merchants**.

## Segmentation and GMV cutoffs

ECDB (Statista-affiliated) publishes the cleanest segmentation:

- **SMB / micro:** <$5M annual GMV
- **Mid-market:** $5M–$100M GMV
- **Enterprise:** $100M+ GMV
- Source: https://ecdb.com/blog/shopify-s-influence-on-global-e-commerce-is-growing/5181

**Shopify Plus** is positioned for the **$2M–$50M GMV** band by Plus-focused agencies — https://onpattison.com/news/2026/may/03/the-top-7-shopify-plus-partners-for-mid-market-merchants-in-2026/

The mid-market band is the right addressable target: large enough that a DWH is justified, small enough that Fivetran + Snowflake is painful.

**Gap:** Shopify does not publish per-tier merchant counts. The number of merchants in each band cannot be sourced credibly.

## Shopify Plus pricing

- **Base:** $2,300/mo (3-year term) or $2,500/mo (1-year term) — https://www.shopify.com/plus/pricing
- **Revenue share** kicks in above ~$800K/mo platform GMV at 0.25% of monthly GMV (whichever higher) — https://www.brokenrubik.com/blog/shopify-plus-pricing-guide
- **Realistic TCO including apps:** $4,000–$10,000+/mo

**Gap:** Plus merchant count not disclosed since 2021. Pre-2021 figures cited "~10,000 Plus merchants" — no longer publicly tracked.

## The mid-market analytics stack TCO

This is the load-bearing number. Component-by-component, 2025/2026 figures:

| Component | Typical cost | Source |
|---|---|---|
| **Snowflake** (mid-size data team, Enterprise edition) | ~$3,000/mo typical; range $2K–$10K/mo; median buyer **~$96,600/year** | https://select.dev/posts/snowflake-pricing and https://mammoth.io/blog/snowflake-pricing/ |
| **Fivetran** (multi-connector mid-market) | $1K–$10K/mo (see next section on 2025 hike) | https://mammoth.io/blog/fivetran-pricing/ |
| **Looker** (BI platform, not Looker Studio) | Base $60K/year; typical $36K–$360K/year; average **~$150K/year** | https://www.luzmo.com/blog/looker-pricing |
| **Power BI** | Pro $14/user/mo (raised April 2025); Premium Per User $24/mo | https://algoscale.com/blog/how-much-does-power-bi-cost/ |

**Composite:** a mid-market Shopify operation pays roughly **$3,500–$25,000/mo** for the Fivetran-Snowflake-BI stack. Lead with the conservative end (~$3-4K/mo); that's still a **$40-50K/year analytics infrastructure bill** before any headcount.

That's the number any Exasol-for-Shopify accelerator needs to beat.

## Fivetran 2025 pricing — confirmed

- **March 2025: Fivetran changed MAR (Monthly Active Rows) calculation from account-wide to per-connector** — https://fivetran.com/docs/usage-based-pricing/pricing-updates/2025-pricing-faq
- **Result: 40–70% cost increase for typical multi-connector setups** per independent analyses — https://mammoth.io/blog/fivetran-pricing/ and https://rivery.io/blog/fivetran-pricing-what-to-know/

Fivetran frames this as "neutral for typical users." Independent analyses disagree. For a Shopify warehouse that pulls orders, customers, products, fulfillments, refunds, and inventory as separate connectors, the bill went up materially in 2025.

## Third-party Shopify analytics market (the ecosystem signal)

Third-party Shopify analytics tools exist *because* native isn't enough. Venture capital flowing into the category is indirect proof of demand.

**Triple Whale**
- 2025 revenue ~$21.6M — https://getlatka.com/companies/triplewhale.com
- $55.4M raised across 3 rounds; ~$300M valuation
- 50,000+ ecommerce/retail brands
- https://www.crunchbase.com/organization/triplewhale

**Polar Analytics**
- $19.1M Series A (Nov 2024, Chalfen Ventures) — https://www.polaranalytics.com/post/polar-analytics-announces-18m-series-a-funding
- $30.3M raised total
- ~$4.8M ARR — https://getlatka.com/companies/polaranalytics.co
- ~3,715 merchants — https://tracxn.com/d/companies/polar-analytics/__YeLZOWqem7X2b0TPddEotX2H0LgM6-GMMFaFTJ6m4z4

**Lifetimely** (acquired by AMP): $29 Growth tier, $59 Pro tier — https://www.lifetimely.io/lifetimely-vs-polar-analytics

**Glew**: from $79/mo, multi-channel positioning — https://www.capterra.com/p/160516/Glew/reviews/

Triple Whale and Polar alone have raised **~$85M** of venture capital to serve **~54,000 Shopify merchants** in the analytics gap. **None of them ship a warehouse. All of them stop at dashboards.** That's the meaningful gap an Exasol-positioned offering can occupy.

## Exasol's existing ecommerce footprint

- **OTTO** (Germany's largest home/living ecommerce site): replaced Hadoop-based DWH with Exasol; halved analytics costs; 1,000+ concurrent Tableau users — https://www.exasol.com/casestudy/otto-and-exasol/
- Exasol has a dedicated **eCommerce and Retail vertical page** — positioning exists — https://www.exasol.com/industries/ecommerce-and-retail/
- **No documented Shopify-specific case study or accelerator** anywhere on Exasol's site

The OTTO story proves Exasol works for ecommerce at scale. The absence of a Shopify story is the white space — that's not a research failure, it's the opportunity.

## Acknowledged gaps

1. Shopify Plus merchant count — not publicly disclosed since 2021
2. Per-tier merchant distribution (how many Basic vs Plus) — not disclosed
3. Glew / Lifetimely revenue or funding — not in public sources

These don't change the directional argument: a multi-million-merchant TAM, a $3-25K/mo per-merchant analytics infrastructure bill, a market where **$85M+ of VC has been spent solving slices of the problem** with dashboards-only products, and zero packaged plays from Exasol.
