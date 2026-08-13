# SPECIFICATION ONLY — NOT EXECUTABLE
# Gherkin scenarios for `board` Slice 1 (PLAN 0072.014). Behaviour is pinned by pytest in
# tests/test_lifecycle.py (pure core) + a live story-proof on project #4 (the gh shell). No pytest-bdd
# harness is wired for Slice 1 — these describe intent and trace to EARS-NNN.

Feature: Board lifecycle transitions roll a parent EPIC up as its PLANs move

  Scenario: a PLAN going Done rolls its EPIC forward          # @EARS-004 @EARS-005
    Given EPIC 0072 is In Progress with PLANs in mixed states
    When the last open PLAN transitions "done"
    And every child is now terminal
    Then the EPIC's computed status is Done
    And the EPIC is closed by the set-status lockstep         # @EARS-002

  Scenario: an active PLAN moves its Backlog EPIC to In Progress   # @EARS-004 @EARS-006
    Given EPIC 0074 is Backlog with all PLANs in Backlog
    When one PLAN transitions "start"
    Then the EPIC's computed status is In Progress

  Scenario: all PLANs merely To Do does not force the EPIC active   # @EARS-006
    Given an EPIC whose PLANs are all To Do
    When the rollup is computed
    Then the EPIC status is unchanged

  Scenario: a PARKED EPIC is never un-parked by a child touch      # @EARS-009
    Given a PARKED EPIC with an In Progress PLAN
    When the rollup is computed
    Then no status change is produced

  Scenario: a Delivered EPIC never regresses to Done               # @EARS-009
    Given a Delivered EPIC whose children are all terminal
    When the rollup is computed
    Then no status change is produced

  Scenario: an unreachable board fails closed                      # @EARS-007
    Given the GitHub board cannot be reached
    When a lifecycle transition is attempted
    Then the command exits non-zero with no partial write

  Scenario: an issue number where an order is expected is rejected # @EARS-008
    Given the argument "367" (a GitHub issue number, not a roadmap order)
    When "board lifecycle 367 done" is invoked
    Then the command rejects it and makes no board change
