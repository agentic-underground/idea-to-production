Feature: REDO badge + required-comment modal (item [30])

  Background:
    Given the flow canvas is mounted with items in various statuses
    And a card "flow-server" is in status "done"
    And a card "svg-flow-canvas" is in status "doing"

  # ---------------------------------------------------------------------------
  # AC1: Backward drag triggers the modal
  # ---------------------------------------------------------------------------

  Scenario: DONE-to-DO drag triggers the REDO modal
    When the user drags the "flow-server" card to the DO column
    Then a REDO comment modal SHALL appear before any status change is committed
    And the modal SHALL have a textarea for the comment
    And the submit button SHALL be disabled

  Scenario: DONE-to-DOING drag triggers the REDO modal
    When the user drags the "flow-server" card to the DOING column
    Then a REDO comment modal SHALL appear before any status change is committed

  Scenario: Non-backward drag (DOING-to-DONE) does NOT trigger the REDO modal
    When the user drags the "svg-flow-canvas" card to the DONE column
    Then no REDO modal SHALL appear
    And api.postStatus SHALL be called immediately with status "done"

  # ---------------------------------------------------------------------------
  # AC1: Empty comment guard
  # ---------------------------------------------------------------------------

  Scenario: Empty comment cannot be submitted
    Given the REDO modal is open for a backward drag
    When the textarea is empty
    Then the submit button SHALL be disabled
    And clicking the submit button SHALL NOT call api.annotate or api.postStatus

  Scenario: Whitespace-only comment cannot be submitted
    Given the REDO modal is open for a backward drag
    When the textarea contains only whitespace
    Then the submit button SHALL be disabled

  # ---------------------------------------------------------------------------
  # AC2: Valid comment path
  # ---------------------------------------------------------------------------

  Scenario: Valid comment stores annotation and posts status, shows REDO badge
    Given the REDO modal is open for a "done" → "do" backward drag on "flow-server"
    When the user types "Regression found in deploy pipeline" and submits
    Then api.annotate SHALL be called with id "flow-server" and the comment text
    And api.postStatus SHALL be called with id "flow-server" and status "do"
    And the modal SHALL close
    And the "flow-server" card SHALL display a coral REDO badge

  # ---------------------------------------------------------------------------
  # AC1: Modal dismissal reverts
  # ---------------------------------------------------------------------------

  Scenario: Cancel button reverts the card to DONE without any API call
    Given the REDO modal is open for a "done" → "do" backward drag
    When the user clicks the Cancel button
    Then the card SHALL return to the DONE column
    And api.annotate SHALL NOT have been called
    And api.postStatus SHALL NOT have been called

  Scenario: Escape key reverts the card to DONE without any API call
    Given the REDO modal is open for a "done" → "do" backward drag
    When the user presses Escape
    Then the card SHALL return to the DONE column
    And api.annotate SHALL NOT have been called

  # ---------------------------------------------------------------------------
  # AC2: REDO badge cleared on forward move
  # ---------------------------------------------------------------------------

  Scenario: Moving a REDO-badged card forward to DONE removes the REDO badge
    Given the "flow-server" card has a REDO badge (item.redo = true) and status "do"
    When the user drags the "flow-server" card to the DONE column
    Then the REDO badge SHALL be removed from the card
    And api.postStatus SHALL be called with status "done"

  # ---------------------------------------------------------------------------
  # Accessibility
  # ---------------------------------------------------------------------------

  Scenario: REDO modal has correct ARIA attributes
    Given the REDO modal is open
    Then the dialog element SHALL have role "dialog"
    And the dialog element SHALL have aria-modal "true"
    And the dialog element SHALL have aria-labelledby pointing to its heading
