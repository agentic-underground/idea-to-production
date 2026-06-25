---
name: self-improve
description: >
  Improve DISCOVER itself by folding downstream feedback back into its parameters, scoring, and
  kill ledger — and by self-cleaving over-broad elements. Trigger with /discover:self-improve (or
  "the scanner approved a dud — fix it", "fold this ideation feedback in", "self-improve the market-scan
  skill"). Reflects one element against the covenant + pillars, applies the fix on a branch, runs the
  adversarial review (deliver's /deliver:pr-review if installed), and opens a PR so every future scan,
  for all users, gets sharper.
metadata:
  type: producer
  output: a sharpened parameter/scoring/element on a branch → adversarial review → PR
model: inherit
---

# DISCOVER — Self-improve

The discovery half of the marketplace's self-improving loop. A scan that **approved a candidate it
should have killed** is the signal: the fix is a *better-articulated parameter or kill-threshold*, fixed
once, upstream — not a louder rule. (Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake (cross-project learning)

The scanner gets sharper from two sources:

1. **Outcome feedback** — an opportunity it approved turned out weak (shipped, no one paid; the channel
   never materialised; an incumbent crushed it). This arrives as an **ideation-feedback** entry
   (symptom → which parameter was too weak → what would have caught it), emitted by DELIVER's LEARN
   station / FOUNDER when the conveyor learns the truth.
2. **Recurring survival** — the same *kind* of weak candidate keeps surviving the scan (flagged by the
   `market-scan` skill).

## The loop

1. **Reflect** on the target element (a parameter row, the scoring rubric, a skill) against the covenant
   + pillars: is a kill-threshold too lax? is a parameter missing? does a skill do more than one thing
   (→ **cleave** it)?
2. **Decide**: sharpen a parameter / add a kill-threshold / add a kill-ledger ANTI-PATTERN
   ([`../../knowledge/discovery/scoring.md`](../../knowledge/discovery/scoring.md)) / cleave / reference-
   not-restate. If the element is already tight, say so and stop.
3. **Apply on a branch** (surgical, one concern).
4. **Adversarial gate**: run **`/deliver:pr-review`** if the deliver plugin is installed; otherwise
   self-review against the covenant and state that the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), so the improvement reaches every user. Follow
   the merge-governance the user has set (DELIVER's `pr-approval` default).

Each pass must leave the scanner **measurably better at killing weak ideas early** — at least halving the
remaining distance. Record the recurring defect class as a kill-ledger ANTI-PATTERN so the next like
candidate dies on sight.
