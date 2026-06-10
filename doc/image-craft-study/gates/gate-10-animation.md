# Gate 10 — broad animation rollout (Phase 10) · FLAGSHIP landed

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste`

## Flagship #1 — the animated lifecycle (LANDED, embedded)

The marquee marketplace diagram, animated: **DISCOVER → IDEATE → DESIGN → BUILD → ASSURE → SECURE → PUBLISH
→ OPERATE**, building up one phase at a time (teal "done" / amber "current" / dim "pending" colour-script),
then the **return arc glows** — *OPERATE's learnings re-enter DISCOVER* — closing the cycle, then it loops.
- Built via the Phase-8 toolchain, 0-GPU: `src/build-lifecycle-frames.sh` → `rsvg-convert` → `gifski` →
  `gifsicle` (200-colour, lossy 40).
- **Embedded** in the canonical lifecycle doc `plugins/i2p/knowledge/product-lifecycle.md` (the most
  semantically-correct home — the statusline phase widget, `/i2p-help`, `/i2p-lifecycle` all read it).
- **Budget:** `doc/images/lifecycle-cycle.gif` = **36 KB** (≤ 2 MB budget, easily). GIF renders inline on
  GitHub. Mandatory alt-text present (names all eight phases + the loop).
- **Self-review (Medium-richness / motion, from the frame-strip `proof/lifecycle-strip.png`):** motion is
  **motivated** (the build-up teaches the phase *order*; the arc teaches the *cycle*), legible per frame,
  dark-mode, ends on a complete poster frame. Passes the §9 motion bar.

## Remaining rollout (this gate stays open until complete)

- **Flagship #2 — animated masthead** (raster atmosphere + the build-up, for the root README front door) —
  pending (outward-facing; will show before wiring into the root README).
- **Broaden ×9** — one animated figure per plugin README, via `handler-composite` + the lifecycle/blend
  recipes, each gated on Medium-richness from a frame-strip, ≤ 2 MB, reduced-motion poster.
- **Full adversarial Gate-10 panel** — confirm every animated asset renders on GitHub, motion is motivated
  (not gratuitous), before/after gallery — run once the set is complete.

## STEER

Flagship lifecycle is live and embedded — the toolchain is proven on real, canonical repo content. Broaden
to the per-plugin set next; keep each motivated + budgeted + poster-backed.
