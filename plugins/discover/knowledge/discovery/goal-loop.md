# The goal → scan → narrow loop

> The one-copy home for **how a standing discovery `/discovery-goal` drives iterative scanning**. Referenced by
> the `goal-setter` and `market-scan` skills.

## The `/discovery-goal` — a standing discovery objective

A goal bounds the search space so scans are focused, not infinite. It captures the *constraints on what
to discover* (distinct from an IDEA, which is *one chosen thing to build*). Fields (set infer-first, each
with a recommended default + multiple-choice; leave blank = "open, surprise me"):

- **Domain / niche interest** — where to look (e.g. "developer tools", "indie creators", "local trades").
- **Builder edge** — domain insight or unfair advantage the builder brings (founder-market fit).
- **Target price band** — the intended price range (reconciled later against the value ceiling).
- **Stack-fit** — which FOUNDRY handlers the build should map to (constrains buildability).
- **Effort / time-to-MVP appetite** — days, small weeks, longer.
- **Constraints** — anything off the table (regulated markets, hardware, etc.).

Stored as a project-local marker (e.g. `.discover/goal.md`) so a loop can read it across runs.
Absent ⇒ the scan asks for the minimum needed before proposing candidates.

## The loop

```
/discovery-goal ──► set/refine the objective
   │
   ▼
/market-scan ──► propose candidate opportunities that fit the goal
   │              (3–5 at a time; breadth before depth)
   ▼
score each against the parameter taxonomy ──► KILL the weak ones immediately
   │
   ▼
NARROW ──► take the 1–2 survivors deeper (probe demand, WTP, channel, wedge)
   │
   ▼
KEEP one (the spark) ──► hand to the ideator plugin (when installed)
   │  …or none survive ──►
   └──────────────► refine /discovery-goal (loosen a constraint, shift the niche) and loop again
```

`/loop` reuses Claude Code's **built-in loop** over the goal — self-paced ideation (`/loop /market-scan`
or an interval) — there is no bespoke scheduler here. Each pass should leave the search **measurably
narrower or the goal sharper**; a pass that surfaces only already-killed shapes means the goal needs
refining (or the niche is genuinely barren — say so, don't manufacture candidates).

## Closing the loop with downstream feedback

When the conveyor later learns something an opportunity got wrong (e.g. it shipped but no one paid), that
**ideation-feedback** flows back here and into [`scoring.md`](scoring.md)'s kill ledger via the plugin's
`self-improve` loop — so the goal-loop proposes better-fitting candidates next time. The spark compounds.
