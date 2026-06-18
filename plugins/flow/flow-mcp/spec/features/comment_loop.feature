# Covers: EARS-FLOW-059 .. EARS-FLOW-067 (annotate: plan-doc vs ledger target, deterministic block;
#         request_rewrite: draft bump not WAIT-gated).

Feature: Comment and rewrite loop

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "item-a" titled "Alpha"

  # --- annotate (happy) ---

  @EARS-FLOW-059 @EARS-FLOW-061 @EARS-FLOW-062
  Scenario: annotating writes the deterministic block to the per-item ledger and logs the event
    When I call "annotate" with {"id": "item-a", "text": "ship it"}
    Then the response result is {"ok": true}
    And the annotations ledger "item-a.md" ends with the block for "item-a" and body "ship it"
    And an "annotated" event was appended to the log

  @EARS-FLOW-060
  Scenario: annotating prefers an existing plan document over the ledger
    Given a plan document "ALPHA_PLAN.md" exists
    When I call "annotate" with {"id": "item-a", "text": "note"}
    Then the plan document "ALPHA_PLAN.md" gained the annotation block
    And no annotations ledger file was created for "item-a"

  # --- annotate (unhappy) ---

  @EARS-FLOW-063
  Scenario: annotating an unknown item is refused
    When I call "annotate" with {"id": "item-z", "text": "note"}
    Then the response is an error with code -32000 and data.error "unknown"

  # --- request_rewrite (happy) ---

  @EARS-FLOW-064 @EARS-FLOW-067
  Scenario: requesting a rewrite bumps the draft and records the request
    When I call "request_rewrite" with {"id": "item-a", "comment": "redo with X"}
    Then the response result draft is 1
    And a "rewrite_requested" event carrying "redo with X" was appended to the log
    When I call "request_rewrite" with {"id": "item-a", "comment": "again"}
    Then the response result draft is 2

  # --- request_rewrite (abuse): not WAIT-gated ---

  @EARS-FLOW-065
  Scenario: a rewrite is allowed even while the item is in WAIT
    Given item "item-a" is in WAIT
    When I call "request_rewrite" with {"id": "item-a", "comment": "redo"}
    Then the response result draft is 1

  @EARS-FLOW-066
  Scenario: requesting a rewrite of an unknown item is refused
    When I call "request_rewrite" with {"id": "item-z", "comment": "redo"}
    Then the response is an error with code -32000 and data.error "unknown"
