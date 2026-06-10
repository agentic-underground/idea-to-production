---
name: mission-control-hero-comfyui
description: Reproducible recipe for plugins/mission-control/diagrams/hero.png — protovisionXL dark-key ops-room, abstract screens to dodge the illegible-text cap.
metadata:
  type: project
---

The mission-control plugin hero (`/home/user/Code/idea-to-production/plugins/mission-control/diagrams/hero.png`) is a ComfyUI dark-key asset.

**Recipe (reproducible, CURRENT WINNER):** template `txt2img-basic`, model `SDXL_1/protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors`, 1216×832, steps 30, cfg 6.5, sampler `dpmpp_2m`, scheduler `karras`, **seed 503**. Positive: "calm empty mission control room, large central glowing teal globe under a warm amber ceiling dome, symmetric curved monitor banks showing ONLY smooth abstract teal glow and soft waveform rings, simple uncluttered foreground floor, empty chairs, dark-key cinematic". Negative: "text, words, letters, numbers, digits, status lines, readouts, dashboards with labels, character blocks, glyphs, symbols on screens, ui text, captions, label strips, cluttered foreground consoles, people, hands, face". Composition: symmetric amphitheatre, warm AMBER ceiling dome + central amber-on-cyan glowing globe twin-focal, big curved screen banks reduced to smooth abstract teal WAVEFORMS, empty chairs + central table, **no foreground desk-monitor row**. Dark-key, no people.

**Why abstract screens + simple foreground:** the figure sits near the pressroom illegible-text hard cap. Across three passes the persistent regression was pseudo-text baked onto SMALL panels — earlier seeds abstracted the big wall banks but left small foreground console desk-monitors / side sub-panels with fake status-lines, character blocks, "537"-like numbers. The reliable fix is TWO-fold: (1) heavy negative against text/glyphs/label-strips AND "cluttered foreground consoles", and (2) compose the FOREGROUND simpler — empty floor leading to the central globe, with fewer/farther/absent desk-monitors. Fewer small bright panels = fewer surfaces for the model to hallucinate glyphs.

**How to apply:** seed 503 (this batch) is the cleanest: smooth abstract waveform big screens, amber dome + central globe twin-focal intact, and crucially NO foreground desk-monitor row at all (empty floor + chairs) so zero small-panel pseudo-text. Reject the cluttered-desk seeds — in the 501-505 batch, seeds 502/504/505 brought back rows of small bright desk-monitors (the glyph-bake risk surface); seed 501 was clean in foreground but had small back-wall sub-panels with faint striping. Always Read EVERY seed at full detail and scan the SMALL panels specifically — the big screens are usually fine; the small ones are where text regresses. See [[comfyui-endpoint]], [[template-meta-strip]], [[i2p-hero-comfyui]].
