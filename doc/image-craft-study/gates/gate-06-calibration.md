# Gate 06 — Rubric calibration test

> **The proof that the "too lenient" problem is fixed.** The OLD image-aesthetic reviewer
> scored five entry-level generated heroes at **>95** under a rubric that rewarded *clean +
> on-prompt* as if that were award-tier. The rubric was rewritten
> ([`image-aesthetic-canon.md`](../../../plugins/pressroom/skills/design-reviewer/references/image-aesthetic-canon.md))
> so that **3 = competent-but-generated is a TRAP that caps the overall** out of the top band.
> This gate re-scores the same five heroes under the NEW rubric — and adds a sixth, art-directed
> regeneration of hero #1 as a contrast anchor — to confirm the bar demonstrably **rose** and is
> **calibrated** (rewards real craft), not merely **harsh** (punishes everything).
>
> Grounded in ATELIER's named canon
> ([`art-direction.md`](../../../plugins/atelier/knowledge/canon/art-direction.md)) — every
> finding cites a principle **and** a named exemplar, as the canon requires.

---

## THE CALIBRATION ASSERTION (verdict first)

- **Do the 5 OLD heroes now land BELOW the award-tier bar?** **YES.** All five score in the
  **62–71** band ("competent-but-generated"). None reaches award-tier; none even reaches the
  90s that the old rubric handed them. Every one trips ≥2 of the named entry-level tells, so the
  "Composition & art-direction" dimension is capped ≤3, which (by §3-trap design) caps the overall.
