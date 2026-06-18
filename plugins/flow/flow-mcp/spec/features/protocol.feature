# Covers: EARS-FLOW-001 .. EARS-FLOW-013 (newline-delimited JSON-RPC over stdio, MCP handshake,
#         tools/list, method/parse error handling, notifications, EOF).

Feature: JSON-RPC stdio transport and MCP handshake

  Background:
    Given a running flow-mcp with an empty store

  # --- handshake (happy) ---

  @EARS-FLOW-002 @EARS-FLOW-003
  Scenario: initialize echoes a supported protocol version
    When I send an "initialize" request with protocolVersion "2024-11-05"
    Then the response result protocolVersion is "2024-11-05"
    And the response result capabilities has a "tools" object
    And the response result serverInfo name is "flow-mcp"
    And the response result serverInfo version is a non-empty string

  @EARS-FLOW-004
  Scenario: initialize negotiates down an unsupported protocol version
    When I send an "initialize" request with protocolVersion "2099-01-01"
    Then the response result protocolVersion is "2024-11-05"

  @EARS-FLOW-006 @EARS-FLOW-007 @EARS-FLOW-008
  Scenario: tools/list advertises all 14 dispatchable verbs with real schemas
    When I send a "tools/list" request
    Then the response result tools has exactly 14 entries
    And every tool entry has "name", "description" and an "inputSchema" object
    And the tool "post_status" inputSchema requires "id" and "status"
    And the tool "post_status" inputSchema "status" enum is ["do","doing","done"]
    And the tool "set_wait_go" inputSchema "gate" enum is ["wait","go"]
    And the tool "mutate_connection" inputSchema "op" enum is ["add","remove"]
    And every advertised tool name is dispatchable via tools/call

  @EARS-FLOW-001 @EARS-FLOW-013
  Scenario: every request with an id gets exactly one response carrying that id
    When I send a "tools/call" request for "ping" with id 77
    Then exactly one response line is written
    And the response id is 77

  @EARS-FLOW-005
  Scenario: a notification (no id) is applied with no response
    When I send a "notifications/initialized" notification with no id
    Then no response line is written

  @EARS-FLOW-012
  Scenario: EOF on stdin exits cleanly
    When stdin reaches EOF
    Then the process exits with code 0

  # --- transport errors (unhappy) ---

  @EARS-FLOW-009
  Scenario: an unparseable line yields a -32700 parse error and the loop continues
    When I send the raw line "{ not json"
    Then the response is an error with code -32700
    And the response id is null
    When I send a "tools/call" request for "ping"
    Then the response result message is present

  @EARS-FLOW-009
  Scenario: a blank line is treated as a parse error
    When I send a blank line
    Then the response is an error with code -32700

  @EARS-FLOW-010
  Scenario: an unknown method yields method-not-found
    When I send a request with method "frobnicate"
    Then the response is an error with code -32601

  # --- abuse ---

  @EARS-FLOW-011
  Scenario: tools/call for a non-existent tool is rejected
    When I call "teleport" with {}
    Then the response is an error with code -32602
    And the error message names the unknown tool "teleport"
