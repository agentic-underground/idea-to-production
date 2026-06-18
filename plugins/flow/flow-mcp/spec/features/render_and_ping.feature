# Covers: EARS-FLOW-073 .. EARS-FLOW-076, EARS-FLOW-098 (render_roadmap determinism + empty
#         diagnostic; ping health/staleness).

Feature: Local-compute render and health

  Background:
    Given a running flow-mcp with a temporary data directory

  # --- render_roadmap (happy) ---

  @EARS-FLOW-073
  Scenario: render_roadmap returns the deterministic board layout
    Given the store contains an item "item-a" titled "Alpha"
    When I call "render_roadmap" with {}
    Then the response result rendered starts with "ROADMAP\n1 item(s)\n"
    And the response result rendered contains "DO\n  · item-a · Alpha · DO · GO · 0 tok · d0"
    And the response result rendered contains "DOING\n  (none)"
    And the response result rendered contains "DONE\n  (none)"

  @EARS-FLOW-075
  Scenario: render_roadmap is byte-stable across calls
    Given the store contains an item "item-a" titled "Alpha"
    When I call "render_roadmap" with {} twice
    Then both rendered results are byte-identical

  # --- render_roadmap (unhappy/abuse): empty store diagnostic ---

  @EARS-FLOW-074
  Scenario: an empty store appends a diagnostic pointing at ping
    When I call "render_roadmap" with {}
    Then the response result rendered contains "0 item(s)"
    And the response result rendered contains a warning mentioning "ping"

  # --- ping ---

  @EARS-FLOW-076 @EARS-FLOW-098
  Scenario: ping reports version, item count and source
    Given the store contains an item "item-a" titled "Alpha"
    When I call "ping" with {}
    Then the response result message is present
    And the response result version is a non-empty string
    And the response result items is 1
    And the response result has a "source" field

  @EARS-FLOW-076
  Scenario: ping on an un-ingested store reports zero items and null source
    When I call "ping" with {}
    Then the response result items is 0
    And the response result source is null
