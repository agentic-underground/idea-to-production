# Knowledge Wall: Roadmap-Item Decomposition / Atomic Job Breakdown

> Raw material for the `handler-roadmap-decomposition` agent-author.
> Synthesised from research-01 (INVEST + vertical slices), research-02 (DAG / parallelisation),
> and research-03 (PHASE_POOL pipeline + sentinel chain). Contradictions resolved inline;
> thin areas flagged.

---

## 1. Prime Directives (Non-Negotiable Rules)

**PD-1 · One EARS statement per atomic job (±2 tightly-coupled statements from the same user journey; never more).**
A job that covers disjoint EARS IDs will be rejected by EARS-REVIEWER before Phase 2. Split the
roadmap item first, not mid-flight.

**PD-2 · The PHASE_POOL sequence is inviolable: Phase 0 → 1 → 2 → 3 → 4 → 5 → 6.**
No phase may be skipped, reordered, or merged with another. A job in Phase 4 cannot touch Phase 3
artefacts. Phases within a single job run strictly in sequence; fan-out within a phase is allowed
(see PD-7).

**PD-3 · Test files are immutable after Phase 3.**
No test modification is permitted during Phase 4 (IMPLEMENT). If the implementation reveals the
test is wrong, the job reverts to Phase 3 (TEST-AGENT reruns). REGRESSION-REVIEWER enforces this
at the Phase 4 exit gate.

**PD-4 · 100% line coverage is the floor at two checkpoints: end of Phase 3 (RED) and end of Phase 5 (GREEN).**
Every uncovered line is an unpinned behaviour. The only valid escape hatch is `# pragma: no cover`
(or language-equivalent) with a written justification committed in the same diff. No job ships
below this floor.

**PD-5 · No `sleep()` / `waitForTimeout()` / arbitrary timing in tests — ever.**
Replace with deterministic-state polling (wait for actual DOM state, API response payload, or
process exit code). Flaky tests are treated as production bugs: fix the race condition in code,
not the test retry count. To confirm non-flakiness, the full suite must pass ≥3 successive runs
without `--retries`.

**PD-6 · STORY_PROVEN sentinel is the only terminal signal that unlocks Phase 6 (DELIVERY).**
No STORY_PROVEN → no DELIVERY → job stalls in the pipeline. The story test (full E2E browser or
CLI journey) is mandatory, not optional.

