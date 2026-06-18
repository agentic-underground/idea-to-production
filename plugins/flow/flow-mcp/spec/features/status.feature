# Covers: EARS-FLOW-029 .. EARS-FLOW-036 (post_status: WAIT guard, events, tree write-back + rollback).

Feature: Carriage status advancement

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "item-a" titled "Alpha"

  # --- happy ---

  @EARS-FLOW-029 @EARS-FLOW-032
  Scenario: advancing a GO item sets its status and logs the event
    When I call "post_status" with {"id": "item-a", "status": "doing"}
    Then the response result is {"ok": true}
    And item "item-a" has status "doing"
    And a "status_posted" event was appended to the log

  @EARS-FLOW-033
  Scenario: a status change writes back to the roadmap tree
    Given the board was ingested from a roadmap tree with item 1 "Alpha" in folder "do"
    When I call "post_status" with {"id": "item-1", "status": "done"}
    Then the tree file for item 1 is now in folder "done"
    And the tree file for item 1 has status front-matter "COMPLETE"

  @EARS-FLOW-036
  Scenario: an item with no tree file still advances (write-back is a no-op)
    Given the board was ingested from a roadmap tree with item 1 "Alpha" in folder "do"
    And the store also contains a synthesized item "item-9" with no tree file
    When I call "post_status" with {"id": "item-9", "status": "doing"}
    Then the response result is {"ok": true}
    And item "item-9" has status "doing"

  # --- unhappy ---

  @EARS-FLOW-030
  Scenario: advancing a WAIT item is refused and leaves status unchanged
    Given item "item-a" is in WAIT
    When I call "post_status" with {"id": "item-a", "status": "doing"}
    Then the response is an error with code -32000 and data.error "waiting"
    And item "item-a" has status "do"

  @EARS-FLOW-031
  Scenario: advancing an unknown item is refused
    When I call "post_status" with {"id": "item-z", "status": "done"}
    Then the response is an error with code -32000 and data.error "unknown"

  # --- abuse: tree write-back failure rolls memory back ---

  @EARS-FLOW-034
  Scenario: a failed tree write-back rolls the in-memory status back
    Given the board was ingested from a roadmap tree with item 1 "Alpha" in folder "do"
    And the roadmap tree destination folder cannot be written
    When I call "post_status" with {"id": "item-1", "status": "done"}
    Then the response is an error
    And item "item-1" has status "do"

  @EARS-FLOW-035
  Scenario: duplicate tree ids move the last match and warn
    Given the board was ingested from a roadmap tree where item 1 appears in both "do" and "doing"
    When I call "post_status" with {"id": "item-1", "status": "done"}
    Then the tree file for item 1 is now in folder "done"
    And a warning was emitted to stderr about the duplicate id
