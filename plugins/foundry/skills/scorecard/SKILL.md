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
SENTINEL gate verdict (from `SECURITY-REPORT.md`), and **real** tokens / wall-clock / regressions /
estimation-accuracy from the **last FOUNDRY cycle's `IDEA_COST.jsonl`** (§12 of the builder writes it;
this reads it). Cost fields are omitted honestly when no cycle recorded them — a shell script cannot
measure tokens, only a real cycle can.

**Marketplace** (`MARKETPLACE_SCORECARD.jsonl`): inspection findings open (CRITICAL/WARNING/SUGGESTION,
tallied from `*_INSPECTION_REPORT.md`), merged self-improve PRs (`gh`), canonical-copy integrity
(check.sh + inspection-core md5 booleans), live `~/.claude` portability violations (must trend to 0), and
self-coverage (plugins/skills/agents/commands/inspect/self-improve counts).

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
