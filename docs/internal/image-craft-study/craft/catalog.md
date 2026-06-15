# Craft study — multi-stage technique catalog

_Empirical, controlled single-variable A/B per objective. Baseline and treatment share ckpt / prompt / seed /
base resolution; the only difference is the named stage. A gain counts only if it is **visible, named, and
reproducible** over the baseline. Rasters are gitignored; this catalog + journal.jsonl are the tracked record._

Rig endpoint: `http://10.10.10.163:8188` · seed `1234`

## portrait

- **Checkpoint:** `nightvisionXLPhotorealisticPortrait_v0743ReleaseBakedvae.safetensors`
- **Gain under test:** hires re-detail on skin/eyes/hair
- **Verdict:** **no-gain** — REGRESSION: hires-fix @0.45 denoise scrubbed close-up skin/hair micro-detail into smooth AI-skin (high-pass energy -17..-20% on eyes/beard/face). Canonical latent-hires failure on tight portraits.
- **A/B sheet:** `contact-sheets/portrait.png`

| technique | template | status | note |
|---|---|---|---|
| `flat` | `txt2img-hires-fix` | done | single-pass baseline (no hires re-detail) |
| `hires` | `txt2img-hires-fix` | done | + latent hires-fix (1.5x upscale, 0.45-denoise re-detail pass) |

## landscape

- **Checkpoint:** `crystalClearXL_ccxl.safetensors`
- **Gain under test:** hires re-detail on atmospheric depth + micro-texture
- **Verdict:** **gain** — hires re-detail resolves smeared mid/foreground into real micro-texture (conifers, rock facets, layered fog banks); does NOT author the depth gradient (a base property). Real but incremental.
- **A/B sheet:** `contact-sheets/landscape.png`

| technique | template | status | note |
|---|---|---|---|
| `flat` | `txt2img-hires-fix` | done | single-pass baseline (no hires re-detail) |
| `hires` | `txt2img-hires-fix` | done | + latent hires-fix (1.5x upscale, 0.45-denoise re-detail pass) |

## marketing-hero

- **Checkpoint:** `foddaxlPhotorealism_v51.safetensors`
- **Gain under test:** hires re-detail on product reflections + studio crispness
- **Verdict:** **gain** — hires re-detail recovers marble micro-veining + crema grain; region-selective (+12.5% on textured surfaces, ~0 on flat wall = not placebo/oversharpen).
- **A/B sheet:** `contact-sheets/marketing-hero.png`

| technique | template | status | note |
|---|---|---|---|
| `flat` | `txt2img-hires-fix` | done | single-pass baseline (no hires re-detail) |
| `hires` | `txt2img-hires-fix` | done | + latent hires-fix (1.5x upscale, 0.45-denoise re-detail pass) |

## dark-key

- **Checkpoint:** `epicrealism_naturalSinRC1VAE.safetensors`
- **Gain under test:** the dark-key LoRA stack (deep chiaroscuro, controlled low-key)
- **Verdict:** **gain** — dark-key LoRA stack (lowkey@0.8 + LowRA@0.6) converts an even mid-tone portrait into true low-key tenebrist chiaroscuro: background to near-black, motivated key carving form. Strongest gain.
- **A/B sheet:** `contact-sheets/dark-key.png`

| technique | template | status | note |
|---|---|---|---|
| `loraoff` | `lora-detail` | done | dark-key baseline (LoRA stack disabled, strengths 0) |
| `loraon` | `lora-detail` | done | + dark-key LoRA stack (lowkey_v1.1 @0.8 + LowRA @0.6) |

## world-axis

- **Checkpoint:** `reproductionSDXL_2v12.safetensors`
- **Gain under test:** regional composition coherence (vertical world-axis, aerial->warm depth gradient)
- **Verdict:** **gain** — tricomposite builds a coherent vertical world-axis (cosmic vortex -> cracked-earth dome -> warm profile figure) with a working cool->warm depth descent; 3 layered feathered planes.
- **A/B sheet:** `contact-sheets/world-axis.png`

| technique | template | status | note |
|---|---|---|---|
| `tricomposite` | `tricomposite` | done | regional latent composition (3 regions -> 2 feathered composites -> unify pass) |

---

_Generated from journal.jsonl: 9 cell(s) done, 0 errored, 5 objective(s) scored._
