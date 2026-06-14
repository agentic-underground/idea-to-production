Feature: Interactive merge prompt in pr-approval mode
  As the lifecycle-orchestrator in AWAITING MERGE state
  I want to offer the user an in-session merge option
  So that delivery can complete in a single session without leaving the conversation

  Background:
    Given the lifecycle-orchestrator has reached AWAITING MERGE state
    And step-9 has emitted "SENTINEL::AWAITING_MERGE::ROADMAP-33::AWAITING_MERGE::https://github.com/agentic-underground/idea-to-production/pull/99"
    And the PR URL is "https://github.com/agentic-underground/idea-to-production/pull/99"
    And the PR number is 99
    And IN_PROGRESS.md has been written with state AWAITING_MERGE and the PR URL

  Scenario: User approves merge and gh succeeds (#33-AC1)
    Given gh is authenticated and available
    And the PR is open
    When the user answers "yes" to "Merge PR now? [yes/no]"
    Then the agent runs "gh pr merge 99 --merge"
    And the agent runs "gh pr view 99 --json state" and confirms state is "MERGED"
    And the agent immediately invokes the post-merge completion handler
    And ROADMAP.md item #33 STATUS changes to "COMPLETE"
    And ROADMAP.md item #33 gains a "COMPLETED: 2026-06-14" line
    And the agent emits "SENTINEL::DELIVERY_COMPLETE::ROADMAP-33::COMPLETE::{commit_hash}"
    And the flow canvas item "item-33" is synced to status "done"
    And the agent emits a completion summary to the user showing item #33 COMPLETE

  Scenario: User declines merge (#33-AC2)
    When the user answers "no" to "Merge PR now? [yes/no]"
    Then the agent halts with the PR URL "https://github.com/agentic-underground/idea-to-production/pull/99" visible
    And ROADMAP.md is not modified
    And no DELIVERY_COMPLETE sentinel is emitted
    And the item remains at AWAITING MERGE
    And the agent instructs the user to merge manually and reply "merged"

  Scenario: gh unavailable — merge fails (#33-AC3-unauthenticated)
    Given gh is unauthenticated
    When the user answers "yes" to "Merge PR now? [yes/no]"
    Then the agent surfaces a descriptive error message from gh
    And the agent falls back to the manual-merge path
    And no DELIVERY_COMPLETE sentinel is emitted
    And ROADMAP.md STATUS is not modified
    And IN_PROGRESS.md carries state AWAITING_MERGE

  Scenario: gh pr merge command fails (#33-AC3-merge-fails)
    Given gh is authenticated
    And "gh pr merge 99 --merge" exits with non-zero status
    When the user answers "yes" to "Merge PR now? [yes/no]"
    Then the agent surfaces the verbatim error text from gh pr merge
    And the agent does not emit DELIVERY_COMPLETE
    And ROADMAP.md is not modified
    And the agent falls back to the manual-merge path displaying the PR URL

  Scenario: gh pr view does not return state MERGED (#33-AC3-verify-fails)
    Given gh is authenticated
    And "gh pr merge 99 --merge" exits with zero status
    But "gh pr view 99 --json state" returns a state that is not "MERGED"
    When the user answers "yes" to "Merge PR now? [yes/no]"
    Then the agent surfaces a warning that the merge state could not be confirmed
    And the agent does not proceed to the post-merge completion handler
    And no DELIVERY_COMPLETE sentinel is emitted
    And ROADMAP.md STATUS is not modified
