# Cached review — PRESSROOM handler-graphviz

**Target file:** `plugins/pressroom/agents/handler-graphviz.md`  
**Unit:** `handler-graphviz`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Canonical preamble bakes a charting-matrix Rule 6 violation into every diagram

**Evidence:** handler-graphviz.md ~line 45 ships `margin="0.20,0.13"` in the canon preamble: `node [style="filled", fillcolor="#1e1e2e", color="#9aa2c0", fontcolor="#e6e9f0", fontname="Inter", penwidth=1.4, margin="0.20,0.13"]`. But the charting-matrix it declares as law (Rule 6, charting-matrix.md ~line 90) mandates: "Boxes carry minimum padding `margin=\"0.22,0.14\"`" — and graphviz-patterns.md Pattern 0 (~line 22) uses `margin="0.22,0.14"` as the universal preamble value. The handler's own template is below the stated minimum.

**Recommendation:** Change the preamble to `margin="0.22,0.14"` (and note Rule 6's escalation to `0.26,0.16` for >2-line labels). Also fold in Pattern 0's failure-preventing layout keys the preamble silently drops: `splines=spline` (failure F3 fix), `nodesep=0.30` (F2 fix), `ranksep=0.50`, `compound=true` — without them every diagram starts in a state the failure catalogue says to stop and fix.

### 2. [HIGH] No failure-mode handling for absent or failing tools — dot is only 'recommended', rsvg-convert only 'optional'

**Evidence:** The handler hard-depends on two binaries with zero preflight or fallback: ~line 54 `dot -Tsvg "<doc-dir>/diagrams/NN-name.dot" -o ...` and ~lines 60-61 `rsvg-convert -b "#000000" ...`. Yet pressroom's own skills/check/requirements.tsv tiers them as `dot ... recommended` (line 12) and `rsvg-convert ... optional` (line 18). The dark-mode canon §5 explicitly offers an alternative (`# or: magick -background "$bg" ...`) the handler omits. There is also no instruction for a DOT parse/render failure (handler-mermaid's ecosystem has an F12 pre-render parse-check; graphviz has nothing) or for a malformed/incomplete SPEC.

**Recommendation:** Add a Preflight step: `command -v dot || <report capability-missing to orchestrator with the requirements.tsv install line>`; for rasterisation, fall back `rsvg-convert → magick -background → dot -Tpng` (per canon §5). Add a render-failure protocol: capture `dot` stderr, fix the .dot, never hand back an asset that did not render. Add a SPEC-validation gate: if `intent`/`message`/`diagram_type`/`ab.axis_of_divergence`/`target` are missing or contradictory, return the defect to the orchestrator instead of guessing — the handler 'produces, does not orchestrate', so it must also not silently repair its contract.

### 3. [HIGH] Load-bearing references unresolvable at runtime — no ${CLAUDE_PLUGIN_ROOT} anywhere in the agent

**Evidence:** Every doctrine document the handler MUST read is addressed by a repo-relative markdown link, e.g. ~line 25: "read [`charting-matrix.md`](../skills/rich-pdf-with-diagrams/references/charting-matrix.md)". `grep -c CLAUDE_PLUGIN_ROOT agents/handler-graphviz.md` = 0. A spawned subagent's cwd is the user's project, not `plugins/pressroom/agents/`, so `../skills/...` resolves to nothing at runtime; the agent must guess where the canon lives. Compare foundry's handler-ansible.md ~line 31: "Read `${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/implementation-covenant.md` before starting any work." — the house pattern for exactly this. The self-containment law says plugin files resolve paths only through ${CLAUDE_PLUGIN_ROOT}.

**Recommendation:** Keep the markdown links for human browsing but make the operative read instructions runtime-resolvable: "Read `${CLAUDE_PLUGIN_ROOT}/skills/rich-pdf-with-diagrams/references/charting-matrix.md`, `.../references/graphviz-patterns.md`, and `${CLAUDE_PLUGIN_ROOT}/skills/illustrator/references/dark-mode-canon.md` before drafting." (All paths stay intra-plugin, so self-containment is preserved.) Apply the same fix to the self-improvement section's three references.

