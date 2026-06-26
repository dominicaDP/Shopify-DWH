# Shopify on Exasol — Why We Should Do This, and What Should Exist

**Author:** Dominic Albrecht, Head of Analytics, Digital Planet
**Audience:** Exasol Product & Engineering team
**Context:** Exasol Xperts programme contribution
**Date:** 2026-05-25

---

## Why I'm writing this

I'm an Exasol Xpert, and over the last few months I've designed a full Shopify data warehouse on Exasol for our brand, Dress Your Tech. The design is complete and I'm now running a focused, five-phase POC to validate it end-to-end against real Shopify data on Exasol Community Edition. Foundations are in place — Exasol up locally, Python environment ready, Shopify OAuth working — and I'm moving into staging schema and extraction next.

But this document isn't really about that build. What I want to talk about is the gap I noticed while designing it: a vertical Exasol has no packaged play for, a problem with documented demand and venture-backed competitors who only solve half of it, and what I think is a really substantial opportunity to make Exasol the obvious answer for an entire segment of mid-market ecommerce.

I'm writing this for product and engineering, because if the *thing* doesn't make sense to you, nothing downstream of it matters.

Two questions only:

1. **Why should an "Exasol for Shopify" accelerator exist?**
2. **What is the accelerator?**

The "how" — schema design, ETL patterns, what to do about webhooks — I've documented separately and it's available on request. It's not the point of this document.

---

## Part 1 — Why this should exist

### The market is large, addressable, and underserved by warehouse-native solutions

I think the most striking thing here is that the demand is documented, the money is real, and yet no one is actually selling what these merchants need:

- **2M+ active Shopify merchants worldwide.** Even the bottom-end estimate makes this one of the biggest single-vertical TAMs in B2B SaaS data tooling.
- **Mid-market Shopify ($5M–$100M GMV) is the sweet spot.** Big enough to need a warehouse; small enough that the typical Snowflake + Fivetran + Looker stack hurts.
- **The going analytics-stack cost for that segment is $3,500–$25,000/month** — before any data engineers — composed of Snowflake (~$3K/mo typical, median buyer ~$96K/year), Fivetran ($1K–$10K/mo), and Looker or Power BI on top. **Fivetran alone moved 40–70% in 2025** via a single MAR calculation change.
- **The third-party "Shopify analytics" category has raised $85M+ of VC** to serve roughly 54,000 of these merchants. Triple Whale alone is at ~$21M revenue and a ~$300M valuation; Polar Analytics closed a $19M Series A in Nov 2024 on the explicit pitch of "restoring marketing signals" Shopify doesn't provide. The demand is proven and the money is real.
- **None of those VC-backed competitors ship a warehouse.** They ship dashboards. They sit *on top of* a warehouse the merchant still has to find, pay for, and maintain.

Full evidence base with sources — segmentation, Plus pricing, vendor revenue and funding, Exasol's existing ecommerce wins — in [Addendum A — Market sizing](exasol-xperts-addendum-a-market-sizing.md).

### Native Shopify reporting has documented, structural gaps

This isn't an opinion. It's documented:

- **The export cap is 10,000 rows per report — on every tier including Shopify Plus at $2,300+/month.** A merchant doing 100K orders/month cannot export a single year of orders from the admin.
- **Custom report creation requires the $399/month Advanced tier or above.** Most of the platform's reporting capability sits behind a paywall most merchants can't justify until they're already feeling the pain.
- **Multi-store and multi-currency consolidation are weak.** Multi-store reporting only landed in 2026 and still defaults to primary currency; B2B-shop consolidation across multi-entity structures isn't supported.
- **Attribution is last-click only.** No multi-touch, no cross-device stitching, no configurable models.
- **LTV and cohort analysis are absent in any useful form.** The cohort report doesn't even segment by acquisition source — you cannot compare Meta-acquired vs Google-acquired LTV.
- **The session-history floor is October 2022.** Anything earlier is simply gone from native analytics.

Full evidence base with sources — merchant-complaint threads, API quirks that bite warehouse implementers (bulk-op concurrency, cost-based rate limiting, webhook reliability), and the full per-tier capability matrix — in [Addendum B — Shopify reporting problems](exasol-xperts-addendum-b-shopify-reporting-problems.md).

### Exasol is structurally the right engine for this workload — and currently absent from the conversation

- **Star schemas are exactly what Exasol's columnar in-memory engine is built for.** Wide fact-table scans, pre-aggregated metrics, denormalised dimensions — every Shopify analytics query is one of these. This is a natural fit, not a stretch.
- **Exasol has ecommerce credibility but no Shopify story.** OTTO halved its analytics costs replacing Hadoop with Exasol, with 1,000+ concurrent Tableau users, and Exasol has a dedicated eCommerce vertical page. There is no Shopify-specific case study, accelerator, or reference architecture anywhere on the website.
- **The mid-market wants what Exasol does well: predictable performance and lower TCO.** Snowflake's median buyer pays ~$96K/year. Exasol's positioning naturally undercuts that for the queries Shopify merchants actually run.

I think the white space here is glaring. Snowflake has Native Apps. BigQuery has connectors. Databricks has lakehouse templates. My concern is that Exasol's competitive risk, sitting here, is being seen as *just a fast columnar database* without a vertical narrative. A Shopify accelerator changes that, in a market that is documented, demanded, and currently underserved by every player who's already taken VC money to address it. I really believe this is solvable, and I'd love Exasol to be the one that solves it.

---

## Part 2 — What should exist

### One-sentence vision

Here's what I think should exist:

