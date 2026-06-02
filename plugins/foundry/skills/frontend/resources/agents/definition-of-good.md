# Definition of Good

The standard a FRONT-END artifact is scored against. A screen/element is *good* when it passes all non-negotiables and earns a strong showing across the defaults. Used by the design-critic and by self-critique before presenting.

## Non-negotiable (any failure = not shippable)
- **Customer is known.** The `customer` marker is filled; the design demonstrably fits that customer.
- **Accessibility (WCAG 2.1 AA).** Keyboard-operable end-to-end; visible focus; contrast ≥4.5:1 (≥3:1 large/UI); targets ≥44×44px; name/role/value present; errors in text; no colour-only signalling; reduced-motion respected.
- **Privacy honoured.** Local-first unless the developer explicitly opted into cloud; no unrequested cloud-save; import/export offered where sharing matters.
- **One-way binding.** Element renders from inputs, emits intents, mutates nothing it doesn't own; render-triggers declared.
- **Real-time validation.** Present, non-destructive, focus-preserving.
- **Markers present.** `intent` (human-readable why) and `customer` filled; ≥1 honest `improve?`; contracts in `breadcrumbs`.

## Strong (scored; weaknesses must be justified or marked)
- **Three modalities.** Touch within the three-tap ceiling; mouse affordances; full keyboard operability and flow.
- **Cognitive load.** One primary focus per panel; groups within ~5 inputs / 7±2 chunking; option sets grouped per Hick's Law.
- **Density.** Sensible default (moderate unless customer says otherwise); toggle where it helps.
- **Paradigm & style fit.** Chosen paradigm and words/operation register match customer + task.
- **Layout & flow.** Clear hierarchy, logical tab order, no layout shift, frictionless repetitive-toil path.
- **Look-and-feel.** Committed, coherent aesthetic via tokens; dark-mode default with a deliberate light theme.
- **Coherence with neighbours.** Honours existing `@front-end` markers; extends rather than dilutes the established direction.

## Delight (bonus — the "at best" bar)
- A memorable, customer-appropriate moment (e.g. a reader's gentle cover-tile lift) achieved without harming load, a11y, or performance.
- A genuinely useful `improve?` that moves the meta-UI forward.
