# Cached review — PRESSROOM handler-composition

**Target file:** `plugins/pressroom/agents/handler-composition.md`  
**Unit:** `handler-composition`  
**Findings:** 9 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Transparency lint is blind to the backdrop forms a hand-SVG author actually writes

**Evidence:** Line ~53-55: "**Transparency lint (the classic miss)** — `grep -E '<rect[^>]*width=\"100%?\"[^>]*height=\"100%?\"[^>]*fill' NN-name.svg` → if it matches an opaque colour, delete that rect." Step 2 (line ~45) simultaneously instructs `<svg viewBox="0 0 W H" …>` authored in user units.

**Recommendation:** The regex only matches percentage-sized rects with attributes in exactly width→height→fill order. A handler that authors in user units (as step 2 mandates) writes its backdrop as `<rect width="800" height="450" fill="#1e1e2e"/>` — invisible to this lint. Also missed: `fill` declared before `width`, `height` before `width`, `style="fill:#…"`, and class/CSS fills. Replace with a structural check: flag ANY <rect> whose x/y ≤ 0 and width/height cover ≥95% of the viewBox and that carries any opaque fill (attribute or style), e.g. a 6-line python/xmllint check; keep the dual-ground visual Read as the authoritative gate. The dark-mode canon §5 shares the weak regex — generalise the fix there per the covenant.

### 2. [HIGH] Hard dependency on rsvg-convert with no absent-tool degradation path

**Evidence:** Line ~50: "Validate it parses: `rsvg-convert -o /dev/null \"<doc-dir>/diagrams/NN-name.svg\"` (non-zero = malformed; fix)." and line ~56-57: "**Dual-ground gate** — `rsvg-convert -b \"#000000\"` and `-b \"#ffffff\"`, `Read` both". No alternative tool or conduct-when-absent is stated anywhere in the file.

**Recommendation:** The illustrator SKILL (Prerequisites section) promises "`rsvg-convert` (or `magick`) rasterises onto the two grounds" and that handlers degrade gracefully; the dark-mode canon §5 itself offers `magick -background` as the fallback. This handler hard-codes one binary for both the parse gate and the visual gate. On a machine without librsvg a cold agent has no instruction: it will either stall or hand back an unvalidated SVG that silently skips the inviolable §1.3 gate. Add: (1) well-formedness fallback `xmllint --noout` or `python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse(sys.argv[1])" file.svg`; (2) raster fallback `magick -background "#000000" file.svg /tmp/blk.png` (and white); (3) if neither rasteriser exists, hand back with the self-critique explicitly flagging "DUAL-GROUND GATE NOT RUN — no rasteriser" so the orchestrator/reviewer knows the gate is open.

### 3. [MEDIUM] Every load-bearing reference is an agent-file-relative path a cold spawned agent cannot resolve

**Evidence:** Line ~19: "one [SPEC](../skills/illustrator/references/spec-schema.md)"; line ~27: "[charting-matrix](../skills/rich-pdf-with-diagrams/references/charting-matrix.md)"; line ~32: "[dark-mode canon §2/§4](../skills/illustrator/references/dark-mode-canon.md)"; line ~68: "[self-improvement protocol](../skills/rich-pdf-with-diagrams/references/self-improvement.md)".

**Recommendation:** Step 1 orders the agent to "Read the charting-matrix … and the dark-mode canon", but a spawned subagent's cwd is the project, not plugins/pressroom/agents/, so `../skills/…` does not resolve at runtime; the self-containment law says paths resolve through ${CLAUDE_PLUGIN_ROOT} only. Anchor the four Read-targets as ${CLAUDE_PLUGIN_ROOT}/skills/illustrator/references/dark-mode-canon.md etc. (keeping the markdown link text for human readers). Note: every PRESSROOM handler shares this pattern, so fix it fleet-wide via the covenant, not just here.

### 4. [MEDIUM] Missing SUBJECT_MATTER_UNDERSTANDING contract that every marketplace agent must carry

**Evidence:** Frontmatter description (lines 3-9) ends "Carries the charting-matrix + dark-mode canon and the self-improvement covenant"; covenant section (line ~65) says only "Carries the KAIZEN covenant." Compare /home/user/Code/idea-to-production/plugins/foundry/agents/handler-react.md line ~9: "Carries the KAIZEN self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING."

