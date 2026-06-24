Feature: PR #56 lifecycle-delivery behaviours, pinned on the current surface (PLAN_0011)
  As the FOUNDRY system
  I want every shipped lifecycle-delivery behaviour pinned by EARS + a test coordinate
  So that regressions are caught at test time, not discovered in production

  # Re-scoped per the provenance caveat: the flow plugin was retired (commit da07db8). The two
  # flow-authored behaviours are pinned by asserting the retired surface is gone AND its live
  # successor behaves correctly; the orchestrator pause + post-merge handler are pinned directly.

  Background:
    Given the flow plugin and its flow-server history.rs have been retired from the tree
    And the lifecycle-orchestrator agent lives at plugins/foundry/agents/lifecycle-orchestrator.md
    And ds-step-9-commit-push lives at plugins/foundry/agents/ds-step-9-commit-push.md

  # ---- EARS-001: AWAITING MERGE -> terminal Done/COMPLETE -----------------------------------

  Scenario: AWAITING MERGE maps to the terminal COMPLETE status (EARS-001, happy)
    Given an item paused at AWAITING MERGE whose PR is confirmed MERGED
    When the post-merge completion handler runs
    Then the orchestrator transitions the item from "STATUS: AWAITING MERGE" to "STATUS: COMPLETE"
    And the v2 manifest terminal state for an item is "completed"

  Scenario: the retired flow-server startup mapping is gone (EARS-001, abuse — no resurrection)
    Given the flow plugin was retired
    Then no tracked flow-server source file (history.rs) exists in the tree
    And no agent instruction calls the retired flow-server status_from startup mapping

  Scenario: an unknown or malformed paused record does not map to terminal (EARS-001, unhappy)
    Given a paused record whose merge state is not confirmed MERGED
    When the post-merge completion handler runs
    Then the item is NOT transitioned to COMPLETE

  # ---- EARS-002: completion status post (Action #8) ----------------------------------------

  Scenario: ds-step-9 emits DELIVERY_COMPLETE at branch HEAD, not a canvas post (EARS-002, happy)
    Given ds-step-9-commit-push completes in engine mode
    Then it emits "SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{branch_head_short_sha}"
    And it does NOT post a "done" status to a live flow canvas

  Scenario: Action #8 is reserved — there is no live board to sync (EARS-002, sink-up equivalent)
    Given the live flow board was retired with the flow plugin
    Then ds-step-9 Action #8 is documented as Reserved with "No separate board to sync"
    And v2 roadmap state is the FLEET engine manifest state column

  # ---- EARS-003: AWAITING MERGE pause ------------------------------------------------------

  Scenario: the orchestrator pauses at AWAITING MERGE with the PR visible (EARS-003, happy)
    Given step-9 returned the AWAITING_MERGE sentinel with a PR URL
    When the orchestrator handles it
    Then it emits the "Merge PR now? [yes/no]" callout with the PR URL visible
    And it writes IN_PROGRESS.md with state AWAITING_MERGE and the PR URL
    And it does not report the item complete while the PR is open

  # ---- EARS-004: post-merge completion handler (happy) -------------------------------------

  Scenario: a merged PR drives the item to COMPLETE (EARS-004, happy)
    Given the user sends the merge confirmation signal
    And "gh pr view {pr_number} --json state" returns state MERGED
    When the post-merge completion handler runs
    Then ROADMAP STATUS changes to COMPLETE with a COMPLETED date
    And the agent emits "SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{commit_hash}"
    And the agent emits a completion summary showing the item COMPLETE

  # ---- EARS-005: status sink unreachable degrades gracefully (unhappy) ---------------------

  Scenario: a down status sink does not fail delivery (EARS-005, unhappy / sink-down)
    Given gh is unavailable or the merge command fails
    When the orchestrator's Path C runs
    Then it does NOT emit DELIVERY_COMPLETE
    And it does NOT modify ROADMAP.md
    And it does NOT corrupt the sentinel chain
    And the item remains paused at AWAITING MERGE

  Scenario: delivery records completion without a live board (EARS-005, sink-up equivalent)
    Given the flow canvas sink has been retired
    When the post-merge completion handler records completion
    Then completion succeeds without depending on a live board
    And ds-step-9 step 4b graceful-skip never blocks delivery on a missing sink

  # ---- EARS-006: refuse to complete an unmerged PR (abuse) ---------------------------------

  Scenario: the handler refuses a not-yet-merged PR (EARS-006, abuse)
    Given the post-merge handler runs against a PR that is not yet merged
    When it verifies the merge state
    Then it warns the user and waits
    And it does NOT mark the item complete
    And no DELIVERY_COMPLETE sentinel is emitted
