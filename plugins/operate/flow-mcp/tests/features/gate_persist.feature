# Feature: Gate state persistence across restarts
#
# Covers: EARS-G36-01, EARS-G36-02, EARS-G36-03, EARS-G36-04, EARS-G36-05,
#         EARS-G36-07, EARS-G36-08
#
# Item [36]: Persist gate state: WAIT/GO survives restart + surfaces in roadmap view

Feature: Gate state persistence across restarts

  Background:
    Given a flow-mcp is running with a temporary .flow/ directory
    And the roadmap contains item "item-a" with title "Alpha" in status PENDING

  # --- Happy path: persist and restore ---

  Scenario: Toggle to WAIT survives a server restart (EARS-G36-01, EARS-G36-02)
    When I POST /api/items/item-a/gate with body {"gate": "wait"}
    Then the response status is 200
    And .flow/gates.json exists and contains {"item-a": "wait"}
    When the server is restarted with the same .flow/ directory
    And I GET /api/items
    Then the response contains item "item-a" with gate "wait"

  Scenario: Toggle back to GO is persisted and restored (EARS-G36-01, EARS-G36-02)
    Given item "item-a" gate is set to "wait"
    When I POST /api/items/item-a/gate with body {"gate": "go"}
    Then .flow/gates.json exists and contains {"item-a": "go"}
    When the server is restarted with the same .flow/ directory
    And I GET /api/items
    Then the response contains item "item-a" with gate "go"

  Scenario: gates.json is written atomically (no partial writes) (EARS-G36-01)
    When I POST /api/items/item-a/gate with body {"gate": "wait"}
    Then .flow/gates.json is valid JSON
    And .flow/gates.json.tmp does not exist

  Scenario: Restore gates after ingest_roadmap preserves WAIT state (EARS-G36-07, EARS-G36-08)
    Given .flow/gates.json contains {"item-a": "wait"}
    When the server starts with the roadmap that contains item "item-a"
    Then item "item-a" has gate "wait" (restore_gates ran AFTER ingest_roadmap)
    And no error occurred during startup

  # --- Unhappy path: missing gates.json ---

  Scenario: Missing gates.json does not prevent startup (EARS-G36-03)
    Given .flow/gates.json does not exist
    When the server starts
    Then the server is healthy (GET /api/items returns HTTP 200)
    And all items have gate "go"

  # --- Unhappy path: corrupt gates.json ---

  Scenario: Corrupt gates.json does not prevent startup (EARS-G36-04)
    Given .flow/gates.json contains the bytes "{not valid json}"
    When the server starts
    Then the server is healthy (GET /api/items returns HTTP 200)
    And all items have gate "go"
    And a warning is emitted to stderr containing "malformed" or "gates.json"

  Scenario: Entirely empty gates.json does not prevent startup (EARS-G36-04)
    Given .flow/gates.json is an empty file
    When the server starts
    Then the server is healthy (GET /api/items returns HTTP 200)
    And all items have gate "go"

  # --- Abuse path: stale item IDs ---

  Scenario: Stale item ID in gates.json is silently discarded (EARS-G36-05)
    Given .flow/gates.json contains {"ghost-item": "wait", "item-a": "wait"}
    And "ghost-item" does not exist in the roadmap
    When the server starts
    Then the server is healthy (GET /api/items returns HTTP 200)
    And item "item-a" has gate "wait"
    And no error occurred during startup

  # --- Warn-and-continue on write failure ---

  Scenario: set_gate succeeds even when gates.json cannot be written (EARS-G36-07)
    Given the .flow/ directory is write-protected for sidecar writes
    When I POST /api/items/item-a/gate with body {"gate": "wait"}
    Then the response status is 200
    And item "item-a" has gate "wait" in memory
    And a warning is emitted to stderr about the sidecar write failure