### 4. [HIGH] Accessibility gate ignored — handler never consumes alt_text and emits SVGs with a meaningless <title>G</title>

**Evidence:** spec-schema.md ~line 54: "`alt_text` | **mandatory.** ... Accessibility is a design-reviewer GATE — a missing/empty `alt_text` blocks PASS." The sibling handler-mermaid.md ~line 52 enforces its half: "Always declare `accTitle:`/`accDescr:` (mmdc emits them as `<title>`/`<desc>` — accessibility gate)." handler-graphviz's Research step (~line 34) reads only "`intent`, `message`, `diagram_type`, and `ab.axis_of_divergence`" — `alt_text` is never mentioned anywhere in the file, and the template names the digraph `G` (~line 41), so `dot -Tsvg` emits `<title>G</title>` as the figure's accessible name.

**Recommendation:** Mirror the mermaid gate: name the digraph meaningfully (the SVG `<title>` comes from the graph name) and set a graph-level `tooltip`/`label` derived from the SPEC's `alt_text` (Graphviz supports `tooltip` on graph/cluster/node/edge for svg output — graphviz.org/docs/attrs/tooltip); add a self-review check that the emitted SVG's `<title>` states the figure's message, not "G". Add `alt_text` to the Research read-list.

### 5. [MEDIUM] graphviz-patterns.md is a light-mode corpus quoted as doctrine with no restyle instruction beyond colour

**Evidence:** The handler (~line 26) says "pick a pattern from graphviz-patterns.md", whose Pattern 0 (~lines 11-23) commands "Every diagram begins with this preamble. Copy-paste, then customise" — a preamble with `fontname="Helvetica"`, light fills (`#f6f8fa`, `#cfe1ff`), opaque light cluster grounds (`bgcolor="#eef4ff"`, ~line 66), and a light-mode palette table. The handler's only counter-instruction is colour-scoped (~line 27: "Every colour comes from the dark-mode canon"), leaving fonts, cluster bgcolor opacity, and the explicit "copy-paste" command in direct conflict for a cold-start agent.

**Recommendation:** Add one explicit precedence sentence: "Take TOPOLOGY (rank structure, clusters, staggering) from graphviz-patterns; take ALL styling — colours, fonts, cluster grounds — from the dark-mode canon §4. Pattern preambles and palettes are light-mode legacy; never copy-paste them. Cluster fills use `surface`/`surface-raised` or no fill, never an opaque light bgcolor."

### 6. [MEDIUM] Matrix-scan threshold cited against the wrong section and in the wrong units for the target

**Evidence:** ~line 65: "**Matrix scan** — boxes ≥5mm at target, no text touching edges, no illegible fan-out (charting-matrix §6)." Charting-matrix §6 is "THE FAILURE CATALOGUE" and contains no 5mm rule — its text-size gate is F1 "Text inside boxes <8pt". The 5mm figure comes from rich-pdf-with-diagrams/SKILL.md (~line 158, "boxes <5mm wide"), and mm is undefined for the SPEC's `target.width_budget_px` (e.g. 800px markdown embed) without a DPI assumption.

**Recommendation:** Restate the gate in target-native, checkable terms: "at `width_budget_px`, rendered label text ≥ 12px equivalent (≈ F1's 8pt at print) and every box ≥ ~1/16 of the budget width; verify by comparing the SVG `viewBox`/`width` to `target.width_budget_px` before rasterising." Cite §6/F1 for the failure mode and Rule 1 for the 4-across law.

### 7. [MEDIUM] Reads the deprecated SPEC field: `target.format` instead of `target.output_format`

