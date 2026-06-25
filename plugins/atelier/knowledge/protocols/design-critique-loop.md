# The convergent design-critique loop — improve, don't ping-pong

> The one-copy home for **how ATELIER's designer and reviewer iterate so the design genuinely improves**
> and the loop *terminates*. A critique that sends the maker in circles is the most expensive waste there
> is. This protocol turns "back-and-forth" into **measured convergence**, modelled on the marketplace's
> writer↔reviewer loop, the perf-delta gate, and the KAIZEN *halve-the-distance* covenant.

## The design-fitness rubric (the fitness function)

The reviewer scores the artefact (a mockup, a screen, a crawled route) on weighted dimensions, each tied
to the [`canon/`](../canon/README.md). Each dimension scores **0–5**; the weighted total is the
**fitness score** (0–100). Accessibility is a **gate**, not just a weight.

| Dimension | Weight | Canon lens | 5 = exemplary | 0–1 = broken |
|---|---:|---|---|---|
| **Hierarchy & focus** | 18 | visual-foundations §2 | one clear focal point; the eye is guided | competing primaries; no order |
| **Layout, grid & spacing** | 15 | visual-foundations §1,§5 | aligned, rhythmic, grouped (Gestalt) | ragged, arbitrary spacing |
| **Typography** | 12 | visual-foundations §4 | modular scale, right measure/leading | font-soup, bad measure |
| **Colour & contrast** | 12 | visual-foundations §3 | disciplined palette; accent earns attention | muddy/garish; colour-only signals |
| **Usability (heuristics + laws)** | 18 | interaction-laws §1,§2 | Nielsen-clean; laws respected | hidden affordances; Hick/Fitts failures |
| **Consistency** | 10 | interaction-laws §2.4 | tokens & patterns coherent; Jakob's Law | one-off styles; convention breaks |
| **Accessibility (GATE)** | 10 | accessibility.md | WCAG 2.2 AA clean | **any AA failure ⇒ cannot PASS** |
| **Delight** | 5 | interaction-laws §3 · [`art-direction.md`](../canon/art-direction.md) | a purposeful, harm-free moment grounded in named art-direction (composition/light/colour) | none / gratuitous, harmful, or "AI sheen" |

> **Findings, prioritised** (like `pr-review`): every gap is **HIGH / MED / LOW**, each naming **(a)** the
> canon principle, **(b)** the violation, **(c)** the user cost, **(d)** the concrete fix, **(e)** the
> rubric dimension it scores. A WCAG-AA failure is always at least HIGH **and** trips the accessibility
> gate.

> **Pictorial / image artefacts (not screens).** When the artefact is a generated or pictorial image (hero
> art, concept, illustration), the **AESTHETICS-REVIEWER** lens scores it against the full
> [`art-direction.md`](../canon/art-direction.md) canon (composition · light · colour · narrative ·
> style/medium · the **award bar**), with the **artifact floor** as a hard cap (mangled anatomy / gibberish
> text / melted geometry / broken perspective ⇒ cannot PASS, regardless of polish). The accessibility *gate*
> is replaced by the artifact floor + the image's alt-text / dual-ground legibility where it embeds. For
> award-tier pictorial work the **TARGET is raised** (the bar is "publication/gallery-ready", not merely
> "acceptable") — "competent but clearly generated" is a finding, not a pass. The **RICHNESS-MOTION-REVIEWER**
> lens (canon §8 medium-reach + §9 motion) co-scores: a flat single-layer image where a blend/depth would
> serve, or motion that's gratuitous rather than motivated, is *"too simple / entry-level"* — also a finding,
> not a pass. Animated artefacts are reviewed from a **frame-strip** and must ship a reduced-motion poster.

## The loop (bounded, measurable, terminating)

```
   make / render  ──▶  REVIEW (score + prioritised findings)  ──▶  converged?
        ▲                                                            │ no
        └──────────  apply HIGH+MED fixes (re-render)  ◀─────────────┘
```

1. **Baseline.** The reviewer scores the first artefact → `score₀` + findings. Record it.
2. **Apply.** The designer applies **every HIGH and every MED** finding (not a vague "improve it") and
   re-renders. LOW/SUGGESTION are applied if cheap, else recorded.
3. **Re-score.** The reviewer re-scores → `scoreₙ`. Compute `Δ = scoreₙ − scoreₙ₋₁`.
4. **Stop** when **any** holds:
   - **CONVERGED** — no HIGH findings, the accessibility gate is clear, **and** `scoreₙ ≥ TARGET`
     (default **85/100**; the user may raise it).
   - **DIMINISHING RETURNS** — `Δ < DELTA_FLOOR` (default **+3 points**) for a turn that still has open
     findings: the loop is no longer earning its tokens. **Halt and surface the impasse** — name what
     remains and why it resists, and ask the user for a decision (accept, change direction, or relax a
     constraint). Do **not** take another lap.
   - **CAP** — `MAX_TURNS` reached (default **4**, baseline + 3 — matching the writer↔reviewer ceiling).
5. **Report, never silent.** On stop, state the final score, the turn-by-turn trajectory, the
   **residual** (open findings, each marked *accepted* / *deferred* / *blocked*), and — if the gate is
   tripped — that the artefact is **not shippable** until it clears.

## The anti-ping-pong guarantees

- **Every turn must measurably improve** (`Δ > 0`). A turn that doesn't raise the score halts the loop —
  the reviewer's job is to *converge the maker*, not to relitigate taste. If the reviewer cannot articulate
  a fix that would raise the score, that is a reviewer failure, recorded for `self-improve`.
- **No moving goalposts.** The rubric is fixed for the duration of a loop; a reviewer may not invent a new
  dimension mid-loop to keep failing the design. New canon lands via `self-improve` → PR, not mid-critique.
- **Specific, applicable fixes only.** "Make it cleaner" is not a finding. "Increase the card gap from 6px
  to 16px (8-pt scale) so the Gestalt proximity groups by section" is.
- **Scope the residual honestly.** A design that stalls below TARGET is *reported as such* with its score
  — never quietly presented as finished, never endlessly re-spun.

## Reuse across the marketplace

This protocol defines the **shape** the marketplace's design loops share (by concept, not by path):
**publish**'s print/DTP & data-viz reviewer adopts the same fitness-function shape and stop conditions
with different rubric dimensions (typography/grid for print; Tufte/Cleveland/Bertin for charts). When
**IDEATE** asks ATELIER to produce a user-flow or mockup
for the IDEA dossier, this loop runs first — so the user sees **carefully-composed, design-reviewed**
material, not a first draft. A recurring stall-class feeds `self-improve` (a sharper canon rule or a
re-weighted dimension), so the loop converges faster next time.
