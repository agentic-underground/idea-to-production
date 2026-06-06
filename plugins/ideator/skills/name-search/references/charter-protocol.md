# Charter protocol — distilling philosophy into a naming brief

The charter steers every later phase. A weak charter yields generic names; a sharp one yields names that
*fit*. The charter has four parts:

1. **Ranked values** — what the name must encode, in priority order (e.g. 1. trust, 2. free-forever,
   3. open, 4. community, 5. craft). The ranking matters: the top value drives the strongest survivors.
2. **Tone** — the emotional register (warm? institutional? sleek? playful?) and one or two exemplar brands
   the user admires (Snyk, Vercel, Stripe…) to anchor the feel.
3. **Structural constraints** — syllable target/range, language/era preferences, and any must-have or
   must-avoid sounds.
4. **Banned / saturated stems** — the lexical neighbourhoods to stay out of. For a security/agent-tooling
   product these are typically `skill* mcp* agent* *scan *sentry *sentinel *guard *gate *shield *audit
   *sec *watch` — names there are both crowded and undistinctive. Add any stems already explored.

## Inferring vs asking

Infer the charter from the brief first; confirm in one line rather than interrogating. Only ask when a
genuinely load-bearing choice is undetermined (e.g. the user said "evoke security AND playfulness" — which
dominates?). One question, recommended answer, move on.

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

A charter block the generation veins consume directly: ranked values · tone + exemplars · structural
constraints · banned stems. Keep it tight (under ~200 words). This is the contract the whole search is
measured against — if a top pick doesn't trace back to a ranked value, the charter or the pick is wrong.
