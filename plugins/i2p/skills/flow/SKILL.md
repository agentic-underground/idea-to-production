---
name: flow
description: >
  The value-flow map. Use for /i2p:flow (or "show me the value flow", "where does each plugin
  fit?", "what's my next step?", "draw the idea-to-production pipeline"). Places each installed
  plugin on DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE, names the
  headline command and artefact at each stage, marks dark stages, and — given a starting point —
  traces the ordered path to PRODUCTION. Renders Mermaid when a renderer is present, else markdown.
metadata:
  type: front-door
  output: a value-flow map + "your next command" (Mermaid when publish/atelier present, else markdown)
  composes: [publish/atelier renderers by capability — read-only]
model: inherit
---

# i2p — The value flow

Answers "where does each plugin fit, and **what do I run next?**" The marketplace is a conveyor that
carries VALUE from IDEA to PRODUCTION; this draws the map with only the parts you have.

---

## 1. The stages

```
                                            ┌──────── fail ◀───────┐
                                            ▼                      │
DISCOVER ──▶ IDEATE ─▶ DELIVER ─▶ DESIGN ─▶ BUILD ─▶ ASSURE ─▶ SECURE ─▶ PUBLISH ─▶ OPERATE ↻
market-       ideator  flow +     atelier   foundry  foundry   security  publish  mission-
scanner                roadmapper                    (quality) (security)          control
                                            └──── BUILD ⇄ ASSURE ⇄ SECURE loop ────┘
 /discovery-  /ideate  /flow:pull  /mockup  IDEA▶…▶ /pr-review /scan-all /publish  observe ·
 goal +                +/roadmapper /ui-rev   SHIP   (quality)                      iterate ↻→DISCOVER
 /market-scan
```

Nine phases forming a **cycle** — OPERATE's learnings loop back to DISCOVER. **DELIVER** sits between
IDEATE and DESIGN: it turns the IDEA package into a dependency-ordered roadmap and pulls the next item
into delivery (intake → EARS/feature authoring → decomposition → **`/flow:pull`** the next item),
owned by **the flow plugin (DELIVER) — headline `/flow:pull`, artefact a dependency-ordered roadmap +
a delivered increment — plus `foundry:roadmapper`** (EARS/feature authoring). The three
realisation phases **BUILD ⇄ ASSURE ⇄ SECURE** form a **loop**, not a straight line — a failed quality or
security gate sends the work *back* to BUILD (the `fail` back-edge), and the loop exits to PUBLISH only
when all three are satisfied. **ASSURE** (foundry, quality V&V) and **SECURE** (security, security) are
**separate first-class gates**. Three concerns **cross-cut** every phase: usability (atelier/DESIGN),
quality (foundry/ASSURE — built-in not inspected-in), security (security/SECURE — baked in from the
start). For each stage, give: the plugin, its **headline command**, and the **artefact** it produces (an
OPPORTUNITY → an IDEA package → a dependency-ordered roadmap → a design-reviewed screen → tested code → a
quality PASS → a SECURITY-REPORT → an article/PDF → a live, observed product). Ground the wording in
`plugins/i2p/knowledge/product-lifecycle.md` (canonical), `plugins/foundry/VALUE_FLOW.md`, and the
marketplace `README.md` composition diagram.

## 2. Light vs dark

Place only **installed** plugins as live stages. Mark each missing plugin's stage as dark:
"▫ DISCOVER — add `market-scanner` to find what's worth building" / "▫ DELIVER — add the `flow` plugin to
turn the IDEA package into a dependency-ordered roadmap and pull the next item with `/flow:pull` (with
`foundry:roadmapper` authoring the EARS specs)" / "▫ OPERATE — add `operate` to observe, respond to
incidents, and iterate the live product." A user should see both the path they have and the path they
could unlock. (The **flow** plugin owns DELIVER — **headline `/flow:pull`** (also `/flow report|carry`
and `/flow:flow-setup` for the one-time MCP setup); treat it like any other specialist: list it as a LIVE
stage with `/flow:pull` when installed, mark DELIVER dark when it is not — name the stage and its owner
regardless; graceful degradation, the gap named not skipped.)

## 3. Trace a path (if asked)

If `$ARGUMENTS` names a starting point — "I have a raw idea", "I have a validated opportunity", "I have a
PR to ship" — output the **ordered list of commands** from there to PRODUCTION, skipping stages whose
plugin is absent (and noting the skip).

## 4. Render

- If **publish** or **atelier** is installed, emit a **Mermaid** `flowchart LR` and defer rendering to
  their engine (so it's legible wherever it lands). The Mermaid SHALL route through **DELIVER** between
  IDEATE and DESIGN and draw the **BUILD ⇄ ASSURE ⇄ SECURE loop** with its back-edge (an
  `ASSURE -->|fail| BUILD` / `SECURE -->|fail| BUILD` edge), not a straight line.
- Otherwise, emit the ASCII/markdown map above, tailored to what's installed (it already shows DELIVER and
  the loop back-edge).

Close with a single **"your next command"** line.

---

## Self-improvement covenant

Inherits the front door covenant (`knowledge/covenant.md`). When the flow gains a stage or a plugin, this
map is the one place that learns it — update once, every `/i2p:flow` inherits it.
