# The typography & page canon — what the typographic reviewer cites

> The named theory of setting type and composing a page. A finding is *"measure exceeds Bringhurst's 75-cpl
> ceiling"*, not *"the lines feel long"*. Grounding is what makes the critique teachable and the loop able
> to verify a fix.

## 1. The text — measure, leading, scale (Bringhurst)

From Robert Bringhurst, *The Elements of Typographic Style*:

- **Measure (line length).** Aim for **45–75 characters** per line for continuous text (≈66 is the classic
  ideal); ~40–50 for a narrow column. Too long tires the eye and loses the return sweep; too short fractures
  rhythm and over-hyphenates.
- **Leading (line spacing).** Tune to the measure and size: a longer measure or larger size needs more
  leading. Body text commonly ~120–145% of size. Cramped leading greys the page; excessive leading breaks
  the column into stripes.
- **Modular scale.** Derive sizes from **one ratio** (a *musical* proportion — minor third 1.2, major third
  1.25, perfect fourth 1.333, perfect fifth 1.5, golden 1.618). Ad-hoc sizes read as amateur; a scale reads
  as composed. 4–6 steps is plenty.
- **Hierarchy** via size/weight/space/colour — not font-soup. Distinguish levels clearly and consistently;
  two families maximum (a display + a text face), paired by contrast.
- **One space after a period**; true small caps and old-style/tabular figures where appropriate; hung
  punctuation and proper dashes/quotes are the marks of care.

## 2. The page — grid, baseline, canon (Müller-Brockmann)

- **The grid is the backbone.** Columns, margins, running heads and folios align to a grid; things that
  relate, align. Josef Müller-Brockmann's *Grid Systems* is the canonical treatment. A consistent grid is
  the quiet signal of competence.
- **Baseline grid.** Body text sits on an invisible baseline rhythm (set by the body leading); headings,
  captions, and figures align to multiples of it. Broken baseline rhythm is felt even when not seen.
- **Page proportions & margins.** Classic canons (Van de Graaf / Villard) place the text block with
  harmonious, usually asymmetric margins (outer > inner, bottom > top) so facing pages feel balanced. The
  text block's *measure* falls out of the page width and margins — set them together.

## 3. Composition discipline (the rendered artefact)

- **Widows & orphans.** No lone last line stranded at the top of a page (widow); no heading or single line
  stranded at the foot (orphan). Within the last ~6 cm of a page, a heading whose section spills over gets
  `\sectionneeds{6cm}` or `\clearpage` (Rule **R-A2**).
- **Figures.** Sized for balance, not maxed; a full-page figure gets `\clearpage` **before and after**
  (Rule 8); bound by width **and** height with `keepaspectratio` (Rule 7); caption stays with its figure.
- **Tables.** Linewidth-relative columns sum to **≤0.80** `\linewidth` (Rule **R-A3**) — `\tabcolsep`
  accumulates and 1.0 always overflows. Numerals right-aligned, tabular figures, rules sparing (Tufte: lose
  the vertical rules).
- **Colour & ink.** Restrained and consistent; code blocks and call-outs with adequate contrast and
  padding; nothing decorative competing with the text.

> **Engine-agnostic.** Judge the *rendered* page — Typst or LaTeX produced it; the composition rules are the
> same. The fixes are concrete source changes (geometry, `\linespread`, a scale step, a `\clearpage`).

---

> **Sources to cite:** Bringhurst, *The Elements of Typographic Style* (measure/leading/scale/page);
> Müller-Brockmann, *Grid Systems in Graphic Design* (grid/baseline); the Van de Graaf / Villard page
> canons (margins); and the marketplace charting-matrix rules (R-A2, R-A3, 7, 8) for the print-fixed
> specifics. Cite the principle by name in every finding.