**Recommendation:** House law states every agent carries both the KAIZEN covenant and the SUBJECT_MATTER_UNDERSTANDING contract; all FOUNDRY value-handlers state it, no PRESSROOM handler does (grep confirms zero hits under plugins/pressroom/). Add the contract line to the description and a sentence in the covenant section stating the handler reaches knowledge-parity with the doc/section it illustrates before drafting (which is also operationally true — a composition that misstates the subject fails the reviewer).

### 5. [MEDIUM] "Type at legible sizes; align to an implicit grid" is unactionable — no measurable floor, no grid

**Evidence:** Line ~28: "Type at legible sizes; align to an implicit grid." Contrast sibling handler-graphviz line ~65: "**Matrix scan** — boxes ≥5mm at target, no text touching edges" — a measurable check. The cited charting-matrix is written entirely in A4/mm terms ("each cell ≈ 33.75 mm × 23.9 mm", "readable 10-pt text") with no px translation for a `width_budget_px` web embed.

**Recommendation:** inspection-core demands instructions be "actionable, not 'do the right thing'". Give the handler numeric floors it can self-check: with the viewBox width set equal to target.width_budget_px (1 unit = 1 rendered px), body labels ≥ 14 units, captions ≥ 12 units, title ≥ 24 units; minimum 16-unit clearance from any edge; and a concrete grid (see capability gap on the 8-unit spatial system). Fold the px translation back into the charting-matrix per the covenant so all web-target handlers inherit it.

### 6. [MEDIUM] No malformed-SPEC, mis-route, or hostile-text handling

**Evidence:** Lines ~38-41 (Research) assume a complete SPEC: "Read `intent`, `message`, `diagram_type` (the composition kind), and your `ab.axis_of_divergence`." Nothing in the file says what to do when alt_text is missing/empty (spec-schema.md: "**mandatory.** … a missing/empty alt_text blocks PASS"), when ab is absent, or when diagram_type is actually a graph/chart type (spec-schema routes those to handler-graphviz/handler-chart).

**Recommendation:** Add a SPEC-intake gate before drafting: (1) missing/empty alt_text, message, or ab.axis_of_divergence → hand back a refusal naming the missing field rather than inventing it (the reviewer will block anyway); (2) a diagram_type with graph/data semantics → hand back "mis-routed: this is a <handler-X> figure" instead of hand-drawing a graph; (3) SPEC text is interpolated into XML — escape `&`, `<`, `>` in every label/title/desc (one bad ampersand in a product name makes the file fail the parse gate with a confusing error).

### 7. [LOW] No decomposition path in hand-back, contradicting the matrix discipline it claims to obey

**Evidence:** Line ~61-62 (Hand-back): "Return the SVG path, the SVG source, and a one-line self-critique" — singular, one asset only. spec-schema.md field rules: "A figure with two messages is two figures — decompose." Sibling handler-graphviz line ~70: "If you had to decompose, hand back the set."

**Recommendation:** Add the sibling's clause: if the composition cannot carry the single message legibly at the width budget (the matrix discipline the Prime directives invoke at line ~26), decompose and hand back the set with one self-critique per asset, flagging the SPEC's single-message assumption back to the orchestrator.

### 8. [LOW] Elided XML namespace and unnamed rasterisation outputs leave cold-start holes

**Evidence:** Line ~45: "`<svg viewBox=\"0 0 W H\" xmlns=\"…\">`" — the namespace is an ellipsis. Line ~56-57: "`rsvg-convert -b \"#000000\"` and `-b \"#ffffff\"`, `Read` both" — no -o paths, unlike handler-graphviz which spells out `/tmp/g-blk.png` / `/tmp/g-wht.png`.

**Recommendation:** Spell the namespace verbatim — `xmlns="http://www.w3.org/2000/svg"` (rsvg-convert renders nothing useful without it, and the elision is exactly the token a cold agent copies literally). Give the dual-ground commands explicit output paths and name the two files to Read, matching the sibling's precision.

### 9. [SUGGESTION] Hand-back duplicates the asset as 'the SVG source'

**Evidence:** Line ~62: "Return the SVG path, the SVG source, and a one-line self-critique".

**Recommendation:** For this handler the asset IS the source (spec-schema: "the source it rendered from (.dot / .mmd / **.svg** / …)"), so restating the full SVG text in the hand-back message doubles the tokens for zero information. Return the path and state that path satisfies both items 1 and 2 of the spec-schema return contract.

