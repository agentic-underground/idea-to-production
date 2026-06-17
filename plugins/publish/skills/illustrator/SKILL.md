---
name: illustrator
description: >
  Trawl documentation, find the highest-impact spots a figure would clarify, and drive each one from
  candidate-site → SPEC → two rendered options → an adversarial A/B-until-best design review → an embedded,
  dark-mode, transparent-background asset. The orchestrator of PUBLISH's graphical value handlers
  (Graphviz / Mermaid / chart / hand-composition / ComfyUI). Trigger with /illustrate (or "illustrate this
  doc", "what figures does this README need", "add a diagram here", "illustrate the docs"). Single-shot on one
  site, or /loop-driven across the whole doc tree with an idempotent, resumable ledger that embeds as it goes.
  Shares the 4×9 charting-matrix and the dark-mode canon with the producers; reuses the design-reviewer's
  typographic + data-viz sub-agents in a comparative (A/B) mode.
metadata:
  type: orchestrator
  output: an embedded figure (svg|png|gif|apng|mp4) + a markdown edit + a ledger entry (.pressroom/illustration-ledger.json) in loop mode
  composes: [handler-graphviz, handler-mermaid, handler-chart, handler-composition, handler-comfyui, handler-composite, design-reviewer]
  shares:
    - ../rich-pdf-with-diagrams/references/charting-matrix.md
    - references/dark-mode-canon.md
    - ../../knowledge/comfyui-model-guide.md
model: inherit
---

# PUBLISH — ILLUSTRATOR

The documentation is dense and comprehensive; the ILLUSTRATOR makes it *illustrative*. It reads a project's
docs the way a careful editor would, finds the few places a figure earns its keep, specs the figure, has a
graphical value handler render **two** options, and runs a strict adversarial review until one is celebrated
as **the best** — not merely the least-worse. Every figure it ships is dark-mode, transparent-ground, and
legible on any host.

> **Where this fits.** The producers (`diagram-studio` with its `handler-graphviz` / `handler-mermaid`
> value-handlers, `rich-pdf-with-diagrams`) *make* figures on request; the `design-reviewer` *judges* them. The ILLUSTRATOR is the **orchestrator** that
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
| [`handler-composite`](../../agents/handler-composite.md) | SVG↔raster blend (raster atmosphere + vector type/frame); animated figure (build-up / loop) | GIF·APNG·MP4·PNG/JPG |

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
| messages-over-time / lifecycle / flow / 2×2 / schedule | `handler-mermaid` | [mermaid-taxonomy](../rich-pdf-with-diagrams/references/mermaid-taxonomy.md) |
| a comparison **of data** | `handler-chart` | dataviz encoding ranking |
| a non-graph concept poster / labelled figure / callout | `handler-composition` | composition kind |
| a genuinely pictorial / generative image | `handler-comfyui` | text-to-image |
| a raster atmosphere **needing crisp vector type/frame/data on top** (masthead, hero with wordmark) | `handler-composite` | blend |
| a figure that earns **motion** — a diagram that builds up, a hero that breathes/loops | `handler-composite` | motion |

**Tie-break: prefer vector + deterministic over ComfyUI** — reach for `handler-comfyui` only when the intent
is genuinely pictorial, never for anything a graph expresses. When two vector handlers both fit, that
ambiguity *becomes* the A/B axis (A from one, B from the other) and the reviewer decides.
**Motion/blend is a deliberate choice, not a default** — route to `handler-composite` only when motion *adds
meaning* (a reveal that teaches structure) or a blend is genuinely needed (raster atmosphere + sharp type);
a static vector figure is the right answer for most diagrams. `handler-composite` degrades to a static poster
when the motion tools are absent ([raster-toolchain canon](../../knowledge/raster-toolchain.md)).

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
asset + source + a one-line self-critique. The illustration tier runs **sonnet concept → opus review → opus
craft** (see [model tiers](#per-stage-model-tiering) below): the cheap tier explores the concept and renders
the first A/B pair, the expensive tier reviews and crafts the winner to the award bar.

### Phase 5 — A/B-until-best review loop (bounded, ship-best-on-cap)
Hand both options to the `design-reviewer` in comparative mode and run
[`references/illustrate-ab-loop.md`](references/illustrate-ab-loop.md): the reviewer runs the
[`layout-reviewer`](../design-reviewer/agents/layout-reviewer.md) **legibility gate FIRST** (edge-clip,
overlap, inline-legibility at `width_budget_px`) and scores taste only on a clean pass — a clipped or
illegible option is `NEEDS_REVISION` before any taste dimension is computed. Then the reviewer picks a winner, gives
per-option feedback, and signals `LEAST-WORSE` or `BEST`. **Carry the winner forward** (apply its own
HIGH+MED), **regenerate only the challenger** per the reviewer's brief, re-review.

The loop is **bounded to `MAX_TURNS = 4` rounds** and **accepts early** the moment either the reviewer's
fitness score meets `TARGET` (85/100) **OR** the verdict is `BEST` (`PASS`). Stop on the first of:
- **BEST-REACHED** — `signal: BEST` (or score ≥ `TARGET`): celebrate, emit.
- **HALT-DIMINISHING-RETURNS** — the best-of-pair score gains stall (`< +3` over two turns): ask the user.
- **CAP** — `MAX_TURNS = 4` reached without `BEST`: **ship the best-scoring draft seen so far** (the carried
  champion, which is monotonic) and **log a cap note** in the ledger (`signal: CAP`, the champion's
  `final_score`, and the top residual finding). The loop never returns nothing and never exceeds the bound.

The whole point: ship a figure that is *good*, not one that beat a worse sibling — and when the bound is
reached, ship the best we have with the residual recorded honestly, rather than spinning.

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

## Per-stage model tiering

The per-completed-item pipeline runs on **parallel sub-agents with explicit model tiers**, so the cheap
model does the cheap work and the expensive model only does the work that demands taste. Each lane has a
default ladder; both ladders climb **draft/concept (cheap) → review → final/craft (expensive)**:

| Lane | Concept / draft | Review | Final / craft |
|---|---|---|---|
| **Illustration** (this skill) | sonnet concept | opus review | opus craft |
| **Documentation text** ([writer](../writer/SKILL.md)) | sonnet draft | opus review | opus final |

where **sonnet = `claude-sonnet-4-6`** and **opus = `claude-opus-4-8`**. This is the same
**model-override** idea the value handlers already carry (a per-job model can be set on the spawning call —
see the handlers' *Spawning Model Policy*): the table above is the **default tier per stage**, and any job
may override it (e.g. force opus for a hero on the front page, or sonnet-only for a throwaway internal note).
The concept stage renders the first A/B pair cheaply; the review and craft stages — where the award bar is
defended — run on opus.

## Cadence & token budget — per completed item, scheduled

This pipeline runs **per completed roadmap item — never per commit.** When an item reaches DONE, one
documentation+illustration pass is dispatched for it; intermediate commits do not trigger it. When the
[token-fairness scheduler](../../../../CLAUDE.md) (`scheduler@token-fairness`) is present, the pass is
**dispatched through it** with a **per-item budget**: it runs **off-peak by default** so it never competes
with interactive work, but the operator may **consent to run it now**. Absent the scheduler, the pass runs
inline and the `MAX_TURNS` bound is the only token guard.

## Prerequisites & graceful degradation
Run `/publish:check` first. The vector handlers need `dot` (Graphviz) and/or `mmdc` (Mermaid); `handler-chart`
needs a chart engine (`vl2svg`/`matplotlib`/hand-SVG); `rsvg-convert` (or `magick`) rasterises onto the two
grounds; `handler-comfyui` needs `$PRESSROOM_COMFYUI_URL` reachable. When a handler's tool is absent, the
ILLUSTRATOR routes around it (another vector handler for the A/B slot) and says so — it never blocks the loop.

## Self-improvement covenant
Carries the KAIZEN covenant. A *site-selection* lesson tunes [site-ranking](references/site-ranking.md); a
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
