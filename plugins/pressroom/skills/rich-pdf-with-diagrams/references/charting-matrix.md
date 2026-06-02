# The Charting Matrix — Composition Rules For A4-Portrait Diagrams

> **The A4 portrait page is a 4-column × 9-row matrix.** Every diagram you
> produce must compose within it. This file is the canonical statement of
> the rules. It is **load-bearing**: tighten it on every feedback cycle.

---

## 1. THE GRID

```
A4 portrait, after 30mm inner + 20mm outer margins and 30mm top + 30mm bottom:
text block ≈ 135 mm wide × 215 mm tall.

Divide into:
  4 columns × 9 rows  =  36 cells
  each cell ≈ 33.75 mm × 23.9 mm

A "box" in a Graphviz diagram should occupy at least one full cell, with
no less than 25 mm × 18 mm of internal space. That is the minimum for
readable 10-pt text inside a labelled box.
```

Why 4×9 and not some other ratio? Because A4 portrait is 1:1.41 (height
over width), and the text block within it is roughly 1:1.6. A 4×9 grid
gives boxes a 1:1.4 aspect ratio (close enough to A4 itself) and accepts
typical Graphviz `margin="0.20,0.13"` padding without crushing.

**A diagram that needs more than 4 boxes across is too wide.** A
diagram that needs more than 9 rows fits on a page only if you sacrifice
caption space; consider whether it should be split.

---

## 2. THE TEN INVIOLABLE RULES

Every rule here is paired with a *Why*. Knowing the *Why* lets you judge
edge cases. **Tighten on feedback; never relax without recording the
exception.**

### Rule 1 — Max 4 boxes across (3 comfortable, 4 absolute max)

**Why:** at 5 boxes across an A4 portrait text block, individual boxes
shrink to <25mm wide, making 10-pt text inside them illegible.

**How to apply:** count your widest row. If it exceeds 4, decompose
into multiple stacked clusters.

### Rule 2 — Default `rankdir=TB`. Use `LR` only when ≤4 boxes wide

**Why:** A4 portrait is taller than wide; matching the page geometry
preserves space. Long horizontal chains never fit.

**How to apply:** before writing DOT, ask "is this flow really
horizontal?" Linear pipelines, decision trees, hierarchies → TB. Two
side-by-side actors with a message bus between them → could be LR if
narrow enough.

### Rule 3 — Cluster by named phase

**Why:** named phases give the reader semantic anchors. Numbers reinforce
order. Pure visual flow without phase names forces the reader to
reconstruct meaning from positions.

**How to apply:** name every cluster with `①  PHASE NAME` (circled
numeral + space + uppercase phase name). Examples:
- `①  PLAN & SPECIFY` / `②  TEST FIRST` / `③  IMPLEMENT & VERIFY` /
  `④  SYNC & SHIP`
- `①  ACQUIRE` / `②  ANALYSE` / `③  REPORT & RELEASE`
- If a meaningful name does not exist, fall back to `PHASE 1`, `PHASE
  2`, etc. — but try hard to find a name first.

### Rule 4 — Within a phase cluster, keep elements ≤3 across

**Why:** same illegibility math as Rule 1. Two phases of 3 elements is
better than one phase of 6.

**How to apply:** count the boxes inside each cluster. If >3 wide,
either split the cluster or stack the elements internally.

### Rule 5 — Wide fan-outs wrap to multiple rows

**Why:** 7 handlers in one row → 7 micro-boxes. 4+3 in two rows → 7
readable boxes.

**How to apply:** use Graphviz `{ rank=same; a; b; c; d; }` followed by
`{ rank=same; e; f; g; }` with invisible alignment edges to keep rows
separate. See `graphviz-patterns.md` "wide fan-out wrap".

### Rule 6 — Boxes carry minimum padding `margin="0.22,0.14"`

**Why:** cramped text inside boxes looks unprofessional and is harder to
scan.

**How to apply:** add `margin="0.22,0.14"` to the global `node` style or
per-node. For boxes containing more than 2 lines of text, increase to
`margin="0.26,0.16"`.

### Rule 7 — Bound figures by both width AND height in LaTeX

**Why:** `width=\linewidth` alone lets very tall diagrams overflow the
bottom of the page (especially in two-column flows).

**How to apply:**
```latex
\includegraphics[width=\linewidth,height=0.86\textheight,keepaspectratio]{...}
```
For inline (non-full-page) figures use `height=0.55\textheight`.

### Rule 8 — `\clearpage` before AND after every full-page figure

**Why:** without `\clearpage` LaTeX may float the figure to an awkward
location, squashing the surrounding paragraph and the figure itself.

**How to apply:**
```latex
\clearpage
\begin{figure}[t]
  \centering
  \includegraphics[...]{...}
  \caption{...}
\end{figure}
\clearpage
```
A "full-page figure" is any diagram whose `height` parameter is ≥
`0.70\textheight`.

