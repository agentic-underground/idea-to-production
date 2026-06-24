# Typst Template — A4 print-quality article (the Typst engine)

> The Typst counterpart to [`latex-template.md`](latex-template.md). Compiles in a **single pass**
> with `typst compile article.typ` (no TeX install). The **composition rules are identical** to the
> LaTeX path — only the syntax differs. Figures embed best as **SVG** (`dot -Tsvg`).
>
> Reachability of `typst` (and the optional `dot`) is verified by `/publish:check`.

Typst ≥ 0.12 (the marketplace is validated against 0.14.x). Save the preamble below as the head of
`article.typ`, then write the body in Typst markup.

## Preamble — page geometry, fonts, colours

```typ
// ── Page: A4 portrait, print margins matching the LaTeX geometry ───────────────
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.4cm, right: 2.4cm),
  numbering: "1",
  number-align: center,
)

// ── Body type: readable serif at 11pt, generous leading ────────────────────────
#set text(font: ("Libertinus Serif", "TeX Gyre Termes", "DejaVu Serif"), size: 11pt, lang: "en")
#set par(justify: true, leading: 0.72em, first-line-indent: 1.2em)
#show heading: set block(above: 1.2em, below: 0.7em)
#set heading(numbering: "1.1")

// ── Palette (keep in sync with graphviz-patterns.md so figures match the text) ──
#let ink     = rgb("#1a1a2e")
#let accent  = rgb("#0f3460")
#let rule    = rgb("#b0b0c0")
#show heading: set text(fill: accent)

// ── Code listings ───────────────────────────────────────────────────────────
#show raw.where(block: true): block.with(
  fill: rgb("#f4f4f8"), inset: 8pt, radius: 4pt, width: 100%,
)
#set raw(theme: none)

// ── Tables: light horizontal rules only ───────────────────────────────────────
#set table(stroke: (x, y) => if y == 0 { (bottom: 0.6pt + ink) } else { (bottom: 0.3pt + rule) })
```

## The `fullpage-figure` helper — same discipline as the LaTeX path

Enforces: a page break **before** a large figure, max width AND max height with aspect preserved
(the Typst equivalent of `keepaspectratio`), centred, captioned, and a break **after**. This is the
one helper that prevents the "figure runs off the page" / "figure too tiny" failure modes.

```typ
#let fullpage-figure(path, caption, full: true) = {
  if full { pagebreak(weak: true) }
  figure(
    // width caps the page width; the 0.86*page-height cap preserves aspect via `fit: "contain"`.
    box(width: 100%, height: if full { 86% } else { auto },
        clip: false, image(path, width: 100%, height: if full { 100% } else { auto }, fit: "contain")),
    caption: caption,
  )
  if full { pagebreak(weak: true) }
}
```

Usage in the body:

```typ
#fullpage-figure("diagrams/01-system-map.svg", [The production conveyor, end to end.])

// inline (smaller) figure — no forced page breaks:
#fullpage-figure("diagrams/02-maturity-ladder.svg", [Maturity ladder.], full: false)
```

## Title block & front matter

```typ
#align(center)[
  #text(size: 22pt, weight: "bold", fill: ink)[Article Title] \
  #v(0.4em)
  #text(size: 12pt, fill: accent)[Subtitle or standfirst] \
  #v(0.2em)
  #text(size: 10pt)[Author · #datetime.today().display("[year]-[month]-[day]")]
]
#v(1.2em)
#outline(title: [Contents], depth: 2)
#pagebreak()
```

## Build

```bash
bash scripts/build-pdf.sh --engine=typst       # renders diagrams/*.dot → .svg (if dot present), then compiles
# equivalently:
typst compile article.typ article.pdf
```

> **Font note:** this machine ships 168 fonts incl. DejaVu; for the exact look install a Libertinus
> or TeX Gyre family. Typst falls back gracefully through the font list above.
