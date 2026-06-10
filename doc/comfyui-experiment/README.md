# ComfyUI model survey — experiment home

The tracked record of PRESSROOM's [model survey](../../plugins/pressroom/skills/model-survey/SKILL.md): a
loop-driven experiment that explores the ComfyUI backend's checkpoints across five illustration objectives
(scenes, landscapes, candid-office/marketing-stock, line-goes-up, cute-mascot), scores them with the design
team's image-aesthetic lens, and folds the findings into the
[`comfyui-model-guide`](../../plugins/pressroom/knowledge/comfyui-model-guide.md) that `handler-comfyui` and
the illustrator consult.

## What's here
| File | Tracked? | What |
|---|---|---|
| `manifest.json` | ✓ | the validated curated subset (models × the five categories × prompts) |
| `journal.jsonl` | ✓ | append-only run ledger — validation verdicts, generated cells, scores |
| `catalog.md` | ✓ | markdown catalog of the files on disk, with scores |
| `comfyui-model-survey.pdf` | ✓ | the efficient, gs-downsampled visual catalog (the deliverable) |
| `images/` `thumbs/` `contact-sheets/` | ✗ gitignored | generated rasters — **retained on disk**, not in git |

## Re-run / widen it
It runs under `/loop` (self-paced), resumable via the journal — only un-done cells generate:
```
/loop  →  the model-survey skill advances VALIDATE → GENERATE → SHEETS → SCORE → CATALOG → GUIDE, then stops
```
To widen, add models/categories in
[`manifest.example.json`](../../plugins/pressroom/skills/model-survey/references/manifest.example.json) and
re-loop. The harness lives in `plugins/pressroom/skills/model-survey/scripts/` (deterministic bash/Typst; only
scoring spends model tokens). Backend: `${PRESSROOM_COMFYUI_URL:-http://10.10.10.163:8188}`.
