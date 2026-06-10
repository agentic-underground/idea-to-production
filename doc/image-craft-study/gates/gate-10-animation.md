# Gate 10 — broad animation rollout · PASS (closed)

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste`

## Delivered

The flagship lifecycle animation **plus the full broaden set**, all built 0-GPU on the worker via the Phase-8
toolchain (SVG frame generators → `rsvg-convert` → `gifski` → `gifsicle`):

- **Flagship #1 — lifecycle cycle** (`doc/images/lifecycle-cycle.gif`) — embedded in `plugins/i2p/knowledge/product-lifecycle.md`.
- **Flagship #2 — animated masthead** (`doc/images/masthead-cycle.gif`) — the wide-and-short **root README front
  door** with the dominant `idea → production` wordmark (the old banner had none) over the igniting value cycle +
  the return loop closing. Replaces the wordmark-less hero.
- **Broaden ×9 — one motivated animated figure per plugin README:** i2p hub-and-spoke dispatch · concierge
  HUD/welcome assembly · foundry red→green test-first conveyor · atelier critique-loop convergence · sentinel
  certify-before-expose gate · pressroom illustrate→review→publish press · market-scanner radar sweep · ideator
  fragment convergence · mission-control observe→respond→loop.

Every figure: optimised GIF (**all ≤ 100 KB**, far under the 2 MB budget), a **reduced-motion poster** PNG, and
**descriptive alt-text** naming the motion. 11 deterministic frame generators under `toolchain/src/`,
frame-strip proofs under `toolchain/proof/`.

## Adversarial panel (3 reviewers, prompted to REFUTE)

Each figure was attacked on: renders-inline-on-GitHub, motion-motivated (not gratuitous), per-frame legibility,
dark-mode canon, ≤2 MB budget, poster present, alt-text present. **All three groups returned overall PASS** —
every figure clears every criterion. The findings were nuances, not failures:

- **Strongest motivated motion:** `foundry-conveyor` (the red→green test-first spine exists *only* in motion —
  TESTS lights RED before IMPL, flips green only when code arrives), `masthead-cycle` (the loop-close a still
  cannot show), `atelier-critique` (converge-to-fit).
- **Weakest (still PASS):** `concierge-welcome` (the typewriter greeting is the most decorative beat) and
  `pressroom-press` (shortest arc; A-vs-B difference asserted via dimming + ★BEST rather than shown).
- **Two genuine accuracy defects FIXED:** the panel caught alt-text describing motion the figure does **not**
  perform — `sentinel-gate` ("the gate barrier lifts apart" → corrected to the label resolving to the PASS
  stamp) and `pressroom-press` ("flies along a teal trail" → corrected to "moves along a teal arrow"). Alt-text
  now matches the rendered frames.
- **Minor note (left as-is):** `mission-control-operate`'s ITERATE learning-arc is the faintest element; it
  passes because the full-frame labels (INCIDENT, MITIGATING, the captioned arc) carry the meaning.

## Verdict: **PASS** — gate closed

The toolchain is proven on real, canonical, **outward-facing** repo content: 11 motivated animated figures, each
GitHub-renderable, budgeted, poster-backed, and now alt-text-accurate. Motion is motivated, not gratuitous; the
two overstatements the panel found are corrected. The broad animation rollout is complete.
