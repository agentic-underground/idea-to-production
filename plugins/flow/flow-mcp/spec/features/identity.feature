# Covers: EARS-FLOW-014, EARS-FLOW-015, EARS-FLOW-016 (ItemId validation; slug is identity).

Feature: Item id validation

  Background:
    Given a running flow-mcp with an empty store

  # --- happy ---

  @EARS-FLOW-014
  Scenario Outline: well-formed slugs are accepted as item ids
    When I call "get_item" with {"id": "<slug>"}
    Then the response is not an invalid-params error

    Examples:
      | slug          |
      | a             |
      | item-42       |
      | a1-b2-c3      |
      | flow-server   |

  # --- unhappy / abuse: malformed ids are rejected before any mutation ---

  @EARS-FLOW-015
  Scenario Outline: malformed ids are rejected with -32602 and mutate nothing
    When I call "set_wait_go" with {"id": "<bad>", "gate": "wait"}
    Then the response is an error with code -32602
    And no event was appended to the log

    Examples:
      | bad           |
      |               |
      | Flow          |
      | flow_server   |
      | -flow         |
      | flow-         |
      | flow--server  |
      | thisisaverylongslugthatgoeswellpastthesixtyfourcharacterlimitxxxxxxxxxx |

  @EARS-FLOW-015
  Scenario: a non-string id is rejected with -32602
    When I call "get_item" with {"id": 123}
    Then the response is an error with code -32602

  @EARS-FLOW-016
  Scenario: the slug, not the display position, is the identity
    Given the store contains items "item-1" and "item-2" with a dependency "item-2" -> "item-1"
    When the board display order is reversed
    Then the dependency "item-2" -> "item-1" still resolves
    And both items are still retrievable by their slug ids
