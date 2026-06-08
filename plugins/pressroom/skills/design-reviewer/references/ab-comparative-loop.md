# The comparative (A/B) design-critique loop — celebrate the best, don't crown the least-worse

> The reviewer's half of the ILLUSTRATOR's two-option selection. Sibling to
> [`design-critique-loop.md`](design-critique-loop.md): **same fitness rubric, same sub-agents**
> (`typographic-reviewer`, `dataviz-reviewer`), **different shape and termination**. The convergent loop
> takes *one* artefact and drives it to a target. This loop takes *two* options, picks a winner, keeps it as
> champion, and only declares victory when the champion is genuinely **the best** — clears every gate, no
> open HIGH, ≥ TARGET, and has an *earned positive* — not merely the **least-worse** of a weak pair. The
> ILLUSTRATOR's half (carry-forward, challenger regeneration) is
> [`illustrate-ab-loop.md`](../../illustrator/references/illustrate-ab-loop.md).

## What the reviewer receives

A small, disposable context: this file + the relevant canon (`dataviz-canon.md` and/or `typography-canon.md`
+ the [dark-mode canon](../../illustrator/references/dark-mode-canon.md)) + the design-fitness rubric from
the convergent loop + **two figure PNGs labelled A and B** (each already rasterised onto both a black and a
white card by the handler) + the [SPEC](../../illustrator/references/spec-schema.md) (intent, message,
audience, `ab.axis_of_divergence`, `alt_text`).

## Procedure

1. **Recover intent.** From the SPEC: what is the single message, for whom, at what width? An option that
   doesn't carry the message loses regardless of polish.
2. **Score each option independently** on the shared design-fitness rubric (same dimensions, same weights,
   same gates) via the appropriate sub-agent(s) — structural/page figures → `typographic-reviewer` in A/B
   mode; charts → `dataviz-reviewer` in A/B mode; both when relevant. Each gate (legibility,
   data-integrity, accessibility incl. the **dark-mode contrast gate on both grounds**) is checked on *both*
   A and B.
3. **Pick the winner** — higher fitness, gates first (a gate failure loses to a gate-clean option even at a
   lower polish score). State *why it wins*, not just *why the other loses*.
4. **Decide the signal** (the load-bearing call): `BEST` only if the winner clears the termination test
   below; otherwise `LEAST-WORSE`.
5. **Brief the next round** — what the winner must still fix (its own open HIGH+MED), and how a regenerated
   challenger should diverge to *beat* it.

## The A/B verdict (the schema the orchestrator parses)

```markdown
## A/B design review: <site>  ·  A=<scoreA>/100  B=<scoreB>/100
### Per-option findings
**A** — | Pri | Principle | Violation → reader cost | Source fix | Dimension |  (rows…)
**B** — | Pri | Principle | Violation → reader cost | Source fix | Dimension |  (rows…)
### Gates
A: legibility ✓/✗ · data-integrity ✓/✗/n-a · accessibility(alt+dual-ground) ✓/✗
B: legibility ✓/✗ · data-integrity ✓/✗/n-a · accessibility(alt+dual-ground) ✓/✗
### Winner
winner: A | B
margin: <signed scoreWinner − scoreLoser>
signal: LEAST-WORSE | BEST
why: "<one sentence: what the winner does WELL — the earned positive — not just where the loser failed>"
carry_forward: "<winner's source>; apply to it: [winner's own open HIGH/MED findings]"
next_challenger_brief: "<how the regenerated challenger should diverge to beat the winner>"
### Loop verdict
CONTINUE (improve winner, regenerate challenger) | BEST-REACHED (celebrate) | HALT-DIMINISHING-RETURNS (<impasse + question>)
```

## Termination — the test for `signal: BEST`

`BEST` is emitted **only when all four hold** for the winning option:

1. **Every gate clears** — legibility at the SPEC's `width_budget_px`; data-integrity (lie factor ≈ 1, zero
   baseline) for charts; accessibility — `alt_text` present *and* the [dark-mode contrast gate](../../illustrator/references/dark-mode-canon.md#3--contrast-gates-measurable-not-vibes)
   passes on **both** the black and white card.
2. **No open HIGH** finding remains on the winner.
3. **Score ≥ TARGET (85/100).**
4. **An earned positive exists** — the reviewer can name a specific thing the figure does *well* (the
   `why:` line is a genuine compliment, not a comparison). A figure that is merely "less broken than B" has
   no earned positive → `LEAST-WORSE`, continue.

Miss any one → `signal: LEAST-WORSE`, loop verdict `CONTINUE`.

## Anti-ping-pong (shared with the convergent loop, A/B-tuned)

- **The champion never regresses** — it is carried forward and only *improved*; only the challenger is
  re-rolled. So `scoreₙ(champion)` is monotonic.
- **Flat turns halt** — if neither option beats the champion by `≥ DELTA_FLOOR (+3)` for two turns, emit
  `HALT-DIMINISHING-RETURNS` with the residual and a question. Don't take another lap to relitigate taste.
- **Gates are never traded for polish** — an inaccessible, illegible, or misleading option cannot win, and
  cannot be `BEST`, however pretty.
- **`MAX_TURNS = 4.`**

## Disposition & self-improvement

The winning source is what the orchestrator emits; the loser is discarded (its lesson, if recurring, is not).
A recurring *comparative* stall — one axis of divergence that always wins (e.g. TB always beats LR for
pipelines), a gate one engine keeps tripping — feeds the shared
[self-improvement protocol](../../rich-pdf-with-diagrams/references/self-improvement.md): promote the winning
choice into a charting-matrix rule or a dark-mode-canon value so the *handlers* start there next time and the
loop converges to BEST in fewer turns.
