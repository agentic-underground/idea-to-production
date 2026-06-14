# Feature: flow-server stdio MCP transport (--mcp flag)
# Item: [37]
# Traces to: UBIQ-37-1, EVT-37-2, EVT-37-3, EVT-37-4, UNWANTED-37-5, EVT-37-6, EVT-37-7

Feature: flow-server stdio MCP transport

  Background:
    Given the flow-server binary is built
    And a temporary data directory exists

  # -----------------------------------------------------------------------
  # UBIQ-37-1: Binary MUST expose --mcp flag
  # -----------------------------------------------------------------------

  Scenario: mcp flag absent — Config.mcp defaults to false
    Given no CLI arguments are passed
    When Config::from_args is called
    Then cfg.mcp is false

  Scenario: mcp flag present — Config.mcp is true
    Given the CLI argument "--mcp" is passed
    When Config::from_args is called
    Then cfg.mcp is true

  Scenario: mcp flag combined with other valid flags — no parse error
    Given the CLI arguments "--mcp --data /tmp/d" are passed
    When Config::from_args is called
    Then cfg.mcp is true
    And cfg.data_dir is "/tmp/d"
    And no ConfigError is returned

  # -----------------------------------------------------------------------
  # EVT-37-2: WHEN --mcp is supplied THEN enter stdio JSON-RPC read loop
  # -----------------------------------------------------------------------

  Scenario: stdio mode — valid tools/call dispatched and response written to stdout
    Given the binary is started with "--mcp --data <tempdir>"
    And stdin contains: {"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_items","arguments":{}}}
    When stdin is closed after the request
    Then stdout contains a line that is valid JSON
    And the response has "jsonrpc" equal to "2.0"
    And the response has "id" equal to 1
    And the response has a "result" field that is an object

  Scenario: stdio mode — tools/list returns tool list
    Given the binary is started with "--mcp --data <tempdir>"
    And stdin contains: {"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
    When stdin is closed after the request
    Then stdout contains a line with "result.tools" being an array

  Scenario: stdio mode — render_roadmap returns rendered markdown
    Given the binary is started with "--mcp --data <tempdir>"
    And stdin contains: {"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_roadmap","arguments":{}}}
    When stdin is closed after the request
    Then the response has "result.rendered" that is a string

  # -----------------------------------------------------------------------
  # EVT-37-3: WHEN stdin closes THEN exit with code 0
  # -----------------------------------------------------------------------

  Scenario: stdin close — process exits cleanly with code 0
    Given the binary is started with "--mcp --data <tempdir>"
    When stdin is closed immediately (no requests sent)
    Then the process exits with code 0

  Scenario: stdin close after one request — process exits cleanly
    Given the binary is started with "--mcp --data <tempdir>"
    And one list_items request was sent and a response received
    When stdin is closed
    Then the process exits with code 0

  Scenario: stdin close via SIGPIPE — process exits without panic
    Given the binary is started with "--mcp --data <tempdir>"
    When the parent process drops the stdin pipe handle
    Then the process exits with code 0 (no panic, no error log)

  # -----------------------------------------------------------------------
  # EVT-37-4: WHEN --mcp and --port are both supplied THEN log warning, stdio mode
  # -----------------------------------------------------------------------

  Scenario: --mcp and --port together — warning emitted to stderr
    Given the binary is started with "--mcp --port 9999 --data <tempdir>"
    When the process starts and stdin is closed immediately
    Then stderr contains "flow-server: --mcp mode active; --port is ignored"
    And the process does NOT bind a TCP listener on port 9999
    And the process exits with code 0

  Scenario: --mcp + --port — stdio requests still dispatched correctly
    Given the binary is started with "--mcp --port 9999 --data <tempdir>"
    And stdin contains a valid list_items request
    When stdin is closed after the request
    Then the response has a "result" field
    And the process exits with code 0

  Scenario: --mcp only (no --port) — no warning emitted
    Given the binary is started with "--mcp --data <tempdir>"
    When the process starts and stdin is closed immediately
    Then the process exits with code 0

  # -----------------------------------------------------------------------
  # UNWANTED-37-5: HTTP+WebSocket behaviour unchanged without --mcp
  # -----------------------------------------------------------------------

  Scenario: HTTP mode unchanged — existing REST routes still respond
    Given the binary is started WITHOUT --mcp
    And the binary is bound on an available port
    When a GET /items request is sent with the correct bearer token
    Then the response status is 200
    And the response body is valid JSON

  Scenario: HTTP mode unchanged — MCP HTTP endpoint still works
    Given the binary is started WITHOUT --mcp
    And the binary is bound on an available port
    When a POST /mcp request is sent with method "tools/list"
    Then the response status is 200
    And the response contains a "tools" array

  Scenario: HTTP mode unchanged — unknown flag still errors (not silently ignored)
    Given the CLI argument "--unknown-flag" is passed (without --mcp)
    When Config::from_args is called
    Then a ConfigError::UnknownFlag is returned

  # -----------------------------------------------------------------------
  # EVT-37-6: WHEN tools/call received over stdio THEN dispatch correctly
  # -----------------------------------------------------------------------

  Scenario: dispatch — list_items returns grouped shape
    Given mcp::dispatch is called directly with a list_items tools/call request
    When the call completes
    Then the returned Value has "result.pending" with "wait" and "go" arrays
    And "result.in_progress" is an array
    And "result.done" is an array

  Scenario: dispatch — post_status updates item status
    Given an item exists in the store with status "do"
    And mcp::dispatch is called with post_status for that item to "doing"
    When the call completes
    Then the returned Value has "result.ok" equal to true

  Scenario: dispatch — set_gate (set_wait_go) updates gate
    Given an item exists in the store
    And mcp::dispatch is called with set_wait_go for that item to gate "go"
    When the call completes
    Then the returned Value has "result.ok" equal to true

  Scenario: dispatch — append_spend records spend
    Given an item exists in the store
    And mcp::dispatch is called with append_spend for that item with delta 100
    When the call completes
    Then the returned Value has "result.total" equal to 100

  Scenario: dispatch — unknown tool name returns -32602
    Given mcp::dispatch is called with a tools/call request for tool name "no_such_tool"
    When the call completes
    Then the returned Value has "error.code" equal to -32602

  Scenario: dispatch — unknown method returns -32601
    Given mcp::dispatch is called with method "unknown/method"
    When the call completes
    Then the returned Value has "error.code" equal to -32601

  # -----------------------------------------------------------------------
  # EVT-37-7: WHEN unparseable JSON line received THEN write parse error response
  # -----------------------------------------------------------------------

  Scenario: malformed JSON — parse error response written, loop continues
    Given the binary is started with "--mcp --data <tempdir>"
    And stdin contains two lines: "not-json\n" then a valid list_items request
    When both lines are processed and stdin is closed
    Then the first stdout line has "error.code" equal to -32700
    And the second stdout line has a valid "result" field
    And the process exits with code 0

  Scenario: empty line — treated as parse error, loop continues
    Given the binary is started with "--mcp --data <tempdir>"
    And stdin contains an empty line followed by a valid request
    When processed
    Then the first response has "error.code" -32700
    And the second response has a valid "result"

  Scenario: totally garbage input — process does not crash
    Given the binary is started with "--mcp --data <tempdir>"
    And stdin contains "}}}}garbage\n"
    When stdin is closed
    Then the process exits with code 0
    And exactly one parse error response was written
