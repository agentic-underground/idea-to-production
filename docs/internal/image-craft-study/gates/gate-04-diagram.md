# Gate 4 — diagram track (vector taste + ComfyUI fail evidence) · PASS

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste`

Phase 4 did **both** halves the plan called for.

## (a) Vector data-viz / diagram taste track

`plugins/pressroom/skills/design-reviewer/references/dataviz-canon.md` sharpened (78 → 122 lines):
- **Named theory with DO/AVOID anchors** — Cleveland–McGill effectiveness ranking, Tufte data-ink ratio &
  small multiples, Bertin's visual variables, Few's dashboard restraint — so the reviewer can demote a
  *merely-competent* chart against a named standard rather than vibes.
- A new **ANIMATED-diagram craft** subsection — when motion helps a diagram (revealing build-order, a cycle
  closing, walking a pipeline) vs when it is gratuitous; the motivated-motion + reduced-motion-poster +
  per-frame-legibility rules; cross-linked to `raster-toolchain.md` and atelier art-direction §9.

This is the vector exemplar track folded into living canon (thin + referenced, not a textbook).

## (b) Fresh ComfyUI diagram-text fail evidence (re-grounding the routing rule)

`docs/internal/image-craft-study/diagram-fail/` — four prompts that **explicitly demand legible labels** (flowchart
START/PROCESS/END, a DATA PIPELINE infographic, a Q1–Q4 bar chart, a CLIENT/SERVER/DATABASE architecture),
rendered on the current rig (`crystalClearXL`, dated 2026-06-10). Result (evidence: `diagram-text-fail.jpg`):
diffusion nails diagram **form** (clean boxes, arrows, flat-design colour, isometric icons) but **every label
is gibberish** — "pross End", "DATA PILLINE", "Revenue Revene: Bar cis Reveze", illegible node names.

## Verdict: **PASS**

The "route diagrams to vector" rule is **re-grounded, not narrowed** — diffusion-text has **not** improved
enough to render legible diagram labels in 2026. The conclusion holds and is now freshly dated: diagrams /
charts / labelled architecture → **vector handlers** (deterministic, legible, accessible); ComfyUI/raster →
genuinely pictorial figures only; a few words over a raster go in **vector `<text>`** (the SVG↔raster blend),
never baked by the model.

## STEER

Re-run `run-diagram-fail.sh` once a major diffusion-text capability lands (e.g. a glyph-aware model on the rig);
if legible labels ever appear, *narrow* the rule rather than dropping it. Until then, the vector routing is the
correct default and the fresh evidence backs it.
