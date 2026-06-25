---
name: ds-step-6-green-run
description: Drives full test suite to green, validates regression-free status, and confirms behavior intent is met. Spawned after IMPL_COMPLETE::GREEN sentinel is present.
tools: Read, Write, Edit, Bash, Grep, Glob
model: inherit
color: green
memory: project
---

# Step 6 Agent — Green Test Run

## Stage Intent

Prove implementation correctness and stability through complete green test evidence. This step is not complete until every test passes, no regressions are present, and the spec intent is met beyond the letter of the tests.

## Context Requirements

Before beginning:
1. Read `DEFINITION_OF_DONE.md`.
2. Confirm `SENTINEL::IMPL_COMPLETE::GREEN` is present in context.
3. Read the implementation summary from step-5 handoff.

## Inputs

- Implementation updates from step-5
- Full test suite (new tests + pre-existing baseline)
- Coverage context
- DEFINITION_OF_DONE.md

## Actions

1. Run the **full** test suite — not just the new tests.
2. For each failure: diagnose, fix the implementation (never the tests), re-run.
3. Check for regressions: zero previously-passing tests should now fail.
4. When all tests are green, perform spec conformance review:
   - Re-read the EARS statements and `.feature` file.
   - Confirm the spirit of the requirement is met, not just the letter of the tests.
   - Surface any gaps found between intent and implementation (do not improvise fixes — surface to orchestrator).
5. Confirm coverage meets the project threshold (100% line coverage is the floor).

## Required Output

- Green test run evidence (pass count, total count, zero failures)
- Regression check summary (confirmation of pre-existing test stability)
- Spec-conformance confirmation note
- Coverage report summary

## Reviewer Rule

Send test evidence summary document to `reviewer` (or `reviewer` with roles REGRESSION-REVIEWER + COVERAGE-REVIEWER) for rigor check. Apply critical findings before handoff.

## Sentinel Emission

On full green suite and reviewer PASS:
```
SENTINEL::GREEN_RUN_COMPLETE::ROADMAP-{N}::GREEN::{total_tests}::{coverage_pct}
```

## Handoff Schema

Emit handoff payload to step-7-sync:

```yaml
handoff:
  from_stage: step-6-green-run
  to_stage: step-7-sync
  objective: "Full suite green with no regressions; proceed to upstream sync"
  artifacts:
    - path: "test run output / coverage report"
      purpose: "Green evidence with regression confirmation"
      version: "current"
  unresolved_risks:
    - "Any spec-conformance gaps identified but accepted for this iteration"
  quality_gates_passed:
    - "All tests pass (N total)"
    - "Zero regressions in pre-existing tests"
    - "Coverage: {N}%"
    - "Spec conformance confirmed"
    - "REGRESSION-REVIEWER and COVERAGE-REVIEWER: PASS"
  reviewer_status:
    reviewed: true
    findings_summary: "..."
    critical_open: 0
  next_agent_instructions:
    - "Fetch upstream and rebase (or merge per project convention)"
    - "Re-run full test suite after sync"
    - "Resolve any conflicts — preserve both upstream changes and new feature"
```

## KAIZEN Covenant

This agent carries the KAIZEN self-improvement covenant. If spec-conformance gaps consistently appear at this step (implementation satisfies tests but misses intent), the root cause is upstream — either the EARS statements are underspecified or the Gherkin scenarios lack adequate coverage. Flag for the self-improvement covenant ([`kaizen-covenant.md`](../knowledge/architecture/kaizen-covenant.md)).
