Feature: Commit-graph view in item detail panel
  As a solo-builder
  I want to see commits for a roadmap item displayed as a dot-and-line graph
  So I can inspect commit history without leaving the board view

  Background:
    Given the RHS detail panel is mounted

  Scenario: Item with commits shows dot-and-line graph
    Given an item with 3 commits
    When I open the detail panel for that item
    Then the bottom section contains a commit-graph-list
    And the list contains 3 list items with commit dots

  Scenario: Clicking a dot expands the commit message
    Given an item with a commit "abc1234abc: feat: add thing\n\nBody here."
    When I click the commit dot for that commit
    Then the commit-body div is visible (has class "open")
    And it contains the full hash "abc1234abc"
    And it contains the full message body

  Scenario: Clicking a dot again collapses the commit message
    Given a commit dot that is expanded
    When I click the same dot again
    Then the commit-body div is hidden (does not have class "open")

  Scenario: Keyboard Enter on a dot expands the commit message
    Given an item with a commit
    When I press Enter on the commit dot
    Then the commit-body div becomes visible

  Scenario: Keyboard Space on a dot expands the commit message
    Given an item with a commit
    When I press Space on the commit dot
    Then the commit-body div becomes visible

  Scenario: Item with no commits shows placeholder
    Given an item with an empty commits array
    When I open the detail panel for that item
    Then the bottom section contains "No commits yet."
    And the bottom section does not contain a commit-graph-list

  Scenario: Long commit message is fully contained in commit-body
    Given an item with a commit whose body is 500 characters long
    When I click the commit dot
    Then the commit-body pre element contains the full 500 characters

  Scenario: Short hash displayed in summary; full hash in body
    Given an item with a commit hash "abc1234abcdef"
    When I open the detail panel
    Then the commit-hash span shows "abc1234" (7 chars)
    When I click the dot
    Then the commit-body pre shows "abc1234abcdef" (full hash)

  Scenario: aria-expanded reflects state
    Given a commit dot in its default state
    Then aria-expanded is "false"
    When I click the dot
    Then aria-expanded is "true"
    When I click the dot again
    Then aria-expanded is "false"

  Scenario: Multiple commits — correct count of list items
    Given an item with 5 commits
    When I open the detail panel
    Then the commit-graph-list contains 5 list items
