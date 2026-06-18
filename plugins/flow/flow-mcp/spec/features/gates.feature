# Covers: EARS-FLOW-023 .. EARS-FLOW-028 (set_wait_go), EARS-FLOW-092 .. EARS-FLOW-094 (gate sidecar
#         + restore), and the warn-and-continue sidecar contract.

Feature: WAIT/GO governance gate

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "item-a" titled "Alpha"

  # --- happy: set, persist, restore ---

  @EARS-FLOW-023 @EARS-FLOW-026 @EARS-FLOW-027
  Scenario: setting WAIT updates the gate, logs the event, and writes the sidecar atomically
    When I call "set_wait_go" with {"id": "item-a", "gate": "wait"}
    Then the response result is {"ok": true}
    And item "item-a" has gate "wait"
    And a "gate_set" event was appended to the log
    And the gates sidecar is valid JSON containing {"item-a": "wait"}
    And no gates sidecar temp file remains

  @EARS-FLOW-024
  Scenario: a WAIT item can still be toggled back to GO
    Given item "item-a" is in WAIT
    When I call "set_wait_go" with {"id": "item-a", "gate": "go"}
    Then the response result is {"ok": true}
    And item "item-a" has gate "go"

  @EARS-FLOW-092
  Scenario: the gates sidecar is a sorted id->gate map
    Given the store contains an item "item-b" titled "Bravo"
    When I call "set_wait_go" with {"id": "item-b", "gate": "wait"}
    And I call "set_wait_go" with {"id": "item-a", "gate": "go"}
    Then the gates sidecar keys are in sorted order

  # --- unhappy ---

  @EARS-FLOW-025
  Scenario: setting the gate on an unknown id is refused
    When I call "set_wait_go" with {"id": "item-z", "gate": "wait"}
    Then the response is an error with code -32000 and data.error "unknown"
    And no event was appended to the log

  @EARS-FLOW-093
  Scenario: a malformed gates sidecar defaults all gates to GO without failing startup
    Given the gates sidecar contains the bytes "{not valid json}"
    When the server restarts with the same data directory
    Then the server is healthy
    And item "item-a" has gate "go"
    And a warning was emitted to stderr matching "malformed|gates"

  # --- abuse ---

  @EARS-FLOW-094
  Scenario: a stale id in the sidecar is silently discarded on restore
    Given the gates sidecar contains {"ghost": "wait", "item-a": "wait"}
    When the server restarts with the same data directory
    Then the server is healthy
    And item "item-a" has gate "wait"
    And no error occurred during startup

  @EARS-FLOW-028
  Scenario: a sidecar write failure still reports the gate change as successful
    Given the gates sidecar cannot be written
    When I call "set_wait_go" with {"id": "item-a", "gate": "wait"}
    Then the response result is {"ok": true}
    And item "item-a" has gate "wait" in memory
    And a warning was emitted to stderr about the sidecar write failure
