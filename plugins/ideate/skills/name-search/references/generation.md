# Generation — casting a wide, layered net

The job of generation is **breadth then distinctiveness**: produce many candidates from genuinely
different sources so the survivors aren't minor variations of one idea. Run veins **in parallel, one
agent per vein** (never one per name). Each vein returns candidates with a syllable count and a
one-line rationale tying the name to a charter value.

Honour the charter throughout: the **ranked values**, **archetype**, **name-type strategy**, **risk
appetite**, **syllable target**, **banned/saturated stems**, language/tone. The candidate pool is
checked by the script in one call ([`../scripts/namecheck.sh`](../scripts/namecheck.sh)); culling is
the deterministic verify + the scored challenge ([`evaluation-rubric.md`](evaluation-rubric.md)) — not
this phase.

> **This is no longer "coined words only."** The old net produced one kind of name. Generation is now
> **layered**: a primary *name-type* layer (selected by the charter), a *language/etymology* layer, and
> transform layers (*affix hooks*, *phonosemantic tuning*) — plus the *power-adjacency* and *humour*
> veins when the brief asks for them.

## Layer 1 — Name-type veins (primary; selected by the charter)

Run the veins the charter's **name-type strategy** selects (typically 4–8, not all). Full catalogue
with examples and trademark strength: [`../../../knowledge/naming/name-types.md`](../../../knowledge/naming/name-types.md).
The strategy maps roughly:

- **Trustworthy / clear brief** → suggestive · compound · metaphor · descriptive.
- **Bold / abstract brief** → coined/fanciful · arbitrary real-word · scientific-taxonomic · portmanteau.
- **Acronym/initialism brief** → acronym · **backronym** (a word that *also* encodes the philosophy as
  initials) · numeronym. (Short forms are mostly taken — favour longer backronyms.)
- Always available where they fit: animal/nature, mythological allusion, foreign-borrow, reduplication,
  onomatopoeia, real-word-respell.

## Layer 2 — Language / etymology veins

Mine roots across tongues (truncate and *fuse*, don't concatenate):

1. **Latin / Greek** — concept roots (proof, clear, light, threshold, vouch). *fides→fidavel.*
2. **Romance** (It/Es/Fr/Pt) — warm, vowel-rich; diminutive/agentive suffixes.
3. **Norse / Old English / Germanic** — hard consonants, gatekeeping/proof roots (*ward, wit, rune*).
4. **Japanese / Korean** — open syllables (ka, ki, ru, na), modern, culturally neutral.
5. **Arabic / Semitic** — trust/safety roots (*amn, wafa, haqq*); near-zero brand footprint.
6. **Pure phonetic invention** — Snyk/Tessl/Sonos-style; punchy, ownable.

## Layer 3 — Transforms (apply across layers 1–2)

- **Affix hooks** — bolt charter-appropriate prefixes/suffixes onto roots for catchiness + a clean
  namespace: [`../../../knowledge/naming/affix-catalogue.md`](../../../knowledge/naming/affix-catalogue.md).
  One hook per name; the hook must add a *signal*, not just availability.
- **Phonosemantic tuning** — match each candidate's *sound* to the archetype palette
  ([`../../../knowledge/naming/phonosemantics.md`](../../../knowledge/naming/phonosemantics.md)): plosive
  vs sonorant initials, front vs back vowels, rhythm. Nudge mismatches; cut the unsayable.

## Layer 4 — Power-adjacency & humour veins (opt-in via the brief)

- **Power-adjacency / borrowed equity** — myth/science/Latin whose canonical trait matches the value
  ([`../../../knowledge/naming/dev-tool-conventions.md`](../../../knowledge/naming/dev-tool-conventions.md)).
  Fire only when the brief names power-adjacency targets.
- **Intellectual humour / pun** — the insider wink, gated on the brief's humour appetite (none ↔ subtle
  ↔ overt). Beware the SCRATCH "curse-of-knowledge" risk for non-dev audiences.

## Ideation methods (prime each vein)

Each vein-agent goes wide *within* its vein using
[`../../../knowledge/naming/ideation-methods.md`](../../../knowledge/naming/ideation-methods.md)
(semantic fields, root mining, combinatorial matrix, thesaurus laddering, reversal, dead-language,
taxonomy/pantheons) — without spawning per-name work.

## Quality bar per candidate

Easy to say + spell on first hearing · sound matches the archetype · encodes ≥1 charter value traceably
· within the syllable target · avoids every banned stem · honours the name-type strategy. **Real-word,
foreign-borrow, and humour candidates are flagged for the connotation + trademark challenge** — never
self-cleared. Generate generously (aim 40–60 deduped across active veins); the script + rubric cull.
