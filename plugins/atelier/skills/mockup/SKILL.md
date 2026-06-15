---
name: mockup
description: >
  Design a polished UI mockup, wireframe, or user-flow — carefully composed and design-reviewed, not a
  first draft. Trigger with /mockup (or "mock up a screen for…", "design a wireframe", "draw the user
  flow", "sketch the onboarding screens"). Generates the artefact (renderable HTML/CSS screenshotted via
  the Playwright MCP, or an SVG wireframe; user-flows as Mermaid via pressroom by capability), then runs
  the convergent designer↔reviewer loop until it clears the design-fitness rubric. This is the capability
  IDEATOR calls so the user sees commercial-grade material, not whipped-up sketches.
metadata:
  type: producer
  output: a design-reviewed mockup / wireframe / user-flow (PNG/SVG/Mermaid) that clears the fitness rubric
model: inherit
---

# ATELIER — mockup (design, then converge)

The generator half of the studio. It makes screens and flows that are **carefully composed and reviewed
before anyone sees them** — closing the designer↔reviewer loop in one place. The output is never a first
draft: it is the artefact *after* the loop has raised it to the rubric.

> **Quality is the point.** A first-draft mockup handed to a user teaches them the wrong thing about the
> idea. ATELIER makes the considered version. (Canon:
> [`../../knowledge/canon/README.md`](../../knowledge/canon/README.md); loop:
> [`../../knowledge/protocols/design-critique-loop.md`](../../knowledge/protocols/design-critique-loop.md).)

## What it produces

| Ask | Artefact | How |
|---|---|---|
| A screen / page mockup | A rendered PNG (and the source) | Compose **HTML/CSS** to the canon (modular type scale, 8-pt spacing, disciplined palette, WCAG-AA contrast), render + screenshot via the Playwright MCP (`mcp__playwright__*`) at desktop + mobile. |
| A low-fidelity **wireframe** | An SVG / greyscale layout | Structure-first: hierarchy, grouping, and flow without colour/branding distraction. |
| A **user-flow** | A Mermaid `flowchart` / `journey` | Author the flow, then render it via **pressroom** `/publish` (format `diagrams`) **by capability** when installed; else emit Mermaid source in a fenced block. Obey the legibility law (≤~4 wide; decompose otherwise). |

## How to run

1. **Recover intent** (knowledge-parity). Who is the customer, what is the job, what are the constraints
   (platform, density, brand, modality)? Read foundry `@front-end` INTENT markers / `definition-of-good`
   by capability if present. Confirm rather than assume; **ask when the brief is thin** — one focused
   question at a time, with a recommended answer.
2. **Design v0** against the canon — don't free-hand. Pick the paradigm, the type scale, the spacing unit,
   the palette, the focal point. Name your choices (they become the artefact's rationale).
3. **Run the convergent loop** ([`../../knowledge/protocols/design-critique-loop.md`](../../knowledge/protocols/design-critique-loop.md)):
   render → invoke the **`ui-design-reviewer`** agent (score + prioritised findings) → apply every HIGH+MED
   → re-render → re-score. **Stop** on CONVERGED (no HIGH, gate clear, score ≥ target) / DIMINISHING-RETURNS
   (surface the impasse, ask the user) / CAP. Never present a draft that hasn't been through at least one
   review turn.
4. **Deliver** the artefact + a short **rationale** (the canon choices) + the **fitness score** and any
   accepted residual. Write under `docs/guide/design/mockups/<slug>/` (PNG/SVG/`.mmd` + `rationale.md`).

## Composition defaults (the starting point, then justify)

- **Type:** a modular scale (e.g. 1.25); 2 families max; measure 45–75 cpl for text.
- **Space:** an 8-pt grid; align everything; group by proximity/common-region before borders.
- **Colour:** neutral ramp + one accent (60-30-10); semantic states; never colour-only; AA contrast.
- **Hierarchy:** one focal point; primary action large and reachable (Fitts); choices grouped (Hick).
- **Accessibility from the first stroke** — keyboard path, focus, names/roles, targets ≥44px. Not a retrofit.

## Self-improvement

Carries the KAIZEN covenant. When a delivered mockup later proves weak in a way the loop didn't catch,
that's a canon/rubric gap → `self-improve` ([`../self-improve/SKILL.md`](../self-improve/SKILL.md)) → PR,
so the next mockup is better by default. When both ATELIER and foundry are present, offer the lesson to
foundry's source-level `design-critic` too.

## Product lifecycle (by capability)

When the product's primary **design phase** concludes and hands off to build (this is guarded, so in-build design reviews never jump the lifecycle), and the **i2p** plugin is installed, mark the **DESIGN** phase done so the marketplace
product lifecycle and the status line advance to BUILD:

```bash
/i2p-lifecycle done DESIGN   # order-safe & idempotent — a no-op unless a lifecycle is running at DESIGN
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
