# Graphviz Patterns — Reusable DOT Recipes For A4 Diagrams

> **Pick a pattern, copy it, edit the content.** Do not design from
> scratch. The patterns below have been tested against the charting
> matrix and produce diagrams that obey the rules by construction.

---

## Pattern 0 — Universal preamble

Every diagram begins with this preamble. Copy-paste, then customise.

```dot
digraph DiagramName {
  rankdir=TB;
  bgcolor="transparent";
  splines=spline;
  ranksep=0.50;
  nodesep=0.30;
  compound=true;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=12, margin="0.22,0.14"];
  edge [fontname="Helvetica", fontsize=10, color="#444444", penwidth=1.3];
  ...
}
```

The palette (use these named hex codes for visual consistency across all
diagrams):

| Role | Background | Border | Text |
|------|-----------|--------|------|
| Default / muted | `#f6f8fa` | `#57606a` | — |
| Action / step (blue) | `#cfe1ff` | `#0969da` | — |
| Sentinel / contract (yellow) | `#fffbcc` / `#fff8c5` | `#9a6700` | — |
| Reviewer / audit (purple) | `#e0cffc` / `#fce8ff` | `#8250df` | — |
| Success / shipped (green) | `#dafbe1` / `#b6f5b6` | `#1a7f37` | — |
| Failure / warning (red) | `#ffd1cc` / `#ffe5e0` | `#cf222e` | — |
| Strong / central anchor | `#0d1117` | `#0d1117` | `#ffffff` |

---

## Pattern 1 — Multi-phase TB stack with clusters (the canonical pattern)

**Use for:** any workflow with 3-5 named phases, each containing 2-3
elements. This is the **default** pattern for most diagrams.

```dot
digraph MultiPhase {
  rankdir=TB;
  bgcolor="transparent";
  splines=spline;
  ranksep=0.50;
  nodesep=0.30;
  compound=true;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=12, margin="0.22,0.13"];
  edge [fontname="Helvetica", fontsize=10, color="#444444", penwidth=1.4];

  trigger [label="entry condition", shape=cds, fillcolor="#fff8c5",
           color="#9a6700", fontname="Helvetica-Bold"];

  subgraph cluster_phase1 {
    label="①   PHASE NAME 1";
    fontname="Helvetica-Bold"; fontsize=13; color="#0969da";
    bgcolor="#eef4ff"; style="rounded,dashed"; margin=16;
    a1 [label="box 1", fillcolor="#cfe1ff", color="#0969da", width=2.0];
    a2 [label="box 2", fillcolor="#cfe1ff", color="#0969da", width=2.0];
    a3 [label="box 3", fillcolor="#cfe1ff", color="#0969da", width=2.0];
    a1 -> a2 -> a3;
    { rank=same; a1; a2; a3; }   // KEEP THEM HORIZONTAL within the cluster
  }

  subgraph cluster_phase2 {
    label="②   PHASE NAME 2";
    fontname="Helvetica-Bold"; fontsize=13; color="#8250df";
    bgcolor="#fce8ff"; style="rounded,dashed"; margin=16;
    b1 [label="box 1", fillcolor="#e0cffc", color="#8250df", width=2.0];
    b2 [label="box 2", fillcolor="#e0cffc", color="#8250df", width=2.0];
    b1 -> b2;
    { rank=same; b1; b2; }
  }

  finish [label="exit / outcome", shape=doubleoctagon,
          fillcolor="#dafbe1", color="#1a7f37",
          fontname="Helvetica-Bold"];

  trigger -> a1 [color="#0969da", penwidth=1.6];
  a3 -> b1 [color="#8250df", penwidth=2, ltail=cluster_phase1,
            lhead=cluster_phase2, label="  inter-phase transition  ",
            fontname="Helvetica-Bold"];
  b2 -> finish [color="#1a7f37", penwidth=2];
}
```

**Key tricks:**
- `{ rank=same; a1; a2; a3; }` *inside* the cluster keeps elements
  horizontal — without it Graphviz would stack them vertically.
- `compound=true` plus `ltail`/`lhead` on inter-cluster edges draws the
  arrow from the *edge* of the cluster, not from a specific node inside.
- Each cluster gets its own colour family. Use the palette table.

---

