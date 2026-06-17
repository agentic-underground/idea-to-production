# Feature: list_items MCP tool groups PENDING items by gate
#
# Covers: EARS-G36-06
#
# Item [36]: MCP list_items response shape change from flat {"items":[...]}
# to grouped {"pending":{"wait":[...],"go":[...]},"in_progress":[...],"done":[...]}

Feature: list_items MCP tool groups PENDING items by gate

  Background:
    Given a flow-mcp is running with a temporary .flow/ directory

  # --- Happy path: correct grouping ---

  Scenario: list_items groups PENDING by gate (EARS-G36-06)
    Given the store contains:
      | id       | title   | status  | gate |
      | item-p-w | PendW   | PENDING | WAIT |
      | item-p-g | PendGo  | PENDING | GO   |
      | item-d   | Doing   | DOING   | GO   |
      | item-x   | Done    | DONE    | GO   |
    When I call MCP tool "list_items" with no arguments
    Then the result contains "pending.wait" with 1 item
    And "pending.wait[0].id" equals "item-p-w"
    And the result contains "pending.go" with 1 item
    And "pending.go[0].id" equals "item-p-g"
    And the result contains "in_progress" with 1 item
    And "in_progress[0].id" equals "item-d"
    And the result contains "done" with 1 item
    And "done[0].id" equals "item-x"

  Scenario: Empty store returns empty groups (EARS-G36-06)
    Given the store contains no items
    When I call MCP tool "list_items" with no arguments
    Then the result contains "pending.wait" as an empty array
    And the result contains "pending.go" as an empty array
    And the result contains "in_progress" as an empty array
    And the result contains "done" as an empty array

  Scenario: All pending GO items leave wait group empty (EARS-G36-06)
    Given the store contains:
      | id     | title | status  | gate |
      | item-1 | One   | PENDING | GO   |
      | item-2 | Two   | PENDING | GO   |
    When I call MCP tool "list_items" with no arguments
    Then the result contains "pending.wait" as an empty array
    And the result contains "pending.go" with 2 items

  Scenario: All pending WAIT items leave go group empty (EARS-G36-06)
    Given the store contains:
      | id     | title | status  | gate |
      | item-1 | One   | PENDING | WAIT |
    When I call MCP tool "list_items" with no arguments
    Then the result contains "pending.wait" with 1 item
    And the result contains "pending.go" as an empty array

  Scenario: Item objects in groups include full item_json fields (EARS-G36-06)
    Given the store contains item "item-a" with title "Alpha" in status PENDING and gate WAIT
    When I call MCP tool "list_items" with no arguments
    Then "pending.wait[0]" contains fields: id, title, status, gate, tokens, model

  Scenario: list_items does not include old "items" flat array key (EARS-G36-06)
    Given the store contains item "item-a" with title "Alpha" in status PENDING and gate GO
    When I call MCP tool "list_items" with no arguments
    Then the result does not contain a top-level "items" key

  # --- Integration with gate persistence ---

  Scenario: list_items reflects restored gate after restart (EARS-G36-02, EARS-G36-06)
    Given item "item-a" gate was set to "wait" before restart
    When the server is restarted with the same .flow/ directory
    And I call MCP tool "list_items" with no arguments
    Then the result contains "pending.wait" with item "item-a"
    And the result contains "pending.go" as an empty array