### Rule 9 — Sentinel names go on edge labels, not as separate nodes

**Why:** if a 10-step pipeline has a sentinel between every pair of
steps, the diagram has 19 boxes and is unreadable. Putting sentinels on
edges keeps node count at 10 and conveys the same information.

**How to apply:**
```dot
s1 -> s2 [label=" SENTINEL_NAME ", fontcolor="#9a6700"];
```
Apply this to: phase transition sentinels, reviewer gates, contract
names, any intermediate "name + arrow" combination.

### Rule 10 — Stagger linear chains with 4+ phases

**Why:** a 4+ step linear TB chain produces a tall, narrow ribbon that
uses <40% of the page width. Staggering (alternating left-aligned and
right-aligned rows) uses the horizontal space and adds visual rhythm.

**How to apply:** use invisible anchor nodes (`shape=point, style=invis`)
on the left and right "rails" of the page. Rank-same each anchor with
its visible phase, then chain `L -> p -> R` with different `minlen`
values to push the box left or right. See `graphviz-patterns.md`
"staggered ladder".

---

## 3. EXTRA RULES ADDED BY FEEDBACK CYCLES

This section grows over time. When `lessons-learned.md` accumulates a
generalisable rule, promote it here.

### Rule R-A1 — Vertical panel groups, not horizontal phase bands

**Why:** Clusters arranged as horizontal phase bands (TB stacking of
clusters, with boxes inside each cluster arranged LR) produce **thin
ribbons that waste page height**, force each box into <30 mm width,
and leave large empty regions above and below. The diagram appears
tiny on the page even though the file rendered to the correct overall
dimensions.

**How to apply:** When a workflow has **2–4 phases each with 2–3
elements**, arrange the phases as **vertical panels in a 2×N grid**.
Within each panel, boxes stack TB; panels themselves are arranged in
two columns (left/right) flowing in reading order. Use **zig-zag
connectors** between panels — the inter-phase arrow goes from
bottom-right of one panel to top-left of the next, drawing the eye
diagonally. Never use the horizontal-band pattern for diagrams with
more than 2 phases.

See Pattern 8 (Zig-zag panel grid) in `graphviz-patterns.md`.

### Rule R-A2 — Section headings near the bottom of a page get `\clearpage`

**Why:** A section heading orphaned at the bottom of a page (with its
content forced to the next page) is **always uglier than a clean page
break**. The reader's eye lands on the heading, then must turn the page
to find the content. The whitespace at the bottom of the previous page
is a typesetting tell that the article was never properly proofed.

**How to apply:** Two modes — corrective and preventive.

- **Corrective (when the user has explicitly flagged an orphan):** use
  `\clearpage` directly before the subsection. **Never `\sectionneeds`**
  for flagged orphans — the soft variant fails when the heading itself
  consumes the threshold's headroom and subsequent content still
  overflows.
- **Preventive (general typesetting hygiene):** prepend
  `\sectionneeds{6cm}` to any subsection that might be orphaned. The
  command checks remaining page space and breaks if insufficient. This
  is the default tool when auditing a draft.

**Exception:** If a section is more than one page long, content-overrun
is unavoidable; do not add `\clearpage` (you would just be moving the
overrun, not fixing it). Multi-page sections are flagged separately and
exempt from this rule.

### Rule R-A3 — Tables in `\linewidth`-relative columns need a safety margin

**Why:** `p{0.5\linewidth}p{0.4\linewidth}` does **not** equal
0.9\linewidth in practice. Each column contributes `2 × \tabcolsep` of
inter-column padding plus borders. Tables specified as exactly summing
to 1.0\linewidth always overflow.

**How to apply:** Sum of all explicit column widths must be **≤ 0.80
of `\linewidth`**, leaving room for `\tabcolsep` and auto-sized columns
(`c`, `r`, `l`). For three columns with a narrow first column, target
`c + p{0.45\linewidth} + p{0.30\linewidth}` (sum 0.75) rather than
`c + p{0.5\linewidth} + p{0.40\linewidth}` (sum 0.90).

For longtables with many rows, prefer `tabularx` which auto-balances
columns within a fixed total width:
```latex
\begin{tabularx}{\linewidth}{lXX}
```

**Sub-rule R-A3a — Monospace identifier columns are tighter (≤ 0.75 of
`\linewidth`):** When any column contains `\texttt{name-with-hyphens}`
content (agent names, slug identifiers, file paths), LaTeX does NOT
hyphenate inside `\texttt` by default, so a single identifier wider
than the column produces a visible overrun into the next column.
Mitigations, in order of preference:

1. Use a column-level font reduction:
   ```latex
   \begin{longtable}{>{\ttfamily\footnotesize}p{0.36\linewidth}p{0.10\linewidth}p{0.32\linewidth}}
   ```
   Then drop the per-cell `\texttt{...}` wrappers.
2. Use `\nolinkurl{name-with-hyphens}` (provided by `hyperref`) — it
   renders in monospace and breaks at any character.
