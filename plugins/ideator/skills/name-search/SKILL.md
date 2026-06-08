---
name: name-search
description: >
  Find the perfect, available product or org name — a marketing-grade naming studio. Trigger with
  /ideator:name (or "name my product", "find a name for this", "the name X is taken, find alternatives",
  "rename this product", "name my org/company"). Runs a deep discovery interview (audience, brand
  archetype, name-type appetite, power-adjacency, intellectual humour, risk appetite — infer-first, asking
  only the load-bearing gaps), then generates a WIDE net across the full name-type taxonomy (suggestive,
  metaphor, mythological, compound, portmanteau, coined, acronym/backronym, scientific-taxonomic, animal,
  more) plus affix HOOKS and phonosemantic tuning, verifies availability DETERMINISTICALLY
  (npm/pypi/crates/GitHub + adoption + NEIGHBOUR/typo-squat proximity + DOMAIN/RDAP + cross-language
  connotation) with zero per-name LLM tokens, scores survivors against named frameworks
  (Neumeier 7 / SMILE-SCRATCH / archetype-fit), and emits a comprehensive ranked report with a top pick,
  confidence, and residual risks. Use proactively whenever a user needs a name that has no neighbours.
metadata:
  type: producer
  output: a ranked naming report (to docs/marketing/naming-report.md or stdout) + a recommended name
model: inherit
---

# NAME-SEARCH — marketing-grade product naming

The naming studio. Turns "I need a name" into a defensible, evidence-backed recommendation: a name —
**coined or real, any of the professional name-types** — with **no neighbours** across
npm/PyPI/crates/GitHub (and a clean domain), that *reads right* for the audience and archetype and
encodes the philosophy. Cleaved out of `ideate` because naming is its own responsibility — `ideate`
references this skill by capability when an idea needs a name.

The art-of-naming canon lives in [`../../knowledge/naming/`](../../knowledge/naming/) (the taxonomy,
phonosemantics, the affix-hook catalogue, the archetype/Neumeier/SMILE-SCRATCH frameworks, dev-tool
conventions, ideation methods); this skill is the thin protocol that runs it.

## The token contract (non-negotiable)

The LLM does only **charter · generate · challenge · synthesize**. **Every** availability/adoption check is
the deterministic script — **never spawn one agent per name** (that pattern burned 20k+ tokens for a
50-candidate list). Call the script **once** for the whole candidate list, via at most one thin wrapper
agent that returns its JSON:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/name-search/scripts/namecheck.sh \
  --json --adoption --neighbors --domains=com,dev,io,ai --connotation \
  --syllables=2-3 --registries=npm,github,pypi,crates  name1 name2 name3 ...
```

The script ([`scripts/namecheck.sh`](scripts/namecheck.sh)) checks npm (exact + hyphenated), PyPI,
crates.io, and GitHub (user/org) in parallel, classifies each name **CLEAR / LOW_ADOPTION / ABANDONED /
TAKEN / UNKNOWN**, and — opt-in — adds **neighbour/typo-squat proximity** (`--neighbors`: GitHub
login-search, `count==0` ⇒ no account *and* no neighbours), **domain availability** (`--domains` via
RDAP), and a **cross-language connotation** screen (`--connotation`). Emits the JSON the report consumes,
zero LLM tokens. Set `GITHUB_TOKEN` to lift rate limits (60→5000/hr core, 10→30/min search) — **needed
for a reliable `--neighbors` pass**; without it the search API throttles and neighbour status is reported
`unknown` (never upgraded).

## How to run

The pipeline: **discover ▸ charter ▸ generate (select veins) ▸ verify ▸ challenge ▸ synthesize.**

1. **Discover (interview).** Follow [`references/discovery-protocol.md`](references/discovery-protocol.md):
   infer everything you can from any upstream IDEA package / `ideate` output / bounded local trawl, then
   ask **only the load-bearing gaps** — audience, **brand archetype**, **name-type appetite**,
   power-adjacency, intellectual-humour appetite, risk appetite — one question per turn, each with a
   recommended answer + multiple-choice. Don't interrogate what's known.
2. **Build the charter.** Distil the interview into the enriched charter
   ([`references/charter-protocol.md`](references/charter-protocol.md)): ranked values · audience &
   archetype · **name-type strategy** · risk/power-adjacency/humour · tone + exemplars · structural
   constraints · banned stems.
3. **Select veins + generate a wide net.** Follow [`references/generation.md`](references/generation.md):
   the charter's name-type strategy picks 4–8 veins from the full taxonomy
   ([`../../knowledge/naming/name-types.md`](../../knowledge/naming/name-types.md)) — suggestive, metaphor,
   mythological, compound, portmanteau, coined, acronym/backronym, scientific-taxonomic, animal, etc. —
   layered with the language/etymology veins, the **affix-hook** transform, **phonosemantic** tuning, and
   (opt-in) the power-adjacency + humour veins. 40–60 deduped candidates. Run **one agent per vein**,
   in parallel — **never one per name**.
4. **Verify deterministically.** Call the script ONCE for all candidates (the token contract above), with
   `--neighbors --domains --connotation` as the brief warrants. Filter to the recommendable set; record
   every name's full disposition (availability + neighbours + domains + connotation) for the report.
5. **Challenge (scored).** Follow [`references/evaluation-rubric.md`](references/evaluation-rubric.md):
   default `survives=false`; score each survivor on Neumeier 7, SMILE/SCRATCH, archetype-fit,
   sound-symbolism-fit, and cross-language connotation (cross-referencing the script's `connotationFlags`,
   `neighbors`, `domains`). Keep availability and challenge in **separate** verdicts.
6. **Synthesize the report** to [`references/report-template.md`](references/report-template.md): brief
   summary, where-it-searched, attrition funnel, per-name disposition (incl. neighbour/domain columns) with
   the axis that killed each, per-vein contribution, the rubric scores, and a ranked shortlist with a top
   pick — confidence + residual risks stated honestly (trademark is web-search-only, RDAP is
   availability-not-legal; never asserted as cleared). Write to `docs/marketing/naming-report.md` (or
   stdout), and offer to render it via pressroom `/publish`.

## Honesty rules

- **availability ≠ challenge.** A name removed for being *taken* (availability) is distinct from one
  *demoted in the challenge*. Keep the two verdicts in separate columns; never conflate "killed".
- **UNKNOWN is not free.** A registry whose probe could not complete is `unknown`, never upgraded to a
  verdict; say so and recommend a re-check.
- **No silent caps.** If the candidate list was truncated (`--max-names`) or a registry was skipped, say so
  in the report.

## Self-improvement covenant

Carries the SOLID covenant ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)). When a name that
passed the search later proves to collide or fall flat, that is not a one-off — it has a named home to be
folded back into, via `/ideator:self-improve`: a missing **name-type** → a vein in
[`../../knowledge/naming/name-types.md`](../../knowledge/naming/name-types.md); a missing **hook** →
[`../../knowledge/naming/affix-catalogue.md`](../../knowledge/naming/affix-catalogue.md); a missing
**evaluation axis** → [`references/evaluation-rubric.md`](references/evaluation-rubric.md); a missed
collision/connotation → a **check (or wordlist entry)** in
[`scripts/namecheck.sh`](scripts/namecheck.sh) / `references/connotation-wordlist.tsv`. Every future
search, for all users, gets sharper by default.
