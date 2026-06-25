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
  output: a value-flow map + "your next command" (Mermaid when publish/design present, else markdown)
  composes: [publish/design renderers by capability — read-only]
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
market-       ideate  roadmapper design   deliver  deliver   security  publish  operate
scanner                (+FLEET)                      (quality) (security)
                                            └──── BUILD ⇄ ASSURE ⇄ SECURE loop ────┘
 /discovery-  /ideate  /roadmapper /mockup  IDEA▶…▶ /pr-review /scan-all /publish  observe ·
 goal +                (+FLEET eng) /ui-rev   SHIP   (quality)                      iterate ↻→DISCOVER
 /market-scan
```

Nine phases forming a **cycle** — OPERATE's learnings loop back to DISCOVER. **DELIVER** sits between
IDEATE and DESIGN: it turns the IDEA package into the **FLEET v2 pipeline** — a dependency-ordered
roadmap of EPIC/PLAN docs (intake → EARS/feature authoring → decomposition) — owned by
**`deliver:roadmapper`** (headline **`/roadmapper`**, artefact the `docs/roadmap/` pipeline); the
external **FLEET continuous-delivery engine** then drains it (building each slice via DELIVER's
PLAN-scope entry). The three
realisation phases **BUILD ⇄ ASSURE ⇄ SECURE** form a **loop**, not a straight line — a failed quality or
security gate sends the work *back* to BUILD (the `fail` back-edge), and the loop exits to PUBLISH only
when all three are satisfied. **ASSURE** (deliver, quality V&V) and **SECURE** (secure, security) are
**separate first-class gates**. Three concerns **cross-cut** every phase: usability (design/DESIGN),
quality (deliver/ASSURE — built-in not inspected-in), security (secure/SECURE — baked in from the
start). For each stage, give: the plugin, its **headline command**, and the **artefact** it produces (an
OPPORTUNITY → an IDEA package → a dependency-ordered roadmap → a design-reviewed screen → tested code → a
quality PASS → a SECURITY-REPORT → an article/PDF → a live, observed product). Ground the wording in
`plugins/i2p/knowledge/product-lifecycle.md` (canonical), `plugins/deliver/VALUE_FLOW.md`, and the
marketplace `README.md` composition diagram.

## 2. Light vs dark

Place only **installed** plugins as live stages. Mark each missing plugin's stage as dark:
"▫ DISCOVER — add `discover` to find what's worth building" / "▫ DELIVER — add `deliver` for
`/roadmapper` to author the FLEET v2 `docs/roadmap/` pipeline (and the external FLEET engine to drain
it)" / "▫ OPERATE — add `operate` to observe, respond to incidents, and iterate the live product." A user
should see both the path they have and the path they could unlock. (DELIVER is owned by
**`deliver:roadmapper`** — **headline `/roadmapper`**; the external FLEET `pipeline` plugin supplies the
build engine — `/pipeline:status`, `/pipeline:run`. Treat DELIVER as a LIVE stage when `deliver` is
installed, dark when it is not — name the stage and its owner regardless; graceful degradation, the gap
named not skipped.)

## 3. Trace a path (if asked)

If `$ARGUMENTS` names a starting point — "I have a raw idea", "I have a validated opportunity", "I have a
PR to ship" — output the **ordered list of commands** from there to PRODUCTION, skipping stages whose
plugin is absent (and noting the skip).

**The thesis lane (a held proposition).** A common starting point is a raw **product proposition** — "By
doing X I propose Y, and the value is Z" (a problem/solution/value triad). Two doors enter the flow at the
front:

- **Confident in the thesis** → enter at **IDEATE** with **`/ideate:ideate "By doing X I propose Y,
  value Z"`** (raw-idea mode — it recognises the triad and pre-fills the brief).
- **Unsure the thesis holds** → enter at **DISCOVER** with **`/discover:market-scan`** in its
  **thesis-validation mode**: hand it the thesis (or an `OPPORTUNITY-*.md` from `/operate:iterate`, closing
  the ↻ loop) and it *validates that specific thesis* into a `doc/opportunities/<slug>.md` rather than
  proposing fresh candidates — then `/ideate` refines it.

Trace the rest of the path (DELIVER → … → OPERATE) from whichever door they pick.

## 4. Render

- If **publish** or **design** is installed, emit a **Mermaid** `flowchart LR` and defer rendering to
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
