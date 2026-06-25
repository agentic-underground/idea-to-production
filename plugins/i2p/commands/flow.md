---
description: Show the idea-to-production value flow — where each installed plugin sits across DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE ↻ and the next command to run at each stage (Mermaid when available, else markdown).
---

Explain the value flow. Follow the [`flow` skill](../skills/flow/SKILL.md):

1. Lay out the nine phases (a cycle) — DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸
   PUBLISH ▸ OPERATE ↻ — and place each **installed** plugin on it, with the headline command at each stage
   and the artefact it produces. **DELIVER** sits between IDEATE and DESIGN, owned by
   **`foundry:roadmapper`** (`/roadmapper` authors the FLEET v2 `docs/roadmap/` pipeline: intake →
   EARS/feature → dependency-ordered EPIC/PLAN decomposition) plus the external **FLEET
   continuous-delivery engine** that drains it. ASSURE (foundry, quality) and SECURE (secure,
   security) are separate gates, and BUILD ⇄ ASSURE ⇄ SECURE is a **loop** (a failed gate re-enters
   BUILD); usability/quality/security cross-cut every phase.
2. Mark which stages are **dark** (plugin not installed) and what installing it would unlock — including
   DELIVER (owned by **`foundry:roadmapper`** — `/roadmapper`; the external FLEET `pipeline` plugin
   supplies the build engine — `/pipeline:status`, `/pipeline:run`; mark it dark when `foundry` is not
   installed, and name the stage and its owner regardless).
3. If `$ARGUMENTS` names a starting point (e.g. "I have a raw idea", "I have a PR"), trace just the path
   from there to PRODUCTION as an ordered list of commands, routing through DELIVER and showing the loop
   back-edge (ASSURE/SECURE fail → BUILD).
4. Render a **Mermaid** flow diagram when publish or design is installed (defer to their renderers) —
   route through DELIVER and draw the BUILD ⇄ ASSURE ⇄ SECURE loop back-edge; otherwise emit a clean
   ASCII/markdown map.

Ground the description in `plugins/foundry/VALUE_FLOW.md` and the marketplace `README.md` composition
diagram. Keep it to a map plus a "your next command" line — not a tutorial.
