# Test Policy Reference

> For FOUNDRY §11. The authoritative test pyramid policy for all projects
> driven through the FOUNDRY pipeline. Enforced by COVERAGE-REVIEWER at
> every phase transition.

---

## Core Principle

> **100% line coverage is the floor, not the goal. 100% branch coverage is required alongside it.**

Line coverage measures whether code was *executed* by tests. Branch coverage
measures whether every conditional outcome (if/else, try/except, switch arm,
ternary) was *reached*. A function with a single happy-path test may achieve
100% line coverage while the error branch — the one that protects production
from data corruption — was never executed. Both gates are mandatory.

FOUNDRY enforces coverage as a gate, not as an objective. The objective is
**behavioural correctness** — every requirement expressed in EARS statements
and Gherkin scenarios must be proven by a test that fails when the behaviour
changes.

---

## Coverage is the floor; density is the variable

100% line+branch coverage is the **floor** — the consequence of pinning every
behaviour, never a target to "chase." The thing you actually work is **coverage
density**: how many distinct behavioural axes each unit is pinned along.

> **THE ONLY WAY:** For every behaviour, the **happy / unhappy / abuse** triad is
> **table-stakes**, not extras. Happy = correct input → expected output. Unhappy =
> missing/invalid input → graceful, asserted failure. Abuse = boundary values,
> malformed/hostile input, resistance. A unit that is 100% covered by happy-path
> tests alone is *under-pinned* — it has high coverage and low density, and the gate
> has been satisfied without the solution being located.

Density is why a test is a **coordinate** (§Coordinates in practice): each axis
(empty, max, unicode, the error branch, the abuse case) narrows the region until
exactly one implementation satisfies all of them. Chasing the coverage *number*
optimises the wrong quantity; pinning every behaviour along every axis yields 100%
as a side-effect and locates the working solution as the point.

---

## Coordinates in practice — how to place a unit test

A failing unit test is a **coordinate in multidimensional logical space** (VALUE_FLOW §7): an
`input → expected output` assertion against a *pure* function that pins one point — or a
tightly-constrained region — in the space of all possible implementations. You navigate from SPEC
to PRODUCT by turning each coordinate green. These are the mechanical habits that make coordinates
*locate* the solution rather than merely *describe* it:

1. **Extract the pure core first.** If logic is tangled with DOM/IO/network, pull the decidable part
   into a pure function (see `architecture/pure-core.md`). A coordinate can only be placed in a pure
   space — side effects blur the location.
2. **Place the coordinate before the implementation.** Write it, run it, and confirm it **fails for
   the right reason** before making it pass. A test written after the code is a *description*; a test
   written before is a *location*.
3. **One axis per edge case.** Empty, whitespace-only, exactly-at-max, over-max, unicode, the
   boundary value exactly at the limit — one coordinate each. Together they narrow the region until
   exactly one implementation satisfies all of them.
4. **A bug fix gets a negation coordinate.** Its test is an input that must *not* yield the corrupt
   output. The coordinate *is* the bug's negation.
5. **Invariants get a property test.** "Never panics for any input", "valid input always
   round-trips" are properties, not examples — pin them with `proptest`/`fast-check`/`hypothesis`,
   not a handful of cases.
6. **Parse, don't validate.** Make construction fallible (`Thing::new(..) -> Result<Thing, Err>`);
   once the type is held, its invariants are guaranteed and no downstream code re-checks them. The
   coordinate that pins construction pins the whole system.
7. **Typed errors, never strings.** A coordinate can assert `Err(TooLong { max: 64, got: 65 })`
   exactly; a `String`/free-text error cannot be matched precisely, so the coordinate is blurry and
   refactors silently change the message without failing a test.

> **WORKED EXAMPLE:** `rust-webapp-rollout`'s `forge-core` pins `Greeting::new` with one coordinate
> per edge (`""`/`"   "` → `EmptyName`; 65 chars → `TooLong{max:64,got:65}`; exactly 64 → `Ok`;
> `"  Ada  "` → trims) plus two `proptest` invariants (every valid name appears in its message;
> construction never panics for any string). Together they leave exactly one correct implementation.

---

## The Test Pyramid

```
          ┌──────────────┐
          │ PERFORMANCE  │  Timing — throughput, latency, response time
          │    TESTS     │  Applied at every layer that has measurable SLOs
          ├──────────────┤
          │   STORY /    │  E2E — user journeys through the real interface
          │   E2E TESTS  │  Playwright, httpx, CLI subprocess
          ├──────────────┤
          │     BDD      │  Behavioural — Gherkin scenarios EXECUTED
          │    TESTS     │  pytest-bdd, behave, cucumber (NOT documentation)
          ├──────────────┤
          │ INTEGRATION  │  Service interactions, disk I/O, external APIs
          │    TESTS     │  Real dependencies, error paths simulated
          ├──────────────┤
          │    UNIT      │  Functions, classes, pure logic
          │    TESTS     │  pytest, jest, vitest — isolated, fast, exhaustive
          └──────────────┘
```

