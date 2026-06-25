# Lessons Learned — Running Log

> Every piece of diagram feedback received and generalised gets a
> numbered entry here. Append-only. Each entry must include the
> verbatim/paraphrased feedback, the generalised rule, the
> charting-matrix entry it affected, and the diagrams that were fixed.

Read this file every time you generate a new diagram. It is the memory
of this skill.

---

## Origin

This skill was created on **2026-05-22** from a structured retrospective
on diagram feedback received while producing the *From Conversation to
Orchestration* print edition at `FootyManager/doc/articles/may-21/`.
The lessons below codify the feedback that prompted the skill's
existence.

---

### Lesson 0001 — 2026-05-22

**Feedback received:**
*"Figure 2: The twenty-one-day timeline of significant commits. The
diagram is tiny on the page. Better to alter the diagram so there are
maximum five boxes across the page, so the diagram should be broken up
into multiple rows, the timeline is already broken up by colour-coding:
make it a tabular diagram with items on the left, lines connecting and
flowing down, and descriptions on the right."*

**Generalised rule:**
Timelines and long event chains must use a vertical tabular layout
(date-cell on the left, description-cell on the right, chained
top-to-bottom). Never use horizontal `rankdir=LR` for chains of more
than 4 events.

**Charting-matrix rule affected:**
- Rule 1 strengthened (max 4 across).
- Rule 2 reinforced (default TB).
- Pattern 4 (Tabular Timeline) added to `graphviz-patterns.md`.

**Diagram(s) fixed:** `09-timeline.dot`.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0002 — 2026-05-22

**Feedback received:**
*"Figures 3 and 4 suffer from too-tiny-syndrome too, better to scale
them up and align them 'portrait, with annotations on the right to
balance the page'."*

**Generalised rule:**
When a diagram has a primary content area and a set of supporting
annotations/callouts, lay it out in portrait orientation (`rankdir=TB`)
with the annotations placed in a right-side column anchored by
`rank=same` to specific layers of the primary content.

**Charting-matrix rule affected:**
- Rule 2 strengthened (TB by default for portrait balance).
- Pattern 1 (Multi-phase TB stack) annotated with "side annotations
  via rank=same" trick.

**Diagram(s) fixed:** `04-system-map.dot`, `02-maturity-ladder.dot`.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0003 — 2026-05-22

**Feedback received:**
*"The diagram on page 11 scales off the page and becomes invisible:
make it smaller and ensure it does not disappear off the page."*

**Generalised rule:**
Every figure must be bounded by **both** `width=\linewidth` and
`height=0.86\textheight` (or `0.55\textheight` for inline) with
`keepaspectratio`. Width-only sizing is the single most common cause
of overflow.

**Charting-matrix rule affected:**
- Rule 7 added (bound by both width and height).
- Failure mode F4 added.

**Diagram(s) fixed:** `03-ds-pipeline.dot` (and LaTeX include).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0004 — 2026-05-22

**Feedback received:**
*"Figure 7: the green section could be made to roll into multiple
lines, which would increase horizontal space for the other boxes, and
enable a scale-up to make the diagram less tiny."*

**Generalised rule:**
Wide fan-outs (one orchestrator to many workers, one parent to many
children) must wrap to multiple rows. Maximum 4 elements per row;
subsequent rows can have fewer. Use `{ rank=same; ... }` pairs with
invisible alignment edges.

**Charting-matrix rule affected:**
- Rule 5 added (wide fan-outs wrap to multiple rows).
- Pattern 3 (Wide fan-out wrap) added to `graphviz-patterns.md`.

**Diagram(s) fixed:** `05-foundry-arch.dot`.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0005 — 2026-05-22

**Feedback received:**
*"The diagram on page 13 disappears off the bottom of the page, this
and the diagram on page 11 could be treated as multi-column flows with
the boxes slightly smaller, and grouped by phase (try to group and
name the phases with meaningful phase names, fall back to numbered
phases if a meaningful name will not be applicable - I think you can
make named phases work)."*

