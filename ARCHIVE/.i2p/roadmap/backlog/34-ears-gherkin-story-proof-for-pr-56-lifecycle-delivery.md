---
id: 34
title: "EARS + Gherkin + story proof for PR #56 lifecycle delivery changes"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "#33"
---

# [34] EARS + Gherkin + story proof for PR #56 lifecycle delivery changes

**Brief Description**
PR #56 shipped three behaviours to the FOUNDRY lifecycle outside the SDLC — no EARS spec,
no Gherkin scenarios, no story proof:
1. `history.rs` `status_from()` now maps `AWAITING MERGE` → `Status::Done` on startup.
2. `ds-step-9-commit-push` Action #8 calls `post_status item-{N} done` on the flow canvas.
3. `lifecycle-orchestrator` gains an AWAITING MERGE pause and a post-merge completion handler.

This item runs those three behaviours through the full quality chain retroactively: EARS IDs,
Gherkin happy/unhappy/abuse scenarios, unit or story tests that confirm each behaviour, and
a passing story proof. Coverage floor is 100%.

### User Stories
- AS the FOUNDRY system I WANT every shipped behaviour pinned by EARS + test coordinates
  SO THAT regressions are caught at test time, not discovered in production.

### Acceptance Criteria
1. EARS IDs exist for all three behaviours; each maps to at least one Gherkin scenario.
2. `AWAITING MERGE → Done` mapping in `history.rs` is covered by an explicit unit test
   (already added as part of PR #56 — verify and expand to unhappy/abuse paths).
3. The AWAITING MERGE pause and post-merge handler in lifecycle-orchestrator have at least one
   happy, one unhappy (merge fails), and one abuse (not-yet-merged PR) Gherkin scenario, each
   backed by a story-level proof.
4. Action #8 (flow canvas sync) has a scenario for server-up and server-down paths.

### Implementation Notes
- No new production code; all work is spec, Gherkin, and story test authoring.
- Story tests for agent-instruction markdown use the lifecycle-orchestrator directly (invoke it
  against a fixture roadmap item, observe sentinel chain and tool calls).
- The existing `cargo test -p flow-server` suite is the unit-test home for `history.rs`; the
  Gherkin scenarios live alongside other `.feature` files in the flow-server test tree.

### Development Plan Reference
`doc/FOUNDRY_PR56_COMPLIANCE_PLAN.md`