## Pattern 2 — Staggered ladder (4+ phases, alternating L/R)

**Use for:** any linear chain of 4+ elements where Pattern 1 would feel
sparse. The four-phases-of-developer-posture diagram uses this.

```dot
digraph Staggered {
  rankdir=TB;
  ranksep=0.55;
  nodesep=0.45;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=12, margin="0.30,0.18", width=3.6];
  edge [fontname="Helvetica-Bold", fontsize=10, penwidth=1.8];

  // Invisible anchors on the left and right rails
  L1 [shape=point, width=0.01, style=invis];
  R1 [shape=point, width=0.01, style=invis];
  L2 [shape=point, width=0.01, style=invis];
  R2 [shape=point, width=0.01, style=invis];
  // ... (Ln, Rn pairs for each phase)

  p1 [label="I  ·  PHASE 1\n...", fillcolor="#ffd1cc", color="#cf222e"];
  p2 [label="II  ·  PHASE 2\n...", fillcolor="#fff8c5", color="#9a6700"];
  p3 [label="III  ·  PHASE 3\n...", fillcolor="#ddf4ff", color="#0969da"];
  p4 [label="IV  ·  PHASE 4\n...", fillcolor="#dafbe1", color="#1a7f37"];

  // Phase 1 LEFT-aligned: L is close, R is far
  { rank=same; L1; p1; R1; }
  L1 -> p1 [style=invis, minlen=1];
  p1 -> R1 [style=invis, minlen=4];

  // Phase 2 RIGHT-aligned: L is far, R is close
  { rank=same; L2; p2; R2; }
  L2 -> p2 [style=invis, minlen=4];
  p2 -> R2 [style=invis, minlen=1];

  // ... repeat alternating pattern for p3, p4

  // Visible transition arrows between phases
  p1 -> p2 [color="#cf222e", label="  trigger 1  "];
  p2 -> p3 [color="#9a6700", label="  trigger 2  "];
  p3 -> p4 [color="#0969da", label="  trigger 3  "];
}
```

**Key tricks:**
- `shape=point, width=0.01, style=invis` creates a zero-size invisible
  anchor.
- `minlen` on invisible edges controls horizontal distance: `minlen=1`
  pulls close, `minlen=4` pushes far.
- The visible `p_i -> p_{i+1}` edges automatically render as diagonals
  because of the alternating L/R positioning.

---

## Pattern 3 — Wide fan-out wrap (1 → N handlers)

**Use for:** orchestrator-to-workers, central node fanning out to
multiple specialists. Examples: DELIVER → 7 handlers; service → multiple
adapters.

```dot
digraph FanOut {
  rankdir=TB;
  ranksep=0.55;
  nodesep=0.30;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=11, margin="0.20,0.12"];
  edge [fontname="Helvetica", fontsize=10, penwidth=1.3];

  central [label="ORCHESTRATOR", fillcolor="#cfe1ff",
           color="#1f6feb", fontname="Helvetica-Bold",
           margin="0.26,0.16"];

  subgraph cluster_workers {
    label="HANDLER POOL";
    fontname="Helvetica-Bold"; fontsize=11; color="#1a7f37";
    bgcolor="#dafbe1"; style="rounded,dashed"; margin=14;
    // Row 1: 4 workers max
    w1 [label="handler\nA"]; w2 [label="handler\nB"];
    w3 [label="handler\nC"]; w4 [label="handler\nD"];
    // Row 2: 3 workers (or fewer)
    w5 [label="handler\nE"]; w6 [label="handler\nF"];
    w7 [label="handler\nG"];
    { rank=same; w1; w2; w3; w4; }
    { rank=same; w5; w6; w7; }
    // Invisible edges to enforce row separation
    w1 -> w5 [style=invis];
    w2 -> w6 [style=invis];
    w3 -> w7 [style=invis];
  }

  central -> w1 [style=dotted, arrowhead=none];
  central -> w2 [style=dotted, arrowhead=none];
  central -> w3 [style=dotted, arrowhead=none];
  central -> w4 [style=dotted, arrowhead=none];
}
```

**Key tricks:**
- Two `{ rank=same; ... }` blocks define two horizontal rows.
- Invisible edges between rows force Graphviz to keep them separate.
- Limit row 1 to **4 boxes**; subsequent rows can have fewer.

