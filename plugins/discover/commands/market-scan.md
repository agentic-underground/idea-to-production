---
description: Discover a worth-building opportunity — an adversarially-challenged ideation dialogue that proposes, scores, and KILLS candidates against a market parameter taxonomy until one earns a keep verdict, then hands a validated opportunity to the ideator plugin (or writes a markdown opportunity brief).
---

Run a market scan. Follow the [`market-scan` skill](../skills/market-scan/SKILL.md):

1. Read the standing `/discovery-goal` (`.discover/goal.md`) if present; otherwise ask only the minimum to
   bound the search (infer-first, one question at a time, **with a recommended answer + multiple-choice**).
2. Propose 3–5 candidate opportunities for `$ARGUMENTS` (or the goal), score each against the parameter
   taxonomy, and **kill the weak ones early** (on the conjunction, not the average).
3. Challenge the survivors adversarially (who pays? what channel? why hasn't an incumbent done it?),
   narrow to 1–2, and reach a **KEEP / PARK / KILL** verdict per candidate.
4. On a **KEEP**, hand the validated opportunity to the **ideator** plugin (`/ideate`) if installed, else
   write a markdown opportunity brief to `doc/opportunities/<slug>.md`. Record any KILL/PARK in the kill
   ledger so a like candidate is recognised faster next time.

Tip: `/loop /market-scan` iterates the scan over your `/discovery-goal` until a candidate earns a keep verdict.
