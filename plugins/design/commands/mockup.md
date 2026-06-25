---
description: Design a polished, design-reviewed UI mockup, wireframe, or user-flow — composed to the design canon and run through the convergent designer↔reviewer loop until it clears the fitness rubric. Produces commercial-grade material, not a first draft.
---

Design with DESIGN. Follow the [`mockup` skill](../skills/mockup/SKILL.md):

1. **Recover intent.** Customer, job, constraints (platform, density, brand, modality) — read foundry
   `@front-end` markers / `definition-of-good` by capability if present; ask when the brief is thin.
2. **Design v0 to the canon** ([canon](../knowledge/canon/README.md)) — name the paradigm, type scale,
   spacing unit, palette, focal point. Don't free-hand.
3. **Run the convergent loop** ([protocol](../knowledge/protocols/design-critique-loop.md)): render
   (HTML/CSS screenshotted via the chrome-devtools MCP, or SVG wireframe; user-flows as Mermaid via publish
   `/publish` *by capability*) → invoke the **`ui-design-reviewer`** → apply HIGH+MED → re-render → re-score
   until CONVERGED / DIMINISHING-RETURNS (surface the impasse) / CAP.
4. **Deliver** under `docs/guide/design/mockups/<slug>/` — the artefact + a rationale (the canon choices) + the
   fitness score and any accepted residual.

Never present a draft that hasn't been through at least one review turn. Verify tools with `/design:check`.
