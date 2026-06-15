---
id: 33
title: "Interactive \"Merge PR now?\" — `gh pr merge` on user approval"
status: COMPLETE
priority: HIGH
added: 2026-06-14
depends_on: "— (atomic; epic #32)"
completed: 2026-06-14
---

# [33] Interactive "Merge PR now?" — `gh pr merge` on user approval

**Brief Description**
When the lifecycle-orchestrator reaches the AWAITING MERGE state and has emitted the PR-ready
callout, it should interactively ask the user "Merge PR now? [yes/no]". On yes: run
`gh pr merge {pr_number} --merge`, then immediately proceed to the post-merge completion
handler (update ROADMAP.md → COMPLETE, emit DELIVERY_COMPLETE sentinel, sync flow canvas,
run DoD audit, emit completion summary). On no: leave the PR open and halt as today.
This makes delivery a single attended flow rather than a two-session hand-off.

### User Stories
- AS a builder I WANT the agent to ask me "Merge PR now?" at the point delivery is ready
  SO THAT I can approve and complete the item in one continuous flow without switching context.
- AS a builder I WANT to say no and keep the PR open SO THAT I can review it externally
  before merging.

### Acceptance Criteria
1. Given the lifecycle reaches AWAITING MERGE and I answer "yes", the agent runs
   `gh pr merge {pr_number} --merge`, confirms the merge, flips ROADMAP.md to COMPLETE,
   emits DELIVERY_COMPLETE, syncs the flow canvas to `done`, and emits a completion summary.
2. Given I answer "no", the agent halts with the PR URL visible and the item at AWAITING MERGE.
3. Given `gh` is not authenticated or the merge fails, the agent surfaces the error and
   falls back to the existing manual-merge path without corrupting the sentinel chain.

### Implementation Notes
- Change is in `plugins/foundry/agents/lifecycle-orchestrator.md` (the AWAITING MERGE section
  added in PR #56): replace the static callout with an interactive yes/no branch.
- `merge-governance.md` should document this as the standard `pr-approval` interactive path.
- No Rust or JS code changes — this is agent-instruction markdown only.
- The "yes" path must verify the merge completed (`gh pr view --json state`) before emitting
  DELIVERY_COMPLETE; the "no" path must not alter roadmap STATUS.

### Development Plan Reference
`docs/internal/FOUNDRY_INTERACTIVE_MERGE_PLAN.md`