---

## Pattern 4 — Tabular timeline (vertical event list)

**Use for:** timelines, change logs, retrospective event chains.
Replaces a horizontal `rankdir=LR` chain that would be illegibly thin.

```dot
digraph Timeline {
  rankdir=TB;
  bgcolor="transparent";
  splines=line;
  ranksep=0.10;
  nodesep=0.05;
  node [shape=plaintext, fontname="Helvetica"];
  edge [arrowhead=none, color="#7d8590", penwidth=1.6];

  t1 [label=<<TABLE BORDER="0" CELLBORDER="1.5" CELLSPACING="0"
                CELLPADDING="9" COLOR="#cf222e">
       <TR>
         <TD BGCOLOR="#ffd1cc" WIDTH="180" ALIGN="LEFT" VALIGN="MIDDLE">
           <FONT FACE="Helvetica-Bold" POINT-SIZE="13" COLOR="#cf222e">
             DATE
           </FONT><BR/>
           <FONT POINT-SIZE="10" COLOR="#57606a">commit-hash · time</FONT>
         </TD>
         <TD BGCOLOR="#fff5f3" WIDTH="430" ALIGN="LEFT" VALIGN="MIDDLE">
           <FONT POINT-SIZE="12" FACE="Helvetica-Bold">headline</FONT>
           <BR/>
           <FONT POINT-SIZE="10" COLOR="#444">description line 1<BR/>
           description line 2</FONT>
         </TD>
       </TR></TABLE>>];

  // t2, t3, ... follow the same template with different colours
  t1 -> t2 -> t3 -> ...;
}
```

**Key tricks:**
- `shape=plaintext` plus HTML-like `<TABLE>` labels gives true tabular
  layout that Graphviz cannot do with native shapes.
- Two cells per row: left = date/anchor, right = description.
- Width values (180 / 430) match the A4 textblock proportions.
- Chain rows top-to-bottom with edges that have `arrowhead=none` for a
  clean ribbon look.

---

## Pattern 5 — Two-actor message bus

**Use for:** inter-process or inter-agent coordination over a shared
medium. Two actors flank a central anchor.

```dot
digraph MessageBus {
  rankdir=TB;
  ranksep=0.55;
  nodesep=0.50;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=12, margin="0.24,0.14", width=2.6];

  // Top row: two actors side by side
  m1 [label="@sender", fillcolor="#cfe1ff", color="#1f6feb",
      fontname="Helvetica-Bold"];
  m2 [label="@receiver", fillcolor="#ffd1cc", color="#cf222e",
      fontname="Helvetica-Bold"];
  { rank=same; m1; m2; }

  // Left column: sender's actions
  send_a [label="write message"];
  send_b [label="commit + push"];

  // Central anchor: the message bus
  bus [label="MESSAGE BUS\n(versioned · auditable)",
       shape=cylinder, fillcolor="#0d1117", fontcolor="#ffffff",
       color="#0d1117", fontname="Helvetica-Bold",
       margin="0.30,0.22"];

  // Right column: receiver's actions
  recv_a [label="pull / poll"];
  recv_b [label="read inbox"];

  // Acknowledgement (optional return path)
  ack [label="acknowledge",
       fillcolor="#dafbe1", color="#1a7f37"];

  m1 -> send_a -> send_b -> bus;
  bus -> recv_a -> recv_b -> m2;
  m2 -> ack;
  ack -> bus [style=dashed, constraint=false];

  { rank=same; send_a; recv_a; }
  { rank=same; send_b; recv_b; }
}
```

**Key tricks:**
- Top row contains the two actors via `rank=same`.
- The cylinder shape is the conventional choice for "the bus".
- Symmetric `rank=same` constraints lower in the diagram keep the two
  columns aligned visually.

---

## Pattern 6 — Layered architecture (front → back → store)

**Use for:** system stack diagrams. The FootyManager system-stack
diagram (exemplar 01) uses this.

