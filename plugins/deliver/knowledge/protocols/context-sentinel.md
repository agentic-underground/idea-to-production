# Context Sentinel Protocol

> For DELIVER §10. Defines the format, accumulation rules, and consumption
> patterns for context sentinels — the structured breadcrumbs that carry
> stage-output metadata between PHASE_POOL agents.

---

## Purpose

Sentinels are structured strings that encode what was produced at each pipeline
stage. They are appended to the context of every downstream agent, giving each
agent a traceable record of the full pipeline state without requiring
conversation history.

A sentinel is not documentation — it is a **machine-readable context anchor**.
Agents use sentinels to:
- Confirm prerequisite stages are complete before proceeding
- Reference specific artefact IDs (EARS IDs, scenario counts, file names)
- Detect revision cycles (REVISION count > 0 signals rework happened)
- Propagate quality signals (GREEN, RED, BLOCK) through the chain

---

## Sentinel Format

```
SENTINEL::{PHASE}::{ROADMAP_ID}::{STATUS}::{PAYLOAD}
```

| Field | Values | Description |
|---|---|---|
| `PHASE` | See phase codes below | Which pipeline phase this sentinel represents |
| `ROADMAP_ID` | `ROADMAP-{N}` | The roadmap item this sentinel belongs to |
| `STATUS` | `PASS`, `RED`, `GREEN`, `COMPLETE`, `REVISION`, `BLOCK` | Quality/completion signal |
| `PAYLOAD` | Phase-specific | Structured data about what was produced |

---

## Phase Codes and Payloads

### PLAN_COMPLETE

```
SENTINEL::PLAN_COMPLETE::ROADMAP-{N}::PASS::{plan_path}
```

Payload: path to the plan document (e.g., `doc/feature-slug_PLAN.md`).
Emitted by `ds-step-0-plan` after plan document passes reviewer.

---

### EARS_COMPLETE

```
SENTINEL::EARS_COMPLETE::ROADMAP-{N}::PASS::{EARS-042,EARS-043,EARS-044}
```

Payload: comma-separated list of EARS IDs assigned to this item.

---

### FEATURE_COMPLETE

```
SENTINEL::FEATURE_COMPLETE::ROADMAP-{N}::PASS::{scenario_count}::{feature_file_path}
```

Payload: number of Gherkin scenarios written; path to the .feature file.

---

### TESTS_WRITTEN

```
SENTINEL::TESTS_WRITTEN::ROADMAP-{N}::RED::{test_count}::{ears_ids_covered}
```

Status is always `RED` at this phase — tests must be failing.
Payload: total test count; comma-separated EARS IDs exercised by tests.

---

### GAP_MAP_COMPLETE

```
SENTINEL::GAP_MAP_COMPLETE::ROADMAP-{N}::RED::{failing_count}::{ears_ids_exposed}
```

Status is `RED` — the gap map records the failure surface before implementation.
Payload: number of failing tests; comma-separated EARS IDs exposed by failures.
Emitted by `ds-step-4-first-test-run` after gap map document is complete.

---

### IMPL_COMPLETE

```
SENTINEL::IMPL_COMPLETE::ROADMAP-{N}::GREEN::{files_changed}::{line_coverage_pct}
```

Status is `GREEN` when all Phase 3 tests pass.
Payload: number of files changed; current line coverage percentage.

---

### STORY_PROVEN

```
SENTINEL::STORY_PROVEN::ROADMAP-{N}::PASS::{story_test_count}::{final_line_coverage_pct}::{final_branch_coverage_pct}
```

Status is `PASS` when line+branch coverage = 100% and all tests pass.
Payload: story test count; final line coverage %; final branch coverage %.
Emitted by `ds-step-story-tests` (Phase 5) — the only owner of this sentinel.
Required by `ds-step-7-sync` before sync may begin.

---

### GREEN_RUN_COMPLETE

```
SENTINEL::GREEN_RUN_COMPLETE::ROADMAP-{N}::GREEN::{total_tests}::{coverage_pct}
```

Status is `GREEN` when full suite passes with no regressions.
Payload: total test count across full suite; current line coverage percentage.
Emitted by `ds-step-6-green-run` after REGRESSION-REVIEWER PASS.

---

### SYNC_COMPLETE

```
SENTINEL::SYNC_COMPLETE::ROADMAP-{N}::GREEN::{sync_method}::{conflicts_resolved}
```

