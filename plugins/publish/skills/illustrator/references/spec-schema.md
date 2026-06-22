# The illustration SPEC — the graphical value-handler contract

> The single artefact the ILLUSTRATOR hands a graphical value handler. It is the visual analogue of
> FOUNDRY's stack manifest: the orchestrator decides *what* and *why*; the handler decides *how* and
> renders. One schema, every handler — so options are comparable and the A/B loop is fair. The handler
> receives the SPEC verbatim and emits exactly one asset that satisfies it.

## The schema

```yaml
spec_version: 1
site:
  doc: README.md                 # repo-relative path to the doc being illustrated
  anchor: "## Value flow"         # the heading or quoted line the figure attaches to
  insert_after: "<exact source line>"   # the line after which the embed is inserted (loop mode)
intent: "Show idea→production flow across the 8 plugins, left to right, in a single read."
message: "One takeaway: each plugin is a phase gate; the output of one is the input to the next."
audience: "an engineer skimming the README for the first time"
handler: handler-graphviz         # the chosen value handler (decision table in SKILL.md §2)
diagram_type: pipeline-staggered  # the type WITHIN that handler's taxonomy
data: null                        # handler-chart only: an inline table, or a path to a data source
constraints:
  charting_matrix: true           # the 4×9 legibility law applies (all SVG handlers)
  dark_mode: true                 # the dark-mode canon applies (all SVG + raster)
  transparent_bg: true            # transparent ground (vector); alpha/dark-key (raster)
  max_boxes_per_row: 4
# --- handler-composite only (blend / motion) — omit/null for the other handlers ---
layers: null                      # blend: [{kind: raster, src: <path>}, {kind: vector, src: <svg>}] bottom→top
motion: null                      # animation: {kind: build-up|reveal|loop|parallax, frames: 11, fps: 4, loop: true}
target:
  embed: markdown                 # markdown | html | print
  width_budget_px: 800            # the host's content-column width
  format: svg                     # see output_format
  output_format: svg              # svg|png (vector/comfyui) · gif|apng|mp4|webp (handler-composite motion) · png/jpg (blend)
alt_text: "Pipeline: ideator → foundry → security → publish, each a phase gate feeding the next."
ab:
  axis_of_divergence: "orientation: top-to-bottom stack (A) vs staggered left-right ladder (B)"
```

## Field rules

| Field | Rule |
|---|---|
| `site.anchor` / `insert_after` | exact strings from the source doc, so the loop's Edit is unambiguous (single occurrence). |
| `intent` | one sentence — what the figure conveys. If you can't state it, there is no figure to make. |
| `message` | the **single** takeaway. A figure with two messages is two figures — decompose. |
| `handler` | one of `handler-graphviz`, `handler-mermaid`, `handler-chart`, `handler-composition`, `handler-comfyui`, `handler-composite`. |
| `diagram_type` | named within the handler's own taxonomy (graphviz-patterns / mermaid-taxonomy / chart type / composition kind / blend|motion). |
| `data` | **required** for `handler-chart` (the figure is *of* data), `null` otherwise. Inline small tables; reference large sources. |
| `layers` | **`handler-composite` blend only.** Ordered bottom→top: a `raster` ground (a comfyui hero/texture path) + a `vector` overlay (an SVG with the in-SVG legibility scrim + wordmark/frame). `null` otherwise. |
| `motion` | **`handler-composite` animation only.** `{kind, frames, fps, loop}`; numeric fields are validated as integers. `null` for any static figure. Motion must be motivated; a static poster is always emitted too. |
| `constraints` | `charting_matrix` + `dark_mode` + `transparent_bg` are `true` for every SVG handler — they are the house law, not options. |
| `target.output_format` | `svg` for the four vector handlers; `png` for `handler-comfyui`; `png`/`jpg` for a `handler-composite` blend; `gif`/`apng`/`mp4`/`webp` for a `handler-composite` animation (GIF/APNG render inline on GitHub; MP4 via `<video>`). `target.format` is kept as the legacy alias. |
| `alt_text` | **mandatory.** States the figure's intent, not "diagram". Accessibility is a design-reviewer GATE — a missing/empty `alt_text` blocks PASS. |
| `ab.axis_of_divergence` | names the **one meaningful way** options A and B must differ (orientation, encoding channel, decomposition, or even two different handlers when the type is genuinely ambiguous). Forces A/B to be a real choice, not two near-identical renders. |

## What the handler returns

The handler hands back, to the orchestrator:
1. the asset path (`<doc-dir>/diagrams/NN-name.{svg,png}`),
2. the source it rendered from (`.dot` / `.mmd` / `.svg` / chart spec / ComfyUI template+params) — so the
   reviewer's fixes are applied to *source*, not pixels,
3. a one-line self-critique (its own adversarial pass — see the handler bodies),
4. for `handler-comfyui`: the checkpoint used and the template id.

The SPEC plus these four make a turn of the [A/B-until-best loop](illustrate-ab-loop.md) fully reproducible.
