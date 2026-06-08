---
name: illustrator
description: >
  Trawl documentation, find the highest-impact spots a figure would clarify, and drive each one from
  candidate-site → SPEC → two rendered options → an adversarial A/B-until-best design review → an embedded,
  dark-mode, transparent-background asset. The orchestrator of PRESSROOM's graphical value handlers
  (Graphviz / Mermaid / chart / hand-composition / ComfyUI). Trigger with /illustrate (or "illustrate this
  doc", "what figures does this README need", "add a diagram here", "illustrate the docs"). Single-shot on one
  site, or /loop-driven across the whole doc tree with an idempotent, resumable ledger that embeds as it goes.
  Shares the 4×9 charting-matrix and the dark-mode canon with the producers; reuses the design-reviewer's
  typographic + data-viz sub-agents in a comparative (A/B) mode.
metadata:
  type: orchestrator
  output: an embedded figure (svg|png) + a markdown edit + a ledger entry (.pressroom/illustration-ledger.json) in loop mode
  composes: [handler-graphviz, handler-mermaid, handler-chart, handler-composition, handler-comfyui, design-reviewer]
  shares:
    - ../rich-pdf-with-diagrams/references/charting-matrix.md
    - references/dark-mode-canon.md
    - ../../knowledge/comfyui-model-guide.md
model: inherit
---

# PRESSROOM — ILLUSTRATOR

The documentation is dense and comprehensive; the ILLUSTRATOR makes it *illustrative*. It reads a project's
docs the way a careful editor would, finds the few places a figure earns its keep, specs the figure, has a
graphical value handler render **two** options, and runs a strict adversarial review until one is celebrated
as **the best** — not merely the least-worse. Every figure it ships is dark-mode, transparent-ground, and
legible on any host.

> **Where this fits.** The producers (`diagram-studio`, `mermaid-specialist`, `rich-pdf-with-diagrams`)
> *make* figures on request; the `design-reviewer` *judges* them. The ILLUSTRATOR is the **orchestrator** that
> decides *what to illustrate and why*, hands a [SPEC](references/spec-schema.md) to the right value handler,
> and closes the A/B loop with the reviewer. It produces nothing itself — it directs.

## The value handlers (it spawns; they render)

| Handler | For | Emits |
|---|---|---|
| [`handler-graphviz`](../../agents/handler-graphviz.md) | architecture, pipeline, dependency, layered, state machine | SVG |
| [`handler-mermaid`](../../agents/handler-mermaid.md) | sequence, state, gantt, journey, sankey, quadrant, timeline | SVG |
| [`handler-chart`](../../agents/handler-chart.md) | quantitative comparison (bar/line/dot/small-multiple) | SVG |
| [`handler-composition`](../../agents/handler-composition.md) | concept poster, labelled illustration, annotated callout, hero | SVG |
| [`handler-comfyui`](../../agents/handler-comfyui.md) | genuinely pictorial / generative raster | PNG |

All SVG handlers honour **dark-mode + transparency by default** ([dark-mode canon](references/dark-mode-canon.md))
and the **4×9 charting matrix** ([charting-matrix](../rich-pdf-with-diagrams/references/charting-matrix.md)).

## The six phases

### Phase 1 — Trawl & rank
Scan the target (one doc, a section, or the whole tree from README → VALUE_FLOW → glossary →
first-principles). For each doc, find candidate figure-sites and score them on **impact** and **clarity-gain**
per [`references/site-ranking.md`](references/site-ranking.md). Keep only sites clearing `SITE_FLOOR` (default
7/10), at most 3 per doc; record below-floor decisions so they aren't re-evaluated. **Do not illustrate
everything** — restraint is the job. Report the budget funnel honestly.

### Phase 2 — Pick handler + type
For a chosen site, pick the value handler and the diagram type:

| The site needs… | Handler | Type source |
|---|---|---|
| a structured graph (architecture, pipeline, state, fan-out) | `handler-graphviz` | [graphviz-patterns](../rich-pdf-with-diagrams/references/graphviz-patterns.md) |
| messages-over-time / lifecycle / flow / 2×2 / schedule | `handler-mermaid` | [mermaid-taxonomy](../mermaid-specialist/references/mermaid-taxonomy.md) |
| a comparison **of data** | `handler-chart` | dataviz encoding ranking |
| a non-graph concept poster / labelled figure / callout | `handler-composition` | composition kind |
| a genuinely pictorial / generative image | `handler-comfyui` | text-to-image |

**Tie-break: prefer vector + deterministic over ComfyUI** — reach for `handler-comfyui` only when the intent
is genuinely pictorial, never for anything a graph expresses. When two vector handlers both fit, that
ambiguity *becomes* the A/B axis (A from one, B from the other) and the reviewer decides.

> **Routing to ComfyUI? Consult the evidence.** When the chosen handler is `handler-comfyui`, the
> [`comfyui-model-guide`](../../knowledge/comfyui-model-guide.md) (built by the
> [model survey](../model-survey/SKILL.md)) says which checkpoint suits the intent and which intents
> diffusion is **bad** at — notably charts/labelled-infographics (`line-goes-up`), which the guide routes
> back to the vector handlers. Don't send an intent to ComfyUI that the guide flags "route to vector".

### Phase 3 — Author the SPEC
Write the [SPEC](references/spec-schema.md): `intent`, the single `message`, `audience`, the chosen
`handler`/`diagram_type`, `data` (for charts), the `constraints` (charting_matrix + dark_mode + transparent_bg
are always true), the `target`, mandatory `alt_text`, and `ab.axis_of_divergence` — the one meaningful way A
and B must differ.

### Phase 4 — Generate two options A/B
Spawn the chosen handler **twice** on the same SPEC, forcing the named divergence — a real choice, not two
near-identical renders. Each handler renders, rasterises onto both grounds, self-reviews, and hands back its
asset + source + a one-line self-critique.

### Phase 5 — A/B-until-best review loop
Hand both options to the `design-reviewer` in comparative mode and run
[`references/illustrate-ab-loop.md`](references/illustrate-ab-loop.md): the reviewer picks a winner, gives
per-option feedback, and signals `LEAST-WORSE` or `BEST`. **Carry the winner forward** (apply its own
HIGH+MED), **regenerate only the challenger** per the reviewer's brief, re-review. Stop on **BEST-REACHED**
(celebrate), **HALT-DIMINISHING-RETURNS** (ask the user), or **CAP** (`MAX_TURNS = 4`). The whole point: ship
a figure that is *good*, not one that beat a worse sibling.

### Phase 6 — Emit (and, in loop mode, embed + ledger)
Write the asset to `<doc-dir>/diagrams/NN-name.{svg,png}`. In **single-shot** mode, show it to the user and
stop. In **loop/`docs`** mode, embed and record — see below.

## Loop mode — trawl, embed, ledger

The whole-tree trawl is `/loop`-driven and **idempotent/resumable** via
`.pressroom/illustration-ledger.json` in the project being illustrated (cwd, beside `.foundry/`):

```json
{ "ledger_version": 1, "settings": {"site_floor": 7, "target": 85, "max_turns": 4},
  "docs": { "README.md": {
    "content_hash": "sha256:…", "status": "done",
    "sites": [ { "id": "readme-valueflow", "anchor": "## Value flow",
      "impact": 5, "clarity": 5, "score": 10, "decision": "illustrate",
      "handler": "handler-graphviz", "asset": "diagrams/01-value-flow.svg",
      "ab": {"winner":"B","final_score":88,"signal":"BEST","turns":3},
      "embedded_line": "<line after which the embed was inserted>", "completed_at": "…" } ] } } }
```

- **Resumable** — before processing a doc, compare its current `content_hash`; if unchanged and
  `status: done`, skip. The 383-file trawl is interruptible and re-entrant — `/loop /illustrate docs` picks up
  where it left off.
- **Done** — a doc is `done` when every above-floor site reached `signal: BEST` (or was explicitly deferred);
  below-floor sites are recorded so they aren't re-scored each pass.
- **Safe embed (idempotent)** — before editing, `grep` the doc for the asset path; if `![alt](diagrams/…)`
  already exists, **no-op**. Otherwise insert `![<alt_text>](diagrams/NN-name.ext)` immediately after the
  SPEC's `insert_after` line via Edit (exact-string, single occurrence); record `embedded_line`.
- **Selectivity** — `SITE_FLOOR` + the per-doc cap + the skip-list ([site-ranking](references/site-ranking.md))
  keep the trawl and its token cost tractable. Report the funnel every pass.

## Prerequisites & graceful degradation
Run `/pressroom:check` first. The vector handlers need `dot` (Graphviz) and/or `mmdc` (Mermaid); `handler-chart`
needs a chart engine (`vl2svg`/`matplotlib`/hand-SVG); `rsvg-convert` (or `magick`) rasterises onto the two
grounds; `handler-comfyui` needs `$PRESSROOM_COMFYUI_URL` reachable. When a handler's tool is absent, the
ILLUSTRATOR routes around it (another vector handler for the A/B slot) and says so — it never blocks the loop.

## Self-improvement covenant
Carries the SOLID covenant. A *site-selection* lesson tunes [site-ranking](references/site-ranking.md); a
*composition* lesson the shared [charting-matrix](../rich-pdf-with-diagrams/references/charting-matrix.md); a
*colour/ground* lesson the [dark-mode canon](references/dark-mode-canon.md); a *comparative* lesson the
[A/B loop](../design-reviewer/references/ab-comparative-loop.md) — all via the shared
[self-improvement protocol](../rich-pdf-with-diagrams/references/self-improvement.md), so the next trawl
converges to BEST in fewer turns and the figure-feedback conversation goes to zero.

## References

| Document | Purpose |
|---|---|
| [`references/spec-schema.md`](references/spec-schema.md) | the value-handler contract (what a handler consumes) |
| [`references/site-ranking.md`](references/site-ranking.md) | impact/clarity rubric, `SITE_FLOOR`, per-doc cap, skip-list |
| [`references/illustrate-ab-loop.md`](references/illustrate-ab-loop.md) | the orchestrator's half of the A/B-until-best loop |
| [`references/dark-mode-canon.md`](references/dark-mode-canon.md) | transparent ground, dark palette, dual-ground contrast gate (shared by all SVG handlers) |
| [`../rich-pdf-with-diagrams/references/charting-matrix.md`](../rich-pdf-with-diagrams/references/charting-matrix.md) | the 4×9 legibility law (shared) |
| [`../design-reviewer/references/ab-comparative-loop.md`](../design-reviewer/references/ab-comparative-loop.md) | the reviewer's half of the A/B loop |
