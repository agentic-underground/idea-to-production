# Scorecard schema reference

Two deterministic, artifact-measured scorecards. Sibling to
[`idea-cost-schema.md`](idea-cost-schema.md) (which the PRODUCT scorecard reads for real cost). Produced by
`skills/scorecard/scripts/{scorecard.sh,marketplace-score.sh}`. **Every field is a measurement of a file on
disk — never a model-assigned score** — so the scorecards cannot be gamed.

## Design principle: measure artifacts, trend over snapshots

A single scorecard is a snapshot. *Improvement* is the **trend** across snapshots (the covenant's "halve
the remaining distance" = direction of travel, not an absolute). A metric that can only be moved by gaming
it does not belong here. The PRODUCT scorecard is regenerable (overwrite); the MARKETPLACE scorecard is
append-only (one line per scoring event), so the series is the proof.

## PRODUCT scorecard — `SCORECARD.json` (project root)

```json
{
  "schema": "product-scorecard/1.0",
  "generated_ts": "ISO8601 or null",
  "project": "dir-name",
  "coverage": { "branch_pct": 0.0, "line_pct": 0.0, "function_pct": 0.0, "statement_pct": 0.0 },
  "corpus":   { "fixtures": 0, "false_positive_pct": 0.0 },
  "rules": 0,
  "tests": "N or 'N files'",
  "security_gate": "PASS | REVIEW | BLOCK | n/a",
  "cost": {
    "tokens_total": 0, "elapsed_s": 0, "regressions_introduced": 0,
    "estimation_accuracy_pct": 0.0, "note": "string-or-null"
  }
}
```

| Field | Source (on disk) | Notes |
|---|---|---|
| `coverage.*` | `coverage/coverage-summary.json` (Istanbul/nyc/vitest) | `.total.{branches,lines,functions,statements}.pct`. **Branch** is the real floor. |
| `corpus.fixtures` | `tests/corpus/parity-baseline.json` | optional; detection-style products only |
| `rules` | `find src rules -name '*.rules.*'` | rule-definition file count (a growth/trend proxy) |
| `tests` | `IDEA_COST.jsonl` `test_count_total`, else a test-file heuristic | authoritative when a cycle recorded it |
| `security_gate` | `SECURITY-REPORT.md` (SENTINEL) | first PASS/REVIEW/BLOCK token |
| `cost.*` | **last record of `IDEA_COST.jsonl`** | **only a real FOUNDRY cycle records tokens** — omitted (null + note) otherwise; a shell script cannot measure tokens |

Absent sources report `null` / `"n/a"` — honest by omission, never a fabricated value.

## MARKETPLACE scorecard — `.foundry/MARKETPLACE_SCORECARD.jsonl` (append-only)

```json
{
  "schema": "marketplace-scorecard/1.0", "ts": "ISO8601 or empty", "event": "score",
  "integrity": { "check_sh_identical": true, "inspection_core_identical": true, "portability_violations": 0 },
  "inspection": { "reports_seen": 0, "critical": 0, "warning": 0, "suggestion": 0 },
  "self_improve_prs_merged": 0,
  "coverage_of_self": { "plugins": 0, "skills": 0, "agents": 0, "commands": 0,
                        "inspect_commands": 0, "self_improve_skills": 0 }
}
```

| Field | Source | Improvement direction |
|---|---|---|
| `integrity.check_sh_identical` | `md5sum plugins/*/skills/check/scripts/check.sh` unique==1 | stay `true` |
| `integrity.inspection_core_identical` | `md5sum plugins/*/knowledge/inspection-core.md` unique==1 | stay `true` |
| `integrity.portability_violations` | live `~/.claude` couplings outside the allowlisted archive | → **0** |
| `inspection.{critical,warning,suggestion}` | tally of `*_INSPECTION_REPORT.md` | findings-closed > findings-opened run-over-run |
| `self_improve_prs_merged` | `gh pr list --state merged --search 'self-improve in:title'` | up |
| `coverage_of_self.*` | `find` over `plugins/` | inspect/self-improve coverage → one per plugin |

## The capture loop (how real cost gets in)

1. The **builder** records `IDEA_COST.jsonl` at `STORY_PROVEN` (§12 — tokens, wall-clock, coverage,
   regressions). This is the only place tokens are measurable (mid-cycle, agent-captured).
2. `scorecard.sh` **reads** the latest record into `SCORECARD.json` at the milestone.
3. `marketplace-score.sh` records the marketplace's own health after each inspection / self-improve PR.

So the two scorecards together answer: *is this product better than the last, and is the marketplace that
built it better than it was?* — both from artifacts, both as a trend.
