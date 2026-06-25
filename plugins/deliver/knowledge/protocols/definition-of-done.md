# Definition Of Done — Template

> For DELIVER DEV_SYSTEM. Each project that uses the Development System MUST create
> `DEFINITION_OF_DONE.md` at the project root using this template. All stage agents
> read this file before beginning work.
>
> **MANDATORY:** If `DEFINITION_OF_DONE.md` is absent, `ds-step-0-plan` creates it
> from this template before doing anything else. No phase may proceed without it.

---

## How To Use This Template

Copy this file to the project root as `DEFINITION_OF_DONE.md`. Fill in the
project-specific values where indicated. Every stage agent will read this file at
startup to understand the shared quality bar for the current project.

---

```markdown
# Definition Of Done

Date: {YYYY-MM-DD}
Scope: IDEATE-originated items processed through the Development System (Steps 0-9)
Owner: Development System Orchestrator

## Purpose

This document defines the shared, non-negotiable quality bar for every IDEATE item
in this project. All agents must consult this file before they begin work and before
they hand off to the next stage.

## Meaning Of Done

The target value is not "code exists". The target value is:
- The original problem is demonstrably solved for intended actors.
- The solution is specified, documented, tested, proven, and packaged for shipment.
- Evidence exists for behavior under happy, unhappy, and abuse conditions.
- Upstream/downstream handoffs are complete, explicit, and auditable.
- Every generated document has passed a reviewer-agent check with approved updates.

## Universal Done Gates

### 1. Problem-Solution Traceability
- Every artifact traces back to the IDEATE brief: problem, actors, scope, constraints.
- Each requirement has a stable ID and mapping to tests.

### 2. Specification Integrity
- EARS statements are complete, unambiguous, and uniquely ID'd.
- Gherkin scenarios cover happy, unhappy, and abuse paths.
- All `.feature` files are either wired to a passing test runner OR explicitly moved to
  `doc/spec/` with a `# SPECIFICATION ONLY — NOT EXECUTABLE` header. Unwired `.feature`
  files in `test/` or `features/` are a **blocking defect**.

### 3. Test Evidence — Non-Negotiable
- Tests fail before implementation (RED evidence) and pass after (GREEN evidence).
- Regressions are absent in full-suite runs.
- **No coverage gaps are accepted without explicit deletion or test closure.**
  The phrase "unresolved gaps are accepted" is NOT allowed in any handoff or reviewer report.
- Line coverage threshold: **100%** for all non-generated, non-migration code.
- Branch coverage threshold: **100%** — every if/else/try/except arm must be reached.
  Use `--cov-branch` (Python) or equivalent. A file at 100% line coverage with untested
  error branches is NOT done.
- Every error path (guard clause, exception handler, else arm) has a test that
  deliberately triggers it and asserts the error response.

### 4. Dead Code Policy
- Any file with < 50% line coverage before this item's changes has two valid dispositions:
  1. **Delete it.** Unused code with no tests must be removed.
  2. **Test it.** If the code is actively used, write the missing tests now.
  "Retain for backward compatibility" without tests is **not a valid disposition**.
- The IMPL_COMPLETE sentinel MUST include `dead_code_disposition: deleted|tested` for any
  such file.

### 5. BDD Executability
- BDD step definitions must exist for every Gherkin scenario wired to the test runner.
- **Before writing any new BDD tests**, confirm the BDD harness is installed:
  `grep -r "pytest_bdd\|from behave\|@scenario" test/`
  If no step definitions exist, surface this to the user before proceeding.
- Gherkin scenarios without step definitions are documentation, not tests. They do not
  count toward any coverage gate.

### 6. Story / E2E Tests
- At least one story test per feature exercises the **complete, unmocked stack** — real
  server, real disk, no route mocking — to prove the deployment unit works end-to-end.
- Every UI element added or changed by this feature is covered by a Playwright test that
  follows the full gesture path: navigate → find → toBeVisible() → act → verify UI reacts
  → reload → verify persists.
- Story tests that mock every route are integration tests, not story tests.

### 7. Performance Evidence
- Every feature that introduces a latency-sensitive path must include at least one
  performance assertion:
  - API endpoint (simple): p95 < 200 ms
  - API endpoint (heavy): p95 < 5000 ms
  - Page load: domContentLoaded < 3000 ms
  - Disk write: wall time < 100 ms
  - Scheduler: wall time documented and asserted ≤ N × current
- Missing performance assertions for a latency-sensitive path = **blocking defect**.

### 8. Implementation Quality
- Production code satisfies spec intent (not just literal assertions).
- Reuse, consistency, and architecture boundaries are maintained.
- Security constraints are addressed — no XSS, injection, or OWASP top-10 defects introduced.

### 9. Integration And Release Readiness
- Upstream sync completed and validated post-sync.
- Commit message documents WHY/WHAT/TESTING/ROADMAP closure.
- Roadmap and plan artifacts updated to COMPLETE state.

### 10. Reviewer Gate Compliance
- Every newly generated or materially changed document reviewed by reviewer agent.
- Reviewer recommendations applied or explicitly dispositioned.
- Zero unresolved CRITICAL findings.

### 11. Handoff Contract Completeness
- Each stage output includes downstream instructions, artifact references, unresolved
  risks, and acceptance checks in the handoff-protocol YAML schema.

## Stage-Specific Done Criteria

### Step 0 — Plan
- Plan exists at `doc/[FEATURE_SLUG]_PLAN.md`
- `DEFINITION_OF_DONE.md` exists at project root (created from template if absent)
- BDD harness check documented (installed? yes/no — surface to user if no)
- Checklist for Steps 0-9 + story phase present
- Resumption section present and explicit

