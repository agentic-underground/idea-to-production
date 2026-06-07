# i2p — pillars & the SOLID self-improvement covenant

> This plugin's own anchor for the marketplace's governing philosophy. Like every `idea-to-production`
> plugin, the **i2p** front door is bound by the **three pillars** and the **SOLID self-improvement
> covenant**. (The canonical, in-depth homes live in the `foundry` plugin's `knowledge/` —
> `architecture/solid-covenant.md` and `pillars/`; this is the local copy a standalone install carries,
> referenced by concept, not by a cross-plugin path.)

## The three pillars

- **Knowledge-parity** (≡ *knowledge-alignment*) — the front door's whole job is to close the gap between
  *powers a user has* and *powers a user knows about*. Every recurring "how do I…?" becomes a written
  answer in `/i2p-help`, asked once. It never describes a capability it cannot confirm is installed.
- **Quality-first** (≡ *quality-confidence*) — `/i2p-review` is a **gate**, not a summary: it returns one
  honest verdict (BLOCK > NEEDS_REVISION > PASS) and is never weakened to make a change look mergeable.
  A reviewer it cannot run is reported as a **gap**, never silently dropped to a green light.
- **Waste-elimination** — remove waste in every form, *including rediscovery*. The front door **delegates,
  never duplicates**: it composes the seven specialist plugins' existing skills rather than re-implementing
  their logic, so a lesson learned in one place is never re-litigated here.

> **Overarching constraint — token-efficiency:** thin skills, fat references; define once, reference
> many; load only what a command needs. The four i2p skills are deliberately thin front-ends that hand
> off to the specialists.

## The SOLID self-improvement covenant

Every element of this plugin continuously asks how it can improve, and each iteration must at least
**halve the remaining distance to perfection**; an element that grows to do more than one thing
**self-cleaves** into smaller, single-purpose elements.

For a **front door**, improvement is folding **discoverability feedback** back into itself: when a user
could not find a power they had, or `/i2p-review` missed a reviewer it should have run, that becomes a
sharper `/i2p-help` entry, a new tip, or a new reviewer in the fan-out — landed via branch → adversarial
review → **PR**, so **every future session, for all users, surfaces it by default**.

> A power that exists but stays hidden has not honoured the covenant — and the fix is upstream: a better
> `/i2p-help` line or tip, fixed once. The front door composes with — never duplicates — the specialist
> plugins; where a capability is absent, it says so plainly rather than pretending coverage.
