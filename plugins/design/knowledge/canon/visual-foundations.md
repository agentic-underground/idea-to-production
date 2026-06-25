# Visual foundations — Gestalt · hierarchy · colour · type · grid

> The perceptual layer: how the eye *groups, ranks, and reads* marks on a screen before any conscious
> thought. Most "it looks off / cluttered / amateur" reactions are a named violation here. Cite the name.

## 1. Gestalt principles (how perception groups marks)

Established by Gestalt psychologists (early 20th c.); the substrate of all layout. The eye applies these
*pre-attentively* — fighting them is why a screen feels wrong.

| Principle | The rule | Common violation to flag |
|---|---|---|
| **Proximity** | Elements placed near each other are read as a group. | Related controls spread apart; a label nearer the *wrong* field; uniform spacing that groups nothing. |
| **Similarity** | Elements sharing colour/shape/size read as related. | Two unrelated things styled alike; one item in a set styled differently with no semantic reason. |
| **Common region** | A shared enclosure (card, panel, border) groups its contents. | Cards that bleed together; a divider that splits a true group. |
| **Continuity** | The eye follows lines/curves and aligned edges. | Broken alignment; a column whose items don't share an edge. |
| **Closure** | The mind completes implied shapes. | Over-drawing borders the eye would have inferred (chartjunk for UI). |
| **Figure/ground** | We separate foreground from background. | Insufficient contrast between a modal and its scrim; foreground that competes with its surface. |
| **Common fate** | Things that move/change together are grouped. | Animations that imply a relationship that doesn't exist. |

> **Rule of thumb:** *whitespace groups more honestly than borders.* Reach for proximity and common
> region before adding lines. Every border is a claim — make sure it's true.

## 2. Visual hierarchy (guiding the eye on purpose)

Hierarchy is the arrangement of elements to communicate **order of importance** — where to look first,
next, and what to ignore. Built from a small set of contrasts:

- **Scale** — size signals importance. One dominant element per view; a clear primary/secondary/tertiary
  tier. *Flag:* everything the same size = nothing is important.
- **Weight & contrast** — heavier/darker/more-saturated draws first. *Flag:* a secondary action louder
  than the primary; competing focal points.
- **Position & reading path** — the eye enters top-left in LTR scripts and scans in **F** (text-dense) or
  **Z** (sparse/landing) patterns. Put the most important thing on the path, not in a dead zone.
- **Whitespace (negative space)** — space *is* a design element; it creates emphasis and rhythm. *Flag:*
  cramped density that raises cognitive load; or formless space that fails to group.
- **Single focal point** — each view earns *one* primary focus. Two primaries = none.

> The **Von Restorff (isolation) effect**: the item that differs is remembered. Spend that contrast on the
> one thing that matters most; spending it everywhere spends it nowhere.

## 3. Colour

- **Roles, not decoration.** A disciplined palette: one or two brand/accent hues, a neutral ramp
  (background→surface→border→text), and semantic colours (success/warn/error/info). Accent earns
  attention precisely *because* it is rare.
- **60-30-10** as a starting balance (dominant neutral / secondary / accent). Adjust with reason.
- **Contrast is accessibility, not taste** — see [`accessibility.md`](accessibility.md) (WCAG 2.2: text
  ≥4.5:1, large/UI ≥3:1). Never signal by colour alone (add text/icon/shape) — colour-blind users and
  the Ishihara minority must get the message too.
- **Dark-mode as a first-class theme**, not an inversion: re-tune surfaces and reduce pure-white text on
  pure-black (use near-blacks/near-whites to cut halation).

## 4. Typography (on screen)

- **Type scale** — a **modular scale** (a fixed ratio, e.g. 1.25 *major third* or 1.5 *perfect fifth*)
  produces harmonious sizes; ad-hoc sizes read as amateur. 4–6 steps is plenty.
- **Measure** — line length ~45–75 characters for body text; longer tires the eye, shorter fractures
  rhythm.
- **Leading (line-height)** — body ~1.4–1.6× size; tighter for large display, looser for dense data.
- **Hierarchy via type** — distinguish levels by size/weight/colour/space, not font-soup. Two families
  max (e.g. one display, one text); pair by contrast, not similarity.
- **Alignment** — left-align body in LTR; avoid justified text on screen (rivers, uneven gaps). Numerals
  in tables: tabular figures, right-aligned.

## 5. Grid, spacing & rhythm

- **Spacing scale** — a consistent unit (commonly an **8-pt** grid, 4-pt for fine control). Every margin,
  padding, and gap is a multiple. *Flag:* arbitrary 13px/17px spacings — they read as noise.
- **Alignment & a grid** — columns and a shared baseline create the calm that signals competence. Things
  that relate, align. *Flag:* ragged left edges, controls that almost-but-not-quite line up.
- **Balance** — symmetric (formal, stable) or asymmetric (dynamic, modern) — but *deliberate*. Weight
  distributed, not pooled in one corner.
- **Density** — moderate by default; offer a comfortable/compact toggle for data-dense surfaces (respect
  the cognitive-load budget in [`interaction-laws.md`](interaction-laws.md)).

---

> **Sources (the canon to cite):** Gestalt school (Wertheimer/Koffka/Köhler); Nielsen Norman Group on
> visual hierarchy & Gestalt; the 60-30-10 and modular-scale traditions; Bringhurst's measure/leading
> guidance (deep print treatment lives in publish's typography canon). When you cite, name the
> principle — *"proximity"*, *"modular scale"*, *"Von Restorff"* — so the fix is teachable and the loop
> can verify it.