Status is `GREEN` when post-sync tests pass.
Payload: sync method used (`rebase` or `merge`); number of conflicts resolved (0 is common).
Emitted by `ds-step-7-sync` after post-sync test run is green.

---

### COMMIT_MSG_READY

```
SENTINEL::COMMIT_MSG_READY::ROADMAP-{N}::PASS::{summary_line}
```

Payload: the first line of the approved commit message (the summary).
Emitted by `ds-step-8-commit-message` after commit message passes reviewer.

---

### DELIVERY_COMPLETE

```
SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{commit_hash}
```

Payload: short commit hash (7 chars). This is the true end-of-life sentinel — DELIVER's
IDEA_COST.jsonl record is written only when both `STORY_PROVEN` (Phase 5) and
`DELIVERY_COMPLETE` (this step) are present in the chain (in **both** invocation modes below).

**Invocation-mode-aware** — what `COMPLETE` asserts depends on how DELIVER was invoked:
- **Standalone cycle** (per [`merge-governance.md`](merge-governance.md)): `COMPLETE` means the change
  is **on `main`** and the roadmap entry updated — emitted by `ds-step-9-commit-push` only when the
  change actually reaches `main` (immediately under `direct-merge`; or **deferred until the human
  merges the PR** under `pr-approval`, where `AWAITING_MERGE` is emitted first — see below).
- **Engine PLAN-scope** (FLEET continuous-delivery engine, builder §2.5): `COMPLETE` means the slice
  is **GREEN on the build branch**, keyed to **branch HEAD** (`git rev-parse --short HEAD`) — NOT on
  `main`. The agent does not push or mutate STATUS; the **engine** re-runs the gate on the branch and
  lands it. IDEA_COST is still written here (cost-of-record is branch-keyed, not merge-keyed).

### AWAITING_MERGE

```
SENTINEL::AWAITING_MERGE::ROADMAP-{N}::AWAITING_MERGE::{pr_url_or_branch}
```

Emitted by `ds-step-9-commit-push` under **`pr-approval`** governance when the change is built,
has **PASSed** the adversarial review (`/deliver:pr-review`), and its **PR is open** but not yet
merged. Payload: PR URL (or branch name). It is a **terminal-pending** signal: the item rests at
roadmap `STATUS: AWAITING MERGE`, the loop takes no further phase action, and it is **superseded by
`DELIVERY_COMPLETE`** once the human merges. It does **not** trigger IDEA_COST recording (the change
is not yet on `main`).

---

### REVISION sentinels

When a REVIEWER returns `NEEDS_REVISION`, a REVISION sentinel is appended:

```
SENTINEL::REVISION::ROADMAP-{N}::{PHASE}::NEEDS_REVISION::{revision_number}::{reviewer_role}
```

Example:
```
SENTINEL::REVISION::ROADMAP-7::FEATURE_COMPLETE::NEEDS_REVISION::1::BDD-REVIEWER
```

The revision number increments with each cycle. If `revision_number` reaches 3,
the sentinel status becomes `BLOCK` and escalation occurs.

---

### SMU loaded sentinel

```
SMU::LOADED::{project-slug}::doc/SUBJECT_MATTER_UNDERSTANDING.md::version-{N}
```

All agents confirm SMU load at instantiation. If absent, agent must load it
before proceeding.

---

## Accumulation Example

By the time `ds-step-9-commit-push` is spawned for ROADMAP-7, its context includes:

```
SMU::LOADED::my-project::doc/SUBJECT_MATTER_UNDERSTANDING.md::version-1
SENTINEL::PLAN_COMPLETE::ROADMAP-7::PASS::doc/user-auth_PLAN.md
SENTINEL::EARS_COMPLETE::ROADMAP-7::PASS::EARS-042,EARS-043,EARS-044
SENTINEL::REVISION::ROADMAP-7::EARS_COMPLETE::NEEDS_REVISION::1::SMU-REVIEWER
SENTINEL::EARS_COMPLETE::ROADMAP-7::PASS::EARS-042,EARS-043,EARS-044,EARS-045
SENTINEL::FEATURE_COMPLETE::ROADMAP-7::PASS::9::features/user-auth.feature
SENTINEL::TESTS_WRITTEN::ROADMAP-7::RED::27::EARS-042,EARS-043,EARS-044,EARS-045
SENTINEL::GAP_MAP_COMPLETE::ROADMAP-7::RED::27::EARS-042,EARS-043,EARS-044,EARS-045
SENTINEL::IMPL_COMPLETE::ROADMAP-7::GREEN::4::98.3
SENTINEL::GREEN_RUN_COMPLETE::ROADMAP-7::GREEN::31::100.0
SENTINEL::STORY_PROVEN::ROADMAP-7::PASS::6::100.0
SENTINEL::SYNC_COMPLETE::ROADMAP-7::GREEN::rebase::0
SENTINEL::COMMIT_MSG_READY::ROADMAP-7::PASS::feat(auth): add JWT-based user authentication
```

