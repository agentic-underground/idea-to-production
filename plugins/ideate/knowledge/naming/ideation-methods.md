# Ideation methods — how an agent primes a generation vein

Techniques a vein-agent uses to go wide *within* its vein before handing candidates to the checker.
Breadth-then-distinctiveness: produce many genuinely different seeds, let the deterministic verify
and the scored challenge cull.

- **Semantic-field / thematic mining.** From a charter value (e.g. "proven"), fan out the whole field:
  synonyms, related concepts, metaphors, objects, actions, opposites. Mine each for roots.
- **Root-word / etymology mining.** Trace a concept to its Latin/Greek/Norse/Arabic roots and truncate
  to ownable stubs (see [`../../skills/name-search/references/generation.md`](../../skills/name-search/references/generation.md)
  language veins). *fides → fidavel; clarus → clarivo.*
- **Combinatorial / matrix.** List A = roots for value 1; List B = roots/affixes for value 2; generate
  the A×B grid, keep the phonetically pleasing cells (*verify × vault → vervault*).
- **Thesaurus laddering.** Walk synonym→synonym away from the obvious word until you reach a fresh,
  un-saturated region of the lexicon.
- **Reversal / opposite.** Name from the *enemy* or the inverse (Outlaw archetype): reclaim a negative,
  or invert the category cliché.
- **Dead / foreign-language mining.** Latin, Ancient Greek, Old Norse, Sanskrit, plus living languages
  — near-zero brand footprint, built-in meaning (verify connotation!).
- **Scientific taxonomy.** Genera/species, the periodic table, constellations, anatomical/botanical
  terms — real, obscure, evocative (see [`dev-tool-conventions.md`](dev-tool-conventions.md)).
- **Mythological pantheons.** Walk a whole pantheon (Greek, Norse, Egyptian, Yoruba) for a figure
  whose trait matches the value.
- **Affix transform.** Apply [`affix-catalogue.md`](affix-catalogue.md) hooks to surviving roots.
- **Phonosemantic nudge.** Tune each candidate's sound to the archetype palette
  ([`phonosemantics.md`](phonosemantics.md)).

## Token discipline

These methods run **inside one vein-agent** — they do not spawn per-name work. The agent returns a
batch of candidates (with a syllable count + one-line rationale tying each to a charter value); the
**script** does every availability check, once, for the whole pooled list. Aim 40–60 deduped across
all active veins.
