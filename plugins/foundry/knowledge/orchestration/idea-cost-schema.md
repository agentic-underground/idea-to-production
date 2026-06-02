# IDEA_COST.jsonl Schema Reference

> For FOUNDRY §12. Defines every field in the cost ledger, its type, source,
> and how it feeds back into future estimates.

---

## File Location

`IDEA_COST.jsonl` lives in the project root or `doc/` directory.
One JSON object per line. Append-only — **never mutate existing records**.

---

## Full Schema

```json
{
  "schema_version": "1.2",
  "id": "ROADMAP-N",
  "title": "Human-readable feature title",
  "slug": "kebab-case-slug",
  "tier": "PRIMARY | SECONDARY | TERTIARY | TERTIARY+",
  "priority_status": "CRITICAL | HIGH | MEDIUM | LOW | BACKLOG",

  "token_accounting": {
    "tokens_in": 0,
    "tokens_out": 0,
    "tokens_total": 0,
    "estimated_tokens": 0,
    "estimation_accuracy_pct": 0.0
  },

  "time_accounting": {
    "elapsed_s": 0,
    "phase_durations_s": {
      "plan": 0,
      "ears": 0,
      "feature": 0,
      "test": 0,
      "implement": 0,
      "story": 0,
      "review_total": 0
    }
  },

  "change_accounting": {
    "lines_added": 0,
    "lines_removed": 0,
    "lines_changed": 0,
    "files_created": 0,
    "files_modified": 0,
    "files_touched": 0
  },

  "artefact_counts": {
    "ears_statements": 0,
    "gherkin_scenarios": 0,
    "unit_tests": 0,
    "integration_tests": 0,
    "bdd_scenarios_executed": 0,
    "story_tests": 0,
    "performance_tests": 0,
    "test_count_total": 0
  },

  "pipeline_accounting": {
    "review_cycles_total": 0,
    "needs_revision_count": 0,
    "block_count": 0,
    "agents_spawned": 0,
    "value_handlers_used": [],
    "reviewers_invoked": []
  },

  "quality": {
    "final_line_coverage_pct": 0.0,
    "final_branch_coverage_pct": 0.0,
    "performance_assertions_passing": 0,
    "performance_assertions_failing": 0,
    "dead_code_disposition": "n/a | deleted | tested",
    "all_tests_passing": true,
    "regressions_introduced": 0,
    "design_reviewer_passes": 0,
    "design_reviewer_revisions": 0,
    "architecture_decisions_recorded": 0
  },

  "stack": [],
  "completed_at": "ISO8601",
  "session_id": "optional-session-identifier"
}
```

---

## Field Definitions

### Identity fields

| Field | Type | Description |
|---|---|---|
| `schema_version` | string | `"1.2"` — v1.2 adds branch coverage, performance test count, BDD scenarios executed, dead code disposition, architecture decisions recorded |
| `id` | string | Roadmap item ID (e.g. `"ROADMAP-7"`) |
| `title` | string | Feature title from roadmap |
| `slug` | string | Kebab-case slug from roadmap |
| `tier` | string | Which tier this item was processed in |
| `priority_status` | string | PRIORITY_STATUS from roadmap at time of processing |

### Token accounting

| Field | Type | Description |
|---|---|---|
| `tokens_in` | int | Input tokens consumed across all agents for this item |
| `tokens_out` | int | Output tokens produced across all agents for this item |
| `tokens_total` | int | Sum of in + out |
| `estimated_tokens` | int | Pre-cycle estimate from FOUNDRY §4.3 |
| `estimation_accuracy_pct` | float | `(1 - abs(actual - estimated) / estimated) * 100` |

### Time accounting

| Field | Type | Description |
|---|---|---|
| `elapsed_s` | int | Wall-clock seconds from PLAN start to STORY_PROVEN |
| `phase_durations_s` | object | Per-phase breakdown — keys: `plan`, `ears`, `feature`, `test`, `implement`, `story`, `review_total` |

### Change accounting

| Field | Type | Description |
|---|---|---|
| `lines_added` | int | Total lines added to the codebase |
| `lines_removed` | int | Total lines removed |
| `lines_changed` | int | `lines_added + lines_removed` |
| `files_created` | int | New files created |
| `files_modified` | int | Existing files modified |
| `files_touched` | int | `files_created + files_modified` |

### Artefact counts

| Field | Type | Description |
|---|---|---|
| `ears_statements` | int | EARS statements written for this item |
| `gherkin_scenarios` | int | Gherkin scenarios in the .feature file |
| `unit_tests` | int | Unit tests written |
| `integration_tests` | int | Integration tests written |
| `bdd_scenarios_executed` | int | Gherkin scenarios with passing step definitions (only counts toward total if step defs exist) |
| `story_tests` | int | Story/E2E tests written |
| `performance_tests` | int | Performance assertions written (per latency-sensitive path) |
| `test_count_total` | int | Sum of all test types |

