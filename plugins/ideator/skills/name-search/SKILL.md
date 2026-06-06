---
name: name-search
description: >
  Coin a distinctive, available product name — a marketing-grade naming search. Trigger with
  /ideator:name (or "name my product", "find a name for this", "the name X is taken, find alternatives",
  "rename this product"). Distils the product's philosophy into a naming charter (optionally trawling the
  local project), generates a wide net of coined candidates across languages/eras/techniques, verifies
  availability DETERMINISTICALLY (npm/pypi/crates/GitHub + adoption tier) with zero per-name LLM tokens,
  adversarially challenges the survivors, and emits a comprehensive report (where it searched, every name
  generated/kept/rejected and WHY, a ranked shortlist, and a top pick with confidence + residual risks).
  Honours user-stated constraints (syllable count, values to evoke). Use proactively whenever a user needs
  a name that has no neighbours.
metadata:
  type: producer
  output: a ranked naming report (to docs/marketing/naming-report.md or stdout) + a recommended name
model: inherit
---

# NAME-SEARCH — marketing-grade product naming

The naming marketeer. Turns "I need a name" into a defensible, evidence-backed recommendation: a coined
word with **no neighbours** across npm/PyPI/crates/GitHub, that *reads right* for the product's niche and
encodes its philosophy. Cleaved out of `ideate` because naming is its own responsibility — `ideate`
references this skill by capability when an idea needs a name.

## The token contract (non-negotiable)

The LLM does only **charter · generate · challenge · synthesize**. **Every** availability/adoption check is
the deterministic script — **never spawn one agent per name** (that pattern burned 20k+ tokens for a
50-candidate list). Call the script **once** for the whole candidate list, via at most one thin wrapper
agent that returns its JSON:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/name-search/scripts/namecheck.sh \
  --json --adoption --syllables=2-3 --registries=npm,github,pypi,crates  name1 name2 name3 ...
```

The script ([`scripts/namecheck.sh`](scripts/namecheck.sh)) checks npm (exact + hyphenated), PyPI,
crates.io, and GitHub (user/org) in parallel, classifies each name **CLEAR / LOW_ADOPTION / ABANDONED /
TAKEN / UNKNOWN**, and emits the JSON the report consumes — in ~2s for 10 names, zero LLM tokens. Set
`GITHUB_TOKEN` in the environment to lift the GitHub rate limit (60→5000/hr) before a large run.

## How to run

1. **Parse the brief into constraints.** From the user's words extract: the product (what it does, its
   niche), the **values to evoke** (e.g. "security + free-forever + assurance"), and any **structural
   constraints** — syllable count/range ("1 syllable", "6 syllables", default 2–3), banned stems, language
   or tone preferences. Confirm the constraints back in one line; infer the rest.
2. **Build the charter.** Follow [`references/charter-protocol.md`](references/charter-protocol.md): distil
   the philosophy into ranked values + tone + banned/saturated stems. When a local project is the subject,
   do the **bounded** local trawl (README, manifest, top-level doc headings, `git log` domain terms — under
   the file/token ceiling) to ground the charter in the product's real language.
3. **Generate a wide net.** Follow [`references/generation.md`](references/generation.md): mine many veins
   — multi-language roots, eras, themes, and coinage techniques (portmanteau, blend, clipping, affixation,
   phonosemantic) — to produce 40–60 deduplicated candidates honouring the constraints. Run the generation
   strategies in parallel (one agent per *strategy*, NOT per name).
4. **Verify deterministically.** Call the script ONCE for all candidates (the token contract above). Filter
   to the recommendable set (CLEAR + the LOW_ADOPTION/ABANDONED names that pass with a caveat); record every
   name's disposition for the report.
5. **Adversarially challenge** the survivors: hidden collisions/trademark adjacency, awkward connotations
   or meanings in other languages, sayability/spellability, genericness, philosophy fit. Default to
   `survives=false`; score each survivor.
6. **Synthesize the report** to [`references/report-template.md`](references/report-template.md): charter,
   where-it-searched, the attrition funnel (generated → verified → challenged → ranked, numbers
   reconciling), per-name disposition with the axis that killed each, the adoption tier, and a ranked
   shortlist with a top pick — its confidence and residual risks stated honestly (trademark/domain checks
   are web-search caveats, never asserted as cleared). Write to `docs/marketing/naming-report.md` in the
   product repo (or stdout), and offer to render it via pressroom `/publish`.

## Honesty rules

- **availability ≠ challenge.** A name removed for being *taken* (availability) is distinct from one
  *demoted in the challenge*. Keep the two verdicts in separate columns; never conflate "killed".
- **UNKNOWN is not free.** A registry whose probe could not complete is `unknown`, never upgraded to a
  verdict; say so and recommend a re-check.
- **No silent caps.** If the candidate list was truncated (`--max-names`) or a registry was skipped, say so
  in the report.

## Self-improvement covenant

Carries the SOLID covenant ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)). When a name that
passed the search later proves to collide (a missed trademark, a registry not checked), that is not a
one-off — it is a **vein to add to `generation.md`** or a **check to add to `namecheck.sh`**; flag it for
`/ideator:self-improve` so every future search is sharper.
