# Self-Improvement Protocol

> **This skill is required to compound.** Every piece of diagram feedback
> received from a user must be absorbed into the charting-matrix and the
> lessons-learned log *before* the next diagram is produced. Without this
> discipline the skill will degrade. With it, the skill gets stricter
> and more reliable on every cycle.

---

## When to run this protocol

Run this protocol when **any** of these occur:

- The user gives feedback on a diagram (size, layout, orientation,
  composition, readability).
- A diagram fails one of the visible failure modes in
  `charting-matrix.md` §6 even though all rules were followed.
- The user requests a revision that adds a new constraint not
  yet codified.

Do **not** run this protocol for:

- Content corrections to a diagram (wrong label, wrong arrow direction)
  — those are local edits, not compositional lessons.
- Stylistic preferences expressed once and not repeated — wait for a
  pattern before promoting to a rule.

---

## The six steps

### Step 1 — Classify

Read the feedback. Ask: *which rule of the charting matrix does this
exercise?*

- If it strengthens an **existing** rule → go to Step 2 with the rule
  number.
- If it exercises a **missing** rule → go to Step 2 and prepare to add
  a new numbered rule.
- If it is ambiguous → ask the user one clarifying question before
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

### Step 3 — Update `charting-matrix.md`

Open `references/charting-matrix.md`.

- **If strengthening an existing rule**: edit the rule's *How to apply*
  paragraph to incorporate the new constraint. Keep the rule's number.
- **If adding a new rule**:
  - Add to §3 EXTRA RULES ADDED BY FEEDBACK CYCLES with the next
    sequential number (R-A1, R-A2, ...).
  - Each new rule must have a *Why* line and a *How to apply* line.
- **If extending the failure catalogue (§6)**: add a new failure mode
  F7, F8, … with root cause and fix.

Always update `charting-matrix.md` *before* the lessons-learned log.
The matrix is the rule; the log is the audit trail.

### Step 4 — Update `graphviz-patterns.md` (if a new pattern emerged)

If the feedback exposes a new diagrammatic pattern not in the existing
seven, add it as **Pattern N+1**. Each new pattern must include:

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

**Charting-matrix rule affected:** [#N existing | R-A1 new | F7 new failure | Pattern 8 new pattern]

**Diagram(s) fixed in this round:** [list of diagram filenames]

**Article:** [path to the article folder]
```

Keep entries in chronological order. Do not edit prior lessons; only
append. The log is the memory.

### Step 6 — Record the skill update

Before re-rendering the affected article, record the lesson. If you are in the pressroom plugin's
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
- 📝 references/charting-matrix.md: [what changed]
- 📝 references/graphviz-patterns.md: [what changed, if anything]
- 📝 references/lessons-learned.md: appended lesson NNNN

ROADMAP: n/a (PRESSROOM self-improvement)
```

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
2. **`charting-matrix.md` § Extra Rules grows** then stops. Same
   signal.
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
