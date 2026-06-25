# Charter protocol — distilling philosophy into a naming brief

The charter steers every later phase. A weak charter yields generic names; a sharp one yields names that
*fit*. It is the output of the **discovery interview** ([`discovery-protocol.md`](discovery-protocol.md))
and the contract generation + evaluation are measured against. Its parts:

1. **Ranked values** — what the name must encode, in priority order (e.g. 1. trust, 2. free-forever,
   3. open, 4. community, 5. craft). The ranking matters: the top value drives the strongest survivors.
2. **Audience & archetype** — who the name is for (a named role + how they speak) and the **1–2 Jung
   archetypes** it must embody ([`../../../knowledge/naming/frameworks.md`](../../../knowledge/naming/frameworks.md)).
   The archetype sets the sound palette ([`../../../knowledge/naming/phonosemantics.md`](../../../knowledge/naming/phonosemantics.md)).
3. **Name-type strategy** — which **veins** to fire (descriptive ↔ suggestive ↔ abstract; real-word ↔
   compound ↔ coined) and *why* ([`../../../knowledge/naming/name-types.md`](../../../knowledge/naming/name-types.md)).
   This is the biggest lever on what the search returns.
4. **Risk appetite + power-adjacency + humour** — safe ↔ bold; any myth/science equity to borrow; humour
   appetite (none ↔ subtle ↔ overt). These gate the opt-in veins.
5. **Tone & exemplars** — emotional register + one or two admired brands (Snyk, Vercel, Stripe…).
6. **Structural constraints** — syllable target/range, language/era preferences, must-have/avoid sounds,
   extendability needs.
7. **Banned / saturated stems** — lexical neighbourhoods to stay out of. For a security/agent-tooling
   product, typically `skill* mcp* agent* *scan *sentry *sentinel *guard *gate *shield *audit *sec *watch`
   — crowded and undistinctive. Add any stems already explored.

## Inferring vs asking

Infer the charter first (from any IDEA package, the `ideate` output, or the bounded local trawl below);
then run the discovery interview for the **load-bearing gaps only** — one question per turn, each with a
recommended answer + multiple-choice. See [`discovery-protocol.md`](discovery-protocol.md). Don't
interrogate what's already known; don't generate on an unfilled load-bearing field.

## Bounded local-material trawl (when the subject is a local project)

When naming an existing project, ground the charter in the product's *real* language — but **bounded**, so
it can't balloon into a token sink (the same waste-elimination discipline the rest of the marketplace
holds). Read, at most:

- the **README** (first ~200 lines) — the positioning and value language;
- the **package manifest** (`package.json` / `pyproject.toml` / `Cargo.toml`) — name, description, keywords;
- the **top-level headings** of `docs/`/`doc/` files (headings only, not full bodies);
- `git log --oneline -50` — recurring domain terms and the product's own vocabulary;
- any existing naming notes (`docs/marketing/*`), to avoid re-proposing killed names.

Hard ceiling: a handful of files, headings/first-lines only. Distil the recurring domain nouns and the
stated values into the charter; do **not** read the whole codebase. If the project is large, sample and say
so. The output is the charter, not a summary of the repo.

## Output

A charter block the generation veins consume directly: ranked values · audience & archetype · name-type
strategy · risk/power-adjacency/humour · tone + exemplars · structural constraints · banned stems. Keep it
tight (under ~250 words). This is the contract the whole search is measured against — if a top pick doesn't
trace back to a ranked value *and* the archetype, the charter or the pick is wrong.
