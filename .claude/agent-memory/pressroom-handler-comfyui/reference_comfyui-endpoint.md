---
name: comfyui-endpoint
description: The reachable ComfyUI server for pressroom raster work is http://10.10.10.163:8188 (the canon default 10.0.1.19 was unreachable).
metadata:
  type: reference
---

Live ComfyUI server for pressroom generative-raster work: **http://10.10.10.163:8188** (export `PRESSROOM_COMFYUI_URL`).

The handler-canon default `http://10.0.1.19:8188` was **unreachable** in the i2p-hero job (2026-06-10); the caller supplied 10.10.10.163 instead, which probed green on `/system_stats`.

**How to apply:** always honour `$PRESSROOM_COMFYUI_URL` if the caller sets it; do not assume the canon default IP is live. Probe `/system_stats` (3s) before any work and decline cleanly if it fails.

Models present here: target `SDXL_1/protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors` and fallback `dreamshaper_8.safetensors`. Remember to strip the template `_meta` block before POST — see [[template-meta-strip]] and [[i2p-hero-comfyui]].
