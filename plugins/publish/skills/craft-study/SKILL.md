---
name: craft-study
description: >
  Empirically discover which MULTI-STAGE techniques actually raise image craft on the ComfyUI backend, so
  PUBLISH stops shipping single-pass MVP output. A loop-driven experiment (NO command — run under /loop,
  self-paced): for a curated short-list of objectives (portrait, landscape, marketing-hero, dark-key,
  world-axis) it runs a CONTROLLED single-variable A/B — baseline vs one named stage (latent hires-fix, a
  dark-key LoRA stack, regional tricomposite) sharing ckpt/prompt/seed/base-res — by filling the Phase-5
  allowlisted templates, scores each A/B from a contact sheet, and folds the proven gains into
  knowledge/comfyui-model-guide.md + skills/illustrator/references/workflow-strategy.md so handler-comfyui and
  the illustrator reach for the stage that pays. Resumable/idempotent via a journal; finishes when every cell
  is generated, scored, cataloged, and the recipes are synthesized. Token-efficient: generation, sheets, and
  catalog are deterministic bash (0 model tokens); only scoring spends tokens, batched one agent per A/B sheet.
metadata:
  type: experiment
  output: image-craft-study/craft/{journal.jsonl, catalog.md, contact-sheets/} + folded recipes in knowledge/comfyui-model-guide.md
  composes: [design-reviewer/image-aesthetic-reviewer]
  loop: run under /loop (self-paced); the phase machine + journal make it resumable and terminating
model: inherit
---

# PUBLISH — CRAFT STUDY (multi-stage technique intelligence)

`handler-comfyui` can render, but the heroes it ships are **single-pass MVP** — no refiner, no hires re-detail,
no LoRA craft, no compositional control. This experiment fixes that with **evidence**: it drives a curated set
of objectives through a **controlled single-variable A/B** (baseline vs one named multi-stage technique), scores
the result against the [stricter image rubric](../design-reviewer/references/image-aesthetic-canon.md), and writes
the proven gains into the [model guide](../../knowledge/comfyui-model-guide.md) and
[workflow strategy](../illustrator/references/workflow-strategy.md). It is **not a command** — it runs under
**`/loop`** (self-paced) and **finishes when the goal end-state is reached**.

> **Why controlled A/B, not a beauty contest.** Each objective's two cells share ckpt, prompt, seed and base
> resolution; the *only* difference is the stage under test (hires re-detail; the dark-key LoRA stack). So any
> visible gain is **attributable to the stage**, reproducible, and namable — exactly what Gate 3 demands. The
> matrix never runs a full cross; it sweeps a curated short-list, one variable at a time. See
> [`references/technique-matrix.md`](references/technique-matrix.md).

