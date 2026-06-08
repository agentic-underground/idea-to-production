# The five test objectives

Each model in the survey is exercised on these five categories — the recurring kinds of illustration the
marketplace docs actually need. Every model sees the **same prompt and the same seed** per category (seed =
`1000 + category-index`, fixed in `generate.sh`) so results are directly comparable: the only variable is the
model. Prompts live canonically in [`manifest.example.json`](manifest.example.json); this is the readable
companion.

| Category | What it probes | Positive prompt (abridged) |
|---|---|---|
| **scenes** | dense, atmospheric environments; lighting & detail | cyberpunk night street market, neon on wet pavement, volumetric light, cinematic |
| **landscapes** | natural vistas; depth, colour, sky | mountain valley at golden hour, river through pine forest, dramatic clouds, wide vista |
| **office** (marketing stock) | believable people + hands; "authentic stock" look | candid diverse team around a laptop in a bright modern office, natural light, corporate stock |
| **line-goes-up** | can the model do clean infographic/chart-like output? (usually the hardest — a key finding) | minimal business growth chart, upward green line on a grid, dark dashboard, flat UI |
| **cute-mascot** | logo/mascot shapes; clean, centred, vector-friendly | adorable rounded robot mascot, big friendly eyes, simple flat background, mascot logo style |

Negatives are category-specific (e.g. office bans `cartoon, deformed hands, extra fingers`; line-goes-up bans
`photograph, people, cluttered`). The point is not pretty pictures — it is **evidence** for the
[`comfyui-model-guide`](../../../knowledge/comfyui-model-guide.md): which model to route each illustration
intent to, and which to avoid (e.g. if no SD1.5 model can render a legible `line-goes-up`, the guide says so
and the illustrator keeps that category on the vector handlers).

To widen the survey, add models or categories here / in `manifest.example.json` and re-run the loop — the
journal makes it incremental (only new cells generate).
