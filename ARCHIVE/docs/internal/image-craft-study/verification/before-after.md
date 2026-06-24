# Before / after — the heroes, old vs new, scored under the NEW rubric

> The proof the craft + taste upgrade worked. The 5 plugin heroes were regenerated through the
> **multi-stage pipeline** (`lora-detail`: dark-key LoRA stack `lowkey_v1.1` + `LowRA` → SDXL base →
> 1.5× latent hires-fix) with **art-directed prompts** (focal point, motivated light, colour script), then
> both the old and the new versions were scored under the **new, stricter, exemplar-grounded** image rubric.

## The calibration test (Gate 6) — proof the bar rose, not just the images

The 5 old heroes scored **>95** under the *old, lenient* rubric. Re-scored under the **new** rubric they fall
to **competent-but-generated**, while the same subject regenerated with real craft scores far higher — so the
rubric is **calibrated, not merely harsh** (it rewards the craft lift). See
[`../gates/gate-06-calibration.md`](../gates/gate-06-calibration.md).

| Hero | Old (lenient rubric) | Old (NEW rubric) | New (NEW rubric) | Δ | Verdict (new) |
|---|---:|---:|---:|---:|---|
| i2p | >95 | 68 | **100** | **+32** | award-tier |
| sentinel | >95 | 68 | **~96** | **+28** | award-tier |
| atelier | >95 | 62 | **~96** | **+34** | strong (brushing award) |
| concierge | >95 | 71 | **~92** | **+21** | strong |
| mission-control | >95 | 65 | **~85** | **+20** | strong (after a focal-hierarchy re-roll) |

(New scores: [`../gates/gate-07-new-heroes.md`](../gates/gate-07-new-heroes.md). mission-control was re-rolled
once per its lift path — single dominant globe focal, abstract screens, the soft pseudo-text panel removed.)

## What changed (the named craft)

- **Multi-stage, not single-pass.** The old heroes were single-stage 1024-ish txt2img. The new ones are a
  LoRA-stacked base + a latent **hires-fix** re-detail at 1.5× — real micro-detail and coherence at size.
- **Art-direction in the prompt.** Each prompt names the composition (one focal point, leading lines,
  negative space), the **motivated light** (a key + rim, volumetric, chiaroscuro), and a **colour script**
  (complementary teal/amber) — the exact things the old flat/centred/muddy results lacked.
- **Dark-key by construction.** The `lowkey_v1.1` + `LowRA` LoRA stack delivers the deep low-key ground a
  README hero needs, instead of fighting a bright bake in the negative prompt.
- **Text-free, people-free.** No baked pseudo-text on any hero (Gate 7 cropped every surface to confirm),
  sidestepping the artifact-floor caps.

## What the taste upgrade fixed

The reviewer is no longer **too lenient**. A clean, on-prompt, but flat/centred/muddy image is now scored
**3-tier ("competent-but-generated")** on the composition & art-direction dimension, which *caps the overall
out of the top band* — so it can no longer score 95+. The aesthetic dimension is scored against **named
art-direction theory** (ATELIER's `art-direction.md`, composed by capability) with every finding citing a
principle **and** a named award-winning exemplar. The old heroes dropping from >95 to the 60s **is** the proof.

## Residual / next iteration

- `mission-control` is the top of the strong band, not award-tier — a further focal pass + a faint inpaint
  would lift it.
- `atelier` / `concierge` are *strong* (≥92); reaching award-tier wants a single-key relight and an
  off-centre (thirds) reframe — the A/B-until-best loop would close that.
- The deferred empirical phases (mine + re-run 50 workflows; the full technique sweep; the diagram track)
  would backfill the model-guide with measured per-genre evidence and push more heroes to ≥95.
