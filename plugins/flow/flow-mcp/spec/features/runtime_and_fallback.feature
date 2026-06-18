# Covers: EARS-FLOW-096, EARS-FLOW-097, EARS-FLOW-099 .. EARS-FLOW-101 (observability, telemetry
#         ledger as the single sink, Ruby floor, fallback runbook parity).

Feature: Runtime, observability and the markdown fallback

  # --- observability ---

  @EARS-FLOW-096
  Scenario: an unexpected internal error emits a full backtrace to stderr
    Given a running flow-mcp with a temporary data directory
    When an internal error is forced on a write path
    Then a full backtrace is written to stderr
    And the response is an error with code -32603

  @EARS-FLOW-097
  Scenario: a spend records to the telemetry ledger and never pushes externally
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "item-a" titled "Alpha"
    When I call "append_spend" with {"id": "item-a", "delta": 10}
    Then the response result total is 10
    And one telemetry record was appended to telemetry.jsonl
    And no external telemetry endpoint is contacted

  # --- Ruby floor ---

  @EARS-FLOW-099
  Scenario: the server runs on Ruby 3.3.8 using only the standard library
    Given Ruby 3.3.8 with no third-party gems installed
    When the launcher starts the server
    Then the server serves a "ping" successfully

  @EARS-FLOW-100
  Scenario: no compliant Ruby points the operator at the fallback runbook
    Given no Ruby >= 3.3.8 is available on PATH
    When the launcher is invoked
    Then the launcher exits non-zero
    And the launcher message points at the flow-by-hand fallback runbook

  # --- fallback parity ---

  @EARS-FLOW-101
  Scenario: performing a verb by hand yields the same on-disk state as the server
    Given a temporary data directory with an item "item-a" in status "do"
    When the flow-by-hand runbook procedure for "post_status" to "doing" is followed for "item-a"
    Then the resulting events.jsonl and ROADMAP.flow.md match what the server would produce
