# Adapted ComfyUI workflow catalog

Adaptation pass over the 53 mined community/official workflows: every referenced asset
remapped to the live rig menus, each graph classified for headless re-run.

## Summary

| Metric | Count |
| --- | --- |
| Source PNGs | 53 |
| Adapted (kept) | 39 |
| &nbsp;&nbsp;rerunnable | 20 |
| &nbsp;&nbsp;needs-input | 14 |
| &nbsp;&nbsp;merge | 5 |
| Rerunnable (auto) | 20 |
| Total substitutions | 81 |
| Dropped | 14 |

## rerunnable  (20)

### 01 · `2-pass-txt2img-hiresfix-esrgan-workflow`
- **family**: SD2.1  ·  **technique**: hires
- **file**: `adapted/01-2-pass-txt2img-hiresfix-esrgan-workflow.json`  ·  **nodes**: 15
- **substitutions**: `RealESRGAN_x4plus.pth`→`RealESRGAN/RealESRGAN_x4plus.pth` (upscale); `v2-1_768-ema-pruned.ckpt`→`v2-1_768-ema-pruned.safetensors` (checkpoint)
- **good for**: two-pass hi-res txt2img with an ESRGAN model upscale between passes

### 02 · `2-pass-txt2img-hiresfix-latent-workflow`
- **family**: SD2.1  ·  **technique**: hires
- **file**: `adapted/02-2-pass-txt2img-hiresfix-latent-workflow.json`  ·  **nodes**: 11
- **substitutions**: `v2-1_768-ema-pruned.ckpt`→`v2-1_768-ema-pruned.safetensors` (checkpoint)
- **good for**: two-pass hi-res via latent upscale (classic hiresfix)

### 03 · `2-pass-txt2img-latent-upscale-different-prompt-model`
- **family**: SD1.5  ·  **technique**: hires
- **file**: `adapted/03-2-pass-txt2img-latent-upscale-different-prompt-model.json`  ·  **nodes**: 15
- **substitutions**: `wd-illusion-fp16.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `cardosAnime_v10.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: latent-upscale second pass with a different prompt/model for detail

### 04 · `area-composition-morning-day-evening-night`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/04-area-composition-morning-day-evening-night.json`  ·  **nodes**: 29
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint); `AbyssOrangeMix2_hard.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: area-conditioned scene split into time-of-day quadrants

### 05 · `area-composition-night-evening-day-morning`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/05-area-composition-night-evening-day-morning.json`  ·  **nodes**: 29
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint); `AbyssOrangeMix2_hard.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: area-conditioned time-of-day gradient (reverse order)

### 06 · `area-composition-night-evening-day-morning-subject`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/06-area-composition-night-evening-day-morning-subject.json`  ·  **nodes**: 32
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `AbyssOrangeMix2_hard.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: time-of-day area split with a foreground subject region

### 07 · `area-composition-square-area-for-2-subjects`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/07-area-composition-square-area-for-2-subjects.json`  ·  **nodes**: 21
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: two subjects placed in separate square areas

### 08 · `area-composition-square-area-for-2-subjects-first-pass`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/08-area-composition-square-area-for-2-subjects-first-pass.json`  ·  **nodes**: 21
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: two-subject area composition, first pass

### 09 · `area-composition-square-area-for-subject`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/09-area-composition-square-area-for-subject.json`  ·  **nodes**: 18
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: single subject confined to a square area

### 10 · `area-composition-workflow-night-evening-day-morning`
- **family**: SD1.5  ·  **technique**: hires, area-composition
- **file**: `adapted/10-area-composition-workflow-night-evening-day-morning.json`  ·  **nodes**: 29
- **substitutions**: `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint); `AbyssOrangeMix2_hard.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: full area-composition workflow over a day cycle

