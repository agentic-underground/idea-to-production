# Diagram Review — adversarial pass over every figure in the repo

**Date:** 2026-06-11 · **Branch:** `visual-quality-overhaul` · **Reviewer:** the calibrated
`image-aesthetic-reviewer` protocol (RENDER-FIRST → read pixels → layout-defect checklist →
score with the AI-slop + photoreal taste caps), fanned out across all figures.

This is the "reviewers SEE the pixels" proof in practice: every figure was rendered to PNG and
read with vision before any verdict. Findings are the at-a-glance defects the maintainer caught by
eye (text past a border, a line through a box, an illegible caption) — the class text-only review
missed. Everything flagged below has been **FIXED** in this branch unless marked otherwise.

## Calibration gate — PASS

`gate-reviewer-calibration.md` ran its first calibration: the reviewer ranked four figures
broken (35) < competent-flat (79) < strong (88) < award (98) monotonically, demoted the flat slop
with a named lift, and caught a planted text-past-border overflow → `NEEDS_REVISION`. The machine
`layout-check.sh` agreed (exit 1 on the same overflow). Gate stamped PASS. (The ATELIER
`ui-design-reviewer` companion run remains a tracked follow-up.)

## Animated GIFs (11) — 7 PASS, 4 fixed

| Figure | Verdict | Defect found → fix |
|---|---|---|
| atelier-critique | PASS (90) | — |
| foundry-conveyor | PASS (89) | — |
| i2p-frontdoor | PASS (91) | (caption-band height fix already applied earlier) |
| ideator-converge | PASS (88) | — |
| lifecycle-cycle | PASS (90) | — |
| masthead-cycle | PASS (90) | — |
| pressroom-press | PASS (89) | — |
| **concierge-welcome** | fixed | the typed greeting never settled legibly (only shown mid-type/dissolve) → emit the fully-typed greeting as a held full-opacity poster beat |
| **market-scanner-radar** | fixed | radar sweep-arm tip + top ring crossed the "MARKET-SCANNER" title → dropped + shrank the radar group (top ring now clears the title by 20px) |
| **mission-control-operate** | fixed | dashed cycle-arc ran through the "↻ …re-enter DISCOVER" caption → moved the arc into its own band (≥10px gap), no bottom clip |
| **sentinel-gate** | fixed | the SAST checklist row was sheared at the canvas bottom → grew canvas H 320→356, re-centred (≥34px clearance) |

All 11 remain flat dark-mode SVG (composite depth was removed per the maintainer), every GIF ≤584KB,
`layout-check` clean.

## Plugin banners (9) — the headline artifact

Reviewed for the photoreal/AI-slop trap. The first cut split into a graphic camp and a
defocused-photograph camp; the photo camp was rejected (it is exactly the slop the maintainer flags).
Resolution: the rig reliably produces stylized line-art only for abstract subjects, so representational
bands were taken down the **motif-bearing pure-vector** path. The set now reads as **one coherent dark
line-art family** — crisp SVG wordmark + tagline + a faint line-art spirit-motif over a dark graphic band:

- **rig line-art (kept):** market-scanner (radar ripples), ideator (facet web)
- **vector line-art (re-rolled to kill photoreal slop):** i2p, concierge, foundry, pressroom, atelier,
  sentinel, mission-control

All 9 wordmarks crisp and legible at inline width; no text clipped; every banner ≤380KB, 1920×400.

## Old square heroes (5) — confirmed SLOP, replaced

i2p, concierge, atelier, sentinel, mission-control shipped near-square (1280×876) photoreal ComfyUI
renders — the default teal/orange checkpoint look, no shared graphic system, the wrong artifact for a
README banner. All five confirmed SLOP / wrong-aspect and **replaced** by the wide banners above;
`hero.jpg` files deleted and the ledger's `comfyui_heroes` block retired.

## Static structural diagrams — mostly PASS, 5 fixed

| Figure | Verdict | Defect found → fix |
|---|---|---|
| foundry/01-orchestration-hierarchy | PASS (88) | — |
| foundry/02-conveyor | PASS (84) | — |
| foundry/knowledge/01-domain-tree | PASS (82) | — |
| foundry/knowledge/02-tests-coordinates | PASS (91) | strongest of the set |
| doc/01-context-doors | PASS (88) | — |
| doc/02-soul-sentinel | PASS (90) | — |
| ideator/01-idea-package-faces | PASS (84) | — |
| pressroom/01-pieces-compose | PASS (82) | — |
| readme-banner (root masthead) | PASS (91) | — |
| **foundry/knowledge/03-three-pillars** | fixed | pillar body text + base-slab caption overflowed both borders → reflowed text / widened the slab |
| **foundry/knowledge/04-pure-core** | fixed | THIN-WIRING subtitle crossed the right border → shortened + reduced font, clears with padding |
| **foundry/03-quality-chain** | fixed | dotted edge tunnelled through the annotation box → re-anchored the Mermaid edge so it routes outside |
| **doc/images/01-value-flow** | fixed | 10px caption illegible at inline width → re-laid out as a 2-row serpentine with legible fonts |
| **market-scanner/01-discovery-loop** | fixed | Mermaid labels lost inter-word spaces ("scoreonmarkettaxonomy") → `xml:space="preserve"` on all text |

## Net

Every figure in the repo has been rendered and read; the 13 layout/legibility/slop defects the pass
surfaced are fixed, and the 5 photoreal heroes are replaced by a coherent stylized banner set. The
deterministic gates back this up: `layout-check` clean across all generators, every GIF ≤2MB, every
banner ≤600KB, `verify-prereqs.sh` PASS.
