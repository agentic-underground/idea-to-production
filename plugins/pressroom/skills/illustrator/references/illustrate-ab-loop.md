# The A/B-until-best loop — the orchestrator's half

> The ILLUSTRATOR's side of the two-option adversarial review. The design-reviewer's side — how it scores
> two options and emits the verdict — is [`ab-comparative-loop.md`](../../design-reviewer/references/ab-comparative-loop.md).
> This loop is a sibling of the single-artefact [convergent loop](../../design-reviewer/references/design-critique-loop.md),
> not a replacement: that one *converges one* artefact toward a target; this one *races two*, keeps the
> champion, and demands the reviewer **celebrate** a winner as **the best**, not merely crown the
> **least-worse**. The difference is the whole point — we ship figures that are good, not figures that
> happened to beat a worse sibling.

## The loop

```
   author SPEC ─▶ generate A and B (handler) ─▶ REVIEW A vs B (comparative) ─▶ signal?
        ▲                                                                       │ LEAST-WORSE
        └─ carry winner forward; regenerate ONLY the challenger per brief ◀─────┘
                                                                              │ BEST
                                                                              ▼
                                                                      celebrate · emit · (embed + ledger)
```

1. **Generate A and B.** Spawn the chosen handler twice on the *same* SPEC, forcing the divergence named in
   `ab.axis_of_divergence` (orientation, encoding channel, decomposition — or two *different* handlers when
   the type is genuinely ambiguous). The two must be a **real choice**, not two near-identical renders.
   Each handler self-reviews and rasterises onto both grounds (the [dark-mode canon §5](dark-mode-canon.md))
   before hand-back.
2. **Review.** Hand both PNGs + the SPEC to the design-reviewer in comparative mode. It returns the
   [A/B verdict](../../design-reviewer/references/ab-comparative-loop.md): `winner`, per-option findings,
   `signal` (LEAST-WORSE | BEST), `carry_forward`, `next_challenger_brief`, loop verdict.
3. **Advance — carry the champion.** On `CONTINUE`:
   - **Keep the winner's source**, apply its *own* open HIGH+MED findings to it (it improves, never regresses).
   - **Regenerate ONLY the challenger** per `next_challenger_brief` — a fresh attempt aimed at *beating* the
     current champion, exploring a different point in the design space.
   - Re-review winner vs new-challenger.
4. **Stop** on the first of:
   - **BEST-REACHED** — `signal: BEST` (the champion earns it; see the termination rule below). Celebrate, emit.
   - **HALT-DIMINISHING-RETURNS** — the best-of-pair score gains `< +3` across turns with no BEST: surface the
     impasse and the residual, ask the user (accept the champion / change approach / relax a constraint).
   - **CAP** — `MAX_TURNS = 4` (baseline + 3, matching the prose and convergent loops).

## "The best", not "the least-worse" — the termination

The reviewer emits `signal: BEST` **only when every one of these holds** for the champion:
- clears **every gate** — legibility (the
  [`layout-reviewer`](../../design-reviewer/agents/layout-reviewer.md) gate, measured at `width_budget_px`
  via the inline-legibility rule), data-integrity (charts), accessibility (alt text present + the dark-mode
  contrast gate on **both** grounds),
- has **no open HIGH** finding,
- scores **≥ TARGET (85/100)** on the shared design-fitness rubric,
- and the reviewer can state an **earned positive** — a specific thing the figure does *well* — that is not
  merely "the other option was worse".

Until all four hold, the signal is `LEAST-WORSE` and the loop continues. This is what stops the loop from
declaring victory the moment one option edges out a poor sibling.

## Anti-ping-pong (A/B-specific)

- **The champion is carried forward and never re-rolled** — only the challenger is regenerated. The
  best-so-far can only improve, so the loop cannot oscillate or regress.
- **A turn where neither option beats the champion counts toward the diminishing-returns floor** — two
  flat turns and the loop halts and asks, rather than burning the token budget.
- **The rubric is fixed for a loop** — new canon lands between loops via self-improvement, never mid-critique.
- **Specific source fixes only** — "make it nicer" is not a finding; "switch the ordered series from hue to
  a sequential ramp; drop the gridlines" is.

## On emit (loop / `docs` mode)

When `BEST-REACHED`, the orchestrator: writes the asset to `<doc-dir>/diagrams/NN-name.{svg,png}`; embeds
`![<alt_text>](diagrams/NN-name.ext)` after the SPEC's `insert_after` line (idempotently — see the SKILL's
ledger section); appends the site's outcome (`winner`, `final_score`, `signal: BEST`, `turns`) to
`.pressroom/illustration-ledger.json`. In single-shot mode it stops at "emit the asset" and shows it to the
user without editing the doc, unless asked.
