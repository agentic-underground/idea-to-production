---
name: rich-pdf-with-diagrams
description: >
  Produce a print-quality rich-text PDF article with embedded Graphviz/TikZ
  diagrams that respect A4-portrait composition rules. Use this skill when
  the user requests a "rich PDF", "print edition", "publication-ready PDF",
  "PDF with diagrams", or whenever WRITER is asked to emit a long-form
  artefact destined for printed/published consumption. Trigger when the
  parent skill (typically WRITER) has the rich-text source in hand and now
  needs to produce a typographically sound, visually balanced PDF artefact
  whose figures are readable on a printed A4 page.
  Carries a self-improvement covenant: every piece of diagram feedback
  received from a user gets generalised and woven back into the
  charting-matrix reference, so the same composition error never occurs
  twice.
metadata:
  type: producer
  output: pdf
  inputs: rich-text article (markdown), diagram specifications, repository context
  preferred-engine: pdflatex / lualatex
  preferred-diagrammer: Graphviz (dot) with vector PDF output
model: inherit
---

# RICH-PDF-WITH-DIAGRAMS

> *Reliable diagrammatic typesetting for A4-portrait print artefacts.*

This skill exists to convert a written article into a publishable PDF whose
diagrams are **immediately readable on a printed A4 page**, with the right
visual rhythm, the right amount of whitespace, and zero feedback wasted
on "make the figure bigger."

It is invoked by **WRITER** (and may be invoked directly by the user) when
the deliverable is a rich PDF rather than markdown. It is **self-improving**:
every piece of diagram feedback gets folded into the charting-matrix and
the lessons-learned log so the same mistake does not recur.

---

## 0. THE PRIME DIRECTIVE

> **The A4 portrait page is a 4×9 charting matrix.**
>
> Every diagram you produce must compose within at most **4 boxes across**
> (3 is the comfortable default; 4 is the absolute maximum) and may use as
> many vertical rows as it needs. Diagrams that exceed this composition
> ratio render as illegible micro-text when scaled to fit the printable
> text block, and waste reader attention.

If a diagram cannot be drawn within 4 columns × 9 rows, **decompose it**
into multiple figures, each obeying the matrix.

---

## 1. WHEN TO INVOKE THIS SKILL

Trigger this skill when **any** of these conditions are present:

| Signal | Action |
|--------|--------|
| The user asks for a "rich PDF", "print edition", "publication-ready" output | invoke |
| The user asks for "PDF with diagrams" or "PDF with graphics" | invoke |
| WRITER has produced markdown and the user wants an upgraded PDF artefact | invoke |
| A diagram revision request arrives ("the figure is too small", "it goes off the page") | invoke §6 SELF-IMPROVEMENT, then apply the lesson |
| User explicitly invokes via `/rich-pdf-with-diagrams` or names the skill | invoke |

Do **not** invoke this skill for ordinary markdown articles, slide decks,
or web-rendered output. The skill targets *print-fixed dimensions only*.

---

## 2. WORKFLOW

The skill is a three-phase pipeline. Each phase has an obligation to the
next.

### Phase A — Compose

For each diagram the article needs:

1. State the **semantic content**: what does this diagram convey?
2. Choose a **pattern** from `references/graphviz-patterns.md` that fits.
3. Sketch the **box inventory** — list every box, every cluster, every
   connection. Count them.
4. Verify the box inventory fits the 4×9 matrix. If not, **split into
   multiple diagrams** before writing any DOT.
5. Decide orientation: default to **`rankdir=TB`** (portrait); use `LR`
   only when the diagram's semantic flow is unambiguously horizontal and
   fits within 4 boxes across.

### Phase B — Generate

For each diagram:

1. Write a `.dot` file in `<article-dir>/build/diagrams/NN-name.dot`,
   following the patterns in `references/graphviz-patterns.md`.
2. Run `dot -Tpdf NN-name.dot -o NN-name.pdf`.
3. **Open the rendered PDF** (or describe its expected dimensions) and
   check: does each box have enough internal padding? Is the text
   readable at 100% page size? If not, increase `margin`, `width`,
   `nodesep`, `ranksep` until it does.

### Phase C — Typeset

For the LaTeX document:

1. Use the preamble in `references/latex-template.md` (geometry, fonts,
   colours, tables, code listings).
