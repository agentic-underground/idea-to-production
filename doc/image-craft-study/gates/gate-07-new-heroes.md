# Gate 07 — New plugin heroes (regenerated), NEW exemplar-grounded rubric

> **Reviewer:** PRESSROOM image-aesthetic reviewer (the new, stricter, exemplar-grounded lens),
> composing ATELIER's art-direction canon (installed). Scored adversarially under
> [`image-aesthetic-canon.md`](../../../plugins/pressroom/skills/design-reviewer/references/image-aesthetic-canon.md)
> with every finding grounded in [`art-direction.md`](../../../plugins/atelier/knowledge/canon/art-direction.md):
> principle **+** named exemplar **+** fix.
>
> **Subjects:** the 5 regenerated heroes at `doc/image-craft-study/verification/new/` (1824×1248).
> Pipeline: dark-key LoRA stack (lowkey_v1.1 + LowRA) → SDXL base → 1.5× latent hires-fix, art-directed prompts.
> **The before/after question:** the OLD versions of these same heroes scored **62–71** (competent-but-generated).
> Do the new ones clearly beat that?

## How scored

Five dimensions (0–5), the canon weights, weighted to /100. Award bands:
**award-tier ≥95 · strong ≥85 · competent-but-generated ~60–84 · broken <40.**
Weights: Category-fit **24** · Prompt-adherence **22** · Artifact-freedom **22** ·
Composition & art-direction **18** · Doc/dark-mode suitability **14**.

**Measured dark-key check (luma, greyscale):** every hero sits genuinely dark and embeddable on a dark page,
with a real value range (true blacks at/near 0, controlled speculars) — this is notan/value-structure, not a
brightened "AI daylight" wash:

| Hero | mean luma | std (value spread) | min | max |
|---|---:|---:|---:|---:|
| i2p | 0.174 | 0.152 | 0.00 | 0.99 |
| sentinel | 0.152 | 0.103 | 0.02 | 0.98 |
| atelier | 0.171 | 0.136 | 0.00 | 1.00 |
| concierge | 0.143 | 0.116 | 0.02 | 0.99 |
| mission-control | 0.228 | 0.187 | 0.00 | 0.98 |

## Artifact-floor sweep (the non-negotiable precondition — §7)

Every screen, surface, blueprint and glass panel was cropped and upscaled (250–600%) and inspected for
baked pseudo-text / gibberish glyphs, melted geometry, and broken perspective.

| Hero | Surfaces scanned (close crops) | Baked text? | Geometry/perspective | Verdict |
|---|---|---|---|---|
| **i2p** | floor inlay, base altar sunburst, arch keystone, ornaments | **none** | symmetric arch coherent; floor recedes correctly | **CLEAN** |
| **sentinel** | lantern room, windows, beam, cliff | **none** | lighthouse structure coherent; beam motivated | **CLEAN** |
| **atelier** | easel board, desk drafting sheet, book spines, window mullions | **none** — both blueprints are abstract line-work (concentric geometry / orbital schematic), spines are dark with no legible titling | lamps & joinery coherent | **CLEAN** |
| **concierge** | door glass, transom, both sconce pairs, rug | **none** — door glass is frosted/textured, not text | one sconce mount slightly soft; no melt | **CLEAN** |
| **mission-control** | ceiling globe, two wall globes, ~12 desk monitors, framed diagram, **amber readout panel (top-right)** | **borderline** — all globes/monitors are abstract (waveforms, network traces, maps); **the small amber panel top-right renders as horizontal striated rows that read as a pseudo-tabular "data readout"** — not legible glyphs, but the *texture of baked text-rows* | room geometry coherent; sweep of consoles convincing | **PASS w/ note** |

**No hard artifact-floor failure on any hero.** No legible or gibberish glyphs were baked anywhere. The one
flag — mission-control's amber top-right panel — is a row-striated readout that *evokes* a data table without
forming glyphs; under the doc-hero rule ("*any* baked pseudo-text is an artifact-freedom failure") it is the
single soft hit and it costs mission-control on Artifact-freedom, but it does not cap the image (it is not
legible text and not melted geometry). Flagged for a clean-up pass below.

---

## 1 — i2p · "luminous gateway into a production galaxy"

