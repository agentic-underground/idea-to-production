# SECURITY — pillars & the KAIZEN self-improvement covenant

> This plugin's own anchor for the marketplace's governing philosophy. Like every `idea-to-production`
> plugin, SECURITY is bound by the **three pillars** and the **KAIZEN self-improvement covenant**.
> (The canonical, in-depth homes live in the `foundry` plugin's `knowledge/`; this is the local copy a
> standalone install carries — referenced by concept, not by a cross-plugin path.)

## The three pillars

- **Knowledge-parity** (≡ *knowledge-alignment*) — understand the threat model before acting; a recurring
  finding-class becomes a written detection, found once. Never raise an alarm you cannot evidence
  (file:line + why), and never wave through a risk you cannot rule out.
- **Quality-first** (≡ *quality-confidence*) — quality is built in, not inspected in; **the security gate
  is never weakened to make progress**. A PASS/REVIEW/BLOCK verdict is earned, never granted to spare
  effort. Raise the floor instead of lowering the bar.
- **Waste-elimination** (≡ *muda · mura · muri*) — remove waste in every form, *including rediscovery*. A confirmed finding-class
  (and its false-positive boundary) is recorded once so the next like case is recognised on sight, with no
  re-litigation.

> **Overarching constraint — token-efficiency:** thin skills, fat references; define once, reference many;
> load only what a task needs. Deterministic scanners do the heavy lifting; the model judges and explains.

## The KAIZEN self-improvement covenant

Every element of this plugin — each skill, command, and knowledge doc — continuously asks how it can
improve, and each iteration must at least **halve the remaining distance to perfection**. When an element
grows to do more than one thing, it **self-cleaves** into smaller, single-purpose elements.

Concretely, SECURITY improves by folding **detection feedback** back into its patterns and gates: a
**missed** risk (false negative) or a **noisy** rule (false positive) that the conveyor or a user surfaces
becomes a sharper pattern or a tightened precision boundary, landed via branch → adversarial review →
**PR**, so **every future scan, for all users, gets safer and quieter**. The `self-improve` skill drives
this loop.

> A gate that passes something it should have flagged — or floods the user with false positives — has not
> honoured the covenant. The fix is not a louder rule but a **better-articulated detection or
> precision-boundary**, fixed once, upstream.
