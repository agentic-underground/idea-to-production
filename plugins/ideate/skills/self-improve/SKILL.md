---
name: self-improve
description: >
  Improve IDEATE itself by folding downstream feedback back into its challenge protocol and the IDEA-
  package contract — and by self-cleaving over-broad elements. Trigger with /ideate:self-improve (or
  "the builder hit an ambiguity the brief missed — fix it", "fold this ideation feedback in",
  "self-improve the ideate skill"). Reflects one element against the covenant + pillars, applies the fix
  on a branch, runs the adversarial review (deliver's /deliver:pr-review if installed), and opens a PR so
  every future ideation, for all users, asks the missing question by default.
metadata:
  type: producer
  output: a sharpened challenge axis / package field / element on a branch → adversarial review → PR
model: inherit
---

# IDEATE — Self-improve

The refinement half of the marketplace's self-improving loop. A package that **passed its exit gate yet
still produced a downstream ambiguity** is the signal: the fix is a *better-articulated challenge axis or
package field*, fixed once, upstream — not a louder rule. (Covenant:
[`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake (cross-project learning)

IDEATE gets sharper from **ideation-feedback** — emitted by DELIVER's LEARN station / FOUNDER when a
builder hits an ambiguity the IDEA package should have resolved. Each entry is **symptom → which IDEA-doc
field was unclear → what would have prevented it** (e.g. *"ACTORS said 'users' → step-1 couldn't write
EARS; the actor axis needed to force a named role"*).

## The loop

1. **Reflect** on the target element (a challenge axis, a package-contract field, the exit gate, a skill)
   against the covenant + pillars: is an axis missing a forcing question? does a package field allow a
   vague value? does a skill do more than one thing (→ **cleave** it)?
2. **Decide**: sharpen a challenge axis
   ([`../../knowledge/ideation/challenge-protocol.md`](../../knowledge/ideation/challenge-protocol.md)) /
   tighten a package field or exit-gate criterion
   ([`../../knowledge/ideation/idea-package.md`](../../knowledge/ideation/idea-package.md)) / cleave /
   reference-not-restate. If the element is already tight, say so and stop.
3. **Apply on a branch** (surgical, one concern). **When the change adds, renames, or cleaves a skill,
   update all four mirrors in the same branch** — `plugin.json` (keywords + `metadata.note`), the
   `marketplace.json` entry (description + keywords + version), the `README.md`, and
   `skills/check/requirements.tsv` (any new tool, tiered to who actually needs it). A capability that lives
   in only one of these is drift the inspector will flag; bump the version so the marketplace re-syncs.
4. **Adversarial gate**: run **`/deliver:pr-review`** if deliver is installed; otherwise self-review
   against the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), following the user's merge governance
   (DELIVER's `pr-approval` default), so the improvement reaches every user.

Each pass must leave IDEATE **measurably better at reaching knowledge-parity before hand-off** — at
least halving the remaining distance. Record the recurring ambiguity class so the next like idea is
disambiguated by default.
