# Covers: EARS-FLOW-104 .. EARS-FLOW-107 (create_item / delete_item — tree write-back, next-id
#         assignment, edge pruning, restart durability, unknown-dependency refusal).

Feature: Item lifecycle — create and delete

  Background:
    Given a running flow-mcp ingested from a roadmap tree with item 1 "Alpha"

  # --- create (happy) ---

  @EARS-FLOW-104
  Scenario: create_item assigns the next id and writes the tree file
    When I call "create_item" with {"title": "Bravo", "status": "doing"}
    Then the response result id is "item-2"
    And the tree file "doing/2.md" exists with title "Bravo"
    And item "item-2" is on the board with status "doing"

  @EARS-FLOW-104
  Scenario: create_item with dependencies records the edges
    When I call "create_item" with {"title": "Charlie", "depends_on": ["item-1"]}
    Then the response result id is "item-2"
    And the edge "item-2" -> "item-1" exists
    And the tree file for item 2 declares depends_on "#1"

  @EARS-FLOW-106
  Scenario: a created item survives a restart
    Given I call "create_item" with {"title": "Bravo", "status": "doing"}
    When the server restarts (ingest then replay) with the same tree and data directory
    Then item "item-2" is on the board with status "doing"

  # --- create (unhappy/abuse) ---

  @EARS-FLOW-107
  Scenario: create_item with an unknown dependency is refused and creates nothing
    When I call "create_item" with {"title": "Bad", "depends_on": ["item-99"]}
    Then the response is an error with code -32000 and data.error "unknown"
    And no item "item-2" exists

  @EARS-FLOW-107
  Scenario: create_item with a malformed dependency id is invalid params
    When I call "create_item" with {"title": "Bad", "depends_on": ["Not An Id"]}
    Then the response is an error with code -32602

  @EARS-FLOW-104
  Scenario: create_item without a title is invalid params
    When I call "create_item" with {}
    Then the response is an error with code -32602

  # --- delete (happy) ---

  @EARS-FLOW-105
  Scenario: delete_item removes the item, its tree file, and incident edges
    Given I call "create_item" with {"title": "Bravo", "depends_on": ["item-1"]}
    When I call "delete_item" with {"id": "item-1"}
    Then the response result is {"ok": true}
    And no item "item-1" exists
    And the tree file for item 1 is gone
    And the edge "item-2" -> "item-1" does not exist

  @EARS-FLOW-106
  Scenario: a deleted item stays gone after a restart
    Given I call "delete_item" with {"id": "item-1"}
    When the server restarts (ingest then replay) with the same tree and data directory
    Then no item "item-1" exists

  # --- delete (unhappy) ---

  @EARS-FLOW-105
  Scenario: deleting an unknown item is refused
    When I call "delete_item" with {"id": "item-99"}
    Then the response is an error with code -32000 and data.error "unknown"
