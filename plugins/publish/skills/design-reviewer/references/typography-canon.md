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

## 4. Document accessibility (PDF/UA, WCAG 2.2) — the honesty gate

A page a reader's *eye* flows through can still be one a screen reader cannot read at all. Accessibility is
to a document what the lie factor is to a chart — a **hard honesty floor**, not a polish dimension: an
untagged or low-contrast document is *making a claim it cannot keep* (that it is readable by everyone). Hold
it against **PDF/UA** (ISO 14289) and **WCAG 2.2 AA** for documents:

- **Tagged structure (PDF/UA §7).** The PDF carries a real tag tree — headings as headings, lists as lists,
  tables as `<Table>` with header cells — not just visually-styled glyphs. An **untagged** document is an
  image of text to assistive tech: a hard failure. (Typst: `pdf.tag`/document metadata; LaTeX: `tagpdf` /
  `pdfx` / `accsupp`.)
- **Logical reading order.** The tag/reading order matches the visual order — multi-column flow, sidebars,
  and floated figures must not scramble what a screen reader speaks.
- **Body-text contrast (WCAG 2.2 SC 1.4.3, AA).** Body and caption text meet **≥ 4.5:1** against their
  background (**≥ 3:1** for large text ≥ 24 px / 18.66 px bold). Cite the *measured* ratio — light-grey body
  on white is the common offender.
- **Alt text for figures (WCAG SC 1.1.1).** Every informative figure, chart, and image carries a text
  alternative; purely decorative marks are tagged as artifacts so they're skipped, not announced.
- **Language & metadata (PDF/UA §7.1, WCAG SC 3.1.1).** Document title and primary language are set;
  long documents carry bookmarks/outline for navigation.

> A WCAG-AA / PDF/UA failure on a *rendered* document is **≥ HIGH and blocks PASS** — the same gate stance
> PUBLISH holds for the Tufte lie factor on a chart. This is the print-side analogue of DESIGN's screen
> a11y gate.

---

> **Sources to cite:** Bringhurst, *The Elements of Typographic Style* (measure/leading/scale/page);
> Müller-Brockmann, *Grid Systems in Graphic Design* (grid/baseline); the Van de Graaf / Villard page
> canons (margins); **PDF/UA (ISO 14289) and WCAG 2.2 AA** (document accessibility); and the marketplace
> charting-matrix rules (R-A2, R-A3, 7, 8) for the print-fixed specifics. Cite the principle by name in
> every finding.