**PD-7 · Parallelisation scope: across roadmap items, not across phases of one item.**
Sub-jobs A/B/C carved from one roadmap item queue into the PHASE_POOL serially (A's Phase 1 before
B's Phase 1). The single exception is within IMPLEMENT + STORY: multiple language-specific
VALUE_HANDLER threads may fan out concurrently on the same job.

**PD-8 · Cycle-free dependency graph before execution begins.**
After topological sort, any remaining edges signal a cycle. This is a HALT condition at
decomposition time, not at runtime. Surface the cycle path to the user; do not attempt to
execute a cyclic plan.

**PD-9 · Hierarchy depth ≤ 3 decomposition levels.**
Deeper hierarchies introduce coordination overhead that erases the parallelisation benefit.
If you reach depth 3 and still can't make a job independently shippable, escalate to
the architect; do not decompose further automatically.

**PD-10 · A story has no user value ↔ it cannot ship independently (INVEST: Valuable + Independent).**
Pure-infrastructure or tech-debt stories without a user-meaningful outcome are not valid atomic jobs.
They must be attached to a shippable story or deferred until a story that exposes the user value
is in scope.

---

## 2. Canonical Tooling & Pinned Versions

### Spec & BDD

| Purpose | Tool | Notes |
|---|---|---|
| Requirement form | EARS syntax | 5 forms: Ubiquitous, Event-driven, Unwanted-behaviour, State-driven, Optional-feature |
| Scenario notation | Gherkin (Cucumber) | Language-agnostic; language binding chosen per project stack |
| Python BDD bridge | `pytest-bdd` | Binds Gherkin scenarios to pytest test functions |
| JS BDD bridge | `jest-cucumber` | Binds Gherkin scenarios to Jest test functions |

### Test Execution & Coverage

| Stack | Test runner | Coverage tool | CI gate |
|---|---|---|---|
| Python | `pytest` | `coverage.py` (`coverage run`, `coverage report`) | Fail if `< 100%` |
| JavaScript/TS | `jest` or `vitest` | `nyc` or `c8` or `vitest --coverage` | Fail if `< 100%` |
| Rust | `cargo test` | `cargo-tarpaulin` | Fail if `< 100%` |

### Browser / E2E (Story Phase)

| Tool | Notes |
|---|---|
| **Playwright** | Preferred: cross-browser, fastest feedback loop, deterministic wait APIs |
| Cypress | Acceptable: dev-friendly, slower than Playwright |
| Selenium | Legacy only: use for compatibility requirements, not greenfield |

### DAG / Dependency Analysis

| Tool | Language | Key functions |
|---|---|---|
| **NetworkX** | Python | `topological_sort()`, `topological_generations()`, `simple_cycles()` (cycle detection) |
| Kahn's algorithm | Any | BFS-based; processes zero-in-degree nodes iteratively; preferred for level stratification |
| DFS topological sort | Any | Stack-based alternative; use when iteration simplicity outweighs level clarity |

No pinned version of NetworkX was identified in the research; **flag for author**: pin a version in
`requirements.txt` / `pyproject.toml` (e.g., `networkx>=3.3`).

### Version Control

| Operation | Tool |
|---|---|
| Atomic commit staging | `git add -p` (interactive hunk staging) |
| Commit message format | Conventional Commits: `[emoji] type(scope): message` per FOUNDRY `commit-message.md` |

---

## 3. Idioms

### INVEST Right-Sizing Checklist (apply before any decomposition output is emitted)

```
[ ] Independent: buildable and shippable without depending on an unbuilt slice
[ ] Negotiable: acceptance criteria are discussion points until spec-freeze (GO commit)
[ ] Valuable: produces measurable user capability; not pure infra/tech-debt
[ ] Estimable: concrete work ≤ 8 hours including review/debug; team can size in half-days
[ ] Small: diff ≤ 400 LOC new/changed; expert review ≤ 90 minutes; touches ≤ 5 files
[ ] Testable: ≥1 failing test at end of Phase 3; ≥1 passing story test at end of Phase 5
```

If any check fails → **SPLIT and implement first part only**.

### Thinness Test (4-of-4 must pass before declaring a slice shippable)

1. Describable in ONE sentence as a user-meaningful change.
2. Diff reviewable in ONE sitting by the reviewer agent (including perf baseline sampling).
3. Produces ≥1 NEW or CHANGED STORY test asserting user value.
4. Shippable to production without depending on any unbuilt future slice.

### Three Decomposition Patterns (for parallelisation routing)

| Pattern | Definition | Scheduling |
|---|---|---|
| **Sequential** | Each sub-job output feeds the next sub-job input | Queue in topological order |
| **Parallel** | Sub-jobs have zero shared state or overlapping file footprint | Dispatch to PHASE_POOL concurrently across items |
| **Hybrid** | Sequential phases with parallel branches within each | Detect per-tier; apply parallel dispatch within tier |

### Sentinel Chain (emit one sentinel per phase per atomic job)

```
SENTINEL::PLAN_COMPLETE::ROADMAP-{N}::PASS::{plan_path}
SENTINEL::EARS_COMPLETE::ROADMAP-{N}::PASS::{EARS-042,EARS-043,...}
SENTINEL::FEATURE_COMPLETE::ROADMAP-{N}::PASS::{scenario_count}::{feature_file_path}
SENTINEL::TESTS_WRITTEN::ROADMAP-{N}::RED::{test_count}::{EARS-IDs}
SENTINEL::IMPL_COMPLETE::ROADMAP-{N}::GREEN::{changed_files}::{coverage_pct}
SENTINEL::STORY_PROVEN::ROADMAP-{N}::PASS::{story_test_count}::{line_coverage}::{branch_coverage}
SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{git_sha}
```

Sentinels are **immutable post-emission**. A cold-start agent reconstructs job state entirely from
the sentinel chain — it is the canonical resumption mechanism.
Full format spec: `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md`.

### Model-Tier Allocation (cost-aware; do not deviate)

| Phase | Agent / Handler | Model tier | Rationale |
|---|---|---|---|
| 0 · PLAN | ds-step-0-plan | sonnet | Mechanical: scan, write plan file |
| 1 · EARS | ds-step-1-ears | **opus** | Spec nuance; form selection requires reasoning |
| 2 · FEATURE | ds-step-2-feature-docs | **opus** | Scenario design; story-craft |
| 3 · TEST | ds-step-3-tests + first-run | **haiku** | Mechanical: enumerate branches, write assertions |
| 4 · IMPLEMENT | PYTHON/JS/RUST-AGENT | **sonnet** | Balance: design patterns + code clarity |
| 5 · STORY | ds-step-story-tests | **opus** | UI journey reasoning; perf assertion design |
| 6 · DELIVERY | ds-step-7/8/9 | sonnet | Mechanical: rebase, message, push |

Mis-tiering haiku on EARS causes downstream rework. Mis-tiering opus on TEST wastes ~40–60% budget.
Canonical reference: `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md`.

### Phase Gate Reviewer Panels

| Gate | Reviewers | Hard conditions |
|---|---|---|
| EARS exit | EARS-REVIEWER, SMU-REVIEWER | Each EARS has unique ID; statement unambiguous |
| Feature exit | BDD-REVIEWER, COVERAGE-REVIEWER | ≥3 scenarios per EARS (happy/unhappy/abuse); `@EARS-{ID}` tags; Gherkin executable |
| Test exit | TEST-DESIGN-REVIEWER, COVERAGE-REVIEWER | 100% line coverage target; all tests RED; gap map complete |
| Implement exit | DESIGN-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER | All Phase-3 tests GREEN; no test-file mutations; coverage ≥ baseline |
| Story exit | SECURITY-REVIEWER, REGRESSION-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER | STORY_PROVEN sentinel emitted; line + branch = 100%; E2E pass; perf gate pass |

---

## 4. Anti-Patterns & Failure Modes

| Failure | Symptom | Fix |
|---|---|---|
| **Job spans multiple EARS / user stories** | EARS-REVIEWER rejects; scope ambiguous to feature-writer | Split job before Phase 1; one job = one EARS (±2 related) |
| **Horizontal work ("build whole data layer first")** | UI integration deferred; learning deferred; no shippable increment | Insist on vertical slices that touch every needed layer end-to-end |
| **Gherkin only, no test code** | TEST-AGENT finds `.feature` file but no `.py`/`.js`/`.rs` test file; COVERAGE-REVIEWER blocks | Gherkin ≠ test code. Both artefacts are required before the Phase 2→3 gate |
| **Test mutation in Phase 4** | REGRESSION-REVIEWER catches test-file delta; build fails | Test files immutable post-Phase 3; if test is wrong → revert IMPLEMENT → rerun Phase 3 |
| **Missing STORY_PROVEN sentinel** | Job stalls; Phase 6 never triggers | STORY phase is mandatory (§16 builder/SKILL.md); gate Phase 6 entry on STORY_PROVEN |
| **Flaky tests patched with retries** | Suite intermittently fails; `--retries` masks root cause | Find race condition in code; deterministic waits; run 3× without `--retries` |
| **Circular job dependencies** | Topological sort fails; remaining edges > 0 post-sort | HALT at decomposition time; surface cycle path (A→B→C→A); do not execute cyclic plan |
| **Over-fragmentation (depth > 3)** | Coordination tax exceeds parallelisation gain; predecessor count per task > 2 | Collapse sub-jobs; re-evaluate scope; escalate to architect if stuck |
| **Implicit dependencies** | False parallelisation claims; hidden ordering constraints | Every dependency must be explicitly encoded in the DAG; never infer from titles alone |
| **Shared-infrastructure blindness** | Multiple "parallel" tasks share same API, DB, or build tool | Scan all sub-jobs for overlapping resource footprint; group shared setup into a dedicated sequenced phase |
| **Speculative abstraction** | Complexity added without user story anchoring it | "We might need this later" is not a valid EARS statement; defer until a story makes it valuable |
| **Premature infrastructure** | Framework plumbing cannot ship as an independent increment | Must be attached to a user-facing story or removed from the current roadmap item |

---

## 5. Environment-Detection Snippet

The handler must detect the dominant stack to route Phase 4 to the correct VALUE_HANDLER. Use this
deterministic probe; extend the `elif` chain for additional stacks.

```bash
#!/usr/bin/env bash
# detect-stack.sh — emit primary VALUE_HANDLER name for IMPLEMENT phase
# Outputs one of: PYTHON-AGENT | JS-AGENT | TS-AGENT | RUST-AGENT | UNKNOWN
# Run from repository root.

set -euo pipefail
ROOT="${1:-.}"

py_count=$(find "$ROOT" -name "*.py" -not -path "*/.*" | wc -l)
rs_count=$(find "$ROOT" -name "*.rs" -not -path "*/.*" | wc -l)
ts_count=$(find "$ROOT" -name "*.ts" -not -path "*/.*" | wc -l)
js_count=$(find "$ROOT" -name "*.js" -not -path "*/.*" | wc -l)

max=$((py_count > rs_count ? py_count : rs_count))
max=$((max > ts_count ? max : ts_count))
max=$((max > js_count ? max : js_count))

if   [ "$py_count" -eq "$max" ] && [ "$max" -gt 0 ]; then echo "PYTHON-AGENT"
elif [ "$rs_count" -eq "$max" ] && [ "$max" -gt 0 ]; then echo "RUST-AGENT"
elif [ "$ts_count" -ge "$js_count" ] && [ "$max" -gt 0 ]; then echo "TS-AGENT"
elif [ "$js_count" -gt 0 ]; then echo "JS-AGENT"
else echo "UNKNOWN"; fi
```

**Note**: For polyglot repos where two stacks tie in file count, manual architect override is
required. The decomposition agent should surface the tie and request a disambiguation directive
before emitting the Phase 4 handler assignment.

---

## 6. Test & Validation Strategy

### Unit Tests for the Decomposition Handler Itself

1. **INVEST gate** — given an oversized story (>5 acceptance criteria, >5 files, 90 min estimate),
   assert the handler emits a SPLIT directive and does not emit Phase 1 sentinels.
2. **Thinness test** — given a story that fails criterion 3 (no new STORY test produced), assert
   the handler rejects it and proposes a split.
3. **Acyclic graph** — given a valid 5-node DAG, assert topological sort produces a valid ordering
   and all generations satisfy `intra-level edge count = 0`.
4. **Cyclic graph** — given A→B→C→A, assert the handler halts, emits cycle path, and does not
   proceed to Phase 1.
5. **Stack detection** — given a fixture repo with 10 `.py` / 2 `.js` files, assert `PYTHON-AGENT`
   is selected; given 5 `.ts` / 5 `.js` files, assert `TS-AGENT` wins the tie-break.
6. **Sentinel chain reconstruction** — given a partial sentinel chain up to `TESTS_WRITTEN`,
   assert the handler correctly determines the job is in Phase 4 (IMPLEMENT) on cold-start resume.

### Integration Tests

- **End-to-end decomposition** — real roadmap item with 3 acceptance criteria → handler outputs
  sub-jobs, dependency graph, model-tier assignments, and Phase 0 PLAN sentinels. Spot-check
  3–5 complex items (cross-stack, multi-phase features, refactorings with shared infra).
- **Gate enforcement** — mock a Phase 3 exit where coverage = 97%; assert the Phase 4 entry gate
  rejects and returns a NEEDS_REVISION verdict.
- **Immutability check** — mock a Phase 4 agent that attempts a test-file diff; assert
  REGRESSION-REVIEWER emits a BLOCK verdict and the job reverts to Phase 3.

### Coverage Requirements for the Handler

The handler itself must meet the same 100% line coverage floor it enforces on the jobs it
decomposes. Use `coverage.py`/`nyc`/`tarpaulin` as appropriate for the handler's implementation
language. No exceptions.

---

## 7. Thin / Unresolved Areas (Flagged for Author)

**THIN-1 · NetworkX version pinning absent.**
Research-02 names NetworkX but gives no version. Author must pin (recommend `networkx>=3.3,<4`)
and test against it in CI.

**THIN-2 · Polyglot tie-break rule is not fully specified.**
Research-03 says "handler choice is deterministic" but does not define the tie-break when two
stacks are equal in file count. The environment-detection snippet above defaults to architect
override; author should codify a secondary heuristic (e.g., entry-point file name convention,
`package.json` vs `Cargo.toml` presence) before shipping.

**THIN-3 · Acceptable-cycle policy is unresolved.**
Research-02 acknowledges some teams tolerate backlog cycles (feature-flag-gated re-enable loops)
but the FOUNDRY pipeline (research-03) treats cycles as a HALT condition. **Resolution adopted
here**: default is HALT (acyclic required); any tolerated cycle must be explicitly declared by
the roadmap author with a written justification. The decomposition handler must surface both
options and prompt for a directive; it must not silently accept a cycle.

**THIN-4 · No timeout specified for NEEDS_REVISION re-run loops.**
Research-03 mentions "max 3 cycles, then BLOCK" for the Feature→Test gate but does not specify
limits for other gates. Author should define a uniform retry ceiling (recommend: 3 reruns → BLOCK
for all reviewer panels) and wire it into the gate protocol.

**THIN-5 · Story-test tooling for non-browser surfaces.**
Research-01/03 discuss Playwright for browser UIs. CLI, API, and TUI surfaces are mentioned in
research-03 (`CLI-HARNESS`, `API-HARNESS`) but no canonical implementation is described. Author
must define harness contracts for each surface type before the STORY phase is fully specified.

**THIN-6 · Perf baseline format and delta gate threshold not specified.**
Research-01 references a "perf baseline" and "perf-delta gate" but gives no numeric threshold,
file format, or baseline initialisation procedure. Author must pull from
`${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md` and embed concrete numbers in the handler.