| Dim | Score | Note |
|---|:--:|---|
| Category-fit (24) | **5** | Unmistakably a luminous gateway opening onto a star-field/galaxy — rendered excellently of its kind. |
| Prompt-adherence (22) | **5** | Gateway **+** production-galaxy **+** luminous all present and *integrated*: the arch, the teal nebula bleeding through it, the radiant altar on the threshold, the inlaid path leading in. |
| Artifact-freedom (22) | **5** | Symmetric arch holds; floor reflection and perspective correct; ornaments coherent; zero baked text. |
| Composition & art-direction (18) | **5** | Frame-within-frame (the arch — *cf. the closing-doorway frame, The Searchers*); the inlaid floor is a textbook **leading line** routing the eye to the altar focal point (*cf. architecture funnelling to the citadel, Dylan Cole / LOTR matte*); **complementary colour script**, gold-amber vs teal (*cf. saturated orange-vs-blue-grey, Monet, Impression Sunrise*); the nebula god-ray through the arch is **motivated volumetric light** (*cf. smoke-shafted temple, Storaro, Apocalypse Now*). |
| Doc/dark-mode (14) | **5** | mean luma 0.17, true blacks — sits beautifully on a dark page; the bright core is a deliberate focal specular, not a flood. |

**Weighted: 100/100 → rounded band ≥95. Verdict: AWARD-TIER.**
This is the strongest of the five and the clearest exemplar of the before/after: it has a decisive focal point,
a named frame, a leading line, a colour script, and motivated light all at once. The bright keystone star is a
hair busy but it is the *intended* hierarchy, not noise.

## 2 — sentinel · "vigilant lighthouse beacon"

| Dim | Score | Note |
|---|:--:|---|
| Category-fit (24) | **5** | A vigilant lighthouse casting a beacon over a night sea — exactly, and excellently, the category. |
| Prompt-adherence (22) | **4** | Lighthouse, beacon, vigilance all present; the one looser specific is the beacon doing little *narrative* work beyond glowing — it sweeps but doesn't pick out a stake. |
| Artifact-freedom (22) | **5** | Lighthouse and cliff geometry coherent; the bioluminescent surf reads cleanly; no artifacts. |
| Composition & art-direction (18) | **5** | The brightest value (the beam + lantern) is the **focal point** with the cliff mass as supporting dark — strong **figure-ground** (*cf. silhouette against a smoky ground, Frazetta*); **motivated single source** (the lantern is the only key — *cf. candlelight-only key, Barry Lyndon*); near-**monochrome teal colour script** with one warm practical (the small amber light on the headland) as the disciplined accent (*cf. limited palette + one accent, Frazetta*); the curve of the foreshore is a gentle **leading line** to the tower. |
| Doc/dark-mode (14) | **5** | Darkest-but-one (luma 0.15), tight value spread, genuinely embeddable; the beam is contained, not blown out. |

**Weighted: ~96/100. Verdict: AWARD-TIER (low end).**
The most disciplined colour script of the set and a real **emotional register** (lonely vigilance — *cf.
reverent, mood-soaked atmosphere, Lubezki, Tree of Life*). It edges award-tier; the only thing keeping it from
i2p's ceiling is a slightly thinner narrative stake (prompt-adherence 4). A faint banding in the upper sky
gradient is the one cosmetic softness, not an artifact.

## 3 — atelier · "a craftsman's drafting studio"

