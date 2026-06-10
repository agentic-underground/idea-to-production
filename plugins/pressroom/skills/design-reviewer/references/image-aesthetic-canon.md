# The image-aesthetic canon — judging generative raster output

> The third design lens, beside [`typography-canon.md`](typography-canon.md) (the page) and
> [`dataviz-canon.md`](dataviz-canon.md) (the chart). This one judges **generative raster images** — what a
> ComfyUI checkpoint produces — so the marketplace can choose models, and ship hero art, on **evidence and
> named taste, not vibes**. There is no "honesty" gate here — but there are **hard failure modes** (mangled
> anatomy, illegible intent) that cap a score regardless of polish, and an **award bar** below which an image
> is "competent but clearly generated," not shippable as best-in-class.

## The bar: award-tier, not "acceptable"

The single most important calibration. An image is scored against **award-winning reference work**, not
against "good enough for a doc." A clean, on-prompt, artifact-free image with no focal point, flat light,
and muddy colour is **not a high score** — it is the *entry-level trap*. Concretely:

- **5 = award-tier** — publication/gallery-ready; a decisive focal point, motivated structured light, a
  disciplined colour script, a felt mood, true to its style; every choice is *nameable*. Indistinguishable in
  intent from the corpus of award-winners.
- **4 = strong** — clearly intentional and well-crafted; one or two named virtues could be sharper.
- **3 = competent-but-generated** — the trap: polished surface, empty craft. On-prompt and clean but with a
  generic "AI sheen", no focal hierarchy, even/sourceless light, or default-render colour. **Caps the overall
  out of the top band** — a doc can use it, a portfolio cannot.
- **2 = weak** — a real aesthetic failure (no focal point AND flat light, or garish/muddy colour).
- **0–1 = broken** — see the hard caps.

A reviewer that hands a "3-tier" image a 90+ is **too lenient** and has failed; that is the exact failure this
canon exists to prevent.

## The five dimensions (each 0–5)

| Dim | Weight | 5 = award-tier | 3 = the trap | 0–1 = broken |
|---|---:|---|---|---|
| **Category-fit** | 24 | unmistakably the asked category, rendered *excellently of its kind* | recognisably the category but generic | wrong subject; unrecognisable |
| **Prompt-adherence** | 22 | every asked element present and *integrated*, not pasted | the gist is there, specifics vague | ignores the prompt; generic filler |
| **Artifact-freedom** | 22 | clean anatomy/geometry/text, coherent everywhere | minor softness, nothing broken | extra limbs, fused faces, melted hands, gibberish glyphs |
| **Composition & art-direction** | 18 | the named art-direction canon clears award-tier (focal hierarchy, motivated light, colour script, mood) | flat/centred/even/muddy — the entry-level tells | no focal point, garish or muddy, amateur |
| **Doc/dark-mode suitability** | 14 | restrained, embeddable, sits on a dark page; cleanly subjectable | usable but slightly busy/bright | garish, busy, hard-baked bright ground that fights a dark doc |

**Weighted total = the image-fitness score (0–100).** Score per image (or per contact-sheet cell), then report
the profile. **The "Composition & art-direction" dimension is the named-taste dimension** — it is NOT scored
by feel; it is scored against the art-direction canon (below).

## The art-direction grounding (named theory, by capability)

The "Composition & art-direction" dimension and the award bar are grounded in a **named art-direction canon**:
composition (focal hierarchy, leading lines, negative space, rule-of-thirds/φ, framing, balance, figure-ground),
light & shadow (key/fill/rim, chiaroscuro/tenebrism, golden/blue hour, volumetric, motivated sources,
value/notan), colour (harmony schemes, temperature contrast, limited palette, atmospheric perspective, the
colour script), narrative & mood (implied story, the decisive moment, gesture/line-of-action), and
style/medium fidelity (excellent *of its declared style*, not a pastiche or "AI sheen").