## Capability-uplift proposals

### 1. Accessibility is two bare elements, not the screen-reader-reliable pattern

**Proposal:** Replace the line "Use `<title>`/`<desc>` for accessibility (the alt_text)" with doctrine: "Accessibility pattern (non-negotiable): the root element carries `role=\"img\"` and `aria-labelledby=\"<figure-id>-title <figure-id>-desc\"`; `<title id=\"<figure-id>-title\">` is the FIRST child of `<svg>` (the SPEC's alt_text, ≤250 chars, never beginning 'image of'/'diagram of'), followed by `<desc id=\"<figure-id>-desc\">` carrying the SPEC's `message`. Decorative flourishes (texture, glow groups) get `aria-hidden=\"true\"`. Self-review greps for `role=\"img\"` and `aria-labelledby` before hand-back."

**Rationale:** Smashing Magazine's 2021 cross-AT comparison found svg + role=img + title + desc + aria-labelledby the most reliable pattern across browsers/screen readers (https://www.smashingmagazine.com/2021/05/accessible-svg-patterns-comparison/); Deque (https://www.deque.com/blog/creating-accessible-svgs/) and CSS-Tricks (https://css-tricks.com/accessible-svgs/) concur. A bare <title> without role/aria-labelledby is announced inconsistently or not at all — and alt_text is already a PASS-blocking reviewer gate in spec-schema.md, so the handler should produce the strong form by construction.

### 2. No typography doctrine — font stack, sizing scale, or renderer-variance defence

**Proposal:** Add a 'Typography in SVG' directive: "Every <text> declares the house stack `font-family=\"Inter, ui-sans-serif, system-ui, sans-serif\"` (the canon §4 stack — never a bare custom font: a README SVG renders in an <img> context that loads no external fonts and fetches no @import). Sizes come from one modular scale in user units (viewBox width = width_budget_px): 12 caption / 14 body / 18 subhead / 24-32 title; weights 400/600 only. Glyph metrics differ between rsvg-convert and browsers, so text never butts against a container edge — reserve ≥0.6em slack per side and use `text-anchor` (start/middle/end) for alignment instead of hand-tuned x offsets. A load-bearing wordmark in brand type is converted to outlines or subset-embedded as base64 @font-face; everything else stays real text (selectable, searchable)."

