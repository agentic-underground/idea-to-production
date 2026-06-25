---
description: Set or refine the standing DISCOVERY GOAL that scans run over — the constraints on WHAT to discover (niche, builder edge, target price band, stack-fit, effort appetite). Infer-first, one question at a time with a recommended answer + multiple-choice; written to .discover/goal.md.
---

Set or refine the discovery goal. Follow the [`goal-setter` skill](../skills/goal-setter/SKILL.md):

1. Read `.discover/goal.md` if present (refining, not restarting).
2. Fill the fields infer-first from `$ARGUMENTS` and context — niche interest, builder edge, target price
   band, stack-fit, effort/time-to-MVP appetite, hard constraints — asking only what blocks a decision,
   one focused question at a time, **each with a recommended answer + multiple-choice**.
3. Write `.discover/goal.md`, confirm the goal back compactly, and offer the next move
   (`/market-scan` once, or `/loop /market-scan` to iterate over the goal).
