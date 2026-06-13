# Roadmap-Item Decomposition Research — Axis 3: Pipeline Phase Mapping

## Atomic Jobs → FOUNDRY Phase Pool Flow

### Core Pattern: EARS → Feature → Test → Implement → Story → Delivery

**The mapping contract:**
- Each decomposed atomic job carries ONE behaviour pinned by EARS statement(s) (e.g., `EARS-042`)
- Job flows through fixed sequence: PHASE_POOL = `EARS-AGENT → FEATURE-AGENT → TEST-AGENT → IMPLEMENT-AGENT → STORY-AGENT → DELIVERY-AGENT`
- Between every phase transition: REVIEWER panel gates advancement (§9 builder/SKILL.md)
- Sentinels accumulate per job, creating traceable chain from EARS through DELIVERY
- **Key: atomic job = one indivisible unit across all 6 phases; never split a job mid-phase**

### Phase Gate Handoff Protocol

**Entry criterion (pre-EARS):**
- Job has PLAN sentinel from §0 (ds-step-0-plan); SUBJECT_MATTER_UNDERSTANDING loaded; codebase scan complete

**EARS→Feature gate (after Phase 1):**
- Reviewers: EARS-REVIEWER, SMU-REVIEWER
- Must pass: each EARS statement unique ID assigned; statement is unambiguous to feature-writer
- Verdict: PASS → proceed to Phase 2; NEEDS_REVISION → EARS-AGENT reruns; BLOCK → escalate

**Feature→Test gate (after Phase 2):**
- Reviewers: BDD-REVIEWER, COVERAGE-REVIEWER
- Must pass: ≥3 scenarios per EARS (happy/unhappy/abuse); each tagged `@EARS-{ID}`; scenarios are executable Gherkin
- Verdict: PASS → proceed to Phase 3; NEEDS_REVISION → FEATURE-AGENT reruns (max 3 cycles, then BLOCK)

**Test→Implement gate (after Phase 3):**
- Reviewers: TEST-DESIGN-REVIEWER, COVERAGE-REVIEWER
- Must pass: 100% line coverage target; all tests RED; gap map complete (which EARS are exposed/covered)
- Verdict: PASS → proceed to Phase 4; NEEDS_REVISION → TEST-AGENT reruns

**Implement→Story gate (after Phase 4):**
- Reviewers: DESIGN-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER
- Must pass: all Phase 3 tests now GREEN; no manual test modifications allowed; coverage ≥expected baseline
- Verdict: PASS → proceed to Phase 5; NEEDS_REVISION → IMPLEMENT-AGENT fixes code (test files immutable)

**Story→Delivery gate (after Phase 5):**
- Reviewers: SECURITY-REVIEWER, REGRESSION-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER
- Must pass: STORY_PROVEN sentinel emitted; line+branch coverage = 100%; E2E story test(s) all pass; perf assertions pass
- Prerequisite: STORY_PROVEN is *only* terminal signal before DELIVERY (§16 builder/SKILL.md); without it, job cannot ship
- Verdict: PASS → proceed to Phase 6; NEEDS_REVISION → STORY-AGENT reruns; BLOCK → escalate (rare)

**Delivery→Complete (Phase 6):**
- Steps: sync+rebase, commit-message write, push; roadmap STATUS updated to COMPLETE; DELIVERY_COMPLETE sentinel emitted
- IDEA_COST record written (§12 builder/SKILL.md); lifecycle BUILD phase marked done (if i2p installed)

### Sentinel Chain (Traceability Ledger)

Each atomic job accumulates ONE sentinel per phase:
```
SENTINEL::PLAN_COMPLETE::ROADMAP-{N}::PASS::{plan_path}
SENTINEL::EARS_COMPLETE::ROADMAP-{N}::PASS::{EARS-042,EARS-043,...}
SENTINEL::FEATURE_COMPLETE::ROADMAP-{N}::PASS::9::features/user-auth.feature
SENTINEL::TESTS_WRITTEN::ROADMAP-{N}::RED::27::EARS-042,EARS-043
SENTINEL::IMPL_COMPLETE::ROADMAP-{N}::GREEN::4::98.3
SENTINEL::STORY_PROVEN::ROADMAP-{N}::PASS::6::100.0::100.0
SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::a1b2c3d
```
- Format spec: `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md`
- Sentinels are **immutable post-emission**; every downstream agent sees the full chain
- Used to resume paused cycles (cold-start agent reconstructs job state from sentinel chain alone)

### VALUE_HANDLER_POOL Routing

When LEAD ENGINEER decomposes a heavy item via `handler-roadmap-decomposition`, each atomic job declares its required VALUE_HANDLER(s):