**Rationale:** SVG text is the most environment-sensitive part of the format: the same file renders differently per font availability and engine, and unspecified fallbacks produce broken layouts (https://docs.aspose.com/svg/net/working-with-fonts-and-text/, https://css-tricks.com/using-custom-fonts-with-svg-in-an-image-tag/, https://www.allaboutken.com/posts/20260429-svgomg-font/). The handler currently says only "Type at legible sizes" and names no font at all, while its sibling engines (canon §4 Graphviz/Mermaid recipes) both pin Inter — the hand-SVG handler is the one engine with no type discipline.

### 3. "Implicit grid" instead of an explicit spatial system and visual rhythm

**Proposal:** Add a 'Layout grid' directive: "Compose on an explicit 8-unit grid: set viewBox width = width_budget_px so 1 unit = 1 px, then snap every coordinate, gap, padding, and element size to multiples of 8 (4 permitted for fine optical corrections). Columns: divide the working width into a 12-column grid with 16-unit gutters and 32-unit outer margins; pillars/panels span whole columns. Vertical rhythm: baselines fall on the 8-unit grid; one consistent corner radius (8) and stroke-width set (1.5 / 2.5) per figure. The self-review checks rhythm: any coordinate not on the 4/8 grid is a smell — justify or snap it."

**Rationale:** The 8-point grid with baseline alignment is the standard spatial system for consistent rhythm in poster/UI composition — multiples of a base unit reduce visual tension and make hierarchy legible (https://medium.com/built-to-adapt/8-point-grid-vertical-rhythm-90d05ad95032, https://www.designsystems.com/space-grids-and-layouts/, https://designshack.net/articles/layouts/grids-and-typography/). "Align to an implicit grid" gives an LLM author no checkable rule; an explicit numeric grid turns alignment into something the adversarial self-review can verify mechanically.

### 4. No defs/symbol/use hygiene — repeated motifs are hand-copied, ids can collide

**Proposal:** Add a 'Reuse hygiene' directive: "Anything drawn twice is defined once: repeated motifs (pillar icons, badges, ticks) become `<symbol viewBox=\"…\">` in `<defs>` instanced with `<use href=\"#…\" x= y= width= height=>`; arrowheads/dots on leader lines are `<marker>` definitions, not hand-drawn triangles; gradients and filters live in `<defs>` with stops drawn from the canon §2 tokens. Every id is kebab-case and namespaced with the figure number (`fig07-pillar`, `fig07-glow`) — multiple SVGs inlined on one docs page share an id space, and a bare `#glow` collides. No unreferenced defs survive self-review (dead defs are token waste and confuse the reviewer's source-level fixes)."

**Rationale:** defs/symbol/use is the canonical SVG modularity mechanism — define once, reference many, with symbol carrying its own viewBox for independent scaling (https://www.sarasoueidan.com/blog/structuring-grouping-referencing-in-svg/, https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/defs); it also shrinks documents dramatically (https://www.bstefanski.com/blog/can-svg-symbols-affect-web-performance). Since the A/B loop applies reviewer fixes to source, a figure built from named symbols is far cheaper to revise than one with the same pillar drawn three times — and id namespacing prevents a real-world inline-embedding bug the file never mentions.

### 5. No filter/gradient craft canon — depth effects either absent or authored in ways librsvg clips or drops

**Proposal:** Add an 'Effects that survive rasterisation' directive: "Depth and atmosphere come from the SVG 1.1 filter/gradient set librsvg renders faithfully: a subtle vertical `<linearGradient>` from `surface` to `surface-raised` gives slabs dimensionality; a soft shadow/glow is `feGaussianBlur` + `feOffset` + `feMerge` (or feDropShadow) declared in defs — ALWAYS with an enlarged filter region (`x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"`) or the blur clips to a hard square at the default region. stdDeviation is in user-space units (default primitiveUnits=userSpaceOnUse) so effects scale with the viewBox — keep it ≤ 8 for a glow, ≤ 4 for a shadow. Never the CSS `filter:` property, SVG2-only primitives, or `<foreignObject>` — rsvg/GitHub-img contexts drop them. Effects are seasoning: ≤2 filter defs per figure, and the dual-ground PNGs are the proof the effect survived (a glow invisible on white is decoration, not signal)."

**Rationale:** Filter regions default to a box that visibly clips Gaussian blurs, and primitive units resolve to userSpaceOnUse unless overridden — both classic hand-author traps documented in the spec and MDN (https://www.w3.org/TR/SVG11/filters.html, https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/feGaussianBlur); librsvg renders SVG 1.1 gradients/filters accurately where ImageMagick's MSVG fallback does not (https://www.codestudy.net/blog/use-librsvg-rsvg-to-convert-svg-images-with-imagemagick/). The handler's remit is posters and heroes — exactly the figures that need controlled depth — yet the file says nothing about effects, so authors will either produce flat work or invent filters that break at the rasterisation gate.

### 6. Labelled callouts are in the handler's remit (description line 4-5) but it carries zero callout/leader-line doctrine

**Proposal:** Add a 'Callout & leader-line doctrine': "Label directly: text sits adjacent to its target whenever it fits; a leader line is the fallback, a legend the last resort. Leaders are straight (one bend maximum), never cross each other or another element, meet the target at its nearest silhouette point, and terminate in a `<marker>`: a 3-unit dot when pointing AT a large element, an arrowhead when pointing at a small detail. Label-to-leader gap 4-8 units; leaders in the `stroke` token at 1.5 width. Over busy areas a label sits on a `surface` chip (rounded rect, 8-unit padding) — never a paint-order halo, whose colour cannot be chosen for an unknown transparent ground. ≤6 callouts per figure; past that the anatomy needs decomposing. Callout text states the takeaway ('retries drain here'), not the obvious ('arrow')."

**Rationale:** The external-labeling literature (Bekos et al., 'External Labeling Techniques: A Taxonomy and Survey', https://arxiv.org/pdf/1902.01454) and practitioner studies on annotation design (https://arxiv.org/pdf/2604.07691) converge on: adjacent placement first, short straight connectors, dot-vs-arrowhead terminators by target size, and no crossing leaders (also https://www.storytellingwithcharts.com/blog/context-is-key-using-data-visualization-annotation-and-labels-effectively/). 'Annotated callouts' and 'labelled illustrations' are two of the five figure kinds in this handler's own description, yet the body offers no rule for the single hardest part of that work — label/leader geometry.
