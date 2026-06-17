---
name: scorecard
description: >
  Keep score — prove that what you build AND the marketplace that builds it are getting better over time.
  Trigger with /foundry:scorecard (or "score this project", "how are we tracking", "marketplace health",
  "are we improving"). Emits TWO deterministic, artifact-measured scorecards: a PRODUCT scorecard
  (coverage, corpus FP-rate, test/rule count, security verdict, and real tokens/wall-clock from the last
  FOUNDRY cycle's IDEA_COST.jsonl) and a MARKETPLACE scorecard (inspection findings, self-improve PRs,
  canonical-copy integrity, portability violations, self-coverage). Every number is measured from a file
  on disk — never a model-assigned score — so it cannot be gamed.
metadata:
  type: diagnostic
  output: SCORECARD.json (product) + an appended line in .foundry/MARKETPLACE_SCORECARD.jsonl (marketplace)
model: claude-haiku-4-5
---

# FOUNDRY — Scorecard

The marketplace's "always BETTER" instrument. Improvement is only real if it is *measured*; this skill
measures it from artifacts, so the proof can't be faked. Two scorecards, two scripts, both deterministic.

## Run it

```bash
# PRODUCT — run in the project you're building:
bash ${CLAUDE_PLUGIN_ROOT}/skills/scorecard/scripts/scorecard.sh            # writes SCORECARD.json + summary

# MARKETPLACE — run in the marketplace source tree:
bash ${CLAUDE_PLUGIN_ROOT}/skills/scorecard/scripts/marketplace-score.sh    # appends MARKETPLACE_SCORECARD.jsonl
```

Pass `SCORECARD_TS="$(date -u +%FT%TZ)"` in the environment to stamp the run (the scripts don't embed a
timestamp themselves, so re-runs stay deterministic). The schema is
[`../../knowledge/orchestration/scorecard-schema.md`](../../knowledge/orchestration/scorecard-schema.md).

## What each measures (artifact-only, un-gameable)

**Product** (`SCORECARD.json`): branch/line/fn/stmt coverage (from `coverage-summary.json`), corpus fixture
count + FP-rate (from a `parity-baseline.json` if the project has one), rule-definition count, test count,
SECURITY gate verdict (from `SECURITY-REPORT.md`), and **real** tokens / wall-clock / regressions /
estimation-accuracy from the **last FOUNDRY cycle's `IDEA_COST.jsonl`** (§12 of the builder writes it;
this reads it). Cost fields are omitted honestly when no cycle recorded them — a shell script cannot
measure tokens, only a real cycle can.

**Marketplace** (`MARKETPLACE_SCORECARD.jsonl`): inspection findings open (CRITICAL/WARNING/SUGGESTION,
tallied from `*_INSPECTION_REPORT.md`), merged self-improve PRs (`gh`), canonical-copy integrity
(check.sh + inspection-core md5 booleans), live `~/.claude` portability violations (must trend to 0), and
self-coverage (plugins/skills/agents/commands/inspect/self-improve counts).

## Regression & drift detectors (flag-only, never a gate)

Three additive signals turn the scorecards from snapshots into *closed loops* — each is surfaced as a
flag/trend, never an exit-1, so a run is never blocked by them:

- **Coverage regression vs the last-N baselines (P2-1, product).** `scorecard.sh` compares the current
  branch coverage against the worst of the previous **5** `IDEA_COST.jsonl` records'
  `quality.final_branch_coverage_pct` and FLAGS a drop in `coverage_regression` — unless the current
  run's record carries a justifying `quality.coverage_regression_pragma` (a non-empty reason string),
  in which case the drop is recorded as *justified*. Older records that predate the field are skipped,
  so the baseline shrinks gracefully rather than erroring.
- **Canon-restatement trend (P2-13, marketplace).** `marketplace-score.sh` greps `plugins/*/agents/*.md`
  for canon inlined *without* a certainty-marker citation — an inlined model-tier table, ≥3 SOLID
  definitions, or the five-level test-contract prose — and reports `canon_restatements.{count,files}`.
  This is the "one thing to fix" from
  [`../../knowledge/architecture/self-architecture.md`](../../knowledge/architecture/self-architecture.md):
  trend it **down** by replacing each pasted copy with a reference (the standing target for
  `/foundry:self-improve`).
- **Per-element finding retention (P2-17, marketplace).** `marketplace-score.sh` tallies inspection
  findings **per element** (grouped by each finding's `**File:** \`path\`` line) into
  `per_element_findings` — a `{element: count}` map retained on every ledger line. This is the
  closed-loop measure `/foundry:self-improve` asserts against:

  > **GUARDRAIL — self-improve closed-loop assertion.** After self-improve touches an element and a fresh
  > inspection runs, score the marketplace and read the PREVIOUS ledger line's `per_element_findings`.
  > **ASSERT** the count for the touched element dropped run-over-run; if it did not, **WARN** (it did not
  > halve the distance to flawless — re-open it). This replaces the eyeballed PR-time check with a measured
  > one. The ledger is append-only, so the per-element series is the proof.

## Reading the trend (the only honest proof)

A single scorecard is a snapshot; *improvement* is the **trend** across snapshots. Because both files are
append-only / regenerable, compare run-over-run:
- product: branch-coverage holds at its floor, FP-rate down, regressions stay 0, estimation-accuracy up;
- marketplace: findings-closed > findings-opened, portability-violations → 0, integrity booleans true.

The covenant's "halve the remaining distance" is checked by **direction of travel**, never by an absolute
anyone can inflate. If a metric can only be moved by gaming it, it does not belong here — propose its
removal via `/foundry:self-improve`.

## When to run

At milestones: after a roadmap item reaches `STORY_PROVEN` (product), and after any `/foundry:inspect` or
self-improve PR merges (marketplace). Optionally wire the product run to the ROADMAP-milestone hook.
