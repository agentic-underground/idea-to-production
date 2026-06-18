# Covers: EARS-FLOW-088 .. EARS-FLOW-095 (event log authoritative, single writer, replay incl. spend
#         roll-up, blank/malformed lines, internal error mapping).

Feature: Persistence and replay

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "child" titled "Child"
    And the store contains an item "parent" titled "Parent"
    And a dependency "child" -> "parent"

  # --- happy: durability across restart ---

  @EARS-FLOW-088 @EARS-FLOW-089
  Scenario: each mutation appends an event and re-renders the markdown board
    When I call "post_status" with {"id": "child", "status": "doing"}
    Then the event log gained one line
    And the markdown board file reflects child in DOING

  @EARS-FLOW-090
  Scenario: a replayed spend re-applies the ancestor roll-up
    Given I call "append_spend" with {"id": "child", "delta": 100}
    When the server restarts with the same data directory
    Then item "child" has tokens 100
    And item "parent" has tokens 100

  @EARS-FLOW-090
  Scenario: annotated and sys_msg events are no-ops for in-memory state on replay
    Given I call "append_sysmsg" with {"text": "hi"}
    And I call "annotate" with {"id": "child", "text": "note"}
    When the server restarts with the same data directory
    Then the server is healthy
    And item "child" has status "do"

  # --- unhappy ---

  @EARS-FLOW-091
  Scenario: a blank line in the event log is skipped on replay
    Given the event log has a blank line appended
    When the server restarts with the same data directory
    Then the server is healthy

  @EARS-FLOW-091
  Scenario: a malformed event line aborts the open rather than dropping state
    Given the event log has a malformed line "{\"kind\":\"nope\"}" appended
    When the server attempts to restart with the same data directory
    Then startup fails with an error

  # --- abuse ---

  @EARS-FLOW-095
  Scenario: an internal IO/serialize failure surfaces as -32603, not a domain refusal
    Given the event log path cannot be appended to
    When I call "append_sysmsg" with {"text": "x"}
    Then the response is an error with code -32603
