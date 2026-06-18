# Covers: EARS-FLOW-046 .. EARS-FLOW-058 (set_item_model; validate/mutate connection: cycle, unknown,
#         broken_dep, idempotent add, refusal leaves state unchanged).

Feature: Model assignment and the dependency graph

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "item-a" titled "Alpha"
    And the store contains an item "item-b" titled "Bravo"

  # --- set_item_model ---

  @EARS-FLOW-046 @EARS-FLOW-049
  Scenario: setting a model updates the item and logs the event
    When I call "set_item_model" with {"id": "item-a", "model": "claude-opus-4-8"}
    Then the response result is {"ok": true}
    And item "item-a" has model "claude-opus-4-8"
    And a "model_set" event was appended to the log

  @EARS-FLOW-047
  Scenario: setting a model on an unknown item is refused
    When I call "set_item_model" with {"id": "item-z", "model": "x"}
    Then the response is an error with code -32000 and data.error "unknown"

  @EARS-FLOW-048
  Scenario: setting a model without a string model is invalid params
    When I call "set_item_model" with {"id": "item-a"}
    Then the response is an error with code -32602

  # --- validate_connection (happy + unhappy) ---

  @EARS-FLOW-050
  Scenario: validating a sound edge reports ok without mutating
    When I call "validate_connection" with {"from": "item-a", "to": "item-b"}
    Then the response result is {"ok": true}
    And the edge set is unchanged

  @EARS-FLOW-051
  Scenario: validating an edge with an unknown endpoint reports unknown
    When I call "validate_connection" with {"from": "item-a", "to": "item-z"}
    Then the response is an error with code -32000 and data.error "unknown"

  @EARS-FLOW-052
  Scenario: a self-edge is rejected as a cycle
    When I call "validate_connection" with {"from": "item-a", "to": "item-a"}
    Then the response is an error with code -32000 and data.error "cycle"

  @EARS-FLOW-052
  Scenario: an edge that would close a cycle is rejected
    Given a dependency "item-a" -> "item-b"
    When I call "validate_connection" with {"from": "item-b", "to": "item-a"}
    Then the response is an error with code -32000 and data.error "cycle"

  # --- mutate_connection: add ---

  @EARS-FLOW-053
  Scenario: adding a valid edge logs connection_added
    When I call "mutate_connection" with {"op": "add", "from": "item-a", "to": "item-b"}
    Then the response result is {"ok": true}
    And the edge "item-a" -> "item-b" exists
    And a "connection_added" event was appended to the log

  @EARS-FLOW-054
  Scenario: adding an existing edge is idempotent
    Given a dependency "item-a" -> "item-b"
    When I call "mutate_connection" with {"op": "add", "from": "item-a", "to": "item-b"}
    Then the response result is {"ok": true}
    And exactly one edge "item-a" -> "item-b" exists

  # --- mutate_connection: remove ---

  @EARS-FLOW-055
  Scenario: removing an existing edge logs connection_removed
    Given a dependency "item-a" -> "item-b"
    When I call "mutate_connection" with {"op": "remove", "from": "item-a", "to": "item-b"}
    Then the response result is {"ok": true}
    And the edge "item-a" -> "item-b" does not exist
    And a "connection_removed" event was appended to the log

  @EARS-FLOW-056
  Scenario: removing a non-existent edge reports broken_dep
    When I call "mutate_connection" with {"op": "remove", "from": "item-a", "to": "item-b"}
    Then the response is an error with code -32000 and data.error "broken_dep"

  # --- abuse ---

  @EARS-FLOW-057
  Scenario: an unknown op is invalid params
    When I call "mutate_connection" with {"op": "toggle", "from": "item-a", "to": "item-b"}
    Then the response is an error with code -32602

  @EARS-FLOW-058
  Scenario: a refused add leaves the edge set unchanged
    Given a dependency "item-a" -> "item-b"
    When I call "mutate_connection" with {"op": "add", "from": "item-b", "to": "item-a"}
    Then the response is an error with code -32000 and data.error "cycle"
    And exactly one edge exists
