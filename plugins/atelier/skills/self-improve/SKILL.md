---
name: self-improve
description: >
  Improve ATELIER itself by folding design feedback back into its canon and its design-fitness rubric —
  and by self-cleaving over-broad elements. Trigger with /atelier:self-improve (or "this design passed
  review but failed real users — fix the canon", "fold this design feedback in", "the reviewer keeps
  missing X"). Reflects one element against the covenant + pillars, applies the fix on a branch, runs the
  adversarial review (foundry's /foundry:pr-review if installed), and opens a PR so every future review
  and mockup, for all users, is sharper by default.
metadata:
  type: producer
  output: a sharpened canon rule / re-weighted rubric dimension / cleaved element on a branch → review → PR
model: inherit
---

# ATELIER — Self-improve

The design half of the marketplace's self-improving loop. A design that **passed the fitness rubric yet
still failed a real user** — a hierarchy that confused, a contrast that broke on a device, a flow that
dead-ended — is the signal: the fix is a *better-articulated canon rule or a re-weighted rubric dimension*,
fixed once, upstream — not a louder reviewer. (Covenant:
[`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake (cross-project learning)

ATELIER gets sharper from **design feedback** — from a downstream user, from a real-usage signal, or from
its own loop stalling. Each entry is **symptom → which canon/rubric gap let it through → what rule would
have caught it** (e.g. *"the CTA tested fine but users missed it → the hierarchy dimension didn't penalise
a primary action that loses the Von Restorff contrast; add that check"*). A loop that **stalls below
target** (diminishing-returns halt) is itself feedback: the reviewer couldn't name a converging fix.

## The loop

1. **Reflect** on the target element (a canon lens, a rubric dimension/weight, the loop's stop-conditions,
   a skill) against the covenant + pillars: is a canon rule missing a forcing check? does a rubric weight
   under-value a real failure? does the loop ping-pong (→ tighten the delta-floor / fix the reviewer)?
   does a skill do more than one thing (→ **cleave** it)?
2. **Decide**: sharpen a canon rule
   ([`../../knowledge/canon/README.md`](../../knowledge/canon/README.md)) / re-weight or add a rubric
   dimension ([`../../knowledge/protocols/design-critique-loop.md`](../../knowledge/protocols/design-critique-loop.md))
   / cleave / reference-not-restate. If the element is already tight, say so and stop.
3. **Apply on a branch** (surgical, one concern).
4. **Adversarial gate**: run **`/foundry:pr-review`** if foundry is installed; otherwise self-review
   against the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), following the user's merge governance
   (FOUNDRY's `pr-approval` default), so the improvement reaches every user. When foundry is present,
   offer the same lesson to its source-level `design-critic` so the discipline compounds across the build.

Each pass must leave ATELIER **measurably better at catching real design failures before they ship** — at
least halving the remaining distance. Record the recurring failure-class so the next like design is caught
by default.
