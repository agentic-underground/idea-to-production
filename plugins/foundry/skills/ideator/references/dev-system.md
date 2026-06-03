# Development System Reference — Steps 0–9

> **For IDEATOR §7 SDLC Handoff.** Present this inline when ROADMAPPER is not available.
> This is the full development system attached to the IDEATOR skill.

---

## Step 0 — Write the Implementation Plan

Before touching any code, write a detailed plan to `doc/[FEATURE_SLUG]_PLAN.md`.

The plan must include:
- Feature title, roadmap entry number, and date
- Summary of the EARS specification to be written
- Summary of the Gherkin scenarios to be written
- Ordered list of files to be created or modified, with rationale
- Test strategy: runner, file locations, naming conventions
- Known risks and mitigations
- A checklist of Steps 1–9 for progress tracking
- A **Resumption** section: instructions explicit enough for a cold-start agent to
  continue without reading conversation history

This plan is the single source of truth. Keep it updated throughout.

---

## Step 1 — EARS Specification

- Locate or create `doc/SPECIFICATION.ears.md`
- Add EARS statements for this feature using the EARS forms (ubiquitous, event-driven,
  state-driven, unwanted behaviour, optional feature)
- Assign each statement a unique ID (e.g. `EARS-042`)
- Each ID must be referenceable from test code and feature files
- Spec changes are a discrete, reviewable diff

---

## Step 2 — Feature Documentation (.feature files)

- Locate or create the appropriate `.feature` file
- Write Gherkin scenarios covering:
  - **Happy path** — correct behaviour under normal conditions
  - **Unhappy path** — graceful handling of bad/missing inputs
  - **Abuse / adversarial path** — resistance to malformed or boundary inputs
- Tag each scenario with the EARS ID(s) it satisfies (`@EARS-042`)
- Scenarios are written **before** test code — they are the human-readable contract

```gherkin
@EARS-042
Feature: [Feature name]

  Scenario: Happy path — [brief description]
    Given [precondition]
    When [action]
    Then [expected outcome]

  Scenario: Unhappy path — [brief description]
    Given [bad precondition]
    When [action]
    Then [graceful failure]

  Scenario: Abuse path — [brief description]
    Given [adversarial input]
    When [action]
    Then [system resists / rejects]
```

---

## Step 3 — Test Code

- Write tests (unit, integration, e2e) that exercise the scenarios from Step 2
- Cover happy, unhappy, and abuse paths
- Each test references the EARS ID and feature scenario in a comment
- **Validate against spec** before running: re-read EARS statements and `.feature` file;
  confirm each test is asserting the correct expectation. Fix mismatches now.
- Do not write implementation code yet. Tests must be red at this point.

---

## Step 4 — Run Tests (first pass — confirm expected failures)

- Run the full test suite
- **Expected**: new tests fail (feature not yet implemented); existing tests pass
- If any pre-existing test is now failing, **stop and investigate** before proceeding
- Document the failure surface — this is the "gap map" guiding implementation
- Fix infrastructure issues (imports, env, config) before proceeding — these are not
  feature gaps

---

## Step 5 — Implementation

- Write the minimum production code to make the failing tests pass
- Follow existing project conventions (naming, structure, error handling, logging)
- Reuse existing components and patterns
- Do **not** modify test code during this step
- If a test is genuinely wrong (tests the wrong thing), return to Step 3, correct it,
  validate it, then return here

---

## Step 6 — Run Tests (second pass — drive to green)

- Run the full suite repeatedly until all tests pass
- For each failure: diagnose → fix implementation → re-run
- Never modify a test to make it pass unless the test is in error (see Step 5)
- Check for regressions: no previously-passing test should now fail
- Final read-through: confirm the spirit of the requirement is met, not just the tests

---

## Step 7 — Sync with Upstream

```bash
git fetch origin
git rebase origin/<main-branch>   # or merge, per project convention
```

- Run tests again after rebase/merge
- Resolve conflicts carefully; preserve both upstream changes and the new feature
- If conflicts affect test files, validate resolved tests against the spec

---

## Step 8 — Write the Commit Message

> Format, emoji convention, and quality rules are defined in:
> **`${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/commit-message.md`**

Write a commit message following the WHY/WHAT/TESTING/ROADMAP structure with a Conventional
Commits type prefix on the summary line: `[emoji] type(scope): short imperative summary`.
Send to reviewer before committing.

---

## Step 9 — Commit and Push

```bash
git add -p          # Stage interactively — review every hunk
git commit          # Paste the commit message from Step 8
git push origin <branch>
```

After pushing (per merge governance — [`../../../knowledge/protocols/merge-governance.md`](../../../knowledge/protocols/merge-governance.md)):
1. Update the roadmap entry: under **direct-merge** `STATUS: IN PROGRESS` → `STATUS: COMPLETE` +
   completion date; under **pr-approval** → `STATUS: AWAITING MERGE` (→ COMPLETE on human merge)
2. Update `doc/[SLUG]_PLAN.md`: mark checklist complete, add commit hash and date
3. If a `CHANGELOG.md` exists, add an entry
