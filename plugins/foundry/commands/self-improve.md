---
description: Reflect on ONE marketplace element (agent/skill/command/knowledge doc) against the KAIZEN covenant + pillars and improve it — usually by self-cleaving an over-broad element into smaller single-purpose ones, or replacing restated knowledge with a reference. Applies on a branch → /foundry:pr-review → PR per merge governance (never self-merges).
---

Run a targeted self-improvement. Follow the [`self-improve` skill](../skills/self-improve/SKILL.md):

1. **Reflect** on `$ARGUMENTS` (an element path or name) against the KAIZEN covenant, the three pillars,
   and the inspector's lenses — focused on this one element (Single-Responsibility, knowledge-
   restatement, clarity, drift, portability).
2. **Decide** the move: **cleave** (split an over-broad element into smaller single-purpose ones),
   **reference** (replace restated canon with a link), **segregate**, or **repair at the source** — or,
   if the element is already tight, say so and stop.
3. For a cleave, **rewire** every reference and **register** any new element (the propagation checklist).
4. **Apply on a branch** (or just propose, with `--dry-run`), run **`/foundry:pr-review`**, and on PASS
   **open a PR targeting `main`** per merge governance for the human to merge — never self-merge.

Distinct from `/foundry:inspect` (which audits the whole plugin). This fixes **one element, well**.
