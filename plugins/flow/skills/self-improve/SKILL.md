---
name: self-improve
description: >
  Improve FLOW itself by folding delivery feedback back into its carry verbs, the flow-mcp contract, and
  its references — and by self-cleaving over-broad elements. Trigger with /flow:self-improve (or "an item
  stalled in a lane — fix it", "the board came up empty on a populated roadmap", "this verb re-implements
  foundry", "fold this delivery friction in", "self-improve the pull skill"). Reflects one element against
  the covenant + pillars, applies the fix on a branch, runs the adversarial review (foundry's
  /foundry:pr-review if installed), and opens a PR so every future delivery, for all users, flows cleaner
  and answers faster.
metadata:
  type: producer
  output: a sharpened verb/contract/reference/element on a branch → adversarial review → PR
  model: inherit
---

# FLOW — Self-improve

The delivery half of the marketplace's self-improving loop. A carry that **stalled** (an item stuck in a
lane, an empty board where a roadmap existed, the server not serving a populated tree) or a verb that
**over-reached** (a wrapper that re-implemented what foundry already owns) is the signal: the fix is a
*better-articulated verb, flow-mcp contract, or reference*, fixed once, upstream — not heroics.
(Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## Feedback intake

FLOW gets sharper from two sources:

1. **Outcome feedback** — a delivery that the carry surface should have handled cleanly: `/flow:pull` came
   up empty on a populated `.i2p/roadmap/`, the board came up empty on a populated tree (flow-mcp not
   serving it — Ruby missing or the `/mcp` approval not granted), a state move recorded the wrong
   who/what/cost, or `/flow-setup` left the MCP unreachable. Arrives as a delivery-feedback entry (symptom →
   which verb/contract/server path failed → what would have carried it correctly).
2. **Recurring friction/duplication** — the same carry step keeps needing a manual nudge (→ automate or
   tighten the verb), or a skill restates what the flow-mcp README / foundry conveyor already owns
   (→ reference-not-restate), or a verb has grown a second responsibility (→ **cleave** it).

## The loop

1. **Reflect** on the target element (a carry verb — `flow`, `pull`, `flow-setup`; the flow-mcp server
   contract; the `check` manifest; the `covenant`; a knowledge doc) against the covenant + pillars: is a
   verb doing more than one thing? does `/flow:pull` re-implement foundry instead of composing it? does the
   server serve a non-deterministic answer? does a skill restate what a reference already owns?
2. **Decide**: sharpen a verb · tighten the flow-mcp server contract · fix a degrade-gracefully gap
   in a hook · correct the `check` tiers to reality · reference-not-restate · **cleave** an over-broad
   element. If the element is already tight, say so and stop.
3. **Apply on a branch** (surgical, one concern). Pin the stall/duplication so it cannot regress.
4. **Adversarial gate**: run **`/foundry:pr-review`** if foundry is installed; otherwise self-review against
   the covenant and state the gate ran in reduced form.
5. **Open a PR** for the human to merge (never self-merge), per the user's merge-governance (FOUNDRY's
   `pr-approval` default), so the improvement reaches every user.

Each pass must leave FLOW **measurably better at carrying real items to delivery and faster at answering
"what's on the roadmap"** — at least halving the remaining distance.
