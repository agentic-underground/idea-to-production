# Site ranking — where a figure earns its place (and where it doesn't)

> The ILLUSTRATOR's first and most important judgement: of all the places a figure *could* go, which few
> *should* get one. The doc tree is ~383 files; illustrating everything is noise, cost, and clutter. This
> rubric finds the high-impact sites and the floor that keeps the trawl tractable. A figure that doesn't
> clear the floor is a figure that wasn't needed — restraint is a feature.

## The two axes (score each 0–5)

For every candidate site (a heading, a paragraph, a list that *describes a structure*), score:

### Impact — does a figure replace reconstruction work?
*How much does the reader otherwise have to build in their head?*

| Score | The prose here… |
|---|---|
| 5 | describes a **system, flow, sequence, state machine, or quantitative comparison** the reader must assemble mentally (architecture, pipeline, lifecycle, before/after, data) |
| 3 | describes a **relationship or hierarchy** that a figure would sharpen but prose mostly carries |
| 1 | is **linear narrative** — a figure would decorate, not clarify |
| 0 | is reference/definitional (a glossary entry, an install command) — a figure would mislead |

### Clarity-gain — how much friction does a figure remove?
*How hard is the current prose to follow?*

| Score | The current prose… |
|---|---|
| 5 | forces re-reading: many named parts, cross-references, "as shown above/below", nested conditions |
| 3 | is followable but dense — the reader holds 4+ things at once |
| 1 | is already clear; a figure adds little |
| 0 | is trivial |

## The floor and the caps (the cost governors)

- **`SITE_FLOOR` (default 7/10).** `impact + clarity_gain ≥ 7` to illustrate. Below the floor → record the
  decision as `below-floor` in the ledger so the site is **not re-evaluated every pass**. **Do not
  illustrate everything** — the floor is the primary throttle, and it should bite.
- **Per-doc cap (default 3).** At most 3 figures per document. More than that and the doc is over-illustrated
  — pick the top 3 by score, defer the rest.
- **Skip-list.** Never illustrate: pure reference/manifest files (`*.tsv`, `*.json`, `requirements.*`),
  files that are *already* figure-dense, generated/historical reports, and canonical-copy files
  (`KAIZEN.md`, `inject-kaizen.sh`, `check.sh` — they must stay byte-identical across plugins).
- **Tie to the matrix.** A site that scores high but cannot fit the [4×9 matrix](../../rich-pdf-with-diagrams/references/charting-matrix.md)
  even when decomposed is a site for **two** figures, or none — never one illegible sprawl.

## The budget report

After a trawl pass, the ILLUSTRATOR reports the funnel honestly — silent truncation reads as "covered
everything" when it didn't:

```
Trawl pass: 142 docs scanned · 38 sites above floor · 3 over per-doc cap (deferred) · 11 illustrated · 27 queued
```

## Worked examples

| Site | Impact | Clarity | Σ | Decision |
|---|---:|---:|---:|---|
| README "How the 8 plugins compose" (9-phase flow in prose) | 5 | 5 | 10 | illustrate → `handler-graphviz` pipeline |
| VALUE_FLOW "the conveyor" (9 stations, hand-drawn ASCII already) | 5 | 4 | 9 | illustrate → replace ASCII with a real figure |
| glossary entry "deliver vs forge vs founder" | 1 | 2 | 3 | below-floor (definitional) |
| first-principles "the three pillars and their bindings" | 4 | 4 | 8 | illustrate → `handler-composition` concept figure |
| a skill's install snippet | 0 | 0 | 0 | skip (reference) |

## Self-improvement

If the floor is consistently letting through low-value sites (or rejecting valuable ones), tune the rubric
here via the shared [self-improvement protocol](../../rich-pdf-with-diagrams/references/self-improvement.md)
— adjust the floor, add a skip-class, or sharpen an axis description. The goal: the budget report's
"illustrated" count converges on *exactly the sites a careful editor would have chosen*.
