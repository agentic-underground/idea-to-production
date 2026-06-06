---
name: self-improve
description: >
  Improve the i2p front door itself by folding discoverability feedback back into /i2p-help, the tips, and
  the /i2p-review fan-out — and by self-cleaving over-broad elements. Trigger with /i2p:self-improve (or
  "a user couldn't find a power they had — fix the front door", "/i2p-review missed a reviewer it should
  run", "fold this onboarding feedback in"). Reflects one element against the covenant + pillars, applies
  the fix on a branch, runs the adversarial review (foundry's /foundry:pr-review if installed), and opens a
  PR so every future session, for all users, surfaces the power by default.
metadata:
  type: producer
  output: a sharpened /i2p-help entry / new tip / added reviewer in the fan-out / cleaved element on a branch → review → PR
model: inherit
---

# i2p — Self-improve

The front door half of the marketplace's self-improving loop. A power that **exists but stayed hidden** —
a user who never found `/i2p-review`, a stage missing from `/i2p-flow`, a new specialist reviewer the
fan-out never called — is the signal: the fix is a *better `/i2p-help` line, a new tip, or a new lens in
`/i2p-review`*, fixed once, upstream — not a one-off explanation in chat. (Covenant:
[`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake (cross-project learning)

i2p gets sharper from **discoverability feedback** — a user who couldn't find a capability they had, a
`/i2p-review` that omitted a reviewer, a tip that misdescribed a command, or a new plugin added to the
marketplace that the front door doesn't yet announce. Each entry is **symptom → which front door surface let
it through → what would have surfaced it** (e.g. *"the user hand-rolled a security check → `/i2p-help`
didn't mention sentinel's `/security-gate` at the SECURE stage; add it"*).

## The loop

1. **Reflect** on the target element (a `/i2p-help` entry, the value-flow map, a tip in `tips/tips.tsv`,
   the `/i2p-review` lens set, a skill) against the covenant + pillars: is a power undiscoverable? does
   `/i2p-review` miss an installed reviewer? does a tip overstate or misname a command? does a skill do
   more than one thing (→ **cleave** it)? does it duplicate a specialist instead of delegating?
2. **Decide**: sharpen the `/i2p-help` menu / add or fix a tip / add a lens to `/i2p-review` / update the
   `/i2p-flow` map / cleave / reference-not-restate. If the element is already tight, say so and stop.
3. **Apply on a branch** (surgical, one concern). Keep i2p **thin** — improvement means composing the
   specialists better, never absorbing their logic.
4. **Adversarial gate**: run **`/foundry:pr-review`** if foundry is installed; otherwise self-review
   against the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), following the user's merge governance
   (FOUNDRY's `pr-approval` default), so the improvement reaches every user.

Each pass must leave i2p **measurably better at closing the gap between powers-held and powers-known** — at
least halving the remaining distance. Record the recurring miss so the next like power is surfaced by
default.