**All five layers must be present for every roadmap item processed by FOUNDRY.**
No layer substitutes for another. Each proves something the others cannot.

---

## Layer Requirements

### Unit tests

- Every function and method has at least one test
- Every branch (if/else, switch, try/except, ternary) has a test for EACH outcome
  — the happy path AND every error/guard path
- Every error path has a test that deliberately triggers it and asserts the error
  response (not just that no exception propagates)
- Fixtures and factories follow the project's established patterns
- No test touches external systems (network, filesystem, DB) — use fakes or
  in-memory substitutes for owned-code boundaries

**Coverage gates:**
- 100% line coverage of all non-generated, non-migration code
- 100% branch coverage — every if/else/try/except arm exercised

---

### Integration tests

- Every service-to-service interaction is tested end-to-end within the process
- Disk I/O paths are tested with a real temporary filesystem — if code writes to
  disk, the test must exercise the success path AND the I/O failure path (simulate
  permission denied or disk full via `monkeypatch` or a read-only tmp dir)
- External API calls use recorded fixtures or a network-boundary test double — not
  by mocking internal code
- No integration test duplicates what a unit test already covers — integration
  tests verify the *join*, not the individual parts

**Coverage gate:** All integration paths between owned services are exercised,
including failure injection paths.

---

### BDD / behavioural tests

> **CRITICAL RULE: Gherkin scenarios that are not executed by a test runner are
> not BDD tests. They are documentation. Documentation is not a test.**

- Every `.feature` file in the project must be wired to a test runner (pytest-bdd,
  behave, or cucumber). If a `.feature` file has no step definitions, it is not a
  BDD test — it must be moved to `doc/spec/` and clearly labelled as specification
  documentation, not as a test artefact
- Every Gherkin `Scenario:` has corresponding step-definition code that executes it
- Scenarios are the source of truth — test code must make scenarios pass
- Each step definition is minimal: Given sets state, When takes action, Then asserts
- Tag coverage: every `@EARS-{ID}` tag must have at least one passing scenario

**BEFORE writing any new BDD tests:** run `grep -r "pytest_bdd\|from behave\|@scenario"
test/` — confirm step definitions exist. If they do not, BLOCK and surface to the user
before proceeding. The BDD layer cannot be created without a working step-definition
harness.

**Coverage gate:** ALL scenarios in ALL `.feature` files that are wired to the test
runner must pass. Any `.feature` file without step definitions must be explicitly
segregated to `doc/spec/` with a `# SPECIFICATION ONLY — NOT EXECUTABLE` header.

---

### Story / E2E tests

- Every user-facing interface (web UI, mobile UI, REST API, CLI) has story tests
- Story tests exercise the product as a user would — through the outermost interface,
  with real data flows, against a running server (not mocked)
- Each story test traces to at least one Gherkin scenario via `@EARS-{ID}` comment
- Playwright is the default E2E runner for web interfaces
- At least ONE story test per feature must exercise the **complete stack** — real
  server, real disk, no route mocking — to prove the deployment unit works end-to-end
- Story tests that mock every route are **integration tests in Playwright clothing**,
  not story tests. They count toward integration coverage but NOT story coverage

**UI Interaction Mandate:** See `handler-playwright.md` for the full gesture-path
requirement (navigate → find → toBeVisible → act → verify UI reacts → reload → verify persists).

**Coverage gate:** Every user journey in the SMU actors + scenarios is exercised by at
least one story test that exercises the complete, unmocked stack.

---

### Performance tests

Performance is not optional. Every feature that introduces a latency-sensitive path
(API endpoint, scheduler run, disk write, page render) must include at least one
performance assertion.

**Performance test requirements:**

| Path type | What to measure | Threshold |
|---|---|---|
| API endpoint (simple) | Response time (p95) | < 200 ms |
| API endpoint (heavy — reallocate) | Response time (p95) | < 5000 ms |
| Scheduler run (full dataset) | Wall time | Document and assert ≤ N×current |
| Page load (Playwright) | `domContentLoaded` | < 3000 ms |
| Disk write (CSV/JSON) | Wall time | < 100 ms |

**Minimum requirement:** At least one test per feature that asserts the primary
operation completes within an acceptable wall-clock time. Use `time.perf_counter()`
(Python) or `performance.now()` (JS) — not `pytest-benchmark` unless already in
the project.

**Regression rule:** A performance test that was passing must not regress. If a change
causes a benchmark to fail, the change must be justified before merging.

**Coverage gate:** Every EARS statement whose behaviour has a measurable latency
implication (file writes, database reads, algorithm runs, API responses) must have
at least one performance assertion.

