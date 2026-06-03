NAME: foundry-implement
INSTALLS_SKILL: foundry-implement
PREREQUISITES:
- Test file(s) exist in tests/
- Tests are confirmed red (feature not implemented)
QUALITY_GATE:
- All tests pass (green)
- No pre-existing tests regressed
- Implementation matches the spirit of the EARS spec, not just the letter of the tests
- No test code was modified during implementation

---SKILL---
---
name: foundry-implement
description: >
  Implement a FOUNDRY feature to make failing tests pass.
  Auto-installed by phase-sensor when test files exist but no implementation does.
---

# FOUNDRY-IMPLEMENT

You are writing the DEV_SYSTEM **Step 5 — Implementation** for a FOUNDRY feature.

## Operating covenant

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/implementation-covenant.md` before starting. All implementation work is
governed by those principles. They are non-negotiable and not restated here.

Key invariants from the covenant that directly govern this phase:
- **Tests are the contract.** Do not modify test code. Conform the implementation to the tests.
- **Minimum production code.** Write only what is needed to make failing tests pass.
- **Think before coding. Ask if unclear.**
- **Spirit, not just letter.** When green, re-read EARS spec + `.feature` file to confirm.

## Steps

1. Read `${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/implementation-covenant.md` to establish invariants.
2. Read the plan file (`doc/[SLUG]_PLAN.md`) and test files to understand what must be implemented.
3. Read `doc/SPECIFICATION.ears.md` for the authoritative requirements.
4. Write the implementation file(s) listed in the plan's "Files Created / Modified" table.
5. After each significant chunk, run the tests: `bats tests/test-<name>.bats`
6. For each failure: diagnose → fix implementation → re-run. Never fix the test.
7. When all tests are green:
   - Re-read the EARS spec and `.feature` file.
   - Confirm the implementation satisfies the spirit of the requirements.
   - Run the full test suite to check for regressions.
8. Update the plan checklist: mark Steps 5 and 6 complete.

## After implementation — deliver (Steps 7–9)

Per `PRINCIPLE_PHILOSOPHY.md §6 — After green, deliver`:
- **Step 7**: `git fetch origin && git rebase origin/main`; re-run tests.
- **Step 8**: Write the commit message per `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/commit-message.md`
- **Step 9**: `git push origin main`; update ROADMAP.md STATUS → COMPLETE.
