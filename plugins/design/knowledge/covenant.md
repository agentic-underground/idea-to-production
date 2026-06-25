# DESIGN — pillars & the KAIZEN self-improvement covenant

> This plugin's own anchor for the marketplace's governing philosophy. Like every `idea-to-production`
> plugin, DESIGN is bound by the **three pillars** and the **KAIZEN self-improvement covenant**. (The
> canonical, in-depth homes live in the `foundry` plugin's `knowledge/`; this is the local copy a
> standalone install carries — referenced by concept, not by a cross-plugin path.)

## The three pillars

- **Knowledge-parity** (≡ *knowledge-alignment*) — understand the design intent completely **before**
  judging or making. DESIGN never critiques against unknown goals: it recovers the *customer*, the
  *job*, and the *constraints* first (asking when the target is ambiguous), then reviews against **named
  canon**, not taste. A recurring critique becomes a written rule in the [`canon/`](canon/README.md),
  asked once.
- **Quality-first** (≡ *quality-confidence*) — quality is built in, not inspected in; a gate is never
  weakened to make progress. DESIGN's gate is the **design-fitness rubric**
  ([`protocols/design-critique-loop.md`](protocols/design-critique-loop.md)): a mockup or screen is not
  "done" because the user is impatient — it is done when it clears the rubric, or its residual is
  *explicitly accepted*. Accessibility (WCAG 2.2 AA) is a floor, never traded away.
- **Waste-elimination** (≡ *muda · mura · muri*) — remove waste in every form, *including rediscovery and ping-pong*. The
  convergent loop **must measurably improve each turn or halt** — a reviewer that sends the designer in
  circles is the most expensive waste there is. Every resolved critique is written into the canon so the
  same flaw is never re-litigated.

> **Overarching constraint — token-efficiency:** thin skills, fat references; define once, reference
> many; load only the canon a given critique needs. The reviewer reads the screenshot + the relevant
> canon slice, not the whole library.

## The KAIZEN self-improvement covenant

Every element of this plugin continuously asks how it can improve, and each iteration must at least
**halve the remaining distance to perfection**; an element that grows to do more than one thing
**self-cleaves** into smaller, single-purpose elements.

Concretely, DESIGN improves by folding **design feedback** back into its canon and its fitness rubric:
when a shipped design proves weak in a way the reviewer missed (a hierarchy that confused real users, a
contrast that failed a device, a flow that dead-ended), that becomes a sharper canon rule or a new rubric
dimension — landed via branch → adversarial review → **PR**, so **every future review, for all users,
catches it by default**. The `self-improve` skill drives this loop.

> A design that passed the rubric yet still failed a real user has not honoured the covenant — and the
> fix is upstream: a better-articulated canon rule or rubric weight, fixed once. DESIGN composes with —
> never duplicates — foundry's source-level `frontend` design-critic; where both are present, a lesson
> learned here is offered to that critic too, so the discipline compounds across the build.