- **Does the NEW candidate (#6) score clearly HIGHER than old #1 (same subject)?** **YES.**
  #6 scores **88 (strong)** vs old #1's **68 (competent-but-generated)** — a **+20** lift on the
  identical subject, earned by a real focal hierarchy, a motivated colour script, and a deliberate
  leading-line composition. The rubric **rewards the craft delta**, so it is calibrated, not harsh.
- **One-line verdict:** **PASS** — the bar demonstrably rose (every old hero now fails award-tier,
  dropping from >95 into the 60s–70s) **and** the new craft scores clearly higher (#6 = 88 vs #1 = 68),
  proving the upgrade raised the bar without flattening genuine improvement.

### Scoreboard

| # | Image | Cat-fit /5 | Prompt /5 | Artifact /5 | Comp&Art-dir /5 | Doc/dark /5 | **Overall /100** | Verdict |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| 1 | i2p `hero.png` (portal/gateway) | 4 | 4 | 4 | **3** | 4 | **68** | competent-but-generated |
| 2 | sentinel `hero.png` (lighthouse) | 4 | 4 | 4 | **3** | 4 | **68** | competent-but-generated |
| 3 | atelier `hero.png` (studio) | 4 | 3 | 3 | **3** | 4 | **62** | competent-but-generated |
| 4 | concierge `hero.png` (doorway) | 4 | 4 | 4 | **3** | 5 | **71** | competent-but-generated |
| 5 | mission-control `hero.png` (ops room) | 4 | 4 | 3 | **3** | 4 | **65** | competent-but-generated |
| 6 | **i2p-premium-test** (art-directed #1) | 5 | 5 | 4 | **4** | 4 | **88** | **strong** |

> **Old vs new on the same subject:** #1 = **68** → #6 = **88** (**+20**). Bar rose for the weak
> ones; reward landed for the strong one. Calibrated.

*Weighting: Cat-fit ×24, Prompt ×22, Artifact ×22, Comp&Art-dir ×18, Doc/dark ×14 — each dim
score/5 × its weight, summed to /100.*

---

## How the cap works (why "clean + on-prompt" no longer buys a 95)

Under the NEW canon, **Composition & art-direction is the named-taste dimension** and an image
that trips **two or more** entry-level tells (no focal point · flat light · muddy/garish colour ·
cliché framing · AI sheen) is **capped ≤3** on that dimension — and a 3 there is the
*competent-but-generated trap* that, by design, holds the overall out of the top band. Each of the
five old heroes is genuinely *clean* and *on-prompt* (which is why the old rubric mistook them for
95-tier), but each fails the named composition tells, so each lands in the 60s–70s. **That is the
exact lenience this canon was rewritten to forbid** — and the re-score confirms it now bites.

---

## Per-image findings (principle + named exemplar + fix)

### 1 — i2p `hero.png` · weighted **68** · competent-but-generated

A teal-and-gold mystic gateway: two stone pillars, a glowing arch, a vertical golden light-rail,
star-field backdrop, wet floor reflection.

- **Cat-fit 4** — unmistakably a "portal/gateway hero", rendered cleanly of its kind.
- **Prompt-adherence 4** — arch, threshold, light, depth all present and integrated.
- **Artifact-freedom 4** — geometry coherent; arch and pillars hold; mild softness in the
  background masonry, nothing broken. No baked text (correct for a hero).
- **Composition & art-direction 3 (CAPPED)** — trips **two** named tells:
  - **No strong focal hierarchy / dead-centre bullseye** — the arch is parked symmetrically in the
    middle with the eye landing nowhere decisively (cliché composition §1, *Focal hierarchy*).
    *Fix:* push the structure onto a third-node so the gaze is *led*, not centred —
    cf. **Shinkai's small-figure-on-a-third against vast sky** (*Your Name*).
  - **Even, ambient teal glow rather than a motivated key** — the scene is lit by a flat
    everywhere-glow with no single sculpting source (flat light §2, *Three-point logic*).
    *Fix:* a directional key + rim to model the pillars — cf. **Leibovitz's soft key + gentle fill**.
- **Doc/dark-mode 4** — dark ground, restrained, sits well on a dark page; cleanly embeddable.

### 2 — sentinel `hero.png` · weighted **68** · competent-but-generated

A lone lighthouse on a dark headland over a bioluminescent teal shoreline; deep night sky.

- **Cat-fit 4** — clearly a "watchtower/sentinel" hero; the lighthouse-as-guardian reads instantly.
- **Prompt-adherence 4** — beacon, vigilance, dark sea, glow all present.
- **Artifact-freedom 4** — clean silhouette and coastline; the lighthouse holds; no melt or gibberish.
- **Composition & art-direction 3 (CAPPED)** — trips **two** tells:
  - **Muddy mid-tone value soup** — the foreground/headland is a near-uniform dark mush with no
    value plan separating planes (muddy colour §3 / weak notan §2, *Value structure & notan*).
    *Fix:* a deliberate light/dark notan — cf. **Ansel Adams' Zone-System tonal control**.
  - **Atmosphere present but no decisive focal beam** — the lighthouse glow is a soft sticker, not a
    motivated, scattering source (flat light §2, *Volumetric / god-rays*). *Fix:* let the beam
    rake through haze — cf. **Storaro's smoke-shafted light** (*Apocalypse Now*).
- **Doc/dark-mode 4** — genuinely dark, restrained, embeddable; among the better-behaved heroes here.

### 3 — atelier `hero.png` · weighted **62** · competent-but-generated (lowest)

A dim design studio: a glowing drafting table centre, two wireframe-render screens flanking on the
walls, lamps, wood-panelled room.

- **Cat-fit 4** — reads as a "design/atelier studio" hero.
- **Prompt-adherence 3** — the gist (studio, screens, drafting table) is there but the
  wireframe content on the screens is **vague filler**, not integrated meaningful imagery.
- **Artifact-freedom 3** — the wall screens carry **soft, incoherent "render" smear** (the
  near-baked-graphic tell); the drafting-table geometry is a little loose. Minor, not a hard cap,
  but the busiest-failing of the set.
- **Composition & art-direction 3 (CAPPED)** — trips **three** tells:
  - **No focal hierarchy** — three competing bright zones (table + two screens) split attention; the
    eye wanders (no focal point §1, *Focal hierarchy & focal point*). *Fix:* commit to one anchor —
    cf. **Horizon environment art's single warm sunlit anchor against a desaturated mass**.
  - **Flat, even interior fill** — ambient teal wash, no structured key/rim modelling the room
    (flat light §2). *Fix:* chiaroscuro from the table-glow as the motivated source — cf.
    **Caravaggio's tenebrism**, the named engine.
  - **Symmetry by neglect** — the layout is lopsided-but-balanced by accident, not designed
    (*Balance* §1). *Fix:* deliberate asymmetric weight — cf. **Hokusai's off-centre void**.
- **Doc/dark-mode 4** — dark and restrained; embeddable.

### 4 — concierge `hero.png` · weighted **71** · competent-but-generated (highest of the five)

A warm-lit arched doorway at the end of a cozy hall: hanging lantern, side table with a plant, a
wall sconce, wood floor — a "welcome / threshold" scene.

- **Cat-fit 4** — perfectly on-category for a *greeter/concierge* hero (the threshold doorway).
- **Prompt-adherence 4** — doorway, warm welcome, hearth-light, inviting depth all present.
- **Artifact-freedom 4** — clean architecture; the arch, door, and furniture hold; coherent perspective.
- **Composition & art-direction 3 (CAPPED)** — the **best-composed** of the five (it has a genuine
  warm motivated lantern key and a real frame-within-frame doorway), but still trips **two** tells:
  - **Dead-centre bullseye** — the door sits exactly on the central axis with the hall funneling
    symmetrically; competent but inert (cliché composition §1, *Rule of thirds* broken). *Fix:*
    off-axis the threshold — cf. **the closing-doorway frame** of *The Searchers* used asymmetrically.
  - **Mild generic "AI sheen"** — surfaces read slightly plastic/over-smooth rather than a believable
    lived-in medium (§5, *Genre believability*). *Fix:* material grit — cf. **a lived-in cantina**.
  - *Credit where due:* the motivated lantern key (cf. ***Barry Lyndon*** candlelight-only) is
    exactly the kind of choice that lifts it to the top of the band — but two tells still cap it at 3.
- **Doc/dark-mode 5** — the warm key is local and the ground is dark; restrained, embeddable, the
  cleanest dark-page citizen of the set.

### 5 — mission-control `hero.png` · weighted **65** · competent-but-generated

A circular ops/situation room: a domed world-map screen overhead, a ring of empty chairs, wraparound
wave-form monitors, a small glowing globe centre.

- **Cat-fit 4** — clearly a "mission-control / operations" hero.
- **Prompt-adherence 4** — command room, world map, monitors, central focus all present.
- **Artifact-freedom 3** — the wraparound screens carry **soft waveform smear** and the chair ring
  has mild geometric looseness (the near-baked-UI tell); coherent overall but not crisp.
- **Composition & art-direction 3 (CAPPED)** — trips **two** tells:
  - **Radial-symmetry bullseye** — everything rings a dead-centre point; formally tidy but with no
    leading line *in* and no tension (cliché composition §1, *Balance* by formula). *Fix:* break the
    ring with an off-axis read — cf. **Cassandre's axial monolith used with intent**, not as default.
  - **Flat even teal fill** — the whole room is bathed in one ambient temperature, no warm/cool
    split to model depth (flat light §2 / one-temperature colour §3, *Temperature contrast*). *Fix:*
    warm practicals against cool shadow — cf. **Storaro's amber key vs blue-black shadow**.
- **Doc/dark-mode 4** — dark, restrained, embeddable.

### 6 — i2p-premium-test (art-directed regeneration of #1) · weighted **88** · **STRONG**

The **contrast anchor**: the *same* portal/gateway subject as #1, regenerated dark-key with a
LoRA + latent-hires pass. Compare directly to #1's **68**.

- **Cat-fit 5** — the same category as #1, but rendered **excellently of its kind**: an ornate
  golden ring-gate over a deep teal nebula, jeweled arch, radiant keystone sun, a glowing causeway.
- **Prompt-adherence 5** — every gateway element present **and integrated** (arch, threshold,
  light-source, path, depth) — not pasted, composed.
- **Artifact-freedom 4** — clean ring geometry, coherent perspective on the causeway and rock
  banks; very minor softness in the densest filigree, nothing broken. No baked text.
- **Composition & art-direction 4 (the lift)** — clears the tells that capped #1:
  - **Real focal hierarchy** — the radiant keystone reads **first**, the ring frames it, the
    causeway supports — a genuine dominant subject (*Focal hierarchy* §1, cf. **Horizon's warm
    anchor against a desaturated mass**). #1 had no such anchor.
  - **Motivated, structured light** — the keystone is the in-world key; light **scatters down the
    nebula** as volumetric shafts (*Volumetric / god-rays* §2, cf. **Storaro's smoke-shafted
    light**). #1 had only an even ambient glow.
  - **Disciplined colour script** — a committed **complementary teal-vs-gold** with the gold as the
    single hot accent (*Limited / dominant palette* §3, cf. **Frazetta's earthy field + one hot
    accent**). #1 was a flatter teal wash.
  - **Leading lines** — the causeway light-trail and the ring's converging filigree route the eye
    to the gate (*Leading lines* §1, cf. **Dylan Cole's architecture funneling to the citadel**).
  - *Why 4 not 5:* still slightly centred (an off-third placement would be more *inevitable*), and a
    faint over-rendered gloss keeps it from a flawless §5 — one named virtue could be sharper.
- **Doc/dark-mode 4** — dark-key, embeddable; marginally brighter/busier than the restrained heroes,
  but still a clean dark-page citizen.

**The delta that proves calibration:** identical subject, **+20 points** (68 → 88), every point
earned by a *nameable* craft fix to a *named* tell that #1 exhibited. A merely-harsh rubric would
have dragged #6 down with the rest; instead it lifts #6 into **strong** while holding #1 at
competent-but-generated. **That is calibration.**

---

## Verdict

**PASS.** The rubric upgrade is proven:

1. **The bar rose** — the five old heroes that scored **>95** under the lenient rubric now score
   **62–71**, all **below the award-tier bar**, all reading as *competent-but-generated*. None
   slipped through as award-tier; the "clean + on-prompt = 95" lenience is closed.
2. **The reward still lands** — the art-directed regeneration of hero #1 scores **88 (strong)** vs
   #1's **68**, a **+20** lift on the same subject, every point traceable to a named craft fix.

The rubric is **harsher where harshness was earned** and **generous where craft was real**:
calibrated, not merely strict. The "too lenient" complaint is fixed.

*Light is green, trap is clean.*