**Evidence:** ~line 52: "Render to SVG (the SPEC's `target.format`)". The SPEC contract (spec-schema.md ~line 53) states: "`target.output_format` | `svg` for the four vector handlers ... `target.format` is kept as the legacy alias." The handler binds itself to the legacy alias, so a SPEC emitted without the alias would leave the handler reading a missing field.

**Recommendation:** Change to "Render to the SPEC's `target.output_format` (svg for this handler; `target.format` is a legacy alias you may encounter in old SPECs)".

### 8. [MEDIUM] fontname="Inter" with no availability check — silent metric/render mismatch when Inter is not installed

**Evidence:** ~line 45 pins `fontname="Inter"` with no fallback or check. Graphviz computes node sizes from the font it resolves via fontconfig; if Inter is absent, dot lays out with a substitute while `-Tsvg` still writes `font-family="Inter"` into the SVG — the host then renders different metrics and text can overflow or clip box boundaries. The mermaid sibling at least declares a stack (`'Inter, ui-sans-serif, system-ui'`, handler-mermaid.md ~line 49); the requirements.tsv has no font entry at all.

**Recommendation:** Add a preflight `fc-list | grep -qi inter` check; when absent, use `fontname="Inter,system-ui,sans-serif"` (Graphviz passes the stack through to SVG while fontconfig resolves the first available for metrics) and treat the dual-ground rasters as the metric truth — the Read-with-vision step must explicitly check for text overflowing box borders, the symptom of this mismatch.

### 9. [MEDIUM] Covenant is present but thinner than the house contract — no SUBJECT_MATTER_UNDERSTANDING, no halving clause

**Evidence:** ~line 73: "Carries the SOLID covenant." — one sentence plus lesson-routing. The marketplace contract is that every agent carries the SOLID covenant AND the project's SUBJECT_MATTER_UNDERSTANDING; compare foundry handler-ansible.md ~line 10: "Carries the SOLID self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." Neither SUBJECT_MATTER_UNDERSTANDING nor the knowledge-parity obligation appears anywhere in handler-graphviz.md (this gap is shared by all pressroom handlers — handler-mermaid.md ~line 73 is identically thin).

**Recommendation:** Extend the covenant section: state SUBJECT_MATTER_UNDERSTANDING explicitly — the handler must reach parity with the SPEC's subject (read the `site.doc` section being illustrated, not just the SPEC fields) before drafting, since a structurally-correct diagram of a misunderstood system is a confident lie. Note this should be fixed plugin-wide, not only here.

### 10. [LOW] Research step omits SPEC fields the handler is contractually bound by: site, audience, constraints, alt_text

**Evidence:** ~line 34: "Read the SPEC's `intent`, `message`, `diagram_type`, and `ab.axis_of_divergence`" — four of the schema's fields. `audience` (calibrates label density/jargon), `constraints.max_boxes_per_row` (may be tighter than 4), `site.doc`/`anchor` (the surrounding prose the figure must agree with), and `alt_text` are never read.

**Recommendation:** Expand the Research read-list to the full SPEC: intent, message, audience, diagram_type, constraints (honour max_boxes_per_row when < 4), target, alt_text, ab — and skim the `site.doc` anchor section for terminology the labels must match.

## Capability-uplift proposals

### 1. No rank-discipline doctrine — the dot ranking engine is driven blind

**Proposal:** Add a "Rank control" subsection to Draft: "The dot engine assigns ranks from edge direction; you steer it, never fight it with whitespace hacks. (1) Pin peers with anonymous subgraphs: `{ rank=same; a; b; c }`; pin entry/exit rows with `rank=source` / `rank=sink` (valid values: same|min|source|max|sink). (2) Set `newrank=true` at graph level whenever you use rank constraints together with clusters — without it, rank=same across cluster boundaries is ignored. (3) An edge that exists for meaning but must not deform the hierarchy gets `constraint=false`; an edge that must stay short and straight gets `weight=10`. (4) Keep a column of nodes vertically aligned with a shared `group="colname"` attribute. Sketch the intended rank grid BEFORE writing edges — every 4×9 fit failure is a rank-assignment failure first."

