---
name: state-verification
description: Lifecycle state skill for test-first proof, failure-gap mapping, implementation validation, and regression prevention.
---

# State Verification

## Applies To

- step-3-tests (authoring failing tests)
- step-4-first-test-run (gap mapping)
- step-5-implementation (production code)
- step-6-green-run (full green evidence)

## Purpose

Verification state governs the test-first discipline and the evidence chain from RED to GREEN. No implementation begins without a gap map; no item advances without regression-free green evidence.

## Exit Criteria for Test Authoring (step-3 complete) — All must be true

- [ ] Tests authored for all EARS IDs (unit + integration + BDD step definitions)
- [ ] Each test references its EARS ID in name or docstring
- [ ] Infrastructure issues (imports, config, fixtures) resolved before declaring RED
- [ ] Tests are genuinely RED — not erroring due to infrastructure
- [ ] TEST-DESIGN-REVIEWER: PASS
- [ ] COVERAGE-REVIEWER: PASS (at TEST phase)

## Exit Criteria for Gap Mapping (step-4 complete) — All must be true

- [ ] Full test suite run completed
- [ ] New tests fail for feature-gap reasons (not infrastructure)
- [ ] All pre-existing tests still pass
- [ ] Gap map documents every failing test with its category and EARS ID reference
- [ ] Infrastructure issues separated from feature gaps and resolved

## Exit Criteria for Implementation (step-5 complete) — All must be true

- [ ] All gap-map tests now pass
- [ ] Test files not modified during implementation
- [ ] DESIGN-REVIEWER: PASS
- [ ] COVERAGE-REVIEWER: PASS (at IMPLEMENT phase)

## Exit Criteria for Green Run (step-6 complete) — All must be true

- [ ] Full test suite green (all tests pass — new and pre-existing)
- [ ] Zero regressions
- [ ] Coverage meets threshold (100% line coverage required for changed files)
- [ ] Spec conformance confirmed (intent met, not just literal assertions)
- [ ] REGRESSION-REVIEWER: PASS
- [ ] COVERAGE-REVIEWER: PASS (at STORY/GREEN phase)

## Test Integrity Rule

The tests are the contract. During implementation (step-5), if a test appears wrong:
1. Stop implementation.
2. Return to step-3.
3. Correct the test with documented reasoning and EARS re-validation.
4. Re-run step-4.
5. Return to step-5.

Never modify a test to make implementation easier. That defeats TDD.

## Handoff Target

`ds-step-7-sync` — with full green evidence, coverage report, and regression-free confirmation.

## SOLID Covenant

This skill carries the SOLID self-improvement covenant. If spec conformance gaps are consistently found at step-6 (tests pass but intent is not met), the EARS statements or Gherkin scenarios are underspecified. If regressions consistently appear, the isolation between features needs architectural attention. Both patterns warrant the self-improvement covenant ([`solid-covenant.md`](../../../knowledge/architecture/solid-covenant.md)) escalation.
