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
4. **Run the always-on adversarial gate.** Invoke `/foundry:pr-review` for this change (if it has
   not already been run and recorded for this exact diff) and require a **PASS**
   (see [`../skills/pr-review/SKILL.md`](../skills/pr-review/SKILL.md)). A `NEEDS_REVISION`/`BLOCK`
   verdict halts delivery — loop back to revision; do not proceed.
5. **Branch on merge governance** — read `.foundry/governance.md` (absent ⇒ default `pr-approval`;
   see [`../knowledge/protocols/merge-governance.md`](../knowledge/protocols/merge-governance.md)):
   - **`pr-approval`**: `git push` the feature branch and **open a PR targeting `main`** (stacked PRs
     are opt-in and need prior user approval — see the PR-base policy in `merge-governance.md`) whose
     body carries the review verdict + findings. **Stop here — the human merges and closes.** Do not
     merge to `main`.
   - **`direct-merge`**: merge the branch to `main` and `git push` (the granted-autonomy path).
6. Capture the commit hash from the push/merge output.
7. Update roadmap entry: change `STATUS: IN PROGRESS` → `STATUS: COMPLETE`, add completion date.
   (In `pr-approval` mode, hold the item at `STATUS: AWAITING MERGE` until the human merges the PR,
   then flip to `COMPLETE`.)
8. Update plan file: mark checklist complete, add "Completed" section with commit hash and date.
9. If `IDEA_COST.jsonl` is in use (FOUNDRY context), append the cost record per [`../knowledge/orchestration/idea-cost-schema.md`](../knowledge/orchestration/idea-cost-schema.md).
10. If a `CHANGELOG.md` exists in the project, add an entry.
11. **Git-hygiene advisory (PROPOSE-only, P1-12).** Run
    [`../skills/builder/scripts/git-hygiene.sh`](../skills/builder/scripts/git-hygiene.sh) from the
    project root. It lists merged-but-undeleted local branches (`git branch --merged main`, minus
    main/current) and orphaned/stale worktrees, and prints the EXACT cleanup commands
    (`git branch -d …`, `git worktree remove …`) for the **human** to run. It is detect-and-propose:
    it NEVER deletes a branch or removes a worktree. Surface its output in the completion report;
    do not act on it yourself.

## Required Output

(Mode-aware — read `.foundry/governance.md`; see [`../knowledge/protocols/merge-governance.md`](../knowledge/protocols/merge-governance.md).)

- Commit hash and push confirmation
- **`direct-merge`:** merged to `main`; roadmap entry **STATUS: COMPLETE**
  **`pr-approval`:** branch pushed + **PR opened** (URL); roadmap entry **STATUS: AWAITING MERGE**
  (flips to COMPLETE only once the human merges the PR)
- Updated plan completion section (date, hash)
- Optional: IDEA_COST.jsonl record appended (**only after the change is on `main`** — see Sentinel Emission)
- Optional: CHANGELOG.md entry added
- Completion report document listing all closure actions taken (and, in `pr-approval`, the open PR)

## Reviewer Rule

Send completion report document to `reviewer` for final audit. This is the final quality gate before handing back to the orchestrator for global DoD audit.

## Sentinel Emission

`DELIVERY_COMPLETE` means **the change is on `main`** — it must not fire for an unmerged change.

- **`direct-merge`** (merged + pushed): emit, on success —
  ```
  SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{commit_hash}
  ```
- **`pr-approval`** (branch pushed, PR opened, NOT yet merged): emit instead —
  ```
  SENTINEL::AWAITING_MERGE::ROADMAP-{N}::AWAITING_MERGE::{pr_url_or_branch}
  ```
  and emit `DELIVERY_COMPLETE::COMPLETE` only once the human's merge is confirmed.

Payload: short commit hash (first 7 chars), or the PR URL/branch for `AWAITING_MERGE`.

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
  merge_mode: "pr-approval | direct-merge"   # from .foundry/governance.md
  artifacts:
    - path: "ROADMAP.md"
      purpose: "STATUS=COMPLETE (direct-merge) or STATUS=AWAITING MERGE + PR url (pr-approval)"
      version: "updated"
    - path: "doc/[FEATURE_SLUG]_PLAN.md"
      purpose: "Checklist complete, commit hash recorded"
      version: "updated"
  unresolved_risks: []
  quality_gates_passed:
    - "Commit created: {hash}"
    - "adversarial review (/foundry:pr-review): PASS"
    - "direct-merge: merged to main + pushed  |  pr-approval: branch pushed + PR opened: {pr_url}"
    - "Roadmap STATUS: COMPLETE (direct-merge) | AWAITING MERGE (pr-approval, until human merges)"
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

This agent carries the SOLID self-improvement covenant. If delivery failures occur here (push rejected, roadmap not updated, cost record missing), the root cause is usually a missing step earlier in the pipeline. Flag systematic delivery failures for the self-improvement covenant ([`solid-covenant.md`](../knowledge/architecture/solid-covenant.md)).
