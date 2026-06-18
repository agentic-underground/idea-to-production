# Covers: EARS-FLOW-037 .. EARS-FLOW-045 (append_spend: own tally, ancestor roll-up, WAIT guard,
#         saturation, events + telemetry).

Feature: Token spend and ancestor roll-up

  Background:
    Given a running flow-mcp with a temporary data directory
    And the store contains an item "child" titled "Child"
    And the store contains an item "parent" titled "Parent"
    And the store contains an item "epic" titled "Epic"
    And a dependency "child" -> "parent"
    And a dependency "parent" -> "epic"

  # --- happy ---

  @EARS-FLOW-037 @EARS-FLOW-044
  Scenario: a spend adds to the item's own tally and logs event + telemetry
    When I call "append_spend" with {"id": "child", "delta": 100}
    Then the response result total is 100
    And item "child" has tokens 100
    And a "spend_appended" event was appended to the log
    And one telemetry record was appended

  @EARS-FLOW-038
  Scenario: a spend rolls up to every transitive ancestor
    When I call "append_spend" with {"id": "child", "delta": 100}
    Then item "parent" has tokens 100
    And item "epic" has tokens 100

  @EARS-FLOW-039
  Scenario: roll-up still accrues onto a WAIT ancestor
    Given item "epic" is in WAIT
    When I call "append_spend" with {"id": "child", "delta": 100}
    Then item "epic" has tokens 100

  @EARS-FLOW-045
  Scenario: the telemetry record attributes the carriage agent and lists ancestors
    When I call "append_spend" with {"id": "child", "delta": 50}
    Then the last telemetry record agent is "carriage-agent"
    And the last telemetry record activity is "spend"
    And the last telemetry record ancestors are ["epic","parent"]

  # --- unhappy ---

  @EARS-FLOW-040
  Scenario: spending on a WAIT item is refused and adds nothing
    Given item "child" is in WAIT
    When I call "append_spend" with {"id": "child", "delta": 100}
    Then the response is an error with code -32000 and data.error "waiting"
    And item "child" has tokens 0

  @EARS-FLOW-041
  Scenario: spending on an unknown item is refused
    When I call "append_spend" with {"id": "item-z", "delta": 100}
    Then the response is an error with code -32000 and data.error "unknown"

  @EARS-FLOW-042
  Scenario: a missing or non-integer delta is invalid params
    When I call "append_spend" with {"id": "child"}
    Then the response is an error with code -32602

  # --- abuse ---

  @EARS-FLOW-043
  Scenario: token tallies saturate rather than overflow
    Given item "child" already has the maximum token tally
    When I call "append_spend" with {"id": "child", "delta": 5}
    Then item "child" still has the maximum token tally