2. For each figure: `\clearpage` **before** every full-page figure (one
   that occupies > 50% of textheight), then:
   ```latex
   \begin{figure}[t]
     \centering
     \includegraphics[width=\linewidth,height=0.86\textheight,keepaspectratio]{diagrams/NN-name.pdf}
     \caption{...}
   \end{figure}
   \clearpage
   ```
3. Run `pdflatex` **three times** (for TOC + cross-references).
4. Visually verify the output: scan every figure for the failure modes in
   `references/charting-matrix.md` §6 (the failure catalogue).

---

## 3. THE CHARTING MATRIX — RULES IN ONE PAGE

These rules are **inviolable** unless a numbered exception in
`references/charting-matrix.md` overrides them.

| # | Rule | Why |
|---|------|-----|
| 1 | **Max 4 boxes across an A4 portrait page** (3 comfortable, 4 absolute max) | Wider compositions render boxes <5mm wide; text becomes unreadable |
| 2 | **Default `rankdir=TB`** (top-to-bottom). Use `LR` only when ≤4 boxes wide and semantically horizontal | A4 portrait is taller than wide; matching the page geometry preserves space |
| 3 | **Cluster by phase.** Name each phase with a number and a noun: `①  PLAN & SPECIFY`, `②  TEST FIRST` | Named phases give the reader semantic anchors; numbers reinforce order |
| 4 | **Within a phase cluster, keep elements at ≤3 across.** If a phase has more, break it into two phases | Same readability reason as Rule 1 |
| 5 | **Wide fan-outs wrap to multiple rows.** 7 handlers? 4 on row 1, 3 on row 2 | Prevents the "tiny boxes in a long line" anti-pattern |
| 6 | **Boxes carry at least 0.20 inch horizontal margin and 0.13 inch vertical margin** (`margin="0.20,0.13"`) | Cramped text inside boxes looks unprofessional and is harder to scan |
| 7 | **Use `keepaspectratio` and bound by both `width=\linewidth` AND `height=0.86\textheight`** in LaTeX | Prevents diagrams from running off the bottom of the page |
| 8 | **Every full-page figure gets `\clearpage` before AND after** | Stops floats from being squeezed by surrounding text |
| 9 | **Edge labels carry sentinel/contract names** wherever possible, so intermediate hexagon nodes can be removed | Frees horizontal space; conveys the same information |
| 10 | **Stagger linear chains** (alternate left/right indented rows) when 4+ phases need to flow | Adds visual rhythm; reuses figure-7-style design |
| **R-A1** | **For 3-4 phase workflows, use the zig-zag panel grid (Pattern 8) — vertical panels in a 2×N grid with diagonal connectors. NEVER horizontal phase bands.** | Horizontal bands produce thin ribbons with negative space above and below; vertical panels use the page area properly and yield bigger boxes |
| **R-A2** | **Subsection headings within the last 6 cm of a page whose content spills to the next page must get `\sectionneeds{6cm}` or `\clearpage` before them** | Orphan headings always look uglier than a clean page break; exception: multi-page sections |
| **R-A3** | **Tables in linewidth-relative columns must sum to ≤ 0.80 of `\linewidth`** | `\tabcolsep` padding accumulates per column; columns summing to 1.0 always overflow |

---

## 4. EXEMPLARS — WHAT GOOD LOOKS LIKE

Two reference exemplars live in `exemplars/` and are what every new
diagram should be measured against:

| Exemplar | What it demonstrates |
|----------|---------------------|
| `exemplars/01-system-stack.dot` | Stacked clusters (browser → server → domain → storage), each cluster ≤4 boxes, vertical flow, edge labels |
| `exemplars/05-foundry-arch.dot` | Central TB flow with a wide fan-out wrapped to 2 rows of handlers; right-side ledger node; clean rank groupings |

When in doubt, **copy the structure** of one of these. Modifying a good
exemplar yields better diagrams than designing from scratch.

---

## 5. REFERENCES

Read each of these before producing a new diagram. They are deliberately
short and prescriptive.

- `references/charting-matrix.md` — the 4×9 grid principle in full, the
  failure catalogue, the decomposition rules.
- `references/graphviz-patterns.md` — DOT recipes for the common diagram
  types (vertical chain, multi-phase cluster, fan-out, staggered ladder,
  message-bus flow, tabular timeline).
