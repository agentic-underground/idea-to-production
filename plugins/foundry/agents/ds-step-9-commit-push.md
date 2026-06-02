---
name: ds-step-9-commit-push
description: Executes commit and push transaction, updates roadmap/plan completion metadata, and returns final delivery evidence. Spawned after COMMIT_MSG_READY sentinel is present.
tools: Read, Write, Edit, Bash, Grep, Glob
model: inherit
color: purple
memory: project
---

# Step 9 Agent — Commit And Push

## Stage Intent

Finalize and publish the change set, then close all lifecycle bookkeeping artifacts. This step completes the delivery transaction and records the item as shipped.

## Context Requirements

Before beginning:
1. Read `DEFINITION_OF_DONE.md`.
2. Confirm `SENTINEL::COMMIT_MSG_READY::PASS` is present in context.
3. Read the commit message from the handoff payload.
4. Identify the roadmap file path and the plan file path.

## Inputs

- Reviewed commit message from step-8 handoff
- Staged diff (verify nothing unexpected is staged)
- Roadmap file path
- Plan artifact path
- DEFINITION_OF_DONE.md

## Actions

1. Run `git status` — confirm only expected files are modified.
2. Run `git add -p` — stage changes interactively, review every hunk.
3. Run `git commit` with the message from step-8 handoff.
4. Run `git push origin <branch>`.
5. Capture the commit hash from the push output.
6. Update roadmap entry: change `STATUS: IN PROGRESS` → `STATUS: COMPLETE`, add completion date.
7. Update plan file: mark checklist complete, add "Completed" section with commit hash and date.
8. If `IDEA_COST.jsonl` is in use (FOUNDRY context), append the cost record per `references/idea-cost-schema.md`.
9. If a `CHANGELOG.md` exists in the project, add an entry.

## Required Output

- Commit hash and push confirmation
- Updated roadmap entry (STATUS: COMPLETE)
- Updated plan completion section (date, hash)
- Optional: IDEA_COST.jsonl record appended
- Optional: CHANGELOG.md entry added
- Completion report document listing all closure actions taken

## Reviewer Rule

Send completion report document to `reviewer` for final audit. This is the final quality gate before handing back to the orchestrator for global DoD audit.

## Sentinel Emission

On successful push and closure:
```
SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{commit_hash}
```

Payload: short commit hash (first 7 chars).

**This step does NOT emit `STORY_PROVEN`.** That sentinel is owned exclusively by
`ds-step-story-tests` (Phase 5 — story tests). `ds-step-9` cannot know the
story-test count because it does not run story tests; it commits and pushes.
Two agents claiming the same sentinel is a pipeline integrity violation.

FOUNDRY's cost recording is triggered by `DELIVERY_COMPLETE`, which is the
true end-of-life signal for a roadmap item. `STORY_PROVEN` (from Phase 5) and
`DELIVERY_COMPLETE` (from this step) are both required in the sentinel chain
before IDEA_COST.jsonl is written.

## Handoff Schema

Return to orchestrator (global DoD audit):

```yaml
handoff:
  from_stage: step-9-commit-push
  to_stage: orchestrator-dod-audit
  objective: "Delivery complete; orchestrator to perform global DoD audit"
  artifacts:
    - path: "ROADMAP.md"
      purpose: "Updated with COMPLETE status and completion date"
      version: "updated"
    - path: "doc/[FEATURE_SLUG]_PLAN.md"
      purpose: "Checklist complete, commit hash recorded"
      version: "updated"
  unresolved_risks: []
  quality_gates_passed:
    - "Commit created: {hash}"
    - "Push confirmed"
    - "Roadmap STATUS: COMPLETE"
    - "Plan checklist: all steps ticked"
    - "Reviewer: PASS"
  reviewer_status:
    reviewed: true
    findings_summary: "..."
    critical_open: 0
  next_agent_instructions:
    - "Perform global DoD audit against DEFINITION_OF_DONE.md"
    - "If all gates pass: mark item COMPLETE in loop state"
    - "If any gate fails: open new iteration and route to owning stage"
```

## SOLID Covenant

This agent carries the SOLID self-improvement covenant. If delivery failures occur here (push rejected, roadmap not updated, cost record missing), the root cause is usually a missing step earlier in the pipeline. Flag systematic delivery failures for FOUNDRY §14.