| Phase | Handler invoked | Model tier | Responsibility |
|---|---|---|---|
| EARS (Phase 1) | ds-step-1-ears (builtin) | opus | Write EARS statements; unique IDs |
| FEATURE (Phase 2) | ds-step-2-feature-docs (builtin) | opus | Write Gherkin; tag with EARS IDs |
| TEST (Phase 3) | ds-step-3-tests + ds-step-4-first-test-run + PYTHON-AGENT/JS-AGENT/... | haiku | Write failing tests; 100% coverage target |
| IMPLEMENT (Phase 4) | PYTHON-AGENT/JS-AGENT/RUST-AGENT/... (spawned per stack) | sonnet | Implement to make tests pass; code design via CODE_QUALITY |
| STORY (Phase 5) | ds-step-story-tests + PLAYWRIGHT-AGENT/CLI-HARNESS/API-HARNESS | opus | E2E story tests; full UI journey |
| DELIVERY (Phase 6) | ds-step-7-sync + ds-step-8-commit-message + ds-step-9-commit-push (builtin) | sonnet | Sync, message, commit, push |

**Allocation rule**: IMPLEMENT-AGENT spawns language-specific VALUE_HANDLER based on dominant file type in job's target codebase. Handler choice is deterministic, not free-form.

### Failure Mode: Common Decomposition Errors

**1. Job spans multiple EARS statements, multiple USER STORIES**
- Symptom: EARS-REVIEWER rejects because one job covers EARS-042 *and* EARS-043; feature-writer sees ambiguous scope
- Fix: Split job. One job = one EARS statement (or tightly-coupled set ≤3 from same user journey)

**2. Job touches ≥2 VALUE_HANDLER stacks**
- Symptom: IMPLEMENT-AGENT cannot spawn (unclear which handler owns the contract); code ownership muddy
- Fix: Split job so IMPLEMENT phase touches one stack. (Exception: orchestration jobs that glue stacks; rare, requires architect)

**3. Gap between Feature and Test: Gherkin written but no test code**
- Symptom: TEST-AGENT finds only `.feature` file, no `test_*.py` or `*.spec.js`; coverage undefined; COVERAGE-REVIEWER blocks
- Fix: Feature & test code are **two separate artefacts in same phase**; both must exist before gate

**4. Test file modified during IMPLEMENT phase**
- Symptom: IMPLEMENT-AGENT changes test expectations to fit implementation; REGRESSION-REVIEWER catches during final gate; job fails
- Fix: Test files are immutable post-Phase 3. If test is wrong, revert implementation and return to Phase 3 (TEST-AGENT reruns)

**5. Story test skipped or incomplete**
- Symptom: STORY_PROVEN sentinel never emitted; no DELIVERY phase triggered; job stalls in pipeline
- Fix: STORY phase is **mandatory** (§16 builder/SKILL.md); 100% coverage required; no job ships without STORY_PROVEN

### Parallel Grouping Within a Tier

LEAD ENGINEER's Phase 5 (builder-lead.md) produces parallel grouping *across roadmap items*. But **atomic jobs within a single item always run in sequence** (Phase 0→1→2→3→4→5→6). Parallelisation opportunity:

- If `handler-roadmap-decomposition` breaks Item #5 into **Sub-jobs A, B, C**, and they have **zero shared state**
- Can Sub-jobs run phases in parallel? **No.** The PHASE_POOL is a global resource. All jobs compete for one instance of each phase agent.
- Sub-jobs queue: A·Phase1 → A·Phase2 → A·Phase3 → ... ; while B waits for A to finish Phase 1 before B enters Phase 1
- **Exception**: IMPLEMENT & STORY phases can spawn multiple VALUE_HANDLER threads in parallel (e.g., PYTHON-AGENT + JS-AGENT on same job)

Parallel grouping optimizes **across items**, not within them. Within an item, phases are strictly sequential; within a phase, handlers can fan out.

---

## Current Best Practice (2025–2026)

### BDD Integration with CI/CD Phase Gates

**Standard pattern:**
- BDD scenarios (Gherkin) serve as *executable acceptance criteria*, not documentation
- Each scenario tagged with requirement ID (EARS-{N}) for traceability
- CI/CD pipeline automatically runs Gherkin scenarios on every commit (Semaphore/CircleCI standard)
- Phase gates are implicit: if Gherkin scenarios fail, the job does not advance

**Tool ecosystem:**
- Cucumber/Gherkin: de facto BDD standard (language-agnostic)
- Playwright: cross-browser E2E; fastest feedback loop (vs Cypress, Selenium)
- pytest-bdd (Python), jest-cucumber (JS): unit→integration bridging
- CI platforms (CircleCI, Semaphore, GitHub Actions): natively integrate Gherkin execution

**Metric:** 26% of QA teams report full DevOps integration as of 2026 (Sembi Software Quality Pulse)—still asymmetric adoption.

### Test-Driven Development (TDD) Model Tier Allocation

**Canonical reference:** `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md`

