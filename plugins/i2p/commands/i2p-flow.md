---
description: Show the idea-to-production value flow — where each installed plugin sits across DISCOVER ▸ IDEATE ▸ BUILD ▸ DESIGN ▸ SECURE ▸ PUBLISH and the next command to run at each stage (Mermaid when available, else markdown).
---

Explain the value flow. Follow the [`flow` skill](../skills/flow/SKILL.md):

1. Lay out the six stages — DISCOVER ▸ IDEATE ▸ BUILD ▸ DESIGN (cross-cutting) ▸ SECURE ▸ PUBLISH — and
   place each **installed** plugin on it, with the headline command at each stage and the artefact it
   produces.
2. Mark which stages are **dark** (plugin not installed) and what installing it would unlock.
3. If `$ARGUMENTS` names a starting point (e.g. "I have a raw idea", "I have a PR"), trace just the path
   from there to PRODUCTION as an ordered list of commands.
4. Render a **Mermaid** flow diagram when pressroom or atelier is installed (defer to their renderers);
   otherwise emit a clean ASCII/markdown map.

Ground the description in `plugins/foundry/VALUE_FLOW.md` and the marketplace `README.md` composition
diagram. Keep it to a map plus a "your next command" line — not a tutorial.