> **Token-efficiency spine.** Every byte of ComfyUI interaction, thumbnailing, contact-sheet montage and catalog
> assembly is **deterministic bash (zero model tokens)** — see `scripts/` (which reuse the sibling `model-survey`
> skill's proven `comfyui-lib.sh` REST client and the Phase-5 allowlisted templates). The only model-token step
> is **scoring**, batched one agent per **A/B sheet** via the Workflow fan-out. The journal makes every phase
> resumable so nothing is recomputed.

## The goal (the loop's DONE gate)

Done when, for every objective in `image-craft-study/craft/manifest.json`: both A/B cells are **generated**
(journal `status:done` + file on disk) or a load-failure is **journalled as a finding**, each objective is
**scored** (journal `event:score` with a `named_gain`), recorded in `catalog.md`, and the proven gains are
**synthesized** into the model guide + workflow strategy. Until then each `/loop` wake advances one phase and
**ScheduleWakeup**s; at DONE it reports completion and the loop stops.

## The phase machine

Resolve `CRAFT_DIR=image-craft-study/craft`; `SCRIPTS=${CLAUDE_PLUGIN_ROOT}/skills/craft-study/scripts`. Read
`journal.jsonl` to determine the current phase, then run **one increment**:

| Phase | Do | Tokens |
|---|---|---|
| **A · SETUP** | `cp ${CLAUDE_PLUGIN_ROOT}/skills/craft-study/references/manifest.example.json $CRAFT_DIR/manifest.json` (once). Re-resolve every `ckpt`/`lora_name` against the live `/object_info` (honour the checkpoint-path move — fine-tunes are bare at root; only `SDXL/` base+refiner keep a prefix). | 0 |
| **B · GENERATE** | `CRAFT_DIR=$CRAFT_DIR bash $SCRIPTS/generate.sh` (runnable in background). Resumable: only un-`done` cells generate; each fills the technique's allowlisted template, submits, downloads the final image + a local thumb, journals the cell. Load-failures (e.g. an SD1.5 LoRA on an SDXL ckpt) are journalled as data. **"All cells resolved" = phase complete.** | 0 |
| **C · SHEETS** | `CRAFT_DIR=$CRAFT_DIR bash $SCRIPTS/contact-sheets.sh` — one labelled A/B PNG per objective (`contact-sheets/<objective>.png`). | 0 |
| **D · SCORE** | One agent per A/B sheet (Workflow fan-out): the [image-aesthetic-reviewer](../design-reviewer/agents/image-aesthetic-reviewer.md) reads the sheet, scores baseline vs treatment on all six rubric dimensions, and decides whether the stage is a **real, named, reproducible gain** — appends `{event:"score",objective,verdict,named_gain,baseline_score,treatment_score}` to the journal. A non-gain is recorded honestly (the technique is then NOT promoted). | scoring only |
| **E · CATALOG** | `CRAFT_DIR=$CRAFT_DIR bash $SCRIPTS/build-catalog.sh` — regenerate `catalog.md` from the journal. | 0 |
| **F · SYNTHESIZE** | Fold every **proven** gain (verdict = gain) into [`comfyui-model-guide.md`](../../knowledge/comfyui-model-guide.md) (per-objective: best ckpt + the stage that pays) and [`workflow-strategy.md`](../illustrator/references/workflow-strategy.md) (when to reach for hires / LoRA / tricomposite). Non-gains are noted as "tested, no gain". | synthesis only |

## Model tiering — how this study staffs the illustration craft ladder

The craft this study discovers is what the per-completed-item illustration pipeline reaches for at its
**craft (opus) stage**. Tie the phases to the same tiers the
[ILLUSTRATOR uses](../illustrator/SKILL.md#per-stage-model-tiering) (**sonnet concept → opus review → opus
craft**, where sonnet = `claude-sonnet-4-6`, opus = `claude-opus-4-8`):

- **Generation/sheets/catalog** are **deterministic bash (0 model tokens)** — no tier applies; they are the
  cheap mechanical substrate beneath the concept stage.
- **Scoring (Phase D)** is the **opus review tier** — the [image-aesthetic-reviewer](../design-reviewer/agents/image-aesthetic-reviewer.md),
  spawned one agent per A/B sheet, runs on opus because deciding whether a stage is a *real, named,
  reproducible* gain is the taste call the expensive tier exists for. A per-job override may force a cheaper
  tier for a throwaway sweep, exactly as the value handlers' *Spawning Model Policy* allows.
- **Synthesize (Phase F)** folds the proven recipes into [`workflow-strategy.md`](../illustrator/references/workflow-strategy.md)
  so the illustration **craft stage starts from the stage that pays** — the study is how the opus craft tier
  gets sharper between cycles.

Like the illustration A/B loop, this study is **per-item-class, not per-commit**, and — when present — is
**dispatched through the [token-fairness scheduler](../../../../CLAUDE.md)** off-peak by default (the operator
may consent to run now), since a full sweep is token-intensive in its scoring fan-out.

## Adversarial gate (Gate 3)

The study's claims face the steering panel: every promoted gain must survive a reviewer **prompted to refute it**
("this 'gain' is seed luck / prompt luck / placebo"). Pass iff each promoted technique is a **visible, named,
reproducible** improvement over its matched baseline, written to `image-craft-study/gates/gate-03-craft.md`
with the human `STEER:` block. Tested-but-no-gain techniques are recorded so the next cycle does not re-litigate them.

## Resumability & safety

- **Idempotent:** a cell regenerates only if not `done` + file present; re-runs are free.
- **Findings, not crashes:** a checkpoint/LoRA that will not load is journalled (`status:error`, with the node +
  exception) and the pass continues — load-failures are evidence.
- **Allowlist-bounded:** generation fills ONLY the Phase-5 templates' declared `fillable` paths (parameter-only,
  no arbitrary node graph) — parameter-only, no caller-supplied node graphs.
- **Self-contained:** scripts reuse the sibling `model-survey/scripts/comfyui-lib.sh` and the in-plugin
  `knowledge/comfyui-workflows/` templates via plugin-relative paths only.
