# Self-Improvement Protocol

> **This skill is required to compound.** Every graphical or animation
> lesson — any feedback or review finding about a figure, diagram, or
> animation — must be absorbed into the canon that owns its domain and
> into the lessons-learned log *before* the next build is produced.
> Without this discipline the craft degrades. With it, it gets stricter
> and more reliable on every cycle.

This is the GENERAL graphics-and-animation **review → rule → canon** loop.
It governs static diagrams (its origin), but equally **layout/legibility,
colour/ground, animation/motion, data-viz encoding, typography, and
generative-raster routing**. The source of a finding does not matter — a
maintainer comment, a reviewer `NEEDS_REVISION`, or a machine/raster/vision
catch all enter here and become durable canon.

---

## When to run this protocol

Run this protocol when **any** graphical or animation feedback or review
finding lands:

- A maintainer (or user) gives feedback on a figure, diagram, or
  animation — size, layout, orientation, composition, readability,
  colour, motion, timing, linger.
- A reviewer returns `NEEDS_REVISION` (e.g. the `layout-reviewer`, an
  aesthetic reviewer) on a graphical surface.
- A machine / raster / vision check catches a defect — a
  `layout-check.sh` violation, a `raster-lint.sh` suspect tile, or a
  finding that cost an expensive vision Read (see the
  **expensive-vision mandate** below).
- A diagram fails one of the visible failure modes in
  [`charting-matrix.md`](charting-matrix.md) §6 even though all rules
  were followed.
- A revision adds a new constraint not yet codified.

Do **not** run this protocol for:

- Content corrections (wrong label, wrong arrow direction, a wrong
  caption) — those are local edits, not compositional lessons.
- Stylistic preferences expressed once and not repeated — wait for a
  pattern before promoting to a rule.

---

## The expensive-vision mandate

**Any finding that cost an expensive machine-vision / pixel Read MUST
yield a one-sentence reusable rule, written to the relevant canon, BEFORE
the next build** — ideally turned into a FREE machine/raster check where
possible (a `layout-check.sh` / `raster-lint.sh` heuristic) so the same
defect is caught without spending vision again.

*The budget that found it is only repaid if the lesson becomes a cheap
check or a named rule.* A review that re-discovers the same defect twice
has not honoured this covenant. This mirrors the self-improvement covenant
already carried in
[`layout-canon.md`](../../design-reviewer/references/layout-canon.md) §7.

---

## The six steps

### Step 1 — Classify

Read the finding. Ask two questions: *which DOMAIN does this exercise*
(composition, colour, layout/legibility, animation/motion, data-viz
encoding, typography, generative-raster routing?), and *does it
strengthen an existing rule or expose a missing one?*