### 23 · `lcm-lcm-basic-example`
- **family**: SDXL  ·  **technique**: lora
- **file**: `adapted/23-lcm-lcm-basic-example.json`  ·  **nodes**: 9
- **substitutions**: `sd_xl_1.0.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint); `lcm_lora_sdxl.safetensors`→`SDXL/xl_more_art-full_v1.safetensors` (lora)
- **good for**: few-step LCM-LoRA fast sampling

### 24 · `lora-lora`
- **family**: SD1.5  ·  **technique**: lora
- **file**: `adapted/24-lora-lora.json`  ·  **nodes**: 8
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `epiNoiseoffset_v2.safetensors`→`LowRA.safetensors` (lora)
- **good for**: single-LoRA style application

### 25 · `lora-lora-multiple`
- **family**: SD1.5  ·  **technique**: lora
- **file**: `adapted/25-lora-lora-multiple.json`  ·  **nodes**: 9
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `epiNoiseoffset_v2.safetensors`→`LowRA.safetensors` (lora); `theovercomer8sContrastFix_sd15.safetensors`→`LowRA.safetensors` (lora)
- **good for**: stacking multiple LoRAs

### 31 · `noisy-latent-composition-noisy-latents-3-subjects`
- **family**: SD1.5  ·  **technique**: txt2img
- **file**: `adapted/31-noisy-latent-composition-noisy-latents-3-subjects.json`  ·  **nodes**: 20
- **substitutions**: `wd-illusion-fp16.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: compose three subjects from noisy latent regions

### 32 · `noisy-latent-composition-noisy-latents-3-subjects`
- **family**: SD1.5  ·  **technique**: txt2img
- **file**: `adapted/32-noisy-latent-composition-noisy-latents-3-subjects.json`  ·  **nodes**: 20
- **substitutions**: `wd-illusion-fp16.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: compose three subjects from noisy latent regions

### 33 · `sdturbo-sdxlturbo-example`
- **family**: SDXL  ·  **technique**: txt2img
- **file**: `adapted/33-sdturbo-sdxlturbo-example.json`  ·  **nodes**: 9
- **substitutions**: `sd_xl_turbo_1.0_fp16.safetensors`→`LIGHTNING/easymodeXLTurbo_v10Lightning.safetensors` (checkpoint)
- **good for**: single-step SDXL-Turbo generation

### 34 · `sdxl-sdxl-refiner-prompt-example`
- **family**: SDXL  ·  **technique**: txt2img
- **file**: `adapted/34-sdxl-sdxl-refiner-prompt-example.json`  ·  **nodes**: 11
- **substitutions**: `sd_xl_base_1.0.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint); `sd_xl_refiner_1.0.safetensors`→`SDXL/sd_xl_refiner_1.0.safetensors` (checkpoint)
- **good for**: SDXL base + refiner two-stage prompt

### 37 · `sdxl-sdxl-simple-example`
- **family**: SDXL  ·  **technique**: txt2img
- **file**: `adapted/37-sdxl-sdxl-simple-example.json`  ·  **nodes**: 11
- **substitutions**: `sd_xl_base_1.0.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint); `sd_xl_refiner_1.0.safetensors`→`SDXL/sd_xl_refiner_1.0.safetensors` (checkpoint)
- **good for**: minimal SDXL base txt2img

### 38 · `textual-inversion-embeddings-embedding-example`
- **family**: SD2.1  ·  **technique**: txt2img
- **file**: `adapted/38-textual-inversion-embeddings-embedding-example.json`  ·  **nodes**: 7
- **substitutions**: `v2-1_768-ema-pruned.ckpt`→`v2-1_768-ema-pruned.safetensors` (checkpoint)
- **good for**: textual-inversion embedding in the prompt

### 39 · `upscale-models-esrgan-example`
- **family**: SD1.5  ·  **technique**: hires
- **file**: `adapted/39-upscale-models-esrgan-example.json`  ·  **nodes**: 9
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `RealESRGAN_x2.pth`→`RealESRGAN/RealESRGAN_x2plus.pth` (upscale)
- **good for**: pure ESRGAN model upscale of a generation

## needs-input  (14)

### 11 · `controlnet-2-pass-pose-worship`
- **family**: SD1.5  ·  **technique**: controlnet, hires
- **file**: `adapted/11-controlnet-2-pass-pose-worship.json`  ·  **nodes**: 20
- **substitutions**: `control_openpose.safetensors`→`ControlNet-v1-1/control_v11p_sd15_openpose.pth` (controlnet); `kl-f8-anime2.ckpt`→`SD1.x/kl-f8-anime2.vae.pt` (vae); `AOM3A3.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: pose-guided generation refined in a second pass

### 12 · `controlnet-controlnet-example`
- **family**: SD1.5  ·  **technique**: controlnet
- **file**: `adapted/12-controlnet-controlnet-example.json`  ·  **nodes**: 11
- **substitutions**: `control_scribble.safetensors`→`ControlNet-v1-1/control_v11p_sd15_scribble.pth` (controlnet); `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae); `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: basic ControlNet conditioning from a hint image