- **When ATELIER is installed** (graceful enhancement) — the reviewer loads ATELIER's
  `knowledge/canon/art-direction.md` (the full, exemplar-anchored canon and the entry-level-trap tells) and
  may compose ATELIER's `ui-design-reviewer` in its **AESTHETICS-REVIEWER** lens directly. This is the richer,
  authoritative review: every finding names the principle **and a concrete award-winning exemplar** that does
  it right (*"flat lighting — cf. Leibovitz's three-point key"*). Detect by capability (atelier's plugin root
  / canon file present); never hardcode a cross-plugin path — if absent, fall back cleanly to the baseline.
- **When ATELIER is absent** — use the **inline baseline** below. It is a compact subset sufficient to review
  competently; it keeps PRESSROOM fully self-contained.

### Inline baseline (used only when atelier is not present)

Score "Composition & art-direction" against these, in order — a failure of the first two is almost always why
an image feels "generated":

1. **Focal hierarchy** — one dominant subject reads first; the rest supports. *No focal point = the #1 generic
   tell* → cap this dimension ≤3.
2. **Light** — directional, motivated, structured (key/fill/rim or chiaroscuro). *Flat, even, sourceless "AI
   daylight" = a tell* → ≤3.
3. **Colour** — a disciplined relationship (complementary/analogous/limited palette + one accent) and a
   warm/cool temperature read. *Muddy mid-tone soup OR every-hue-maxed "clown-vomit" = a tell* → ≤3.
4. **Composition** — leading lines / negative space / deliberate framing; *dead-centre bullseye with no path
   in = cliché* → ≤3.
5. **Mood & style fidelity** — the image commits to one feeling and is excellent *of its declared style*; a
   generic plastic "AI sheen" or style-worn-as-costume is a tell.

An image that trips two or more of these tells is **competent-but-generated (3-tier)** at best on this
dimension, however clean and on-prompt — that is the lenience this canon forbids.

## Hard caps (no amount of polish overrides)

- **Mangled human anatomy** (extra/missing limbs, fused or distorted faces, broken hands) where people are
  central caps that image at **≤ 2** — a beautiful-but-deformed result is unusable.
- **Category miss** (not recognisably the asked category) caps **prompt-adherence ≤ 1**.
- **Illegible "text" attempt** — if the category invites text/labels and the model bakes gibberish glyphs,
  note it explicitly: the signal that this model/base must **not** be routed that category (the vector
  handlers own it). For doc heroes, *any* baked pseudo-text is an artifact-freedom failure (heroes are
  text-free by construction).
- **Melted geometry / broken perspective** (duplicated/fused/dissolved forms; impossible vanishing) caps
  **artifact-freedom 0–1**.

## The per-image / per-model profile (what review extracts)

For a single image: the five scores, the weighted total, the **named** aesthetic findings (principle +
exemplar + fix), and an explicit award-tier verdict (award-tier / strong / competent-but-generated / broken).
For a model's contact-sheet, additionally:
- **best-for** — the 1–2 categories it scores ≥ 4 on (its sweet spot).
- **avoid-for** — categories it scores ≤ 2 on.
- **base trait** — recurring base-level truths (e.g. *SD1.5 cannot render legible chart text*; *this model bakes
  flat frontal light*; *lightning trades micro-detail for ~3× speed*).
- **lift path** — the concrete craft change that would raise it (e.g. *"+ a latent-upscale re-detail pass
  would lift artifact-freedom and micro-detail"*; *"a low-key LoRA would fix the flat light"*) — trajectory
  guidance, not just a snapshot.

## Stance

Adversarial and concrete, like the other lenses: name the failure ("melted left hand; third arm on the seated
figure"; "no focal point — the eye wanders"; "flat frontal light — cf. a motivated key in the corpus"), never
"looks off". A model/image earns a high score against the **award bar**; it is not given one for being pretty
in the easy categories while failing the hard one, nor for being clean-but-generic. When you cannot name a fix
that would raise the score, that is a **reviewer failure** — record it for self-improvement (a sharper canon
rule), so the next review converges.
