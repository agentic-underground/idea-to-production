# Mermaid Patterns — recipes and when to prefer Mermaid

Mermaid's strength is diagrams that live **as source inside markdown**, drawn by the renderer
(GitHub, GitLab, most docs sites, many wikis). When the target renders Mermaid, emit the source
in a fenced block — don't pre-render. When it doesn't, render to SVG with `mmdc` (the Mermaid
CLI) and embed the image.

> Legibility still governs: the 4×9 charting-matrix intuition applies — keep node counts modest,
> break a sprawling graph into several. See `../../rich-pdf-with-diagrams/references/charting-matrix.md`.

---

## When to prefer Mermaid over Graphviz

| Prefer Mermaid | Prefer Graphviz |
|---|---|
| Sequence diagrams (interactions over time) | Architecture / dependency graphs |
| Gantt / simple timelines | Anything needing precise layout control (clusters, ranks) |
| Class / ER diagrams from a known schema | Wide fan-outs wrapped to rows |
| Diagram should stay editable inline in markdown | Print/PDF vector output |

---

## Sequence diagram

```mermaid
sequenceDiagram
    participant B as Browser
    participant A as API
    participant S as Service
    participant D as Database
    B->>A: POST /order
    A->>S: createOrder(cmd)
    S->>D: INSERT order
    D-->>S: id
    S-->>A: OrderCreated(id)
    A-->>B: 201 Created
```

Keep participants ≤6; past that, split the interaction or group participants into boxes
(`box ... end`).

## Flowchart

```mermaid
flowchart TB
    start([Request]) --> auth{Authenticated?}
    auth -- no --> reject[401]
    auth -- yes --> rate{Within rate limit?}
    rate -- no --> throttle[429]
    rate -- yes --> handle[Handle] --> done([Response])
```

Use `TB` for documentation (tall column); `LR` for slides (wide). Label every decision edge.

## Class diagram

```mermaid
classDiagram
    class Order {
      +UUID id
      +Money total
      +place()
    }
    class LineItem
    Order "1" *-- "many" LineItem
```

## Gantt (roadmaps/timelines)

```mermaid
gantt
    title Release plan
    dateFormat YYYY-MM-DD
    section Core
    Spec        :done,    a1, 2026-06-01, 5d
    Implement   :active,  a2, after a1, 10d
    Harden      :         a3, after a2, 5d
```

## State diagram

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Review
    Review --> Draft: changes
    Review --> Published
    Published --> [*]
```

---

## Rendering when the target can't draw Mermaid

```bash
mmdc -i diagrams/01-flow.mmd -o diagrams/01-flow.svg     # vector for web/markdown
mmdc -i diagrams/01-flow.mmd -o diagrams/01-flow.png -s 2 # 2× raster if SVG unsupported
```

Then embed the rendered file: `![Flow](diagrams/01-flow.svg)`.

---

## Accessibility

Add an accessible title/description so the diagram is not opaque to screen readers:

```mermaid
%%{init: {'theme':'neutral'}}%%
flowchart TB
  accTitle: Request handling flow
  accDescr: Authenticated, rate-limited requests are handled; others are rejected.
  ...
```

For rendered SVG, ensure the `<svg>` carries a `<title>` and `<desc>` (mmdc emits these from
`accTitle`/`accDescr`).

---

## Self-improvement

New Mermaid recipe or a legibility lesson? Add it here, and if the lesson is about composition
(too many nodes, wrong direction for the target), generalise it into the shared charting-matrix
via `../../rich-pdf-with-diagrams/references/self-improvement.md`.