### 13 · `controlnet-depth-controlnet`
- **family**: SD1.5  ·  **technique**: controlnet
- **file**: `adapted/13-controlnet-depth-controlnet.json`  ·  **nodes**: 10
- **substitutions**: `diff_control_sd15_depth_fp16.safetensors`→`ControlNet-v1-1/control_v11f1p_sd15_depth.pth` (controlnet); `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint)
- **good for**: depth-map guided generation

### 14 · `controlnet-depth-t2i-adapter`
- **family**: SD1.5  ·  **technique**: controlnet
- **file**: `adapted/14-controlnet-depth-t2i-adapter.json`  ·  **nodes**: 10
- **substitutions**: `t2iadapter_depth_sd14v1.pth`→`ControlNet-v1-1/control_v11f1p_sd15_depth.pth` (controlnet); `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint)
- **good for**: lightweight depth T2I-adapter guidance

### 15 · `controlnet-mixing-controlnets`
- **family**: SD1.5  ·  **technique**: controlnet
- **file**: `adapted/15-controlnet-mixing-controlnets.json`  ·  **nodes**: 14
- **substitutions**: `kl-f8-anime2.ckpt`→`SD1.x/kl-f8-anime2.vae.pt` (vae); `control_scribble.safetensors`→`ControlNet-v1-1/control_v11p_sd15_scribble.pth` (controlnet); `control_openpose.safetensors`→`ControlNet-v1-1/control_v11p_sd15_openpose.pth` (controlnet); `AOM3A1.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint)
- **good for**: stacking two ControlNets on one generation

### 16 · `img2img-img2img-workflow`
- **family**: SD1.5  ·  **technique**: txt2img
- **file**: `adapted/16-img2img-img2img-workflow.json`  ·  **nodes**: 8
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint)
- **good for**: denoise-from-source img2img

### 17 · `inpaint-inpain-model-cat`
- **family**: SD1.5  ·  **technique**: inpaint
- **file**: `adapted/17-inpaint-inpain-model-cat.json`  ·  **nodes**: 8
- **substitutions**: —
- **good for**: inpaint a cat with a dedicated inpainting model

### 18 · `inpaint-inpain-model-outpainting`
- **family**: SD1.5  ·  **technique**: inpaint
- **file**: `adapted/18-inpaint-inpain-model-outpainting.json`  ·  **nodes**: 9
- **substitutions**: —
- **good for**: outpainting via the inpaint model + pad

### 19 · `inpaint-inpain-model-woman`
- **family**: SD1.5  ·  **technique**: inpaint
- **file**: `adapted/19-inpaint-inpain-model-woman.json`  ·  **nodes**: 8
- **substitutions**: —
- **good for**: portrait inpaint with the inpainting model

### 20 · `inpaint-inpaint-anythingv3-woman`
- **family**: SD1.5  ·  **technique**: inpaint
- **file**: `adapted/20-inpaint-inpaint-anythingv3-woman.json`  ·  **nodes**: 10
- **substitutions**: `Anything-V3.0.ckpt`→`cardosAnimated_v20.safetensors` (checkpoint); `vae-ft-mse-840000-ema-pruned.safetensors`→`SD1.x/vae-ft-mse-840000-ema-pruned.safetensors` (vae)
- **good for**: anime portrait inpaint

### 21 · `inpaint-inpaint-example`
- **family**: SD1.5  ·  **technique**: inpaint
- **file**: `adapted/21-inpaint-inpaint-example.json`  ·  **nodes**: 8
- **substitutions**: —
- **good for**: basic masked inpaint

### 22 · `inpaint-yosemite-outpaint-example`
- **family**: SD1.5  ·  **technique**: inpaint
- **file**: `adapted/22-inpaint-yosemite-outpaint-example.json`  ·  **nodes**: 9
- **substitutions**: —
- **good for**: landscape outpaint extending a photo

### 35 · `sdxl-sdxl-revision-text-prompts`
- **family**: SDXL  ·  **technique**: unclip
- **file**: `adapted/35-sdxl-sdxl-revision-text-prompts.json`  ·  **nodes**: 14
- **substitutions**: `sd_xl_base_1.0.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint)
- **good for**: SDXL Revision image-prompt + text

