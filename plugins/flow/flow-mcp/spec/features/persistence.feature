# Covers: EARS-FLOW-088 .. EARS-FLOW-095 (ownership: tree=identity, log=runtime; ingest→replay;
#         non-clobbering replay; deterministic roll-up; blank/malformed lines; internal-error mapping)
#         and EARS-FLOW-102/103 (no-growth + stored-ancestor roll-up).

Feature: Persistence and replay

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "child" titled "Child"
    And the store contains an item "parent" titled "Parent"
    And a dependency "child" -> "parent"

  # --- happy: durability across restart (the WART fix) ---

  @EARS-FLOW-088 @EARS-FLOW-089
  Scenario: a runtime mutation appends an event and re-renders the markdown board
    When I call "post_status" with {"id": "child", "status": "doing"}
    Then the event log gained one line
    And the markdown board file reflects child in DOING

  @EARS-FLOW-090 @EARS-FLOW-094 @EARS-FLOW-103
  Scenario: spend / model / draft survive a restart and the roll-up is deterministic
    Given I call "append_spend" with {"id": "child", "delta": 100}
    And I call "set_item_model" with {"id": "child", "model": "claude-opus-4-8"}
    And I call "request_rewrite" with {"id": "child", "comment": "redo"}
    When the server restarts (ingest then replay) with the same data directory
    Then item "child" has tokens 100
    And item "parent" has tokens 100
    And item "child" has model "claude-opus-4-8"
    And item "child" has draft 1

  @EARS-FLOW-102
  Scenario: re-ingesting the same tree across restarts does not grow the event log
    Given the board was ingested from a roadmap tree
    When the server restarts twice with the same tree and data directory
    Then the event log line count is unchanged across the restarts
    And list_events returns no duplicate item_upserted entries

  @EARS-FLOW-090
  Scenario: annotated and sys_msg events do not mutate item state on replay
    Given I call "append_sysmsg" with {"text": "hi"}
    And I call "annotate" with {"id": "child", "text": "note"}
    When the server restarts (ingest then replay) with the same data directory
    Then the server is healthy
    And the annotation "note" is still attached to "child"

  # --- unhappy ---

  @EARS-FLOW-091
  Scenario: a blank line in the event log is skipped on load
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
