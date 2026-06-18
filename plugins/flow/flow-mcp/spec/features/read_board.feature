# Covers: EARS-FLOW-017 .. EARS-FLOW-022 (list_items grouping, get_item shape, read verbs are pure).

Feature: Reading the board

  Background:
    Given a running flow-mcp with an empty store
    And the store contains an item "item-a" titled "Alpha"
    And the store contains an item "item-b" titled "Bravo"
    And the store contains an item "item-c" titled "Charlie"

  # --- happy: grouping by status and gate ---

  @EARS-FLOW-017 @EARS-FLOW-018
  Scenario: list_items groups by status, splitting pending by gate, in display order
    Given item "item-a" is in WAIT
    And item "item-b" has status "doing"
    And item "item-c" has status "done"
    When I call "list_items" with {}
    Then the response result "pending.wait" contains item "item-a"
    And the response result "pending.go" is empty
    And the response result "in_progress" contains item "item-b"
    And the response result "done" contains item "item-c"

  @EARS-FLOW-019
  Scenario: each rendered item carries the full field set
    When I call "get_item" with {"id": "item-a"}
    Then the response result item has fields "id","title","status","gate","tokens","model","draft","deps","annotations","commits","pr"
    And the response result item "commits" is an empty array
    And the response result item "pr" is null

  @EARS-FLOW-019
  Scenario: deps and annotations are rendered on the item
    Given a dependency "item-a" -> "item-b"
    And item "item-a" has an annotation "looks good"
    When I call "get_item" with {"id": "item-a"}
    Then the response result item "deps" contains "item-b"
    And the response result item "annotations" contains "looks good"

  @EARS-FLOW-020
  Scenario: get_item returns a known item
    When I call "get_item" with {"id": "item-b"}
    Then the response result item "id" is "item-b"
    And the response result item "title" is "Bravo"

  # --- unhappy ---

  @EARS-FLOW-021
  Scenario: get_item on an unknown id returns -32004
    When I call "get_item" with {"id": "item-z"}
    Then the response is an error with code -32004

  # --- abuse: reads never mutate ---

  @EARS-FLOW-022
  Scenario: list_items and get_item append no events
    When I call "list_items" with {}
    And I call "get_item" with {"id": "item-a"}
    Then no event was appended to the log