| Dim | Score | Note |
|---|:--:|---|
| Category-fit (24) | **5** | A warm, lived-in drafting studio — easel, drafting table, instruments, lamps, glowing schematics. Excellent of its kind. |
| Prompt-adherence (22) | **5** | Craftsman's studio with the *tools of drafting* foregrounded and two glowing blueprints (easel + desk) integrated as the cyan light-source, not pasted props. |
| Artifact-freedom (22) | **5** | **Both blueprints are correctly abstract** (concentric geometry / orbital schematic) — *no baked text*, the exact trap this category invites and avoids; lamps, joinery, instruments all coherent. |
| Composition & art-direction (18) | **4** | Beautiful **warm/cool temperature contrast** — tungsten lamp key against cyan-blueprint glow (*cf. amber key vs blue-black shadow, Storaro*) — and **motivated practical light** (the two lamps are the in-world key, *cf. neon practicals as the whole script, Doyle, Fallen Angels*). The one held-back point: **focal hierarchy is split** — the eye ping-pongs between the two equally-bright lamps and the easel; there is no single dominant subject reading first (*the #1 generic tell the canon names — focal hierarchy §1, cf. one warm anchor against a desaturated mass, Horizon env art*). Strong, not yet inevitable. |
| Doc/dark-mode (14) | **5** | luma 0.17, deep shadow, embeddable; the cyan glow is a contained accent. |

**Weighted: ~96/100, but Composition held at 4 → caps the *felt* tier just below the top.
Verdict: STRONG (high), brushing award-tier.**
This is a large leap past the old competent-but-generated version — real materials, real motivated light, real
medium truth. The single craft change to push it award-tier is below.

## 4 — concierge · "warm lantern-lit doorway"

| Dim | Score | Note |
|---|:--:|---|
| Category-fit (24) | **5** | A warm, lantern-lit panelled vestibule with an inviting arched doorway — exactly the brief. |
| Prompt-adherence (22) | **5** | Lantern-lit (four warm sconces), doorway (arched, glazed, framed), warmth all integrated; the rug and bench complete a lived-in threshold. |
| Artifact-freedom (22) | **4** | Coherent throughout; one sconce's mounting bracket is slightly soft and the symmetric sconce pairs are *almost* mirror-identical (a mild generative tell), but nothing broken and no baked text. |
| Composition & art-direction (18) | **4** | Excellent **frame-within-frame** (the arch around the door — *cf. the threshold doorway, The Searchers*) and a warm **analogous colour script** (amber sconces against teal panelling, *cf. analogous warm field, Rothko* / *teal-vs-warm, Shape of Water*). Held at 4 because the **light is even rather than directional** — four near-equal sconces give a balanced, slightly *flat* wash with no single raking key sculpting the space (*the flat-light tell §2, cf. soft directional key, Leibovitz*); the composition is also near-**dead-centre symmetric** (*cliché-centring risk §1*), saved only by the off-axis bench and rug. |
| Doc/dark-mode (14) | **5** | Darkest of the set (luma 0.14), genuinely embeddable; warm pools read against deep teal. |

**Weighted: ~92/100. Verdict: STRONG.**
A clear, warm, on-mood threshold — a real upgrade. It is held out of award-tier by the most classic entry-level
pair: even (un-raked) light and centred symmetry. Both are fixable below.

## 5 — mission-control · "calm ops room"

| Dim | Score | Note |
|---|:--:|---|
| Category-fit (24) | **5** | Unmistakably a calm ops room — circular console pit, ranked monitor banks, ceiling globe. Excellent of its kind. |
| Prompt-adherence (22) | **5** | Ops room **+** calm **+** the monitoring surfaces all present and integrated (globes, waveform/network screens, console ring). |
| Artifact-freedom (22) | **3** | All globes and monitors are correctly **abstract** (maps, waveforms, network traces) — the hard part, passed. **But** the small amber readout panel top-right renders as **striated pseudo-tabular rows** — the *texture of baked text* without forming glyphs. Under the doc-hero rule (heroes are text-free by construction) this is a soft artifact-freedom hit; it does not cap (not legible, not melted) but it is the one blemish, and the dense monitor field has the faint over-rendered "AI sheen" the canon warns of (*§5 medium truth*). |
| Composition & art-direction (18) | **3** | The trap dimension. **No single focal point** — the eye wanders the ring of near-equal-brightness screens (*the #1 generic tell, focal hierarchy §1*). Light is the **even teal CRT-glow wash** with the warm ceiling cove as the only structure — pleasant but **not a motivated directional key** (*flat-light tell §2*). Colour is a competent teal-vs-amber complementary, but applied evenly rather than as a *script* with a value plan (*§3, cf. the deliberate value structure of notan, Ansel Adams*). The symmetry is wide-angle-centred (*cliché-centring §1*). It is polished and clean — and that is exactly the **competent-but-generated** profile the canon names. |
| Doc/dark-mode (14) | **4** | Brightest of the five (luma 0.23) and the busiest; the many lit screens make it slightly louder on a dark page than the others, though still embeddable. |

**Weighted: ~81/100. Verdict: COMPETENT-BUT-GENERATED (top of band).**
It is the *best-executed* competent-but-generated of the five and noticeably better than its old self, but it
has not crossed the line the canon draws: no focal hierarchy, even sourceless glow, even colour, centred
symmetry, plus the one pseudo-text panel. It is the only hero that still trips ≥2 named entry-level tells.

---

## Scoreboard

| Hero | Cat | Prompt | Artifact | Comp | Doc | **/100** | Verdict | Old |
|---|:--:|:--:|:--:|:--:|:--:|:--:|---|:--:|
| **i2p** | 5 | 5 | 5 | 5 | 5 | **100** | **award-tier** | 62–71 |
| **sentinel** | 5 | 4 | 5 | 5 | 5 | **~96** | **award-tier** | 62–71 |
| **atelier** | 5 | 5 | 5 | 4 | 5 | **~96** | **strong** (brushing award) | 62–71 |
| **concierge** | 5 | 5 | 4 | 4 | 5 | **~92** | **strong** | 62–71 |
| **mission-control** | 5 | 5 | 3 | 3 | 4 | **~81** | **competent-but-generated** | 62–71 |

**Clear "strong" (≥85) or "award-tier" (≥95): i2p, sentinel, atelier, concierge (4 of 5).**
**Still competent-but-generated: mission-control (1 of 5).**

## Lift paths (the concrete craft change to the next tier)

- **mission-control → strong/award (the one that must move).** Two changes, in order of impact:
  1. **Install a focal hierarchy.** Right now every screen is the same brightness. *Reframe* so ONE element
     dominates — e.g. push the **ceiling globe** as the single bright hero (raise its key, dim the console-ring
     screens ~30–40% via prompt weighting / a darkened LoRA pass on the monitor field) so the eye lands first
     on the globe, then reads the ring as support (*focal hierarchy §1, cf. one warm anchor vs a desaturated
     mass, Horizon env art*). This single move is what separates it from i2p.
  2. **Motivate the light.** Add a directional key — a warm cove-light raking from screen-left, or god-rays from
     the ceiling globe down into the pit — so the room is *sculpted* rather than evenly CRT-lit (*three-point /
     motivated light §2, cf. Storaro's amber key vs blue shadow*).
  3. **Kill the amber pseudo-text panel.** Either inpaint it to an abstract waveform like its neighbours, or
     re-roll with a stronger negative on "text, ui, hud, table, readout" so no surface striates into rows.
  4. Cheapest experiment first: a **different seed** on the same prompt-with-added-focal-weighting often resolves
     both the wandering eye and the sheen.

- **atelier → award-tier.** Resolve the **split focal point**. Let the **easel blueprint be the single hero**:
  dim the right-hand lamp (or warm it down / move it further out of frame) so the left lamp + easel form one
  dominant reading, the right lamp a quiet rim. A modest **depth-of-field** pass (sharp easel, softened
  background shelving) would also concentrate the eye (*focal hierarchy §1*). It is one prompt/relight tweak away.

- **concierge → award-tier.** Trade even four-sconce fill for a **raking key**: dim two sconces and let one warm
  source rake across the panelling so the doorway is *modelled* with a clear light/shadow gradient (*motivated
  directional key §2, cf. Leibovitz / Barry Lyndon candlelight*). Break the near-symmetry by **shifting the
  doorway off the third-line** so it sits on a rule-of-thirds node rather than dead-centre (*§1, cf. Shinkai*).
  Both are prompt/seed-level, not pipeline.

- **sentinel → ceiling.** Already award-tier; the only further gain is a **narrative stake** — a faint ship,
  buoy or rock the beam *picks out* — to turn "a lighthouse glowing" into "a lighthouse warning *something*"
  (*the decisive moment / implied story §4, cf. the threshold implying a life, The Searchers*). Optional.

- **i2p → none.** It is the calibration exemplar of this batch.

## Before/after verdict

> **PASS.**

The new heroes **clearly and decisively beat the old 62–71**. Four of five clear **strong (≥85)** — two of those
are **award-tier** — versus an old set that was uniformly competent-but-generated. The pipeline (dark-key LoRA
stack + latent hires-fix + art-directed prompts) is doing exactly what it should: real focal points, motivated
in-world light, disciplined colour scripts, genuine dark-key value structure, and — critically — **abstract,
text-free surfaces on the categories that invite baked text** (atelier blueprints, i2p inlay, mission-control
screens). **No hard artifact-floor failure on any hero; no legible or gibberish baked text anywhere.**

The single laggard, **mission-control**, is still competent-but-generated (no focal hierarchy, even glow, one
pseudo-tabular amber panel) — but it is *top of that band* and has a clear, cheap lift path (a focal-weighted
re-roll + relight + inpaint the one panel). It does not block the gate; it is a follow-up.

**Light is green, trap is clean** — the before/after holds; this is a successful, non-inflated improvement, with
mission-control flagged for one more pass.