3. Cap the table width at **≤ 0.75 of `\linewidth`** rather than the
   general 0.80.

Identifier tables that violate this sub-rule are the second most
common cause of "column overlap" feedback after Rule R-A3 itself.

---

## 4. DECOMPOSITION RULES — WHEN ONE DIAGRAM SHOULD BECOME TWO

If a diagram fails any of Rules 1, 4, or 5 even after restructuring,
**split** it. Splitting rules:

| Symptom | Split strategy |
|---------|---------------|
| 6+ phases in one TB stack | Two figures: "phases 1-3" and "phases 4-6"; cross-reference in captions |
| 5+ boxes across a row | Decompose the row into two clusters with semantic names |
| Mixing semantic layers (orchestration + execution + storage) in one diagram | One figure per layer; arrows between figures via caption text |
| Multiple complex fan-outs | One figure for the orchestrator, one for each fan-out |

Splitting always reads better than cramming. The reader will thank you.

---

## 5. ORIENTATION DECISION TABLE

```
┌──────────────────────────────────────────────┬──────────────────────────┐
│ Question                                     │ Orientation               │
├──────────────────────────────────────────────┼──────────────────────────┤
│ Linear pipeline, ≤4 steps                    │ LR or TB                  │
│ Linear pipeline, ≥5 steps                    │ TB (staggered ladder)     │
│ Branching tree                               │ TB                        │
│ Multi-phase workflow (2 phases)              │ TB (stacked clusters)     │
│ Multi-phase workflow (3–4 phases)            │ TB with 2×N PANEL GRID    │  ← R-A1
│ Multi-phase workflow (5+ phases)             │ split into 2 diagrams     │
│ Two-actor message bus                        │ TB (3-column anchor)      │
│ Layered architecture (front → back → db)     │ TB                        │
│ Timeline of events                           │ TB (tabular)              │
│ Fan-out (1 → N) or fan-in (N → 1)            │ TB (wrap rows)            │
└──────────────────────────────────────────────┴──────────────────────────┘
```

**Default to TB.** Switch to LR only with a defensible reason.

**For 3–4 phases use the zig-zag panel grid** (Pattern 8), NOT
horizontal-band clusters. This is non-negotiable; see Rule R-A1.

---

## 6. THE FAILURE CATALOGUE

Eight visible failure modes. If you see any of these in a rendered
diagram or page, stop and fix it before delivering the article.

| # | Failure mode | Root cause | Fix |
|---|--------------|-----------|-----|
| F1 | Text inside boxes <8pt | Diagram scaled down too far | Reduce box count per row; split into multiple figures |
| F2 | Boxes touching each other (no whitespace) | `nodesep` too small | Set `nodesep=0.30` minimum |
| F3 | Edges crossing through boxes | Wrong layout engine or missing rank groupings | Add `{ rank=same; ... }` constraints; try `splines=spline` |
| F4 | Diagram extends below page bottom | Missing height bound in `\includegraphics` | Add `height=0.86\textheight,keepaspectratio` |
| F5 | Wide horizontal flow squeezed to thin column | `rankdir=LR` with too many boxes | Switch to TB and stack |
| F6 | Caption squashed against figure | Missing `\clearpage` | Wrap figure in `\clearpage…\clearpage` |
| F7 | Diagram is a thin horizontal ribbon with huge negative space above and below | Horizontal-band cluster pattern (LR inside, TB between) | Switch to **zig-zag panel grid** (Pattern 8); vertical panels in 2×N grid |
| F8 | Section heading at bottom of page, content on next page | Missing `\sectionneeds` / `\clearpage` before the heading | Prepend `\sectionneeds{6cm}` or `\clearpage` per Rule R-A2 |

---

## 7. NAMING CONVENTIONS FOR PHASE LABELS

When clustering by phase, use this hierarchy of options for the cluster
label:

1. **Best**: a verb-phrase that names what the phase *does* — `PLAN &
   SPECIFY`, `IMPLEMENT & VERIFY`, `ACQUIRE`, `ANALYSE`.
2. **Acceptable**: a noun-phrase that names the *artefact* produced —
   `SPECIFICATION`, `TEST SUITE`, `IMPLEMENTATION`.
3. **Fallback only**: a numbered phase — `PHASE 1`, `PHASE 2`.

Always prefix with a circled numeral: `①`, `②`, `③`, `④`, `⑤`, `⑥`.
This is the strongest visual signal of order.

Use the en-space (` `) — not a hyphen — between numeral and name:
`①  PLAN & SPECIFY` reads better than `①-PLAN & SPECIFY` or `①PLAN`.

---

## 8. WHEN IN DOUBT

Read `lessons-learned.md`. Pick the lesson most similar to the situation
you face. Apply it. If no lesson matches, design conservatively (more
whitespace, fewer boxes per row, more clusters) and record the new case
as a candidate lesson for the next feedback cycle.