---

## COVERAGE-REVIEWER Checklist

Applied at every phase transition where code or tests are involved:

### After TEST-AGENT (Phase 3 → Phase 4)

- [ ] All EARS IDs referenced in at least one test
- [ ] All Gherkin scenarios have step definitions (or are segregated to `doc/spec/`)
- [ ] Unit tests present for all new code paths — happy AND error branches
- [ ] Integration tests cover disk I/O failure paths where applicable
- [ ] Performance test skeleton present for any latency-sensitive path
- [ ] Tests are genuinely RED — run the suite and confirm failures
- [ ] No vacuous assertion (`assert True`, `assert result is not None` without content check)

### After IMPLEMENT-AGENT (Phase 4 → Phase 5)

- [ ] Line coverage ≥ 100% for all changed files
- [ ] Branch coverage ≥ 100% — every if/else/try/except arm reached
- [ ] All unit tests pass
- [ ] All integration tests pass (including error-injection paths)
- [ ] All BDD scenarios pass (if step definitions exist)
- [ ] No previously-passing test is now failing
- [ ] No dead code with < 50% coverage remains without explicit exclusion

### After STORY-AGENT (Phase 5 → COMPLETE)

- [ ] At least one story test exercises the **unmocked full stack** per feature
- [ ] All Playwright interaction tests exercise real browser gestures (no `page.evaluate()` bypasses for UI actions)
- [ ] All user journeys in SMU actors section covered by ≥ 1 story test
- [ ] All `.feature` files either have passing step definitions OR are in `doc/spec/` as specification-only
- [ ] Performance assertion passes for each latency-sensitive path
- [ ] Total line coverage = 100.0%, branch coverage = 100.0%
- [ ] No regressions in existing story tests

---

## Dead Code Policy

Code with < 50% line coverage that is not referenced by any active test is **dead code**.
Dead code has two valid dispositions — no others:

1. **Delete it.** If the code is genuinely unused and its absence will not break any
   test, delete it. A tidy codebase is better than a covered-up-legacy one.
2. **Test it.** If the code is actively used but tests haven't been written, write them now.

**"Retain for backward compatibility" with no tests is not an acceptable disposition.**
If the only reason to keep code is backward compatibility, and the compatibility claim
is not validated by a test, the code is dead and should be deleted.

The IMPL_COMPLETE sentinel MUST include `dead_code_disposition: deleted|tested` for any
file where existing coverage was < 80% before this item's changes.

---

## Branch Coverage Commands

| Stack | Command |
|---|---|
| Python (pytest-cov) | `uv run pytest --cov=. --cov-branch --cov-report=term-missing --cov-fail-under=100` |
| JavaScript (jest) | `npx jest --coverage --coverageThreshold='{"global":{"lines":100,"branches":100}}'` |
| TypeScript (vitest) | `npx vitest run --coverage` (configure `thresholds: {lines: 100, branches: 100}`) |

Note: `--cov-branch` is the critical flag for Python. Without it, only line coverage is
measured. Always use it.

---

## Stack-Specific Coverage Commands

| Stack | Command |
|---|---|
| Python (pytest) | `uv run pytest --cov=. --cov-branch --cov-report=xml --cov-fail-under=100` |
| JavaScript (jest) | `npx jest --coverage --coverageThreshold='{"global":{"lines":100,"branches":100}}'` |
| TypeScript (vitest) | `npx vitest run --coverage` |
| E2E (Playwright) | `npx playwright test` |

---

## What Never Counts Toward the 100% Floor

The COVERAGE-REVIEWER must exclude from the 100% requirement:

- Auto-generated files (migration scripts, protobuf output, ORM-generated code)
- `__init__.py` files with no logic
- Configuration files
- Files explicitly marked `# coverage: excluded — [reason]` with reviewer sign-off
- Vendor / `node_modules` / `.venv` directories
- Specification-only `.feature` files in `doc/spec/`

Everything else counts. No exceptions without an explicit exclusion comment
and a reviewer sign-off in the handoff record.

---

## The "Fake Coverage" Anti-Pattern

The following patterns are **always rejected** by COVERAGE-REVIEWER:

```python
# BAD — executes code without asserting behaviour
def test_something():
    result = do_something()
    # no assertion

# BAD — asserts the wrong thing
def test_something():
    assert True

# BAD — catches exception to make test pass, hiding the error
def test_something():
    try:
        do_something()
    except Exception:
        pass

# BAD — page.evaluate() for UI gestures (bypasses the DOM)
await page.evaluate("() => openEditMode('5')")  # not a UI test

# BAD — all routes mocked = integration test, not story test
await page.route('**', handler)   # with no unmocked full-stack test
```

A test that increases coverage without asserting behaviour is worse than no
test — it creates false confidence. Reject it. Write it correctly.
