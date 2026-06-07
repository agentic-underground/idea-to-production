---
name: self-improve
description: >
  Improve MISSION-CONTROL itself by folding operational feedback back into its signals, SLOs, runbooks, and
  cadence — and by self-cleaving over-broad elements. Trigger with /mission-control:self-improve (or "an
  incident surprised us — fix it", "this alert is noisy", "we missed a signal", "fold this postmortem
  action in", "self-improve the observability skill"). Reflects one element against the covenant + pillars,
  applies the fix on a branch, runs the adversarial review (foundry's /foundry:pr-review if installed), and
  opens a PR so every future operate cycle, for all users, is calmer and catches more, sooner.
metadata:
  type: producer
  output: a sharpened signal/SLO/runbook/element on a branch → adversarial review → PR
  model: inherit
---

# MISSION-CONTROL — Self-improve

The operate half of the marketplace's self-improving loop. An incident that **surprised us** (no runbook,
no alert, an unwatched signal) or an alert that **flooded the on-call** (fired without action) is the
signal: the fix is a *better-articulated signal, SLO, or runbook*, fixed once, upstream — not heroics.
(Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake

MISSION-CONTROL gets sharper from two sources:

1. **Outcome feedback** — an incident that an OPERATE-READY verdict should have foreseen (an unwatched
   golden signal, a missing rollback, an undefined SLO), or an alert a user reported as noise. Arrives as an
   operational-feedback entry (symptom → which signal/SLO/runbook/threshold failed → what would have caught
   it / what over-fired).
2. **Recurring toil/noise** — the same manual task keeps recurring (→ automate), or the same alert keeps
   firing without action (→ tighten or delete), or the same incident-class keeps recurring (→ runbook).

## The loop

1. **Reflect** on the target element (a golden signal/SLI, an SLO, an alert rule, a runbook, the
   `operate-canon`, a skill) against the covenant + pillars: is a signal missing? is an alert over-broad
   (fatigue)? is a runbook absent for a recurring incident? does a skill do more than one thing (→ **cleave**
   it)?
2. **Decide**: add a golden-signal/SLI · recalibrate an SLO to reality · tighten or delete an alert ·
   add/extend a runbook · add a `maintain` cadence item · reference-not-restate. If the element is already
   tight, say so and stop.
3. **Apply on a branch** (surgical, one concern). Pin the miss/false-alarm so it cannot regress.
4. **Adversarial gate**: run **`/foundry:pr-review`** if foundry is installed; otherwise self-review against
   the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), per the user's merge-governance (FOUNDRY's
   `pr-approval` default), so the improvement reaches every user.

Each pass must leave MISSION-CONTROL **measurably better at catching real incidents and quieter on benign
conditions** — at least halving the remaining distance.