### Pipeline accounting

| Field | Type | Description |
|---|---|---|
| `review_cycles_total` | int | Total REVIEWER invocations across all transitions |
| `needs_revision_count` | int | How many times a phase was sent back for revision |
| `block_count` | int | How many BLOCK verdicts were issued |
| `agents_spawned` | int | Total agents spawned for this item |
| `value_handlers_used` | array | Which VALUE_HANDLER agents were spawned |
| `reviewers_invoked` | array | Which reviewer roles were invoked |

### Quality

| Field | Type | Description |
|---|---|---|
| `final_line_coverage_pct` | float | Line coverage % at STORY_PROVEN |
| `final_branch_coverage_pct` | float | Branch coverage % at STORY_PROVEN — `--cov-branch` required |
| `performance_assertions_passing` | int | Performance tests passing their SLO threshold |
| `performance_assertions_failing` | int | Performance tests over their SLO threshold (should be 0 at STORY_PROVEN) |
| `dead_code_disposition` | string | `n/a` if no file was <50% pre-change; otherwise `deleted` or `tested` per Dead Code Policy |
| `all_tests_passing` | bool | Whether all tests pass at completion |
| `regressions_introduced` | int | Pre-existing tests broken (should always be 0) |
| `design_reviewer_passes` | int | Number of first-pass approvals from DESIGN-REVIEWER |
| `design_reviewer_revisions` | int | Number of revisions requested by DESIGN-REVIEWER |
| `architecture_decisions_recorded` | int | Number of ADRs (`doc/architecture/ADR-*.md`) produced by `handler-architect` for this item |

---

## Example Record

```json
{
  "schema_version": "1.1",
  "id": "ROADMAP-3",
  "title": "User authentication with JWT",
  "slug": "user-auth-jwt",
  "tier": "PRIMARY",
  "priority_status": "HIGH",
  "token_accounting": {
    "tokens_in": 42300,
    "tokens_out": 18700,
    "tokens_total": 61000,
    "estimated_tokens": 50000,
    "estimation_accuracy_pct": 78.0
  },
  "time_accounting": {
    "elapsed_s": 2847,
    "phase_durations_s": {
      "plan": 95,
      "ears": 180,
      "feature": 240,
      "test": 420,
      "implement": 1680,
      "story": 210,
      "review_total": 117
    }
  },
  "change_accounting": {
    "lines_added": 487,
    "lines_removed": 23,
    "lines_changed": 510,
    "files_created": 6,
    "files_modified": 4,
    "files_touched": 10
  },
  "artefact_counts": {
    "ears_statements": 6,
    "gherkin_scenarios": 14,
    "unit_tests": 31,
    "integration_tests": 8,
    "story_tests": 5,
    "test_count_total": 44
  },
  "pipeline_accounting": {
    "review_cycles_total": 9,
    "needs_revision_count": 2,
    "block_count": 0,
    "agents_spawned": 11,
    "value_handlers_used": ["PYTHON-AGENT", "FASTAPI-AGENT"],
    "reviewers_invoked": ["EARS-REVIEWER", "SMU-REVIEWER", "BDD-REVIEWER",
                          "COVERAGE-REVIEWER", "TEST-DESIGN-REVIEWER",
                          "DESIGN-REVIEWER", "SECURITY-REVIEWER",
                          "REGRESSION-REVIEWER"]
  },
  "quality": {
    "final_line_coverage_pct": 100.0,
    "all_tests_passing": true,
    "regressions_introduced": 0,
    "design_reviewer_passes": 3,
    "design_reviewer_revisions": 2
  },
  "stack": ["python", "fastapi", "pytest", "jwt"],
  "completed_at": "2026-05-17T14:23:10Z",
  "session_id": "foundry-cycle-001"
}
```

---

## Querying IDEA_COST.jsonl

```bash
# Total tokens spent across all completed items
jq -s '[.[].token_accounting.tokens_total] | add' IDEA_COST.jsonl

# Average estimation accuracy
jq -s '[.[].token_accounting.estimation_accuracy_pct] | add / length' IDEA_COST.jsonl

# Items that caused BLOCKs
jq 'select(.pipeline_accounting.block_count > 0) | .id, .title' IDEA_COST.jsonl

# Coverage distribution
jq '.id + ": " + (.quality.final_line_coverage_pct | tostring) + "%"' IDEA_COST.jsonl
```