**Generalised rule:**
Multi-phase workflows must be clustered with named phase labels. Each
phase cluster gets a circled numeral (`①`, `②`, `③`, `④`, `⑤`, `⑥`)
followed by an UPPERCASE phase name. Prefer verb-phrases ("PLAN &
SPECIFY") over numbered fallbacks ("PHASE 1"). The numeral order
matters; the name carries semantic anchoring.

**Charting-matrix rule affected:**
- Rule 3 added (cluster by named phase).
- §7 Naming Conventions for Phase Labels added.

**Diagram(s) fixed:** `03-ds-pipeline.dot`, `07-inspector-flow.dot`.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0006 — 2026-05-22

**Feedback received:**
*"Page 14 section 5.2 'panels' the text scrolls off the right edge.
Break the line into two and the list will fit on the page."*

**Generalised rule:**
Long enumerative content inside a table cell must wrap to multiple
continuation rows rather than relying on the column to absorb the
overflow. Add explicit `\\` linebreaks within the cell, or use
continuation rows with `& \footnotesize ...`.

**Charting-matrix rule affected:**
- Promoted from a LaTeX-template concern to a typesetting note in
  `latex-template.md` §6 Common Errors.

**Diagram(s) fixed:** N/A (LaTeX-only fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0007 — 2026-05-22

**Feedback received:**
*"Page 17 figure 9 the table almost works, but the phase names are
broken: better to break at 'I' (phase numeral) and have the name on a
new line inside the cell, giving it plenty of space to be unbroken."*

**Generalised rule:**
When a table cell contains a compound label (numeral + name, or
prefix + descriptor), force a `\newline` between the prefix and the
descriptor so the cell does not wrap mid-name. Pattern: `\textbf{I}
\newline \textbf{Phase Name}`.

**Charting-matrix rule affected:**
- Promoted to `latex-template.md` §6 Common Errors.

**Diagram(s) fixed:** N/A (table-cell fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0008 — 2026-05-22

**Feedback received:**
*"Tables on page 18 and 19: extra space required between columns, so
the names and class do not overlap."*

**Generalised rule:**
Multi-column reference tables (catalogues, listings, glossaries) must
set `\setlength{\tabcolsep}{10pt}` before the table to prevent column
overlap. Default `\tabcolsep` is too tight for two-line cell content.

**Charting-matrix rule affected:**
- Promoted to `latex-template.md` §6 Common Errors.

**Diagram(s) fixed:** N/A (table fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0009 — 2026-05-22

**Feedback received:**
*"Page 20/21 section 8.3 'What this means for the field' section needs
to be on one page, not broken. It's the most impactful text in the
entire document, 8.3 deserves its own page."*

**Generalised rule:**
The thesis-bearing or highest-impact paragraph of an article must be
forced onto its own page with `\clearpage` and a visible callout
(coloured box or pull-quote frame). Identify the thesis sentence
during the typesetting pass; treat it as a feature, not as body text.

**Charting-matrix rule affected:**
- `latex-template.md` §5 Page-Break Rules updated with
  "Highest-impact paragraph: own page + callout box."

**Diagram(s) fixed:** N/A (LaTeX layout fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0010 — 2026-05-22

**Feedback received:**
*"Appendix B, the TRACK column needs to be wider to prevent overlap."*

**Generalised rule:**
For catalogue-style longtables, never trust default column widths.
Set explicit `p{0.16\linewidth}` (or wider) for narrow label columns
that may contain wrapped multi-line content. Combine with
`\tabcolsep=10pt`.

**Charting-matrix rule affected:**
- `latex-template.md` §6 Common Errors updated.

**Diagram(s) fixed:** N/A (table column fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0011 — 2026-05-22

**Feedback received:**
*"P25 Colophon: put the Colophon on its own page."*

**Generalised rule:**
Front-matter and back-matter sections (Title, Epigraph, Table of
Contents, Colophon, each Appendix) must always be on their own page.
Use `\clearpage` before each such section unconditionally.

**Charting-matrix rule affected:**
- `latex-template.md` §5 Page-Break Rules already states this; the
  lesson reinforces that "always" means "always", with no exceptions.

**Diagram(s) fixed:** N/A (page-break fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0012 — 2026-05-22

**Feedback received:**
*"Page break before figure 5, vertical orientation: it's currently so
tiny even the box elements are difficult to distinguish .. same for
figure 6: page break before, vertical orientation, larger box
elements .. same for figure 8: page break before, vertical orientation
breaking at phase: each phase has at most 3 box elements which is ok
for the A4 page, they can be larger .. same again for figure 9: page
break before, staggered vertical orientation, larger box elements."*

**Generalised rule (compound — three sub-rules):**

1. **Every diagram that occupies > 50% of the page receives
   `\clearpage` before AND after**, and is sized by `height=0.86
   \textheight,keepaspectratio` so it fills the freed page.
2. **Within a phase cluster, at most 3 boxes across is the
   comfortable maximum**, with 4 as the absolute ceiling. Phases of
   3 elements can have visibly larger boxes than phases of 4-5.
3. **Linear chains of 4+ phases must use a staggered ladder
   layout** (alternating left/right indented rows, via invisible
   anchor nodes on each "rail").

**Charting-matrix rule affected:**
- Rule 4 added (within a phase cluster ≤3 across).
- Rule 8 added (clearpage before AND after full-page figure).
- Rule 10 added (stagger linear chains with 4+ phases).
- Pattern 2 (Staggered ladder) added to `graphviz-patterns.md`.

**Diagram(s) fixed:** `03-ds-pipeline.dot`, `06-four-phases.dot`,
`07-inspector-flow.dot`, `08-hello-protocol.dot`.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0013 — 2026-05-22

**Feedback received:**
*"Figures 5 and 8 are staggered across the page and are too small,
leaving a lot of negative space above and beneath on the page: so two
problems in one, tiny text and unbalanced page wastage. Prefer to use
the connector lines to draw the reader from panel to panel 'right to
left and down' instead of just 'down to next'."*

**Generalised rule:**
For any multi-phase workflow with 3-4 phases, arrange the phases as
**vertical panels in a 2×N grid**, NOT as horizontal phase bands.
Within each panel, boxes stack TB; panels are arranged in 2 columns
(left/right). Inter-phase connectors zig-zag — the key "right-to-left
and down" diagonal arrow between row 1 and row 2 draws the reader's
eye through the layout. The horizontal-band pattern (TB clusters with
LR boxes inside) is the canonical cause of failure mode F7 (thin
horizontal ribbon with negative space above and below).

**Charting-matrix rule affected:**
- Rule R-A1 added (vertical panel groups, not horizontal phase bands).
- Failure mode F7 added (thin horizontal ribbon).
- Pattern 8 (Zig-zag panel grid) added to `graphviz-patterns.md` and
  promoted to THE canonical pattern for 3-4 phases (replacing Pattern
  1 for those cases).
- Orientation Decision Table updated.

**Diagram(s) fixed:** `03-ds-pipeline.dot`, `07-inspector-flow.dot`.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0014 — 2026-05-22

**Feedback received:**
*"Figure 9 is good for orientation but still too small, it can be
larger on the page which will make it easier to read."*

**Generalised rule:**
Staggered-ladder diagrams (Pattern 2) should be sized at the maximum
`height` constraint allowed by the page layout (typically
`height=0.92\textheight`). Their natural aspect ratio is taller than
the page, so the height bound is the dominant constraint; bumping it
up uses the freed page space and makes boxes physically larger.

**Charting-matrix rule affected:**
- Pattern 2 (Staggered ladder) annotated with recommended figure
  height in `latex-template.md` §2.

**Diagram(s) fixed:** `06-four-phases.dot` and its `\includegraphics`
height in the .tex.

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0015 — 2026-05-22

**Feedback received:**
*"The table in 5.1 is too wide and extends beyond the right edge of
the page."*

**Generalised rule:**
Tables specified with explicit `p{N\linewidth}` column widths must
sum to **≤ 0.80 of `\linewidth`**, leaving room for the per-column
`\tabcolsep` padding (which scales with column count) and any
auto-sized `c`/`l`/`r` columns. A table with columns summing to
exactly `1.0\linewidth` will always overflow.

**Charting-matrix rule affected:**
- Rule R-A3 added (tables in linewidth-relative columns need a safety
  margin).

**Diagram(s) fixed:** N/A (LaTeX table column-width fix in §5.1).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0016 — 2026-05-22

**Feedback received:**
*"§5.3 — the §5.3 heading is at the bottom of page 19 and there is
plenty of space on page 20 for that section heading to be, so I want
to encode a new rule into the rich-pdf-skill which is that section
headers should consider page-break-before where they are near the
bottom of a page, and if the section content is going to be mostly on
the next page. If multiple sections will fit on a page, that's ok but
if a section is spilling over to the next page it should get a
page-break-before — with one exception: if a section is more than one
page long then content-overrun is unavoidable so let it be."*

**Generalised rule:**
Section/subsection headings within the last 6 cm of a page that have
content spilling to the next page must be preceded by `\clearpage`
(or `\sectionneeds{6cm}`). The exception is multi-page sections,
where the spillover is unavoidable.

**Charting-matrix rule affected:**
- Rule R-A2 added (section headings near bottom of page get
  `\clearpage`).
- Failure mode F8 added (section heading at bottom of page).
- `latex-template.md` §1 Preamble: `\sectionneeds{height}` command
  added.
- `latex-template.md` §5 Page-Break Rules: subsection row added.

**Diagram(s) fixed:** N/A (LaTeX layout fix on §5.3 and §6.2).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0017 — 2026-05-22

**Feedback received:**
*"§5.3 section heading is still at the bottom of page 19 with the
section content on the next page and it must not be: section heading
must be on the same page as the section content."*

**Generalised rule:**
`\sectionneeds{Ncm}` is **soft** — it only triggers when remaining
space drops below `N`. In practice, the soft form fails for two reasons:
(1) the heading itself takes vertical space, so what fits after the
threshold check may still orphan; (2) following content often
exceeds the conservative estimate. For any subsection the user has
**explicitly flagged** as needing a page break, use `\clearpage`
directly — not `\sectionneeds`. Reserve `\sectionneeds{Ncm}` for
preventive use on subsections that have not been individually
audited.

**Charting-matrix rule affected:**
- Rule R-A2 tightened: "explicitly flagged" subsections → `\clearpage`,
  not `\sectionneeds`. `\sectionneeds` remains the default *preventive*
  tool but is not the *corrective* tool.
- `latex-template.md` §5 Page-Break Rules clarified accordingly.

**Diagram(s) fixed:** N/A (LaTeX page-break fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0018 — 2026-05-22

**Feedback received:**
*"The table on 6.2 'agent' column needs extra padding on the right to
avoid text overlap, the table in 5.1 should be less wide as it is
disappearing off the right side of the page, make it narrower so as
to fit."*

**Generalised rule:**
Catalogue tables with **monospace identifier columns** (\texttt names
with hyphens, e.g., agent names like `ds-step-0-plan`) have a special
overflow risk: LaTeX does NOT break \texttt content at hyphens by
default, so a single identifier wider than the column produces a
visible overrun into the next column. Three robust fixes:

1. **Apply column-level font reduction** with `>{\ttfamily\footnotesize}`
   on the column type instead of per-cell `\texttt{...}`. Smaller font
   fits more characters per row width.
2. **Use `\nolinkurl{...}` or `\seqsplit{...}`** for content that must
   break at any character.
3. **Conservative widths**: for any table with monospace identifier
   columns, sum of explicit column widths must be **≤ 0.75 of
   `\linewidth`** (tighter than the general Rule R-A3 of ≤ 0.80) to
   leave headroom for the inflexibility of `\texttt`.

For ordinary tables in `\linewidth`-relative columns where overflow
persists despite Rule R-A3, narrow further. Iterate to ≤ 0.70 if
needed. There is no penalty for a slightly narrower table; the
overflow penalty is unprofessional output.

**Charting-matrix rule affected:**
- Rule R-A3 tightened: when monospace identifier columns are present,
  cap at 0.75 of `\linewidth`, not 0.80.
- `latex-template.md` §6 Common Errors: monospace-overflow row added.

**Diagram(s) fixed:** N/A (LaTeX table-fit fix).

**Article:** `FootyManager/doc/articles/may-21/`.

---

### Lesson 0019 — 2026-05-22

**Feedback received:**
*"Figure 7 and figure 8 should be zoomed in a little so the content
is larger."*

**Generalised rule:**
When a user reports a diagram "needs to be zoomed in" or "boxes are
too small", the cure is to increase **three per-node parameters
simultaneously**, not just one: (a) `fontsize` on the global `node`
attribute by +2 points; (b) `margin` by ~30% (e.g., 0.22 → 0.30
horizontal, 0.14 → 0.18 vertical); (c) `width` on specific boxes by
~15% where set. Changing only `fontsize` makes text larger but boxes
also expand to fit; the diagram's overall dimensions scale up
together, and the `\includegraphics` constraint (typically
`height=0.86\textheight`) then displays the diagram at a higher
effective magnification.

**Charting-matrix rule affected:**
- `graphviz-patterns.md` Pattern 0 (Universal preamble): default
  `fontsize=12` and `margin="0.22,0.14"` are minimums; for "zoom in"
  feedback, raise to `fontsize=14` and `margin="0.30,0.18"`.

**Diagram(s) fixed:** `05-foundry-arch.dot` (figure 7), `07-inspector-flow.dot` (figure 8).

**Article:** `FootyManager/doc/articles/may-21/`.

---

> **Batch 0020–0026 — 2026-06-09, Mermaid retrospective.** Seven lessons from one session
> producing the FLEET *Caching Layer — Impact Report* (`knowledge-base/reference/artifact-store-impact.print/`).
> First Mermaid-specific lessons in this log; absorbed together (like the 0001–0019 origin batch),
> each numbered separately as the audit trail. An adversarial design review of the rendered PDF
> caught a backwards-decoded chart legend and several diagram defects.

### Lesson 0020 — 2026-06-09

**Feedback received:** *"figure 4 … the title says 'compile (baseline, dark) vs store pull (after, light)' but the bar chart has the highest bars as light colour and the lowest as dark blue."* (`xychart-beta` legend decoded backwards.)

**Generalised rule:** `xychart-beta` has no legend and no reliable per-series colour — never encode series identity in a colour-word; name series in the caption, or don't use xychart for a legend-dependent claim.

**Charting-matrix rule affected:** strengthened the `mermaid-taxonomy.md` xychart row; new failure F11-adjacent (mis-decode) folded into R-A5 + dataviz-canon.

**Diagram(s) fixed:** the per-tool chart → replaced with a table (see 0021). **Article:** FLEET caching-layer impact report.

### Lesson 0021 — 2026-06-09

**Feedback received:** the "after" bars (≈1 s) were invisible against a 0–280 s linear axis — the headline collapse was the one thing the eye couldn't see.

**Generalised rule:** order-of-magnitude (>~10×) or legend-dependent comparisons → a table with a ratio/"×" column (or a single-series ratio chart), not an overlaid linear bar chart; `xychart-beta` has no log scale.

**Charting-matrix rule affected:** **R-A5** (new) + **F10** (new). **Diagram(s) fixed:** per-tool figure → table. **Article:** FLEET caching-layer impact report.

### Lesson 0022 — 2026-06-09

**Feedback received:** the architecture diagram was a tangle with a doubled "byby .local name" edge label.

**Generalised rule:** never fan a shared edge label across a node-product (`A & B -- "x" --> C & D`); route one group→group/hub edge and label once; cap fan-out.

**Charting-matrix rule affected:** **R-A4** (new) + **F11** (new). **Diagram(s) fixed:** `architecture.mmd`. **Article:** FLEET caching-layer impact report.

### Lesson 0023 — 2026-06-09

**Feedback received:** key edge labels rendered struck through (the edge line ran through the text) in the Typst PDF.

**Generalised rule:** the Typst-safe render uses `htmlLabels:false`, which drops edge-label backgrounds — keep edge labels short, move meaning to caption/nodes, and let the edge clear the label.

**Charting-matrix rule affected:** **F9** (new) + `mermaid-theming.md` limitation. **Diagram(s) fixed:** `architecture.mmd`, `beforeafter.mmd`. **Article:** FLEET caching-layer impact report.

### Lesson 0024 — 2026-06-09

**Feedback received:** the before/after figure rendered AFTER-left/BEFORE-right, inverting the timeline.

**Generalised rule:** Mermaid/Graphviz don't guarantee subgraph render order — pin it with an invisible link (`before ~~~ after`) or explicit ranks, and verify in the rendered image.

**Charting-matrix rule affected:** **R-A6** (new). **Diagram(s) fixed:** `beforeafter.mmd`. **Article:** FLEET caching-layer impact report.

### Lesson 0025 — 2026-06-09

**Feedback received:** a `;` inside a `sequenceDiagram` Note hard-failed the render (`build.sh` reported a mermaid parse error).

**Generalised rule:** reserved chars (`;`, unescaped `#`, unbalanced quotes) break Mermaid inside labels/notes — use commas/em-dashes; a pre-render `mmdc` parse-check catches it before compile.

**Charting-matrix rule affected:** **F12** (new) + `mermaid-taxonomy.md` reserved-chars note (+ the PR-2 lint). **Diagram(s) fixed:** `sequence.mmd`. **Article:** FLEET caching-layer impact report.

### Lesson 0026 — 2026-06-09

**Feedback received:** *"did this go through adversarial review? … run the entire pdf through adversarial review"* — the backwards-legend figure had shipped on a self-review of the source, with no visual review of the render.

**Generalised rule:** a figure that encodes quantities/a legend is not "done" until rasterised and run through the design-reviewer **with the source data** so it can verify figure↔data integrity; source self-review ≠ visual review of the output. (Process rule — lands in `publish.md` / rich-pdf SKILL + a dataviz-canon lie-factor line, PR-3.)

**Charting-matrix rule affected:** n/a (process); see dataviz-canon integrity principle. **Diagram(s) fixed:** the whole report re-reviewed → CONVERGED. **Article:** FLEET caching-layer impact report.

---

> **Batch 0027–0028 — 2026-06-11, animated-README craft retrospective.** Two lessons from the
> `research/image-craft-taste` session, the first to route through the *generalised* self-improvement
> loop (Classify → Generalise → route via the Step-3 table → log). Lesson 0027 is a LAYOUT/legibility
> finding (routes to `layout-canon.md`); lesson 0028 is an ANIMATION/motion finding (routes to the
> `raster-toolchain.md` Motion canon) — proving the routing table sends each domain to its owning canon
> rather than collapsing both into the charting matrix.

### Lesson 0027 — 2026-06-11

**Feedback received:** the inline-legibility gate caught several animated README figures shipping captions
too small to read at embed width — atelier "review" at 5.9px inline, ideate "the pain, shared" at 5.2px,
publish "published" at 5.5px — all below the 6px machine floor (and the corpus broadly sitting below the
9px comfort target).

**Generalised rule:** Author every caption/label large enough to clear the inline-legibility floor at the
figure's embed width *before* assembly — for a ~1280px-wide figure that means `font-size ≥ ~13` (→ ≥6.5px
inline), generally `font_size ≥ FLOOR × svg_width / 640`; never ship a sub-floor caption, and prove the
smallest text element above the floor with `layout-check.sh` before assembly.

**Canon rule affected:** `layout-canon.md` §5 — new "How to apply — author above the floor, don't fix below
it" authoring guidance appended to the inline-legibility rule (extends, does not duplicate, the §5 detector).

**Figure(s)/animation(s) fixed in this round:** `atelier-critique`, `ideate-converge`, `publish-press`.

**Article:** `research/image-craft-taste` README animated-figure corpus.

### Lesson 0028 — 2026-06-11

**Feedback received:** the repo-welcome figure's key amber greeting was only ever shown mid-typewriter /
mid-dissolve and never settled at full opacity, so the most important sentence read as garbled ("we come —
corcierge"); the fix held the fully-typed greeting as a settled full-opacity poster beat before any fade.

**Generalised rule:** A typed or animated key (meaning-bearing) label must settle at full opacity for a held
beat — at least its own caption/dense dwell tier — *before* it fades or the loop restarts; never present the
meaning-bearing sentence only mid-transition. The reveal animates; the message must hold legibly.

**Canon rule affected:** `raster-toolchain.md` Motion canon — new "SETTLE the key label before you fade it"
motion rule (placed before "FADES, not hard cuts").

**Figure(s)/animation(s) fixed in this round:** the repo-welcome figure.

**Article:** `research/image-craft-taste` README animated-figure corpus.

---

## Standing notes (not numbered lessons, but always true)

- **Always re-read `charting-matrix.md` before composing.** It is the
  cumulative rule set; lessons here are only the audit trail.
- **Default values matter.** A diagram with the wrong default `nodesep`
  or `ranksep` looks subtly bad in a way that is hard to articulate.
  The patterns in `graphviz-patterns.md` carry tested defaults; copy
  them, don't fight them.
- **When two rules conflict, surface the conflict.** Do not silently
  pick one. Surface it to the user (or, in the source repo, resolve it explicitly).
