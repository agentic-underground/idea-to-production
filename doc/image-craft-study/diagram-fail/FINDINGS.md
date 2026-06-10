# Diagram-text failure — fresh dated evidence (2026-06-10)

**Claim re-grounded:** _diffusion cannot render legible diagram text, so any figure whose value **is** its
labels must be authored as **vector** (Graphviz / Mermaid / hand-SVG / charts), never generated as raster._

This is the empirical basis for the illustrator's "route diagrams to vector; ComfyUI is for genuinely pictorial
figures only" rule. The evidence was getting stale, so we re-ran it on the current rig.

## Method

`run-diagram-fail.sh` — four prompts that **explicitly demand readable labels**, through the allowlisted
`txt2img-basic` template, on a strong general SDXL checkpoint (`crystalClearXL_ccxl`), 30 steps, fixed seeds
4200–4203. Raw rasters are gitignored; the committed evidence is the 2×2 montage `diagram-text-fail.jpg`.

| prompt id | what we asked for | text we wanted |
|---|---|---|
| `flowchart` | three connected boxes | **START**, **PROCESS**, **END** |
| `pipeline` | a titled 4-step infographic | title **DATA PIPELINE** + step labels |
| `barchart` | a labelled business bar chart | axes **Revenue** / **Q1–Q4** + legend |
| `architecture` | three labelled nodes | **CLIENT**, **SERVER**, **DATABASE** |

## Result — the aesthetic is convincing, the text is gibberish

The model nails *diagram styling* — clean boxes, arrows, flat-design colour, isometric server icons, plausible
chart bars — which is exactly the trap: it **looks** like a real diagram at a glance. But **every label is
nonsense**:

- **flowchart** → "Start Magter", "Start Sertch", "pross End", "Sjoran erame", "Processakold them" — boxes and
  arrows are fine; not one word is the requested label.
- **pipeline** → the title renders as "Dat / DATA / PILLINE"; step bodies are noise-bars; the "numbers" 11/12/13
  are placed arbitrarily.
- **barchart** → "Revenue Revene: Bar cis Reveze"; axis ticks and the Q1–Q4 categories are illegible smears.
- **architecture** → node labels are unreadable blobs; CLIENT / SERVER / DATABASE appear nowhere.

## Conclusion (unchanged, now re-dated)

Diffusion models in 2026 still produce **convincing diagram *form* with non-functional diagram *text***. A
diagram's value is its labels and relations; a figure that looks right but reads as gibberish is worse than
none (it misinforms). Therefore:

- **Diagrams, charts, labelled architecture, flowcharts → vector handlers** (Graphviz, Mermaid, hand-SVG,
  charts). Deterministic, legible, dark-mode, accessible alt-text.
- **ComfyUI / raster → genuinely pictorial figures only** (hero art, texture, photoreal concept, mood) — where
  there is no load-bearing text.
- When a pictorial figure *needs* a few words (a masthead wordmark, a label), add them as **vector `<text>`**
  composited over the raster (the SVG↔raster blend capability), never baked by the diffusion model.

_Cross-refs: `plugins/pressroom/skills/illustrator/SKILL.md` (routing), `plugins/pressroom/knowledge/raster-toolchain.md`
(SVG↔raster text overlay), `plugins/pressroom/skills/design-reviewer/references/dataviz-canon.md` (vector data-viz canon)._