### 36 · `sdxl-sdxl-revision-zero-positive`
- **family**: SDXL  ·  **technique**: unclip
- **file**: `adapted/36-sdxl-sdxl-revision-zero-positive.json`  ·  **nodes**: 14
- **substitutions**: `sd_xl_base_1.0.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint)
- **good for**: SDXL Revision with zeroed positive

## merge  (5)

### 26 · `model-merging-model-merging-3-checkpoints`
- **family**: SD1.5  ·  **technique**: merge
- **file**: `adapted/26-model-merging-model-merging-3-checkpoints.json`  ·  **nodes**: 12
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `cardosAnime_v10.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `AOM3A1.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `kl-f8-anime2.ckpt`→`SD1.x/kl-f8-anime2.vae.pt` (vae)
- **good for**: block-merge of three checkpoints

### 27 · `model-merging-model-merging-basic`
- **family**: SD1.5  ·  **technique**: merge
- **file**: `adapted/27-model-merging-model-merging-basic.json`  ·  **nodes**: 10
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `cardosAnime_v10.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `kl-f8-anime2.ckpt`→`SD1.x/kl-f8-anime2.vae.pt` (vae)
- **good for**: simple weighted two-checkpoint merge

### 28 · `model-merging-model-merging-cosxl`
- **family**: SDXL  ·  **technique**: merge
- **file**: `adapted/28-model-merging-model-merging-cosxl.json`  ·  **nodes**: 15
- **substitutions**: `cosxl.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint); `albedobaseXL_v21.safetensors`→`juggernautXL_version2.safetensors` (checkpoint); `sd_xl_1.0.safetensors`→`SDXL/sd_xl_base_1.0.safetensors` (checkpoint)
- **good for**: CosXL add/subtract SDXL merge recipe

### 29 · `model-merging-model-merging-inpaint`
- **family**: SD1.5  ·  **technique**: merge, inpaint
- **file**: `adapted/29-model-merging-model-merging-inpaint.json`  ·  **nodes**: 14
- **substitutions**: `sd-v1-5-inpainting.ckpt`→`512-inpainting-ema.safetensors` (checkpoint); `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `AOM3A1.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `kl-f8-anime2.ckpt`→`SD1.x/kl-f8-anime2.vae.pt` (vae)
- **good for**: transplant inpainting capability via add/subtract merge

### 30 · `model-merging-model-merging-lora`
- **family**: SD1.5  ·  **technique**: merge, lora
- **file**: `adapted/30-model-merging-model-merging-lora.json`  ·  **nodes**: 11
- **substitutions**: `v1-5-pruned-emaonly.ckpt`→`dreamshaper_8.safetensors` (checkpoint); `cardosAnime_v10.safetensors`→`cardosAnimated_v20.safetensors` (checkpoint); `kl-f8-anime2.ckpt`→`SD1.x/kl-f8-anime2.vae.pt` (vae); `theovercomer8sContrastFix_sd15.safetensors`→`LowRA.safetensors` (lora)
- **good for**: bake a LoRA into a merged checkpoint

## dropped  (14)

| source | family | reason |
| --- | --- | --- |
| `controlnet_house_scribble.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `controlnet_input_scribble_example.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `controlnet_pose_present.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `controlnet_pose_worship.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `controlnet_shark_depthmap.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `gligen_gligen_textbox_example.png` | SD1.5 | gligen required but no analog on rig (gligen_sd14_textbox_pruned.safetensors) |
| `hypernetworks_hypernetwork_example.png` | SD1.5 | hypernetwork required but no analog on rig (dantionMarbleStatues_10.pt) |
| `hypernetworks_hypernetwork_example_output.png` | SD1.5 | hypernetwork required but no analog on rig (dantionMarbleStatues_10.pt) |
| `inpaint_yosemite_inpaint_example.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `unclip_mountains.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `unclip_sunset.png` | ? | input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph |
| `unclip_unclip_2pass.png` | SD1.5 | unclip-checkpoint required but no analog on rig (wd-1-5-beta2-aesthetic-unclip-h-fp32.safetensors) |
| `unclip_unclip_example.png` | SD1.5 | unclip-checkpoint required but no analog on rig (sd21-unclip-h.ckpt) |
| `unclip_unclip_example_multiple.png` | SD1.5 | unclip-checkpoint required but no analog on rig (sd21-unclip-h.ckpt) |
