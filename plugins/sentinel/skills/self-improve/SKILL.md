---
name: self-improve
description: >
  Improve SENTINEL itself by folding detection feedback back into its patterns, precision boundaries, and
  gates — and by self-cleaving over-broad elements. Trigger with /sentinel:self-improve (or "the scan
  missed a vuln — fix it", "this rule is too noisy", "fold this finding back in", "self-improve the
  secret-scan skill"). Reflects one element against the covenant + pillars, applies the fix on a branch,
  runs the adversarial review (foundry's /foundry:pr-review if installed), and opens a PR so every future
  scan, for all users, gets safer and quieter.
metadata:
  type: producer
  output: a sharpened pattern/precision-boundary/element on a branch → adversarial review → PR
model: inherit
---

# SENTINEL — Self-improve

The security half of the marketplace's self-improving loop. A scan that **missed a risk** (false negative)
or **flooded the user** (false positive) is the signal: the fix is a *better-articulated detection or
precision boundary*, fixed once, upstream — not a louder rule. (Covenant:
[`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake

SENTINEL gets sharper from two sources:

1. **Outcome feedback** — a risk shipped that a scan should have caught (a leaked secret, an unpinned
   vulnerable dep, a PII exposure), or a user reported a finding as a false positive. Arrives as a
   detection-feedback entry (symptom → which pattern/boundary failed → what would have caught it / what
   over-matched).
2. **Recurring noise/miss** — the same finding-class keeps slipping through, or the same benign pattern
   keeps tripping a rule.

## The loop

1. **Reflect** on the target element (a secret pattern, a PII definition, a dependency rule, the
   security-gate composition, a skill) against the covenant + pillars: is a detection missing? is a pattern
   over-broad (false positives)? does a skill do more than one thing (→ **cleave** it)?
2. **Decide**: add/tighten a pattern (`secret-scan/references/SECRET-PATTERNS.md`,
   `pii-audit/references/PII-DEFINITION.md`) · adjust a precision boundary · cleave · reference-not-restate.
   If the element is already tight, say so and stop.
3. **Apply on a branch** (surgical, one concern). Add or adjust the matching test fixture so the
   miss/false-positive is pinned and cannot regress.
4. **Adversarial gate**: run **`/foundry:pr-review`** if foundry is installed; otherwise self-review against
   the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), per the user's merge-governance (FOUNDRY's
   `pr-approval` default), so the improvement reaches every user.

Each pass must leave SENTINEL **measurably better at catching real risks and quieter on benign code** — at
least halving the remaining distance.
