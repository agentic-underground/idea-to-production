# Gate 05 — allowlisted templates + recipe library + self-containment (Phase 5)

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste`

## What shipped

- **Self-containment fix (Gate-8 debt cleared).** The allowlisted templates now ship **inside the plugin** at
  `plugins/pressroom/knowledge/comfyui-workflows/` (`txt2img-basic`, `txt2img-hires-fix`, `lora-detail`,
  `upscale`, `tricomposite`). `handler-comfyui.md` resolves them under `${CLAUDE_PLUGIN_ROOT}` (the jq fill
  path + all links repointed); the old `../../../comfyui-mcp/…` escape that broke standalone install is gone.
  `comfyui-mcp/workflows/` keeps a synced mirror for the future server.
- **NEW `tricomposite.json`** — the maintainer's vertical-stack signature, templatized from the **real rig
  graph** (extracted from `TRICOMPOSITE_00001`): three increasing-height regions → two feathered
  `LatentComposite`s → a unifying `KSampler` @ denoise ~0.5. Checkpoint at **root** (`reproductionSDXL_2v12`,
  post-move); bounded `_meta.fillable` exposes the 4 prompts, the composite x/y/**feather**, seeds, and the
  unify denoise/steps/cfg — the actual compositional controls. Samplers upgraded to the maintainer's
  `dpmpp_sde_gpu`/karras.
- **EARS** — fixed the wrong "`sd_xl_base_1.0` fails to load / no refiner" claim; added `tricomposite` to the
  allowlist + E5 multi-stage validation; documented that local raster post-processing is **out of scope**
  (pressroom's `handler-composite` + `raster-toolchain.md` recipe library, int()-validated, own surface).

## Proof — the template runs end-to-end on the rig

Validated, not asserted: all required node classes present on the rig (`LatentComposite`, `unCLIPConditioning`,
`UltimateSDUpscale`, …); checkpoint confirmed at root; the filled template (strip `_meta` → POST → poll →
download) produced a **coherent 1024×1280 vertical world-axis composition** — cosmic starfield sky → glowing
ancient-tree canopy → warm forest floor, the tree threading all three registers with a cool→warm depth
gradient. Exactly the tricomposite craft, now a fillable allowlisted template.
Evidence: `toolchain/proof/tricomposite-validated.jpg`.

## STEER

Green. The bounded recipe library (Phase 8 `raster-toolchain.md`) + the allowlisted ComfyUI templates now
share one allowlist philosophy across two independent surfaces. The IRU/unCLIP-REIMAGINE premium graph
(42 nodes, saved in `rig-inventory/iru-premium-workflow.json`) can be templatized next if a REIMAGINE slot is
wanted; deferred (heavy, needs a reference-image input contract).
