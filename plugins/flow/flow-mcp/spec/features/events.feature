# Covers: EARS-FLOW-068 .. EARS-FLOW-072 (append_sysmsg; list_events ordering + kind filter).

Feature: Event feed

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "item-a" titled "Alpha"

  # --- append_sysmsg ---

  @EARS-FLOW-068
  Scenario: a system message is appended to the feed
    When I call "append_sysmsg" with {"text": "wave 1 starting"}
    Then the response result is {"ok": true}
    And a "sys_msg" event was appended to the log

  @EARS-FLOW-069
  Scenario: a system message without string text is invalid params
    When I call "append_sysmsg" with {}
    Then the response is an error with code -32602

  # --- list_events ---

  @EARS-FLOW-070
  Scenario: list_events returns every event oldest-first
    Given the following calls have been made:
      | call          | args                                  |
      | append_sysmsg | {"text": "one"}                       |
      | set_wait_go   | {"id": "item-a", "gate": "wait"}      |
    When I call "list_events" with {}
    Then the response result events has 2 entries
    And the response result events[0] kind is "sys_msg"
    And the response result events[1] kind is "gate_set"

  @EARS-FLOW-071
  Scenario: list_events filters by kind
    Given the following calls have been made:
      | call          | args                                  |
      | append_sysmsg | {"text": "one"}                       |
      | set_wait_go   | {"id": "item-a", "gate": "wait"}      |
    When I call "list_events" with {"kind": "sys_msg"}
    Then the response result events has 1 entry
    And the response result events[0] kind is "sys_msg"

  # --- abuse ---

  @EARS-FLOW-072
  Scenario: a non-string kind filter is ignored and the full log returns
    Given the following calls have been made:
      | call          | args              |
      | append_sysmsg | {"text": "one"}   |
    When I call "list_events" with {"kind": 5}
    Then the response result events has 1 entry
