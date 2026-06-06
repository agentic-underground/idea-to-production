---
name: flow
description: >
  The value-flow map. Use for /i2p-flow (or "show me the value flow", "where does each plugin
  fit?", "what's my next step?", "draw the idea-to-production pipeline"). Places each installed
  plugin on DISCOVER ▸ IDEATE ▸ BUILD ▸ DESIGN ▸ SECURE ▸ PUBLISH, names the headline command and
  artefact at each stage, marks dark stages, and — given a starting point — traces the ordered path
  to PRODUCTION. Renders Mermaid when a renderer is present, else markdown.
metadata:
  type: front-door
  output: a value-flow map + "your next command" (Mermaid when pressroom/atelier present, else markdown)
  composes: [pressroom/atelier renderers by capability — read-only]
model: inherit
---

# i2p — The value flow

Answers "where does each plugin fit, and **what do I run next?**" The marketplace is a conveyor that
carries VALUE from IDEA to PRODUCTION; this draws the map with only the parts you have.

---

## 1. The stages

```
DISCOVER ──▶ IDEATE ──▶ BUILD ──────────────▶ SECURE / PUBLISH
market-scanner ideator  foundry               sentinel · pressroom
   /goal +     /ideate   IDEA ▶ ROADMAP ▶ … ▶ STORY ▶ SHIP
   /market-scan          │
                         ▼
   DESIGN (atelier) ── cross-cutting ──▶ /ui-review · /mockup
```

For each stage, give: the plugin, its **headline command**, and the **artefact** it produces (an
OPPORTUNITY → an IDEA package → tested code → a design-reviewed screen → a SECURITY-REPORT → an
article/PDF). Ground the wording in `plugins/foundry/VALUE_FLOW.md` and the marketplace `README.md`
composition diagram.

## 2. Light vs dark

Place only **installed** plugins as live stages. Mark each missing plugin's stage as dark:
"▫ DISCOVER — add `market-scanner` to find what's worth building." A user should see both the path they
have and the path they could unlock.

## 3. Trace a path (if asked)

If `$ARGUMENTS` names a starting point — "I have a raw idea", "I have a validated opportunity", "I have a
PR to ship" — output the **ordered list of commands** from there to PRODUCTION, skipping stages whose
plugin is absent (and noting the skip).

## 4. Render

- If **pressroom** or **atelier** is installed, emit a **Mermaid** `flowchart LR` and defer rendering to
  their engine (so it's legible wherever it lands).
- Otherwise, emit the ASCII/markdown map above, tailored to what's installed.

Close with a single **"your next command"** line.

---

## Self-improvement covenant

Inherits the front door covenant (`knowledge/covenant.md`). When the flow gains a stage or a plugin, this
map is the one place that learns it — update once, every `/i2p-flow` inherits it.
