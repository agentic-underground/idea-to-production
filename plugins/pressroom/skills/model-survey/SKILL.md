---
name: model-survey
description: >
  Explore, test, score, and journal the image models available on the ComfyUI backend so PRESSROOM can choose
  models on evidence. A loop-driven experiment (NO command — run it under /loop, self-paced): it generates a
  curated subset of checkpoints (SDXL + SD1.5) across five test objectives — scenes, landscapes, candid-office
  (marketing stock), line-goes-up, cute-mascot — has the design team score each, retains the images on disk
  (not in git), assembles an efficient PDF + a markdown catalog in doc/comfyui-experiment/, and folds the
  findings into knowledge/comfyui-model-guide.md so handler-comfyui and the illustrator pick models well.
  Resumable/idempotent via a journal; finishes when every cell is generated, scored, cataloged, and the guide
  is synthesized. Token-efficient by design: generation, catalog, and PDF are deterministic bash; only scoring spends
  model tokens (one agent per model contact-sheet via a Workflow fan-out).
metadata:
  type: experiment
  output: doc/comfyui-experiment/{journal.jsonl, catalog.md, comfyui-model-survey.pdf} + knowledge/comfyui-model-guide.md
  composes: [design-reviewer/image-aesthetic-reviewer]
  loop: run under /loop (self-paced); the phase machine + journal make it resumable and terminating
model: inherit
---

# PRESSROOM — MODEL SURVEY

`handler-comfyui` can list ~90 checkpoints but has no idea which is good for what. This experiment fixes that
with **evidence**: it drives a curated model subset through five real illustration objectives, scores the
output, and writes a curated [`comfyui-model-guide`](../../knowledge/comfyui-model-guide.md) that both the
handler and the illustrator consult. It is **not a command** — it runs under **`/loop`** (self-paced) and
**finishes when the goal end-state is reached**.

> **Token-efficiency spine.** Every byte of ComfyUI interaction and PDF assembly is **deterministic bash/Typst
> (zero model tokens)** — see `scripts/`. The only model-token step is **scoring**, and it is batched: one
> agent reads one **contact-sheet** per model (five category cells in a single image), via the Workflow
> fan-out `scripts/score-workflow.js`. The journal makes every phase resumable so nothing is recomputed.

## The goal (the loop's DONE gate)

The survey is **done** when, for every model in `doc/comfyui-experiment/manifest.json`: all five category cells
are **generated** (journal `status:done` + file on disk), **scored** (journal `event:score`), recorded in
`catalog.md` + the PDF, and the findings are synthesized into `comfyui-model-guide.md`. Until then, each `/loop`
wake advances the current phase and **ScheduleWakeup**s; at DONE it reports completion and the loop stops.

## The phase machine

Resolve `SURVEY_DIR=doc/comfyui-experiment`; `SCRIPTS=${CLAUDE_PLUGIN_ROOT}/skills/model-survey/scripts`. Read
`journal.jsonl` to determine the current phase, then run **one increment**:

| Phase | Do | Tokens |
|---|---|---|
| **A · VALIDATE** | `bash $SCRIPTS/validate.sh` — intersect the curated wishlist (`references/manifest.example.json`) with the live checkpoint list, dry-run loadability, write `manifest.json` + journal each verdict (load-failures are findings — e.g. the SDXL-subfolder quirk). | 0 |
| **B · GENERATE** | `SURVEY_DIR=$SURVEY_DIR bash $SCRIPTS/generate.sh` (runnable in background). Resumable: only un-`done` cells generate; each downloads a full image + a GPU-downscaled thumb and journals the cell. **"All images ready" = this phase complete.** | 0 |
| **C · SHEETS** | `bash $SCRIPTS/contact-sheets.sh` — one labelled review PNG per model (`contact-sheets/<model>.png`). | 0 |
| **D · SCORE** | Invoke the **Workflow** `scripts/score-workflow.js` with `args:{surveyDir, canon, reviewer, models:[{id,base,family,sheet,categories}]}` → one image-aesthetic reviewer per model. **Append each returned scorecard's per-cell `overall` to the journal** as `{event:"score",model,category,overall,…}`. | batched (1 agent/model) |
| **E · CATALOG** | `bash $SCRIPTS/build-catalog.sh` — `catalog.md` (files + scores) and the Typst catalog → **gs-downsampled** `comfyui-model-survey.pdf` (efficient, dependency-free). | 0 |
| **F · GUIDE** | Synthesize the journal's scores into [`comfyui-model-guide.md`](../../knowledge/comfyui-model-guide.md): per-model rows + the **intent → recommended-models** table + base-level routing rules (e.g. "no SD1.5 → line-goes-up"). | once |

> Each `/loop` iteration runs the next not-yet-complete phase's increment. Generation (B) is the long pole —
> kick it off in the background and let the loop check progress and advance to C once the journal shows all
> cells `done`. A killed endpoint journals an error and the loop retries on the next wake — it never crashes.

## Curated subset & objectives
- Models: `references/manifest.example.json` — ~12–16 spanning families/purposes across SDXL + SD1.5, validated
  live before the run. Widen by editing the manifest and re-looping (only new cells generate).
- Objectives: `references/test-prompts.md` — the five categories, same prompt + seed per category across all
  models (only the model varies → comparable).

## The feedback (why this exists)
The findings are not pretty pictures — they are the [`comfyui-model-guide`](../../knowledge/comfyui-model-guide.md),
the **one canonical source** (referenced, not forked) that:
- `handler-comfyui` consults to pick a checkpoint (and steps/sampler) for a SPEC's intent, and
- the illustrator consults when routing an intent to `handler-comfyui`.
Each run appends/sharpens the guide via the shared
[self-improvement protocol](../rich-pdf-with-diagrams/references/self-improvement.md) — recurring base-level
truths become routing rules, so the model-selection conversation converges toward "always the right model".

## Outputs (in `doc/comfyui-experiment/`)
`manifest.json`, `journal.jsonl`, `catalog.md`, `comfyui-model-survey.pdf` are **tracked**; `images/`, `thumbs/`,
`contact-sheets/` are **gitignored** (retained on disk, not in git). The guide lives at
`plugins/pressroom/knowledge/comfyui-model-guide.md`.
