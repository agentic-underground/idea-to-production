---
description: Coin a distinctive, available product name — a marketing-grade naming search. Distils the product philosophy into a charter, generates a wide net of coined candidates across languages/eras/techniques, verifies availability DETERMINISTICALLY (npm/pypi/crates/GitHub + adoption tier, zero per-name LLM tokens), adversarially challenges the survivors, and emits a comprehensive ranked report with a top pick + residual risks. Honours stated constraints (syllable count, values to evoke).
---

Search for a product name. Follow the [`name-search` skill](../skills/name-search/SKILL.md):

1. **Parse the brief** in `$ARGUMENTS` into constraints — the product/niche, the **values to evoke**, and
   structural constraints (syllable count/range, banned stems, language/tone). Confirm in one line; infer
   the rest.
2. **Build the charter** (distil philosophy → ranked values + tone + banned stems; bounded local-project
   trawl when naming an existing repo).
3. **Generate a wide net** — many veins (multi-language roots, eras, coinage techniques), one agent per
   *vein*, 40–60 deduped candidates.
4. **Verify deterministically** — call `scripts/namecheck.sh` ONCE for all candidates (npm/pypi/crates/
   GitHub + adoption tier). **Never one agent per name.**
5. **Adversarially challenge** the survivors, then **synthesize** the report to the canonical template
   (charter · where-it-searched · attrition funnel · per-name disposition with separate availability vs
   challenge verdicts · ranked shortlist · top pick with confidence + residual risks).

Write the report to `docs/marketing/naming-report.md` (or stdout); offer to render via pressroom `/publish`.
Set `GITHUB_TOKEN` before a large run to lift the GitHub rate limit. Distinct from `/ideate` (which refines
a whole idea); this does naming, well.
