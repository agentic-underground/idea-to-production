# Orchestration Loop Reference

> For FOUNDRY DEV_SYSTEM and `lifecycle-orchestrator`. Defines the loop
> state model, execution sequence, and iteration logic for processing a single
> roadmap item through the 10-step Development System.

---

## Purpose

The orchestration loop drives a single IDEATOR item from brief to COMPLETE through
iterative stage execution. The loop never terminates early — it continues until all
Definition Of Done gates pass or the user explicitly stops it.

---

## Kickoff Inputs

1. IDEATOR brief (title, actors, problem, in-scope, out-of-scope, constraints, success metric)
2. Development System reference (`${CLAUDE_PLUGIN_ROOT}/skills/development-system-core/SKILL.md`)
3. Roadmap entry number and current status
4. Current repository state (stack, existing EARS, feature files, test structure)
5. `DEFINITION_OF_DONE.md` (project root or `doc/`)

---

## Loop State Model

Maintain this YAML block across all stage transitions. Update on every stage completion:

```yaml
loop_state:
  item_slug: "feature-slug-here"
  iteration: 1
  current_stage: step-0
  stage_status:
    step-0: pending    # → in-progress → complete | blocked
    step-1: pending
    step-2: pending
    step-3: pending
    step-4: pending
    step-5: pending
    step-6: pending
    step-story: pending  # MANDATORY — owner of STORY_PROVEN sentinel
    step-7: pending
    step-8: pending
    step-9: pending
  dod_status: not-satisfied   # → satisfied
  critical_findings_open: 0
  revision_counts:
    step-0: 0
    step-1: 0
    step-2: 0
    step-3: 0
    step-4: 0
    step-5: 0
    step-6: 0
    step-story: 0
    step-7: 0
    step-8: 0
    step-9: 0
  sentinel_chain: []          # Accumulates as stages complete
  artifacts_index:
    - path: "..."
      stage: "step-N"
      reviewed: false
```

---

## Execution Loop

```
1. Load DEFINITION_OF_DONE.md.
2. Initialize loop state for this item.
3. For each stage in order [step-0, step-1, step-2, step-3, step-4, step-5, step-6,
   step-story, step-7, step-8, step-9]:
   a. Set current_stage and stage_status[step-N] = in-progress.
   b. Spawn the named step agent (ds-step-N-*) with:
      - All upstream artifacts
      - Accumulated sentinel chain from loop state
      - Handoff payload from previous stage
      - DEFINITION_OF_DONE.md reference
   c. If the step produces/updates a document:
      - Invoke reviewer agent (reviewer or reviewer)
      - Apply reviewer updates or record disposition with rationale
      - Increment revision_counts[step-N] on each NEEDS_REVISION
      - If revision_counts[step-N] >= 3: escalate to BLOCK → surface to user
   d. Validate stage quality gates (from DEFINITION_OF_DONE.md Stage-Specific criteria)
   e. If stage complete:
      - Set stage_status[step-N] = complete
      - Append sentinel to sentinel_chain
      - Add artifacts to artifacts_index (with reviewed: true)
      - Emit handoff payload
      - Advance to step-N+1
   f. If stage blocked:
      - Set stage_status[step-N] = blocked
      - Surface to user with specific blocking reason
      - Wait for resolution before retrying
4. After step-9:
   - Perform global DoD audit against all universal gates.
   - If all gates pass, branch on merge governance ([`../protocols/merge-governance.md`](../protocols/merge-governance.md)):
     - **`direct-merge`** (sentinel `DELIVERY_COMPLETE`): set dod_status = satisfied → mark item COMPLETE.
     - **`pr-approval`** (sentinel `AWAITING_MERGE`): the work is DoD-satisfied but **not on `main`** — hold
       the item at `STATUS: AWAITING MERGE` (a terminal-pending state; the loop takes no further phase
       action), and mark COMPLETE only when the human's merge produces `DELIVERY_COMPLETE`.
   - If any gate fails: increment iteration, reset owning stage to pending, route there.
5. Stop only when dod_status = satisfied AND critical_findings_open = 0 (under `pr-approval`, the item
   stops the active loop at AWAITING MERGE; final COMPLETE is recorded on human merge).
```

---

## Stage Routing Table

| Stage | Agent | Sentinel In | Sentinel Out |
|---|---|---|---|
| step-0-plan | `ds-step-0-plan` | (brief) | `PLAN_COMPLETE` |
| step-1-ears | `ds-step-1-ears` | `PLAN_COMPLETE` | `EARS_COMPLETE` |
| step-2-feature-docs | `ds-step-2-feature-docs` | `EARS_COMPLETE` | `FEATURE_COMPLETE` |
| step-3-tests | `ds-step-3-tests` | `FEATURE_COMPLETE` | `TESTS_WRITTEN::RED` |
| step-4-first-test-run | `ds-step-4-first-test-run` | `TESTS_WRITTEN` | `GAP_MAP_COMPLETE` |
| step-5-implementation | `ds-step-5-implementation` | `GAP_MAP_COMPLETE` | `IMPL_COMPLETE::GREEN` |
| step-6-green-run | `ds-step-6-green-run` | `IMPL_COMPLETE` | `GREEN_RUN_COMPLETE` |
| step-story-tests | `ds-step-story-tests` | `GREEN_RUN_COMPLETE` | `STORY_PROVEN` |
| step-7-sync | `ds-step-7-sync` | `STORY_PROVEN` | `SYNC_COMPLETE` |
| step-8-commit-message | `ds-step-8-commit-message` | `SYNC_COMPLETE` | `COMMIT_MSG_READY` |
| step-9-commit-push | `ds-step-9-commit-push` | `COMMIT_MSG_READY` | `DELIVERY_COMPLETE` (direct-merge) / `AWAITING_MERGE` (pr-approval) |

> **Story step enforcement:** `ds-step-7-sync` MUST validate that `STORY_PROVEN`
> is present in its incoming sentinel chain. If absent, the orchestrator returns
> to `step-story-tests` rather than synchronising green-without-stories. This
> prevents the most common silent coverage gap in CI-driven pipelines.

---

## Reviewer Enforcement Rule

No document may advance without reviewer output being processed.
A stage CANNOT mark complete when reviewer findings include unresolved CRITICAL issues.
If `critical_findings_open > 0` after a reviewer pass, the stage stays `in-progress`.

---

## Global DoD Audit (after step-9)

Check every universal gate in `DEFINITION_OF_DONE.md`:
1. Problem-Solution Traceability
2. Specification Integrity
3. Test Evidence
4. Implementation Quality
5. Integration and Release Readiness
6. Reviewer Gate Compliance
7. Handoff Contract Completeness

Map each failing gate to its owning stage, then route to that stage in the next iteration.

---

## Iteration Semantics

| Iteration | Meaning |
|---|---|
| 1 | First pass through all stages |
| 2+ | Correction iteration — only stages that failed DoD gates are re-run |
| N | Upper bound: 3 iterations before surfacing to user as systemic failure |

An item that requires > 3 iterations has a fundamental problem in its specification
or an environmental issue. Surface to user rather than continuing to loop.

---

## Integration With FOUNDRY

When operating inside a FOUNDRY cycle:
- FOUNDRY manages tier assignment, parallelization, and token budgeting across items
- This orchestration loop handles the per-item sequential SDLC execution
- FOUNDRY sentinels wrap DS sentinels in the same chain
- On `DELIVERY_COMPLETE` (with prior `STORY_PROVEN` in the chain), FOUNDRY records `IDEA_COST.jsonl` and marks the item done in the tier summary