```dot
digraph SystemStack {
  rankdir=TB;
  bgcolor="transparent";
  splines=ortho;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=11, margin="0.20,0.12"];

  subgraph cluster_layer1 {
    label="UI / FRONTEND LAYER";
    fontname="Helvetica-Bold"; fontsize=11;
    color="#1f6feb"; bgcolor="#eef4ff";
    style="rounded,dashed";
    // 3-4 boxes inside, each describing a frontend concern
  }

  subgraph cluster_layer2 {
    label="API / SERVER LAYER";
    fontname="Helvetica-Bold"; fontsize=11;
    color="#cf222e"; bgcolor="#fff0ee";
    style="rounded,dashed";
    // 3-4 boxes inside
  }

  subgraph cluster_layer3 {
    label="DOMAIN / LOGIC LAYER";
    fontname="Helvetica-Bold"; fontsize=11;
    color="#1a7f37"; bgcolor="#ecffe8";
    style="rounded,dashed";
    // 3-4 boxes inside
  }

  subgraph cluster_layer4 {
    label="STORAGE LAYER";
    fontname="Helvetica-Bold"; fontsize=11;
    color="#8250df"; bgcolor="#f4ecff";
    style="rounded,dashed";
    // 2-3 boxes inside
  }

  // Inter-layer arrows go from outer-most boxes of each cluster
}
```

**Key tricks:**
- Each layer is a labelled cluster with a unique colour family.
- Use `splines=ortho` for clean right-angle connectors when layers are
  rectangular blocks.
- Layer labels include a noun ("UI / FRONTEND LAYER") not just a number.

---

## Pattern 8 — Zig-zag panel grid (THE canonical pattern for 3–4 phases)

**Use for:** any multi-phase workflow with 3 or 4 phases, each
containing 2-3 elements. **This pattern replaces Pattern 1 whenever
there are more than 2 phases.** It is the single biggest cure for the
"diagram is tiny on the page" failure mode (F7).

**Visual layout:**
```
[ ① PHASE 1 ]                        [ ② PHASE 2 ]
   box A1                                box B1
   │                                     │
   box A2                                box B2
   │                                     │
   box A3 ────────── (rightward) ─────→  (entry)
                                         │
                                         ↓ (down)
                                         box B3
                                         │
                          (down-left)    │
        ┌────────────────────────────────┘
        │
        ↓
[ ③ PHASE 3 ]                        [ ④ PHASE 4 ]
   box C1                                box D1
   │                                     │
   box C2 ────────── (rightward) ─────→  box D2
                                         │
                                         ↓
                                         box D3
```

