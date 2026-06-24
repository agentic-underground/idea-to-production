# Rig inventory — the i9-13900f model disk + example library (via SSH)

Authoritative on-disk asset lists (`/media/user/1T_990/AIs/DIFFUSION_MODELS/`), captured read-only over SSH —
richer than the ComfyUI `/object_info` API list and used to ground the craft canon.

- `checkpoints.txt` — 86 checkpoints (`.safetensors`/`.ckpt`)
- `loras.txt` — 239 LoRAs (root `LORA/` + an `SDXL/` subfolder)
- `upscalers.txt` — 24 upscale models
- (also on disk: CONTROLNET, VAE, EMBEDDINGS, HYPERNETWORKS, CLIP/clip_vision_g, Codeformer/GFPGAN face-restore)

## The example library — `~/Pictures/ComfyUI` (23,771 PNGs · 82 GB — DO NOT bulk-read)

Every PNG carries the embedded ComfyUI `prompt` + `workflow` JSON, so recipes can be mined from the **text
chunks** (cheap) without ever loading pixels — use `../workflows/extract-workflow.py`. Map in `library-map.txt`:
- `WORKFLOW_OUTPUTS/` (7,724) — technique-categorized: **BASE_REFINED_T2I · CONTROLNET · REIMAGINE · SCALE**.
- `MODEL_TESTS/` (14,514) — themed style/subject tests.
- A curated **"this is what I like"** folder is forthcoming from the maintainer → mine those workflows first.
