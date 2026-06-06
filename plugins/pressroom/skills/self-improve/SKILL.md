---
name: self-improve
description: >
  Improve PRESSROOM itself by folding design feedback back into its charting-matrix, templates, and
  reviewer rubrics — and by self-cleaving over-broad elements. Trigger with /pressroom:self-improve (or
  "this chart passed review but read poorly — fix the matrix", "the PDF engine fell over — harden it",
  "fold this design feedback in", "self-improve the diagram-studio skill"). Reflects one element against
  the covenant + pillars, applies the fix on a branch, runs the adversarial review (foundry's
  /foundry:pr-review if installed), and opens a PR so every future publish, for all users, looks better.
metadata:
  type: producer
  output: a sharpened matrix entry / template / rubric on a branch → adversarial review → PR
model: inherit
---

# PRESSROOM — Self-improve

The publishing half of the marketplace's self-improving loop. A document that **passed the design review
but failed a real reader** — an illegible chart at A4, a widow on every page, an engine that fell over — is
the signal: the fix is a *sharper rubric or charting-matrix entry*, fixed once, upstream — not a one-off
touch-up. (Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake

PRESSROOM gets sharper from two sources:

1. **Design feedback** — a rendered artefact (chart, diagram, PDF page) that read poorly in the real target
   despite passing review, or an engine/render path that failed. Arrives as a design-feedback entry
   (symptom → which matrix rule/template/rubric was too weak → what would have caught it).
2. **Recurring defect** — the same legibility or layout failure keeps recurring across publishes.

## The loop

1. **Reflect** on the target element (a charting-matrix rule, a typst/latex template, a reviewer rubric, a
   skill) against the covenant + pillars: is a legibility rule missing? does a template produce
   widows/orphans? does a skill do more than one thing (→ **cleave** it)?
2. **Decide**: sharpen a charting-matrix entry / fix a template / tighten a reviewer rubric (the
   `design-reviewer` agents) / cleave / reference-not-restate. If the element is already tight, say so and
   stop.
3. **Apply on a branch** (surgical, one concern); update the shared lessons log so the defect class is
   pinned.
4. **Adversarial gate**: run **`/foundry:pr-review`** if foundry is installed; otherwise self-review against
   the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), per the user's merge-governance (FOUNDRY's
   `pr-approval` default), so the improvement reaches every user.

Each pass must leave PRESSROOM **measurably better at producing legible, print-quality artefacts** — at
least halving the remaining distance.
