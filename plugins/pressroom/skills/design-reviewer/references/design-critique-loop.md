# The convergent design-critique loop (print & data-viz) — improve, don't ping-pong

> How PRESSROOM's producer and design-reviewer iterate so the artefact **measurably improves** and the loop
> *terminates*. Same shape as the marketplace's other design loops (carried by concept, not by path — see
> the ATELIER protocol it mirrors); different rubric — typography and data-viz, not screen UI. Modelled on
> WRITER's max-3-turn prose loop, the perf-delta gate, and the SOLID *halve-the-distance* covenant.

## Cost discipline — vision is expensive

Governs **every** graphical review lens, not just layout. Machine vision — a pixel Read of a render — is the
**expensive** action; the cheap deterministic checks come **first**. Run the free machine tiers up front (the
layout machine `layout-check.sh` + `raster-lint.sh`), and spend a vision Read **only when something cheap has
already flagged a suspect**: *vision on suspicion, never by default.* The cost-tier doctrine is specified for
layout — with its worked tier order — in [`layout-canon.md`](layout-canon.md) §3; the **same discipline binds
any reviewer that would otherwise Read pixels by default** (aesthetic, typographic, motion). A reviewer that
opens vision on every artefact has spent the budget the free tiers exist to protect.

## The design-fitness rubric (the fitness function)

The reviewer scores the rendered artefact on weighted dimensions, each tied to the canon
([`typography-canon.md`](typography-canon.md), [`dataviz-canon.md`](dataviz-canon.md)). Each scores **0–5**;
the weighted total is the **fitness score** (0–100). **Honesty** (no misleading chart), **legibility at
target size**, and **document accessibility** (PDF/UA + WCAG 2.2 — a document everyone can read) are
*gates*, not mere weights.

| Dimension | Weight | Canon | 5 = exemplary | 0–1 = broken |
|---|---:|---|---|---|
| **Legibility (GATE)** | 12 | charting-matrix | readable at print/target size | micro-text, overflow |
| **Measure & leading** | 12 | typography §1 | 45–75 cpl, rhythmic leading | long/cramped, greyed page |
| **Hierarchy & scale** | 12 | typography §1 | modular scale, clear levels | font-soup, flat |
| **Grid & baseline** | 10 | typography §2 | aligned, on baseline | ragged, off-rhythm |
| **Page composition** | 10 | typography §3 | balanced figures, no widows/orphans, clean breaks | stranded lines, overflowing tables |
| **Accessibility (GATE)** | 10 | typography §4 | tagged, logical reading order, body contrast ≥ 4.5:1, alt text, title/lang set | untagged image-of-text, low contrast, no alt text |
| **Encoding fit (charts)** | 16 | dataviz §1–2 | high-accuracy channel for the key quantity | pie/3-D/area where bars belong |
| **Data integrity (GATE)** | 12 | dataviz §3 | lie factor ≈1, zero baseline, honest axes | truncated/exaggerated → misleads |
| **Colour** | 8 | dataviz §4 | colour-blind-safe, ordered ramps, restrained | rainbow for ordered, colour-only |
| **Data-ink / restraint** | 8 | dataviz §3 | chartjunk removed, high data-ink | gridlines/3-D/decoration |

> Documents with no charts skip the chart dimensions (re-normalise the weights over what applies);
> standalone charts skip the page dimensions. Score what the artefact contains.
>
> **Findings, prioritised** (pr-review model): each is **HIGH / MED / LOW**, naming **(a)** the principle,
> **(b)** the violation, **(c)** the reader cost, **(d)** the concrete *source* fix (`.typ`/`.tex`/`.dot`/
> `.mmd`), **(e)** the rubric dimension. A gate failure (misleading chart, illegible figure, inaccessible
> document) is always at least HIGH and blocks PASS.

## The loop (bounded, measurable, terminating)

```
   build / render  ──▶  REVIEW (score + prioritised findings)  ──▶  converged?
        ▲                                                            │ no
        └────────  apply HIGH+MED source fixes (re-build)  ◀─────────┘
```

1. **Baseline.** Reviewer scores the first build → `score₀` + findings. Record it.
2. **Apply.** The producer applies **every HIGH and MED** finding as a concrete source change and re-builds.
3. **Re-score.** `scoreₙ`; `Δ = scoreₙ − scoreₙ₋₁`.
4. **Stop** when **any** holds:
   - **CONVERGED** — no HIGH, all gates clear (honesty, legibility, accessibility), **and** `scoreₙ ≥ TARGET` (default **85/100**).
   - **DIMINISHING RETURNS** — `Δ < DELTA_FLOOR` (default **+3**) with findings still open: the loop is no
     longer earning its tokens. **Halt, surface the impasse**, ask the user (accept / change approach /
     relax a constraint). Do not take another lap.
   - **CAP** — `MAX_TURNS` reached (default **4** = baseline + 3, matching WRITER's prose loop).
5. **Report, never silent.** Final score, turn-by-turn trajectory, and the **residual** (each open finding
   *accepted* / *deferred* / *blocked*). A gate left tripped ⇒ the artefact is **not publishable** until cleared.

## Anti-ping-pong guarantees

- **Every turn must measurably improve** (`Δ > 0`); a flat turn halts the loop — the reviewer converges the
  producer, it doesn't relitigate taste.
- **No moving goalposts** — the rubric is fixed for a loop; new canon lands via the shared self-improvement
  protocol (a charting-matrix rule, a re-weight), not mid-critique.
- **Specific source fixes only** — "make the figure better" is not a finding; "set the bar baseline to 0 and
  sort descending; drop the 3-D" is.
- **Honesty and legibility are gates** — never traded for polish, never quietly waived.

> A recurring stall-class (e.g. pies keep recurring, tables keep overflowing) feeds
> [`../../rich-pdf-with-diagrams/references/self-improvement.md`](../../rich-pdf-with-diagrams/references/self-improvement.md)
> so the *producers* stop making it — the loop converges faster next time, and the lesson improves every
> diagram surface (Graphviz, Mermaid, print) at once.