**Rationale:** The handler's only layout levers today are rankdir and "pick a pattern". Graphviz's own docs (graphviz.org rankType, constraint attrs; grid.gv gallery example using rank=same + edge weights) show rank pinning is THE mechanism for the 4×9 matrix the handler is sworn to — and `newrank=true` is the classic silent failure when clusters are involved, which the patterns doc mandates (Rule 3: cluster by named phase).

### 2. No edge-routing or port discipline — edges through boxes (failure F3) has no doctrine beyond 'try splines=spline'

**Proposal:** Add an "Edge routing & ports" subsection: "(1) Default `splines=spline`; switch to `splines=ortho` for layered-architecture and bus diagrams where right-angle channels read cleaner (note: ortho disables edge labels' background masks — keep labels short or use xlabel). (2) Attach edges at the semantically correct face with compass ports: `a:s -> b:n` for flow, `a:e -> b:w` inside a rank — this kills the loop-back arcs that cross node bodies. (3) For record-like nodes built from HTML labels, declare `PORT="f1"` on the TD and target `node:f1:e` so the edge meets the exact cell. (4) Tune `nodesep`/`ranksep` before accepting a crossing; set `concentrate=true` to merge parallel edge bundles in fan-ins. Self-review must name the worst edge crossing and either justify or fix it."

**Rationale:** Failure F3 ("Edges crossing through boxes") is in the failure catalogue the handler must enforce, but the handler carries zero routing vocabulary. Graphviz docs show ports (head/tailport, compass points, HTML-label PORT cells) are the standard fix; the structs/HTML-table examples in the official docs all drive edges into PORT cells.

### 3. No HTML-like label capability — multi-field nodes get crammed into plain labels or faked with \n

**Proposal:** Add an "HTML-like labels" subsection: "When a node carries structured content (name + role + state; a table of fields; an icon row), use an HTML-like label, not \n-packed text: `shape=plaintext` + `label=<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="6" COLOR="#9aa2c0"><TR><TD BGCOLOR="#2a2a3c"><FONT COLOR="#e6e9f0"><B>Title</B></FONT></TD></TR><TR><TD BGCOLOR="#1e1e2e" PORT="body"><FONT COLOR="#b8bed0">detail</FONT></TD></TR></TABLE>>`. Canon mapping: TABLE COLOR = `stroke` #9aa2c0, header TD BGCOLOR = `surface-raised` #2a2a3c, body TD BGCOLOR = `surface` #1e1e2e, FONT COLOR = `text`/`text-dim`. Never leave a TD without BGCOLOR (it would be transparent and its text must then clear both grounds). Give edge-targeted cells a PORT. One nesting level max — deeper tables blow the 4×9 box budget."

**Rationale:** HTML-like labels are core modern Graphviz craft (official shapes.html doc: TABLE/TD with BGCOLOR, PORT, ROWSPAN/COLSPAN) and the only way to do header+body nodes that the architecture/layered-stack diagrams this handler owns constantly need. Neither the handler nor graphviz-patterns.md mentions them, and they interact non-trivially with the dark-mode canon (per-cell BGCOLOR), so the doctrine must live here.

### 4. No adaptive-SVG craft — the handler targets one static compromise palette when Graphviz can emit class-addressable, CSS-themable SVG

**Proposal:** Add a "Progressive enhancement (optional, after the base gates pass)" subsection: "Graphviz supports `class="phase-cluster"` on nodes/edges/clusters (multiple space-separated classes) and a graph-level `stylesheet="..."` attribute that links CSS into the SVG header. For HTML-host embeds you may add classes and a small inline `@media (prefers-color-scheme: light)` block that nudges `stroke`/`text-dim` darker on light hosts — mirroring the hand-SVG canon's media-query enhancement. Two GUARDRAILS: (a) Graphviz writes literal fill/stroke attributes on elements which override external CSS — adaptive styling needs the classes plus a post-render sed/xmlstarlet pass replacing the hardcoded hex with `var(--token, <base-hex>)` fallbacks; (b) GitHub `<img>` embeds sandbox external stylesheets and many renderers ignore media queries, so the BASE colours must already clear both §3 contrast gates — the media query is garnish, never the gate."

