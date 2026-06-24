# EARS Specification — Item #33: Interactive "Merge PR now?" — `gh pr merge` on user approval

**Date:** 2026-06-14
**Item:** #33
**Reviewer target:** EARS-REVIEWER

---

## #33-AC1 — YES PATH (happy path: user approves, gh available)

**EARS statement:**

WHERE the lifecycle-orchestrator is in the `AWAITING_MERGE` state
AND `gh` is authenticated and available
AND the PR is open,
WHEN the user answers "yes" to the "Merge PR now? [yes/no]" prompt,
THEN the system SHALL run `gh pr merge {pr_number} --merge`,
AND confirm `state == "MERGED"` via `gh pr view {pr_number} --json state`,
AND immediately invoke the post-merge completion handler,
AND update `ROADMAP.md` item #33 status to `COMPLETE` with `COMPLETED: YYYY-MM-DD`,
AND emit `SENTINEL::DELIVERY_COMPLETE::ROADMAP-33::COMPLETE::{commit_hash}`,
AND sync the flow canvas card for item #33 to status `done`,
AND display a completion summary to the user.

**Preconditions:**
- The orchestrator has reached AWAITING_MERGE state after step-9 emits `SENTINEL::AWAITING_MERGE`
- `gh` CLI is installed and authenticated against the repository
- The PR is open (not already merged or closed)

**Success postconditions:**
- `gh pr view {pr_number} --json state` returns `"MERGED"`
- ROADMAP.md item #33 STATUS field reads `COMPLETE`
- `SENTINEL::DELIVERY_COMPLETE::ROADMAP-33::COMPLETE::{commit_hash}` is emitted in the session
- Flow canvas item-33 is in status `done`
- Completion summary is visible to the user

---

## #33-AC2 — NO PATH (user declines)

**EARS statement:**

WHERE the lifecycle-orchestrator is in the `AWAITING_MERGE` state,
WHEN the user answers "no" to the "Merge PR now? [yes/no]" prompt,
THEN the system SHALL halt with the PR URL visible in a callout,
AND ROADMAP.md SHALL NOT be modified,
AND no `SENTINEL::DELIVERY_COMPLETE` SHALL be emitted,
AND the item SHALL remain at status `AWAITING MERGE`,
AND `IN_PROGRESS.md` SHALL carry state `AWAITING_MERGE` and the PR URL.

**Preconditions:**
- The orchestrator has reached AWAITING_MERGE state after step-9 emits `SENTINEL::AWAITING_MERGE`

**Success postconditions:**
- The PR URL is visible to the user
- ROADMAP.md is unchanged (item remains at `AWAITING MERGE`)
- No `DELIVERY_COMPLETE` sentinel appears in the sentinel chain
- `IN_PROGRESS.md` records `AWAITING_MERGE` and the PR URL
- The agent is halted, waiting for a future post-merge signal

---

## #33-AC3 — FAILURE PATH (gh unauthenticated or merge fails)

**EARS statement:**

WHERE the lifecycle-orchestrator is in the `AWAITING_MERGE` state
AND the user answers "yes" to the "Merge PR now? [yes/no]" prompt
AND `gh pr merge` exits with a non-zero status
OR `gh` is unauthenticated / unavailable
OR `gh pr view {pr_number} --json state` does not return `state == "MERGED"`,
WHEN the merge is attempted,
THEN the system SHALL surface a descriptive error message to the user,
AND SHALL NOT emit `SENTINEL::DELIVERY_COMPLETE`,
AND SHALL NOT modify `ROADMAP.md`,
AND SHALL NOT corrupt the sentinel chain (chain ends at `AWAITING_MERGE`),
AND SHALL fall back to the manual-merge path (Path B behaviour):
  display the PR URL, leave the PR open, and instruct the user to merge manually and send the post-merge signal.

**Preconditions:**
- The orchestrator has reached AWAITING_MERGE state after step-9 emits `SENTINEL::AWAITING_MERGE`
- The user has answered "yes" to the merge prompt

**Success postconditions:**
- The error text is surfaced verbatim to the user
- ROADMAP.md is unchanged
- No `DELIVERY_COMPLETE` sentinel in the chain
- `IN_PROGRESS.md` carries state `AWAITING_MERGE` (not `COMPLETE`)
- The PR URL is visible; the user is instructed to merge manually