- **EARS (Phase 1)**: opus (reasoning over spec clarity; nuance in requirement form selection)
- **Feature docs (Phase 2)**: opus (story-craft; scenario design requires domain reasoning)
- **Test code (Phase 3)**: haiku (mechanical: enumerate branches, write assertions)
- **Implementation (Phase 4)**: sonnet (balance: design patterns, code clarity, minimal loops)
- **Story tests (Phase 5)**: opus (integration; UI journey reasoning; performance assertion design)
- **Delivery (Phase 6)**: sonnet (mechanical: rebase, message, push)

**Why tiering matters:** Haiku on test-writing phase can cut cost 40–60% vs opus; sonnet on IMPLEMENT balances speed with code quality. Mis-tiering (e.g., haiku on EARS) causes rework downstream.

### Coverage Standards & Validation

**100% line coverage floor (non-negotiable):**
- Every uncovered line = unpinned behaviour = latent defect
- Valid escape: `# pragma: no cover` with justification (rare; logged in code)
- Verified at **end of TEST phase** (must be RED 100% coverage) and **end of STORY phase** (must be GREEN 100% coverage)
- Tools: `coverage.py` (Python), `nyc`/`c8` (JavaScript), `tarpaulin` (Rust)

**Coverage feedback in CI/CD:** Fail the job if coverage drops below baseline. Most CI platforms support this natively (GitHub Actions, CircleCI, etc.).

### Atomic Job Sizing Heuristic

**INVEST boundaries (per research-01.md + current industry practice):**
- **Estimable**: Team can size in half-days (1–4 hours concrete work; ≤8 hours with review/debug)
- **Testable**: ≥1 failing test at end of Phase 3; ≥1 passing story test at end of Phase 5
- **Small**: Code review fits in ≤90 minutes for expert (≤400 LOC new/changed)
- **Valuable**: Produces measurable user capability; not pure infra or tech debt

**Red flags (job too big; split required):**
- Diff touches >5 files
- Review time estimate >90 min
- Crosses >2 VALUE_HANDLER stacks
- Acceptance criteria >5 items
- Estimate confidence <70%

### Common Failure Modes & How to TEST/Validate

| Failure Mode | Detection method | Validation |
|---|---|---|
| Job spans multiple EARS | EARS-REVIEWER panel rejects; manual parse shows >1 EARS-{N} in single job scope | Write EARS statements early; one job = one EARS ID (±2 related) |
| Incomplete Feature file | COVERAGE-REVIEWER flags; Gherkin scenarios < 3 per EARS | Playbook: for each EARS, write 3 scenarios (happy/unhappy/abuse); verify `@EARS-{ID}` tags present |
| Test code missing | TEST-AGENT finds only `.feature`, no language-specific test file | Gherkin is NOT the same as test code; write `.py`/`.js`/`.rs` test file separately; verify both exist |
| Flaky tests | STORY-AGENT reruns STORY phase; tests fail non-deterministically on re-run | Ban `sleep()` / `waitFor()` timeouts; poll for actual state; run full suite ≥3× without `--retries` |
| Coverage gaps | Coverage report shows <100% line coverage at Phase 3 or Phase 5 gates | Run `coverage.py report` or `nyc report`; add tests for each uncovered branch; re-run until 100% |
| Test mutation during IMPLEMENT | REGRESSION-REVIEWER catches test file delta during Phase 4; build fails | Make test files immutable post-Phase 3; if test is wrong, revert IMPLEMENT and re-run Phase 3 (TEST-AGENT) |
| Missing STORY_PROVEN sentinel | Job stalls; DELIVERY phase never triggered | STORY phase is mandatory; verify `SENTINEL::STORY_PROVEN` emitted before Phase 6 can run; gate in code |
| Circular job dependencies | Topological sort fails; cycle detected in decomposition | Validate with: `builder-lead` Phase 4.5 detects cycles; HALT and surface the cycle path to user |

---

## Sources

- [Test-Driven Development (TDD): A Comprehensive Guide For 2025](https://monday.com/blog/rnd/what-is-tdd/)
- [Accelerate your CI/CD Pipeline with BDD and Acceptance Testing - Semaphore](https://semaphore.io/blog/bdd-acceptance-testing)
- [BDD using Cucumber and Gherkin - Medium](https://medium.com/@kaustubh.saha/bdd-using-cucumber-and-gherkin-9f3b3d1f081b)
- [Playwright BDD: Setup, Gherkin & E2E Testing Guide](https://testdino.com/blog/playwright-bdd)
- [Agile Testing Methodology: Life Cycle, Techniques and Strategy](https://www.testrail.com/blog/agile-testing-methodology/)
- [Test-driven development (TDD) explained - CircleCI](https://circleci.com/blog/test-driven-development-tdd/)
- FOUNDRY builder/SKILL.md §7 (PHASE_POOL pipeline) & §9 (REVIEWER panel)
- FOUNDRY builder-lead.md Phase 4 (work decomposition) & Phase 4.5 (cycle-integrity gates)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md` (sentinel format & accumulation)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md` (tier allocation per phase)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md` (coverage & test pyramid)
