# Mermaid taxonomy — every diagram type, and when each fits

> Mermaid is far more than flowcharts. Choosing the **right type** is the single biggest lever on whether a
> diagram explains or obscures. Match the diagram to the *structure of the idea*. Each row gives the type,
> the meaning it carries best, a syntax cue, and its legibility ceiling (decompose past it — the shared 4×9
> charting-matrix governs). Types marked *(beta)* may need a recent Mermaid; `/pressroom:check` reports
> `mmdc`'s presence, and when a type isn't supported by the target renderer, emit source or render via
> `mmdc`.

## Structure & process

| Type | Best for | Cue | Ceiling |
|---|---|---|---|
| **flowchart** | processes with decisions, pipelines | `flowchart TB` · `A-->B` · `A--yes-->B` | ≤~12 nodes; TB for docs, LR for slides; label every decision edge |
| **sequenceDiagram** | messages/calls between actors over time | `participant A` · `A->>B: msg` · `loop/alt/opt` | **≤6 participants** (else `box … end` or split) |
| **stateDiagram-v2** | lifecycle, modes, transitions | `[*] --> S` · `S --> T: event` · composite `state S { … }` | ≤~8 states before nesting composites |
| **classDiagram** | OO structure, schema with behaviour | `class X { +field\n +method() }` · `X "1" *-- "many" Y` | ≤~10 classes per figure |
| **erDiagram** | data model, entities & cardinality | `A ||--o{ B : has` | ≤~10 entities; split by bounded context |
| **architecture-beta** | cloud/service topology with icons | `service db(database)[DB]` · `group`, junctions | keep groups shallow |
| **C4** *(C4Context/Container/Component)* | layered software architecture (the C4 model) | `C4Context` · `Person`, `System`, `Rel` | one C4 level per diagram |
| **block-beta** | arbitrary block layouts / packet-ish structure | `block` · columns | modest block count |
| **requirementDiagram** | requirements & their satisfaction links | `requirement r { id, text, risk }` | group by area |

## Time, sequence & plans

| Type | Best for | Cue | Ceiling |
|---|---|---|---|
| **gantt** | schedules over real dates, dependencies | `gantt` · `dateFormat` · `task :id, after x, 5d` | **≤~15 tasks**; split by section |
| **timeline** | ordered events without precise dates | `timeline` · `2026 : event : event` | group into periods |
| **gitGraph** | branch/merge history | `gitGraph` · `commit`, `branch`, `merge` | a handful of branches |
| **journey** (user journey) | a user's steps + satisfaction score | `journey` · `Task: 5: Actor` | one journey per diagram |
| **kanban** | work-in-progress board state | `kanban` · columns of cards | a snapshot, not a history |

## Quantity, comparison & position

| Type | Best for | Cue | Ceiling / caveat |
|---|---|---|---|
| **pie** | part-to-whole, **few** slices | `pie title T` · `"A" : 40` | ≤~5 slices; often a bar is better (Cleveland) |
| **xychart-beta** | a single simple bar/line trend | `xychart-beta` · `bar [..]` · `line [..]` | **no legend, no per-series colour control, no log scale.** A *single* same-order series only; for ≥2 series, a legend-dependent claim, or an order-of-magnitude comparison use a **table with a ratio/"×" column** (charting-matrix R-A5) — a colour-word legend WILL mis-decode, and a small series vanishes on a linear axis. Dense quant → a real charting tool |
| **quadrantChart** | 2×2 strategic positioning | `quadrantChart` · axes + points | ≤~12 points; label axes meaningfully |
| **radar** *(beta)* | multi-axis comparison of a few items | `radar` · axes + series | ≤~3 series, ≤~8 axes |
| **sankey-beta** | flow/throughput between stages | `sankey-beta` · `Source,Target,value` rows | keep nodes few; order by magnitude |

## Knowledge, relationships & misc

| Type | Best for | Cue | Ceiling |
|---|---|---|---|
| **mindmap** | hierarchy, brainstorm, taxonomy | `mindmap` · indented nodes | ≤~3 levels deep |
| **treemap** *(beta)* | nested part-to-whole by area | `treemap` | shallow nesting; area-perception is weak (Cleveland) |
| **packet-beta** | byte/bit field layouts (protocols) | `packet-beta` · ranges | one structure per diagram |
| **zenuml** | sequence diagrams (alt syntax) | `zenuml` | as sequence |

## Reserved characters break the parse — keep labels/notes clean

Mermaid parses certain characters as syntax; placing them in node labels, edge labels, or
`Note` text **fails the render outright** (not a cosmetic issue — the whole `.mmd` errors):

- **`;`** is a statement separator — a semicolon inside a `Note` or label aborts parsing. Use a
  comma or em-dash. (Cost a hard render-fail in a `sequenceDiagram` note.)
- **`#`** starts an entity/clashes with directives; **unbalanced `"`** breaks label tokenising.
- Safest fix for any rich text: wrap the label in quotes *and* avoid the reserved set, or use
  HTML entities (`#35;` for `#`). A pre-render `mmdc` parse-check (the rich-pdf lint) catches
  these before compile — see charting-matrix **F12**.

## Choosing well — the three questions

1. **Structure or quantity?** Structure (who relates to whom, what flows to what, what state follows what)
   → a structural type above. Quantity (how much, what trend) → a chart — and for anything dense, prefer a
   real data-viz tool and submit it to the [`design-reviewer`](../../design-reviewer/SKILL.md)'s
   Tufte/Cleveland/Bertin rubric.
2. **Time-ordered?** If the *sequence in time* is the point → sequence / timeline / gantt / journey.
3. **Will it fit the matrix?** Count nodes/participants/tasks against the ceilings above. If not, **split**
   into multiple diagrams (small multiples beat one unreadable sprawl) before writing any source.

> **Self-improvement.** New recipe or a sharper "when to use" rule? Add it here. If the lesson is about
> *composition* (too many nodes, wrong direction), generalise it into the shared charting-matrix via
> `../../rich-pdf-with-diagrams/references/self-improvement.md`, so Graphviz and the print pipeline inherit
> it too.