- `references/latex-template.md` — the LaTeX preamble (geometry, fonts,
  colours, tables, code listings, custom environments) used for every
  rich-PDF article.
- `references/self-improvement.md` — the protocol for absorbing feedback
  and amending this skill.
- `references/lessons-learned.md` — the running log of generalised
  feedback. **Read this every time you generate a diagram.**

---

## 6. SELF-IMPROVEMENT PROTOCOL — MANDATORY

> **Every piece of diagram feedback received from a user MUST be
> generalised and woven back into this skill before the next diagram is
> produced.** This is not optional. It is what makes the skill reliable.

When the user provides feedback on a diagram:

1. **Classify** the feedback against the charting-matrix rules. Which
   rule (existing or missing) does this feedback exercise?
2. **Generalise**: rewrite the feedback as a one-sentence rule. Strip
   the specific diagram, keep the principle.
3. **Update** `references/charting-matrix.md`:
   - If the feedback strengthens an existing rule → tighten the rule.
   - If the feedback exposes a new rule → add it as the next numbered
     rule, with a one-line *Why*.
4. **Log** the lesson in `references/lessons-learned.md`:
   ```
   ### Lesson NNNN — YYYY-MM-DD
   **Feedback received:** [verbatim or close paraphrase]
   **Generalised rule:** [the one-sentence principle]
   **Charting-matrix rule affected:** [#N, new, or [pattern name]]
   **Diagram(s) fixed in this round:** [list]
   ```
5. **Record the lesson** *before* re-rendering the affected article. If you are working in the
   pressroom plugin's own source repository, commit the update there; otherwise surface the
   generalised rule to the user so it can be folded upstream:
   ```bash
   git add skills/rich-pdf-with-diagrams/
   git commit -m "skill: rich-pdf-with-diagrams — absorb feedback (lesson NNNN)"
   ```
6. **Re-render** the article applying the new rule. The next diagram
   produced by anyone using this skill will inherit the lesson.

The lessons-learned log is the **memory** of this skill. Without
maintaining it, the skill will degrade. With it, the skill compounds.

---

## 7. HOW WRITER CALLS THIS SKILL

WRITER ([`${CLAUDE_PLUGIN_ROOT}/skills/writer/SKILL.md`](../../skills/writer/SKILL.md)) reaches the point where the
markdown article exists and the user has asked for a PDF. At that point
WRITER should:

1. Read this `SKILL.md` and the four references in order.
2. Re-read `references/lessons-learned.md` (the memory) carefully.
3. Follow §2 WORKFLOW for each diagram and the final typesetting pass.
4. After delivery, if the user provides any diagram feedback, follow §6
   SELF-IMPROVEMENT before producing a revision.

WRITER does not re-implement the diagramming logic. It defers to this
skill.

---

## 8. ANTI-PATTERNS (NEVER DO THESE)

| Anti-pattern | Why it fails | Do instead |
|--------------|--------------|------------|
| `rankdir=LR` with >4 boxes side-by-side | Boxes shrink to <5mm wide when scaled to A4 width | Switch to TB, break into rows |
| 9-step linear chain in one row | Same illegibility problem | Group into phases (cluster + label); stack phases TB |
| Every sentinel/intermediate as its own node | Doubles the box count and halves readable size | Put sentinel names on edge labels |
| Letting the figure float without `\clearpage` | Figure squashed; surrounding text jammed | `\clearpage` before AND after every full-page figure |
| `\includegraphics[width=\linewidth]` only | Tall diagrams overflow the bottom of the page | Bound by both width and height with `keepaspectratio` |
| Margins ≤ 0.10 on boxes | Text touches box edges; looks unprofessional | Use `margin="0.22,0.14"` minimum |
| Designing diagrams without consulting `lessons-learned.md` | Re-introduces fixed bugs | **Always** consult lessons before composing |

---

## 9. PROVENANCE

This skill was synthesised on 2026-05-22 from feedback gathered while
producing the *From Conversation to Orchestration* print edition at
`FootyManager/doc/articles/may-21/`. The two exemplar diagrams were taken
from that article's first successful figures (system stack, FOUNDRY
architecture).

The skill's self-improvement covenant ensures that every subsequent
article using it will start from a stricter baseline than the last.
