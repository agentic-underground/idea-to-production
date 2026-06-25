# Interaction laws — the UX laws · Nielsen's heuristics · Norman's delight

> The behavioural layer: whether a screen is *usable, learnable, and delightful*. Visual foundations get
> the eye to the right place; these get the hand to the right outcome — and leave the user feeling good.

## 1. The UX laws (predictive models of behaviour)

Cite the law by name; each gives a concrete, checkable prediction.

| Law | What it predicts | Apply / flag |
|---|---|---|
| **Fitts's Law** | Time-to-target grows with distance and shrinks with target size. | Primary actions: large and near the likely cursor/thumb. Touch targets ≥44×44px (≥24px min per WCAG 2.2 *Target Size*). *Flag:* tiny/crowded tap targets; a destructive action adjacent to a common one. |
| **Hick's Law** | Decision time grows with the number/complexity of choices. | Reduce and group options; progressive disclosure; sensible defaults. *Flag:* a wall of equally-weighted choices; a 12-item menu with no grouping. |
| **Miller's Law** | ~7±2 items in working memory; chunk to cope. | Chunk long strings/lists (phone numbers, IDs); ≤~5 inputs per group. *Flag:* ungrouped 20-field forms. |
| **Jakob's Law** | Users expect your site to work like the others they know. | Reuse conventions (nav position, icon meaning, form patterns) unless you have a *proven* reason. *Flag:* novelty that taxes recognition for no gain. |
| **Zeigarnik effect** | Unfinished tasks are remembered; progress pulls completion. | Progress indicators, checklists, saved drafts. |
| **Aesthetic-Usability effect** | Beautiful designs are *perceived* as more usable (and forgiven more). | Polish is not vanity — it buys trust and tolerance. But it can mask usability flaws in testing: never let beauty excuse a broken path. |
| **Doherty threshold** | Productivity soars when system response <400ms. | Optimistic UI, skeletons, instant feedback. *Flag:* unacknowledged waits. |
| **Tesler's Law** | Complexity is conserved — someone bears it. | Move inherent complexity *off* the user (smart defaults), don't just hide it. |
| **Postel's Law** | Be liberal in what you accept (input), conservative in what you emit. | Forgiving inputs (paste any phone format), precise outputs. |

> **Peak-end & serial-position:** users judge an experience by its peak and its end, and remember the
> first and last items best. Design the peak (the delightful moment) and the end (a clean confirmation),
> and put the most important list items first and last.

## 2. Nielsen's 10 usability heuristics (the evaluation method)

The standard lens for *heuristic evaluation* — walk every screen against all ten:

1. **Visibility of system status** — keep users informed with timely feedback.
2. **Match between system and the real world** — speak the user's language and conventions.
3. **User control & freedom** — clear exits, undo/redo; no dead ends.
4. **Consistency & standards** — within the product and with platform conventions (Jakob's Law).
5. **Error prevention** — prevent problems before they happen (constraints, confirmations on destructive acts).
6. **Recognition rather than recall** — show options; don't make users remember across screens.
7. **Flexibility & efficiency of use** — accelerators for experts; sensible defaults for novices.
8. **Aesthetic & minimalist design** — every extra unit of information competes with the relevant; remove it.
9. **Help users recognise, diagnose & recover from errors** — plain-language, specific, constructive errors.
10. **Help & documentation** — available, searchable, task-focused when needed.

> Use these as a **checklist**: each becomes a finding (with severity) or a confirmed pass. This is the
> backbone of the [`design-critique-loop`](../protocols/design-critique-loop.md)'s "usability" dimension.

## 3. Norman's emotional design — the path to delight

Don Norman's three levels of processing; *delight* is engineered across all three, never bolted on:

- **Visceral** — the immediate, pre-conscious reaction to *look and feel* (the first 50ms). Earned by
  visual foundations: coherent palette, type, rhythm, polish. This is the Aesthetic-Usability effect's source.
- **Behavioural** — the *feel of use*: responsiveness, the satisfying click, friction removed from the
  repetitive path, error tolerance. Competence felt in the hands.
- **Reflective** — the *story the user tells themselves* afterward: pride, identity, recommendation. The
  peak-end moments, the thoughtful empty states, the copy that respects them.

> **Delight is the "at best" bar, not the floor.** A delightful moment (a gentle, purposeful micro-
> interaction; a genuinely helpful empty state; an anticipatory default) is bonus — and only counts if it
> harms neither usability, accessibility, nor performance. From Norman's *The Design of Everyday Things*:
> **affordances** (what an element lets you do) and **signifiers** (how it shows you) must agree, and a
> good **conceptual model** + visible **feedback** keep the user oriented. Confusion is a design failure,
> never a user failure.

---

> **Sources (the canon to cite):** Nielsen (10 heuristics; heuristic evaluation; NN/g); the Laws of UX
> (Fitts, Hick, Miller, Jakob, Tesler, Postel, Doherty, Zeigarnik, Aesthetic-Usability); Norman, *The
> Design of Everyday Things* and *Emotional Design*. Name the law in the finding so the designer can
> verify the fix removed it.