Reading order is left→right on row 1, then **right-to-left and down**
to row 2 (the diagonal arrow that catches the reader's eye), then
left→right on row 2.

**DOT skeleton:**

```dot
digraph ZigZagPanels {
  rankdir=TB;
  newrank=true;
  bgcolor="transparent";
  splines=spline;
  ranksep=0.55;
  nodesep=0.50;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=12, margin="0.24,0.16"];
  edge [fontname="Helvetica", fontsize=10, color="#444444", penwidth=1.4];

  // Phase 1 — top-left panel, boxes stack VERTICALLY
  subgraph cluster_p1 {
    label="①   PHASE NAME 1";
    fontname="Helvetica-Bold"; fontsize=13;
    color="#0969da"; bgcolor="#eef4ff";
    style="rounded,dashed"; margin=18;
    a1; a2; a3;
    a1 -> a2 -> a3;             // VERTICAL chain inside the panel
  }

  // Phase 2 — top-right panel
  subgraph cluster_p2 {
    label="②   PHASE NAME 2";
    fontname="Helvetica-Bold"; fontsize=13;
    color="#0969da"; bgcolor="#eef4ff";
    style="rounded,dashed"; margin=18;
    b1; b2;
    b1 -> b2;
  }

  // Phase 3 — bottom-left panel
  subgraph cluster_p3 {
    label="③   PHASE NAME 3";
    fontname="Helvetica-Bold"; fontsize=13;
    color="#0969da"; bgcolor="#eef4ff";
    style="rounded,dashed"; margin=18;
    c1; c2;
    c1 -> c2;
  }

  // Phase 4 — bottom-right panel
  subgraph cluster_p4 {
    label="④   PHASE NAME 4";
    fontname="Helvetica-Bold"; fontsize=13;
    color="#0969da"; bgcolor="#eef4ff";
    style="rounded,dashed"; margin=18;
    d1; d2; d3;
    d1 -> d2 -> d3;
  }

  // ============================================================
  // The grid-positioning machinery:
  //   Force a 2×2 grid by ranking the top-row entries together
  //   and the bottom-row entries together, then using invisible
  //   edges to control left/right ordering within each rank.
  // ============================================================

  { rank=same; a1; b1; }                  // top-row entries
  { rank=same; c1; d1; }                  // bottom-row entries

  a1 -> b1 [style=invis, minlen=3];       // P1 left of P2
  c1 -> d1 [style=invis, minlen=3];       // P3 left of P4

  // Vertical alignment hints (left column = a→c, right column = b→d)
  a3 -> c1 [style=invis];
  b2 -> d1 [style=invis];

  // ============================================================
  // The visible zig-zag transition arrows
  // ============================================================

  a3 -> b1 [color="#8250df", penwidth=2,
            label="  transition 1 →  ",
            fontname="Helvetica-Bold", fontcolor="#8250df",
            constraint=false];

  // The key arrow: bottom-right of P2 down-and-left to top-left of P3
  b2 -> c1 [color="#8250df", penwidth=2,
            label="  ↙ right-to-left and down ↙  ",
            fontname="Helvetica-Bold", fontcolor="#8250df",
            constraint=false];

  c2 -> d1 [color="#8250df", penwidth=2,
            label="  transition 3 →  ",
            fontname="Helvetica-Bold", fontcolor="#8250df",
            constraint=false];
}
```

**Key tricks:**
- `newrank=true` is REQUIRED for `rank=same` to operate across
  cluster boundaries in TB mode. Without it, ranking is local to each
  cluster.
- The `rank=same` blocks pair the **first** node of each row's panels,
  not the cluster itself (Graphviz cannot rank clusters directly).
- Invisible edges with `minlen=3` enforce horizontal spacing.
- Invisible vertical edges (`a3 -> c1`, `b2 -> d1`) keep the left-column
  panels above each other and same for the right column.
- The diagonal `b2 -> c1` transition (the "right-to-left and down" arrow)
  is the visual signature of the pattern — make it visible and labelled.
- All inter-panel transitions use `constraint=false` so they do not
  affect the grid layout, only render visually.

**Three-phase variant:** for 3 phases use the same skeleton minus P4.
Place P3 either in bottom-left (with bottom-right empty — wider P3 box
fills the row) or bottom-spanning the full width. Reading flow becomes
P1 → P2 → (down-and-left) → P3.

**Anti-pattern check:** before writing this pattern, confirm that you
are NOT doing the horizontal-band layout (Pattern 1 with `{ rank=same;
a1; a2; a3; }` *inside* the cluster). Pattern 1's horizontal-band
layout is for **single-phase** wide rows or **small** 2-phase
workflows. Anything with 3+ phases must use this pattern instead.

---

## Pattern 7 — Decision tree (branching TB)

**Use for:** decision flowcharts, if/else logic, classification trees.

```dot
digraph Decision {
  rankdir=TB;
  ranksep=0.45;
  nodesep=0.35;
  node [shape=box, style="rounded,filled", fontname="Helvetica",
        fontsize=11, margin="0.22,0.13"];

  q1 [shape=diamond, label="condition?",
      fillcolor="#fff8c5", color="#9a6700",
      fontname="Helvetica-Bold"];

  // Two branches max per row (or 3 for ternary decisions)
  branch_a [label="action A", fillcolor="#cfe1ff", color="#0969da"];
  branch_b [label="action B", fillcolor="#cfe1ff", color="#0969da"];

  q1 -> branch_a [label="  yes  "];
  q1 -> branch_b [label="  no   "];
}
```

**Key tricks:**
- Use `shape=diamond` for decision points.
- Label every edge with the condition's outcome.
- Never branch >3 ways from a single node — refactor to nested
  diamonds.

---

## When patterns are not enough

If your diagram does not fit any of these patterns, do **not** invent a
new approach. Instead:

1. Identify the closest pattern from the table above.
2. Decompose the diagram so the closest pattern can carry it.
3. If multiple patterns are needed, **produce multiple diagrams** rather
   than one complex one.

The cost of a clean second diagram is much lower than the cost of a
confusing single diagram.
