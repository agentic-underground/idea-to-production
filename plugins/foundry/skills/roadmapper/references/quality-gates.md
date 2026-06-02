# Quality Gates

> For ROADMAPPER §9. Defines the mandatory gates that must pass before advancing
> between Development System steps. Read before confirming any stage transition.

---

## Gate Table

Before moving from one step to the next, every condition in the gate must be true:

| Transition | Gate conditions |
|---|---|
| Step 1 → Step 2 | EARS statements are uniquely ID'd; all actors from the brief are represented; all constraints addressed; EARS-REVIEWER PASS |
| Step 2 → Step 3 | Every `.feature` scenario maps to ≥ 1 EARS statement via `@EARS-{ID}` tag; happy + unhappy + abuse paths present for each EARS ID; BDD-REVIEWER PASS |
| Step 3 → Step 4 | Tests validated against spec; infrastructure stable (no test-runner errors); no implementation code written; TEST-DESIGN-REVIEWER PASS |
| Step 4 → Step 5 | New tests genuinely fail (RED confirmed by running suite); pre-existing tests still pass; failure surface documented in gap map |
| Step 5 → Step 6 | No test code modified during implementation; implementation satisfies spec intent (not just literal assertions); DESIGN-REVIEWER PASS |
| Step 6 → Step 7 | 100% of tests green; zero regressions; coverage ≥ threshold (default 100% line); REGRESSION-REVIEWER PASS |
| Step 7 → Step 8 | Tests re-run post-sync and still green; conflicts resolved cleanly; no upstream changes break the feature |
| Step 8 → Step 9 | Commit message follows WHY/WHAT/TESTING/ROADMAP structure; diff summary matches actual changed files; reviewer PASS |

---

## Blocking Rules

- **No stage may be marked complete** while any gate condition for that transition is unmet.
- **Reviewer PASS is non-negotiable.** `NEEDS_REVISION` means rework and re-review — not advance with known issues.
- **Test RED is required at Step 4.** A test that passes before implementation is either wrong or testing the wrong thing — investigate before proceeding.
- **Coverage gate at Step 6 is a floor**, not a target. 100% line coverage for changed files is the minimum; branch coverage and mutation testing are encouraged where tooling supports it.

---

## Gate Failure Protocol

When a gate fails:
1. Record the specific failing condition(s) in the handoff payload under `unresolved_risks`.
2. Route back to the earliest step that owns the failing condition.
3. Do not advance until all conditions are satisfied — partial advancement creates technical debt that compounds through the pipeline.

See `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/definition-of-done.md` for the full stage-specific and universal DoD gates used by the orchestrator.