- If it strengthens an **existing** rule → go to Step 2 with the rule
  id (and note which canon owns it — see Step 3's routing table).
- If it exercises a **missing** rule → go to Step 2 and prepare to add
  a new numbered rule to the owning canon.
- If it is ambiguous → ask the maintainer one clarifying question before
  proceeding. Do not guess.

### Step 2 — Generalise

Rewrite the feedback as a one-sentence rule. The rule must:

- Strip the specific diagram (no "the system map" or "figure 3").
- Keep the underlying principle (about composition, orientation,
  density, padding, etc.).
- Be **actionable** — a future diagrammer should be able to apply it
  without re-deriving the principle.

Example:

| Feedback (raw) | Generalised rule |
|----------------|------------------|
| "The system map should have a vertical panel of skills on the left and agents on the right" | When a central node has multiple categorical groupings, arrange each group as a vertical panel; pick orientations (left/middle/right) that match semantic primacy |
| "Figure 8 disappears off the bottom" | Every full-page figure must be sized by both `width` and `height` with `keepaspectratio`, and wrapped in `\clearpage` before AND after |
| "The pipeline is too tiny on the page" | Linear pipelines of >4 steps must be grouped into named phases with clusters, stacked vertically, with at most 4 boxes across any cluster |

### Step 3 — Update the RIGHT canon

Route the generalised rule to the canon that **owns its domain**. Do not
collapse every lesson into `charting-matrix.md` — a layout lesson belongs
in the layout canon, a motion lesson in the motion canon, and so on. Use
this table:

| Finding domain | Canon home |
|----------------|------------|
| composition / layout-on-the-page | [`charting-matrix.md`](charting-matrix.md) (§3 *R-A\**, §6 *F\**) |
| colour / ground / transparency | [`dark-mode-canon.md`](../../illustrator/references/dark-mode-canon.md) |
| layout / legibility (clip, overlap, crowding, vertical, z-index, min-text-size, inline-legibility) | [`layout-canon.md`](../../design-reviewer/references/layout-canon.md) (the Phase-1 single source) |
| animation / motion / timing / linger | [`raster-toolchain.md`](../../../knowledge/raster-toolchain.md) — the **"Motion canon"** section |
| data-viz encoding | [`dataviz-canon.md`](../../design-reviewer/references/dataviz-canon.md) |
| typography / DTP | [`typography-canon.md`](../../design-reviewer/references/typography-canon.md) |
| generative-raster routing / model / recipe | [`comfyui-model-guide.md`](../../../knowledge/comfyui-model-guide.md) |

Open the canon the table selects and apply the same mechanics that the
charting matrix has always used, adapted to that canon's numbering:

- **If strengthening an existing rule**: edit the rule's *How to apply*
  paragraph to incorporate the new constraint. Keep the rule's id.
- **If adding a new rule**:
  - Add it under the canon's "extra rules / feedback cycles" section with
    the next sequential id in that canon's scheme. In `charting-matrix.md`
    that is §3 EXTRA RULES ADDED BY FEEDBACK CYCLES, numbered R-A1,
    R-A2, …; other canons use their own rule ids (e.g. a `layout-canon.md`
    checklist item, a Motion-canon motion rule).
  - Each new rule must have a *Why* line and a *How to apply* line.
- **If extending a failure catalogue**: in `charting-matrix.md` §6, add a
  new failure mode F7, F8, … with root cause and fix; other canons take
  the equivalent failure note in their own structure.

Always update the owning canon *before* the lessons-learned log. The canon
is the rule; the log is the audit trail.

### Step 4 — Update `graphviz-patterns.md` (if a new pattern emerged)

`graphviz-patterns.md` remains the graphviz-specific pattern home — it is
not displaced by the Step 3 routing table. If the feedback exposes a new
diagrammatic pattern not in the existing seven, add it as **Pattern N+1**.
Each new pattern must include:

- A one-line "Use for:" sentence.
- A complete, copy-pasteable DOT snippet.
- A "Key tricks" bullet list (3-5 items).

If the feedback is a tightening of an existing pattern, edit that
pattern's "Key tricks" or DOT snippet directly.

### Step 5 — Log in `lessons-learned.md`

Append a numbered lesson:

```markdown
### Lesson NNNN — YYYY-MM-DD

**Feedback received:** [verbatim or close paraphrase]

**Generalised rule:** [the one-sentence principle from Step 2]

**Canon rule affected:** [which canon + rule id — e.g. `charting-matrix.md` R-A1 new | `charting-matrix.md` F7 new failure | `layout-canon.md` checklist item | `raster-toolchain.md` Motion-canon rule | `graphviz-patterns.md` Pattern 8 new]

**Figure(s)/animation(s) fixed in this round:** [list of filenames]

**Article:** [path to the article folder]
```

Keep entries in chronological order. Do not edit prior lessons; only
append. The log is the memory.

### Step 6 — Record the skill update

Before re-rendering the affected article, record the lesson. If you are in the publish plugin's
own source repository, commit it there; otherwise surface the generalised rule to the user to fold
upstream:

```bash
git add skills/rich-pdf-with-diagrams/
git commit -m "skill: rich-pdf-with-diagrams — absorb lesson NNNN ([short topic])"
```

Commit message format (`COMMIT_MESSAGE.md` rules):

```
skill: rich-pdf-with-diagrams — absorb lesson NNNN ([short topic])

WHY:
[One sentence: what feedback prompted the lesson and which rule changed.]

WHAT:
- 📝 [the routed canon, e.g. references/charting-matrix.md | design-reviewer/references/layout-canon.md | knowledge/raster-toolchain.md]: [what changed]
- 📝 references/graphviz-patterns.md: [what changed, if anything]
- 📝 references/lessons-learned.md: appended lesson NNNN

ROADMAP: n/a (PUBLISH self-improvement)
```

---

## Maintainer feedback intake

This is the documented path for a **batch** of comprehensive graphical
feedback — the maintainer (or a reviewer) hands over a list of findings
across many figures and animations at once. This same intake receives a
reviewer's `NEEDS_REVISION` findings and the maintainer's comments
alike; they are not different procedures.

Process the batch **item-by-item**. For EACH item, run the full loop:

1. **Classify** (Step 1) — name the domain and whether it strengthens or
   adds a rule.
2. **Generalise** (Step 2) — rewrite it as a one-sentence rule that
   strips the specific figure.
3. **Route to the right canon** (Step 3) — use the routing table; a
   layout item lands in `layout-canon.md`, a motion item in the Motion
   canon of `raster-toolchain.md`, a colour item in `dark-mode-canon.md`,
   and so on.
4. **Log** in [`lessons-learned.md`](lessons-learned.md) (Step 5) — one
   lesson per item.
5. **Commit** (Step 6) — one commit per lesson.

**Never patch one figure and move on** — that fixes the symptom and loses
the lesson, so the same class of defect recurs on the next build. A batch
of feedback is processed one item at a time precisely so that each item
becomes durable canon, not a one-off touch-up. Ten figures fixed without
ten rules recorded is ten lessons lost.

---

## Anti-protocol — what NOT to do

| Don't | Why |
|-------|-----|
| Apply the fix to the current article without updating the skill | The same mistake will recur next time |
| Update the skill without testing the fix on the current article | The rule is unproven |
| Tighten a rule based on a single piece of feedback without recording the case | The log preserves context for future re-evaluation |
| Add a rule that contradicts an existing one | Surface the contradiction to the user; do not silently override |
| Bundle multiple lessons into a single commit | One commit per lesson keeps the audit trail clean |

---

## The compounding effect

This is the math of the discipline:

- **Cycle 1** (first article): N pieces of feedback land. All are
  absorbed. The rule set grows by N.
- **Cycle 2** (next article): the rule set prevents most of the
  original N issues. New feedback exposes a smaller M < N issues. M
  are absorbed.
- **Cycle k**: feedback converges toward zero on composition issues.
  The user's attention focuses entirely on content.

The promise of this skill is that **eventually, the diagram-feedback
conversation goes to zero**, and the only remaining conversation is
about what the diagrams *say*. That is the goal.

---

## How to know it's working

Three observable signals that the protocol is functioning:

1. **The lessons-learned log grows steadily** in early articles, then
   plateaus. A flat log is a sign the rules have stabilised.
2. **The routed canons grow** their feedback-cycle rules (`charting-matrix.md`
   § Extra Rules, `layout-canon.md` checklist items, the Motion canon
   verbs, …) then stop. Same signal.
3. **The user's diagram feedback shortens** over successive
   articles, from "redraw all of these" to "minor tweak on figure 3"
   to "all the diagrams look great."

If any of these signals are not appearing, audit the protocol — either
the classifications are wrong, the generalisations are too narrow, or
the rules are being added but not consulted.

---

## Cross-skill responsibility

If feedback received here exposes a rule that belongs in a sibling
skill (e.g. `writer`, or a foundry skill), surface it to the user — or, in
the marketplace's source repo, propose the change to that skill directly. Do
not silently transplant rules across skill boundaries.
