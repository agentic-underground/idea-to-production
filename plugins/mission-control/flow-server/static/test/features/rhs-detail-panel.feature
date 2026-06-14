Feature: RHS Detail Panel
  As a solo builder
  I want to click a card and see its details in a right-hand panel
  So that I can inspect PR linkage, issue text, and commit history without leaving the board

  Background:
    Given the flow-server returns items with deps, annotations, commits, and pr fields
    And the detail panel is mounted beside the canvas

  Scenario: EPIC card click shows PR placeholder and deps list
    Given an item with id "epic-1" has pr=null and deps=["item-a", "item-b"]
    When the user clicks the card for "epic-1"
    Then the detail panel SHALL be visible
    And the top section SHALL display "PR not linked yet."
    And the bottom section SHALL display "2 items" and list "item-a" and "item-b"

  Scenario: ITEM card click shows latest annotation and empty commits placeholder
    Given an item with id "item-a" has annotations=["first note", "latest note"] and commits=[]
    When the user clicks the card for "item-a"
    Then the detail panel SHALL be visible
    And the top section SHALL display "first note" and "latest note"
    And the bottom section SHALL display "No commits yet."

  Scenario: Panel shows "No issue text recorded." for item with empty annotations
    Given an item with id "item-b" has annotations=[] and commits=[]
    When the user clicks the card for "item-b"
    Then the top section SHALL display "No issue text recorded."

  Scenario: Panel sections scroll independently on overflow
    Given an item with id "item-c" has many annotations that overflow the top section
    When the user clicks the card for "item-c"
    Then the top section SHALL have overflow-y: auto (independent scroll)
    And the bottom section SHALL have overflow-y: auto (independent scroll)

  Scenario: Panel hidden when no selection
    Given no card has been clicked
    Then the detail panel SHALL be hidden (hidden attribute present)

  Scenario: Close button hides the panel
    Given the detail panel is open for any card
    When the user activates the close button
    Then the detail panel SHALL be hidden
    And the panel content SHALL be cleared

  Scenario: API returns extended item shape
    Given the flow-server has an item "item-a" with one Annotated event and one dep
    When GET /api/items is called
    Then each item in the response SHALL include a "deps" array
    And each item in the response SHALL include an "annotations" array
    And each item in the response SHALL include a "commits" array
    And each item in the response SHALL include a "pr" field (null)

  Scenario: API annotations are newest-last
    Given item "item-a" has Annotated events in order ["first", "second", "third"]
    When GET /api/items/:id is called for "item-a"
    Then the "annotations" field SHALL be ["first", "second", "third"]