**An "Exasol for Shopify" accelerator — a configuration-driven, deployable Layer 1 data warehouse template that any mid-market Shopify merchant can stand up on Exasol in hours, with their own schema, their own ETL, their own metrics, and no Fivetran licence in sight.**

That's the artifact. The rest of this section is what's in the box.

### The core components

**1. A merchant-configurable schema template**
A staging-plus-warehouse design — staging that mirrors the Shopify GraphQL API, and a star-schema warehouse layer optimised for Exasol natively. Driven by a YAML configuration per merchant: their payment methods, tax types, discount categories, fiscal calendar, customer-segment rules, custom metafields. The generator produces self-documenting DDL — `payment_payfast_amount`, not `payment_1` — so the schema fits the business, not the other way around. I think clarity in the schema is one of the underpinnings that makes the whole accelerator robust enough to repeat across merchants.

**2. An ETL toolkit, not a SaaS**
Lightweight Python that runs on the same Linux host as Exasol — Shopify GraphQL bulk operations + PyExasol + systemd timers. Configurable, parameterised, no licence cost. Merchants own it, run it, modify it. This is the antidote to Fivetran's 2025 pricing and the moat against any future hike.

**3. A documented metric catalogue**
57 standard ecommerce metrics — revenue, AOV, customer lifetime value, RFM segmentation, fulfilment timing, refund rates, inventory tracking — defined once, with full lineage back to the Shopify API fields they derive from. Out-of-the-box answers to the questions native reporting can't.

**4. Deployment automation**
An auto-discovery script that crawls a merchant's live store, identifies their actual payment gateways, tax types, and discount patterns, and generates the configuration file. From there, hours to a working warehouse, not weeks.

**5. An extension pattern**
The Layer 1 + Layer 2 split is deliberate. Layer 1 is the productisable core; Layer 2 is where merchants (or partners) add domain-specific facts and dimensions without breaking the upgrade path. Our own B2B2C voucher analytics for Dress Your Tech is the worked example proving the pattern.

### What deploying it looks like (for a new merchant)

1. Run the auto-discovery script against their Shopify store
2. Review and tweak the generated YAML config
3. Run the schema generator — DDL lands in their Exasol tenant
4. Run the ETL — first historical load via bulk operations, then incremental
5. Point any BI tool at the star schema; the metric catalogue is the reference

Hours, not weeks. Repeatable across merchants. That's the rhythm I want this to settle into.

### What it is NOT

- **Not a SaaS.** Merchants run it on their own Exasol. Exasol's revenue comes from the platform, not a wrapper.
- **Not a dashboarding tool.** It deliberately stops at the warehouse layer where Triple Whale, Polar, and Looker stop being warehouse-aware. Pick your own BI.
- **Not opinionated on Shopify configuration.** The point of configuration-driven design is that *every* Shopify store is different, and the schema needs to reflect the merchant's actual business.
- **Not a competitor to Plus's native reporting at small scale.** This kicks in when the merchant outgrows native — typically somewhere in the $5M GMV range.
- **Not a one-off custom build.** That's the whole point of Layer 1 being productisable.

### Where we actually are (and why I think this is feasible)

I want to be honest about the current state, because I think it's the strongest part of the case:

- **Layer 1 (the productisable generic core) is complete.** 17 staging tables, 7 dimensions, 5 facts, 57 ecommerce metrics with full lineage back to the Shopify API, plus API mappings and productisation strategy — all documented and available for review.
- **Layer 2 (DYT extensions) is also complete, as the worked example.** Our B2B2C voucher model adds 3 staging tables, 2 dimensions, 2 facts, 1 view, and 25 voucher/campaign-specific metrics on top of Layer 1 — proving the extension pattern without contaminating the generic core.
- **The POC is in flight.** Foundations are done — Exasol Community Edition running locally, Python environment ready, Shopify OAuth captured against our live store. I'm now moving into the staging schema and extraction phases, validating Layer 1 end-to-end against real Dress Your Tech data.

I don't think the accelerator is a green-field engineering ask. It's a packaging-and-distribution ask on top of a design that already exists, with a live validation already underway.

---

## What I'd like to discuss

Four conversations I'd really like to have, lowest-friction first:

1. **Visibility within the Xperts programme.** Featured contribution — a published reference architecture, a community-maintained repo, a talk at an Exasol event. I think this is the lowest friction and the highest signal on whether the rest is worth pursuing.
2. **Case study / co-marketing.** Once the POC closes, Digital Planet + DYT as a published Exasol customer story focused on the mid-market ecommerce angle Exasol currently doesn't tell.
3. **Productisation as an Xperts accelerator.** Officially packaged "Exasol for Shopify" reference solution, distributed under the Xperts banner or as part of Exasol's solution library. I'd want engineering buy-in on shape and scope before this has any commercial form.
4. **Technical engagement.** The places where I'd really value Exasol's input or co-development: documented patterns for GraphQL bulk-loading into Exasol, a reference Yellowfin semantic layer over an ecommerce star schema, better-documented examples for UDF use cases. I'm building these anyway — I'd much rather build them in a form Exasol could absorb.

I'd really rather have any of these conversations than ship around them. The design docs, metric lineage, and POC plan are all written up and ready to share whenever it's useful. I hope we can turn this into something substantial together.

---

**Contact:** dom.albrecht@gmail.com
**Companion documents:**
- [Addendum A — Market sizing](exasol-xperts-addendum-a-market-sizing.md)
- [Addendum B — Shopify reporting problems](exasol-xperts-addendum-b-shopify-reporting-problems.md)
- Full architecture, schema, and POC plan available on request