After `ds-step-9-commit-push` completes, the chain is closed with:

```
SENTINEL::DELIVERY_COMPLETE::ROADMAP-7::COMPLETE::a1b2c3d
```

The agent reads the chain and knows:
- Plan document exists at `doc/user-auth_PLAN.md`
- EARS had one revision (SMU-REVIEWER caught a vocabulary issue)
- 4 EARS statements, 9 Gherkin scenarios, 27 tests authored (all RED)
- Gap map confirmed 27 failing tests before implementation
- Implementation: 4 files changed, 98.3% coverage at step-5
- Full suite after step-6: 31 tests passing at 100% coverage
- 6 story tests passing at 100% line+branch coverage (Phase 5)
- Sync: rebased, no conflicts
- Commit message approved — ready to commit
- Delivery confirmed — commit a1b2c3d pushed to origin

---

## Sentinel Validation Rules

Agents must validate the sentinel chain before proceeding:

1. **Prerequisite check**: The required predecessor sentinel must be present.
   - `ds-step-1-ears` requires `PLAN_COMPLETE` with status `PASS`
   - `ds-step-2-feature-docs` requires `EARS_COMPLETE` with status `PASS`
   - `ds-step-3-tests` requires `FEATURE_COMPLETE` with status `PASS`
   - `ds-step-4-first-test-run` requires `TESTS_WRITTEN` with status `RED`
   - `ds-step-5-implementation` requires `GAP_MAP_COMPLETE` with status `RED`
   - `ds-step-6-green-run` requires `IMPL_COMPLETE` with status `GREEN`
   - `ds-step-story-tests` requires `GREEN_RUN_COMPLETE` with status `GREEN`
   - `ds-step-7-sync` requires both `GREEN_RUN_COMPLETE::GREEN` AND `STORY_PROVEN::PASS`
   - `ds-step-8-commit-message` requires `SYNC_COMPLETE` with status `GREEN`
   - `ds-step-9-commit-push` requires `COMMIT_MSG_READY` with status `PASS`

2. **No orphan revisions**: A REVISION sentinel must be followed by a
   re-issuance of the same phase sentinel with `PASS`.

3. **Coverage gate**: `STORY_PROVEN::PASS` is only valid when
   `final_line_coverage_pct = 100.0` AND `final_branch_coverage_pct = 100.0`.
   `DELIVERY_COMPLETE` is only valid when `STORY_PROVEN::PASS` precedes it
   in the same chain.

If validation fails, the agent must halt and report the specific violation
before doing any work.

---

## Sentinel Storage

Sentinels are passed as context strings, not stored in files.
For audit purposes, DELIVER appends the full sentinel chain for each item
to `docs/internal/DELIVER_PLAN.md` under `## Sentinel Audit Log` after completion.

---

## Adding a new sentinel or roadmap status — propagation checklist

A new pipeline token must be **registered in every contract that defines or consumes it**, not just
the agent that emits it (the recurring drift: emitter updated, contracts not). When you add one,
update all that apply in the same change:

- [ ] **This registry** (`context-sentinel.md`) — grammar, status, payload, ordering/supersession.
- [ ] **`orchestration/orchestration-loop.md`** — Stage Routing Table output column + terminal-state logic.
- [ ] **`roadmapper/SKILL.md`** — the `STATUS:` enum + a one-line definition (for a new roadmap status).
- [ ] **The emitting agent** (`agents/ds-step-*.md`) — emission + handoff schema.
- [ ] **`lifecycle-states/states/*.md`** — exit criteria, if the token gates a state transition.
- [ ] **`protocols/definition-of-done.md`** — the §Step-N done criteria AND the §Orchestrator Exit
      Condition sentinel-chain rule (a prose-duplicate of the closure contract — easy to miss).
- [ ] **`roadmapper/SKILL.md`** — both the entry-schema `STATUS:` enum *and* the §STEP-N delivery
      procedure (a second, procedural copy of the flow).
- [ ] **`glossary.md`** — if the token introduces a new user-facing term.