**Rationale:** Researched: the official `stylesheet` and `class` attributes (graphviz.org/docs/attrs/stylesheet, /docs/attrs/class) plus the documented technique of piping SVG through sed to swap hardcoded colours for CSS variables under prefers-color-scheme (noncombatant.org 2024 'Styling Graphviz with CSS'). The dark-mode canon already blesses exactly this pattern for handler-composition (§4 'Hand SVG' optional media query); the Graphviz handler is the only SVG handler without it.

### 5. No large-graph decomposition toolkit — 'decompose' is commanded but no mechanism is given

**Proposal:** Add a "Taming a graph that won't fit" subsection, in escalation order: "(1) `unflatten -l 3 -f` preprocesses a wide fan-out (1→N) by staggering leaf ranks — run it when a single rank exceeds 4 boxes: `unflatten -l 3 -f in.dot | dot -Tsvg -o out.svg`. (2) `concentrate=true` merges parallel edges sharing a path segment — use for many-to-one fan-ins (failure F11's tangle). (3) Collapse a finished subsystem to ONE summary node carrying an HTML-label title bar; the subsystem becomes its own figure (the SPEC's one-message law: a figure with two messages is two figures). (4) Cluster-level edges: set `compound=true` and `lhead=cluster_x`/`ltail=cluster_y` so one edge represents cluster→cluster instead of a node-product spray. (5) If the structure is genuinely non-hierarchical (peer mesh, hub-and-spoke), say so in the hand-back — `neato`/`sfdp`/`twopi` exist but produce organic layouts that rarely pass the 4×9 grid; prefer re-decomposition. Hand back the decomposed SET with a one-line map of which figure carries which message."

**Rationale:** The handler's prime directive says "or you decompose" but gives zero mechanics. `unflatten` and `concentrate` are the standard Graphviz tools for exactly the fan-out/tangle failures (F11, Rule 5 'wide fan-outs wrap') in the charting matrix; `compound`+`lhead/ltail` is the documented cluster-edge idiom. Without this section every oversized SPEC becomes improvisation.

### 6. No deterministic pre-vision lint pass — every check rides on the vision Read, which is the most expensive and least repeatable gate

**Proposal:** Add a "Deterministic lints (run BEFORE the vision pass)" subsection: "(1) Parse gate: `dot -Tcanon in.dot > /dev/null` — a non-zero exit is a syntax defect; fix before any render (the graphviz analogue of the mermaid F12 parse-check). (2) Size gate: extract the emitted `viewBox` (`grep -o 'viewBox="[^"]*"' out.svg`) and compute effective px-per-box at `target.width_budget_px`; a box narrower than budget/16 or label text computed under ~12px fails the matrix BEFORE you spend a vision call. (3) Forbidden-token lint: grep the SVG for `fill="white"`, `fill="#ffffff"` on non-text shapes, `font-family` not in the approved stack, and any hex not in the canon §2 palette — each hit is a canon escape. (4) Title gate: the first `<title>` element must not be a bare graph variable name (`G`, `g`, `DiagramName`). Only after all four pass do you rasterise both grounds and Read with vision." 

**Rationale:** The handler's self-review is 100% vision-dependent (two rasters + Read), which is slow, token-expensive, and non-reproducible — while the failure catalogue's most frequent defects (parse errors, white fills, sub-legible scale, dead titles) are all greppable. The canon §5 already models one cheap structural lint (the full-bleed-rect grep); this generalises it into a proper deterministic gate tier, matching the marketplace's quality-first/waste-elimination pillars.