### Step 1 — EARS
- EARS file updated with unique IDs
- Every statement testable and mapped forward
- EARS-REVIEWER: PASS

### Step 2 — Feature Docs
- `.feature` scenarios exist for happy/unhappy/abuse paths
- Scenario tags reference EARS IDs
- UI elements requiring interaction tests listed in "UI ELEMENTS REQUIRING INTERACTION TESTS" block
- BDD-REVIEWER: PASS

### Step 3 — Tests
- Tests authored to match EARS and Gherkin contracts — **both** happy AND all error/guard paths
- Error paths deliberately triggered and response asserted (not just "no exception propagates")
- Branch coverage intent documented — every if/else/try/except arm covered
- BDD step definitions written (or BDD harness absence surfaced to user)
- Playwright interaction test skeletons written for all UI elements (RED — element not in DOM yet)
- Performance test skeleton present for every latency-sensitive path
- New tests are RED for expected feature-gap reasons (not infrastructure errors)
- TEST-DESIGN-REVIEWER: PASS

### Step 4 — First Test Run
- Failure surface documented (gap map)
- Pre-existing tests remain passing
- Red reasons classified: feature-gap (expected) vs infrastructure (must fix)

### Step 5 — Implementation
- Minimal implementation added to satisfy failing tests
- Test intent not changed during implementation
- Dead code disposition documented for any file < 50% coverage before this item
- DESIGN-REVIEWER: PASS

### Step 6 — Green Run
- Full suite is green: unit + integration + BDD (where harness exists)
- **Line coverage = 100%** for all changed files
- **Branch coverage = 100%** — `--cov-branch` or equivalent confirmed
- No regressions
- Post-green spec conformance confirmed
- REGRESSION-REVIEWER: PASS

### Step Story — Story / E2E Tests
- At least one story test per feature exercises the **complete, unmocked stack**
- All UI elements in the "UI ELEMENTS REQUIRING INTERACTION TESTS" block have passing
  Playwright gesture tests
- All Gherkin scenarios in wired `.feature` files have passing step definitions
  (or files are explicitly moved to `doc/spec/` as SPECIFICATION ONLY)
- Performance assertion passes for each latency-sensitive path
- Total line coverage = 100%, branch coverage = 100%
- STORY-AGENT: PASS + UI_GATE_PASSED sentinel emitted
- SECURITY-REVIEWER, REGRESSION-REVIEWER, COVERAGE-REVIEWER: PASS

### Step 7 — Sync
- Fetch/rebase-or-merge completed
- Tests re-run green after sync

### Step 8 — Commit Message
- Message follows WHY/WHAT/TESTING/ROADMAP structure
- Diff summary aligns with actual changed files
- Reviewer: PASS

### Step 9 — Commit And Push
- Adversarial review (`/deliver:pr-review`) returned PASS
- Changes committed and pushed
- Delivered per merge governance ([`merge-governance.md`](merge-governance.md)):
  **direct-merge** → merged to `main`, roadmap STATUS: COMPLETE with date;
  **pr-approval** → branch pushed + PR opened, roadmap STATUS: AWAITING MERGE (→ COMPLETE on human merge)
- Plan file completion section populated with commit hash and date

## Orchestrator Exit Condition

An IDEATE item is done ONLY when:
- All stage-specific done criteria are satisfied.
- All universal gates are satisfied.
- Line coverage = 100% AND branch coverage = 100% (confirmed with `--cov-branch`).
- All `.feature` files wired to test runner have passing step definitions, OR are
  explicitly in `doc/spec/` labelled SPECIFICATION ONLY.
- At least one unmocked full-stack story test passes per feature.
- Every latency-sensitive path has a passing performance assertion.
- **`STORY_PROVEN` (Phase 5) is present**, and the delivery sentinel matches the merge-governance
  mode ([`merge-governance.md`](merge-governance.md)): under **direct-merge**, `DELIVERY_COMPLETE`
  is present (the change is on `main`); under **pr-approval**, the item legitimately rests at
  `AWAITING_MERGE` (PR open, review PASSed) with `DELIVERY_COMPLETE` following only on the human
  merge. `STORY_PROVEN` absent is an integrity violation (shipped without E2E evidence);
  `DELIVERY_COMPLETE` *without* a preceding `STORY_PROVEN` is likewise a violation. An item at
  `AWAITING_MERGE` is **DoD-satisfied but not yet on `main`** — final closure is the merge.
- Reviewer gate has zero unresolved CRITICAL findings.
- Orchestrator marks the item COMPLETE in loop state.

## Required Carry-Over Message Schema

Use in every stage handoff (from `handoff-protocol` skill):

\`\`\`yaml
handoff:
  from_stage: step-x
  to_stage: step-y
  objective: "single sentence objective"
  artifacts:
    - path: "..."
      purpose: "..."
      version: "..."
  unresolved_risks:
    - "..."
  quality_gates_passed:
    - "..."
  reviewer_status:
    reviewed: true
    findings_summary: "..."
    critical_open: 0
  next_agent_instructions:
    - "..."
\`\`\`
```

---

## Notes For DELIVER Integration

When DELIVER is orchestrating items, the project's `DEFINITION_OF_DONE.md` is the
authority for what constitutes completion of a single item. DELIVER's `IDEA_COST.jsonl`
record is only written after the DoD audit passes.

The `lifecycle-orchestrator` agent performs the global DoD audit after step-9.
