# EARS Requirements — Item [37]: Flow-server stdio MCP transport (`--mcp` flag)

Item: [37]
Author: foundry-lifecycle-orchestrator
Date: 2026-06-14
Status: EARS_COMPLETE

---

## Requirements

### UBIQ-37-1 — Binary MUST expose `--mcp` flag

The flow-server binary SHALL accept `--mcp` as a boolean CLI flag. When absent, the flag
defaults to `false`. When present, it sets `Config.mcp = true`. An unrecognised flag
following `--mcp` SHALL be processed normally (the flag takes no value argument). Passing
`--mcp` together with any other valid flags SHALL not produce a parse error.

### EVT-37-2 — WHEN `--mcp` is supplied THEN enter stdio JSON-RPC read loop

WHEN the binary is started with `--mcp`, THEN it SHALL:
1. Skip HTTP server binding entirely.
2. Open the store from `cfg.data_dir` as normal (same startup sequence).
3. Enter a newline-delimited JSON-RPC 2.0 read loop on stdin.
4. For each line received: parse as JSON, dispatch to the MCP tool handler, write the
   JSON-RPC response as a single newline-terminated line to stdout, and flush.
5. Continue until stdin is closed (EOF).

### EVT-37-3 — WHEN stdin closes THEN exit with code 0

WHEN the binary is running in `--mcp` mode AND stdin reaches EOF (read_line returns 0
bytes), THEN the binary SHALL exit cleanly with process exit code 0. No error SHALL be
logged for a normal stdin close.

### EVT-37-4 — WHEN `--mcp` and `--port` are both supplied THEN log warning and run stdio mode

WHEN the binary is started with both `--mcp` and `--port` flags, THEN it SHALL:
1. Log a warning to stderr: `"flow-server: --mcp mode active; --port is ignored"`.
2. Ignore the `--port` value.
3. Proceed in stdio MCP mode (HTTP server NOT started).

### UNWANTED-37-5 — IF `--mcp` is NOT supplied THEN HTTP+WebSocket behaviour is unchanged

IF the binary is started WITHOUT `--mcp`, THEN ALL existing HTTP and WebSocket behaviour
SHALL remain unchanged. No regression in HTTP routes, bearer-token auth, WebSocket
broadcast, static file serving, or any existing observable behaviour is permitted.

### EVT-37-6 — WHEN a `tools/call` request is received over stdio THEN dispatch to the correct tool handler and write a JSON-RPC response to stdout

WHEN the binary is running in `--mcp` mode AND receives a valid JSON-RPC 2.0 `tools/call`
request on stdin, THEN it SHALL:
1. Parse the `params.name` field to identify the tool.
2. Dispatch to the same handler logic used by the HTTP `/mcp` endpoint (via the extracted
   `mcp::dispatch` function).
3. Write the JSON-RPC 2.0 response (with matching `id` and either `result` or `error`) as
   a single newline-terminated line to stdout.
4. Flush stdout after each response.

The five tools exposed MUST be: `list_items`, `render_roadmap`, `post_status`, `set_wait_go`,
`append_spend`. All other existing tools (`get_item`, `set_item_model`,
`validate_connection`, `mutate_connection`, `append_sysmsg`, `annotate`, `request_rewrite`,
`list_events`) MUST also be dispatched correctly (they share the same dispatch function).

### EVT-37-7 — WHEN an unparseable JSON line is received THEN write a JSON-RPC parse error response

WHEN the binary is running in `--mcp` mode AND receives a line that cannot be parsed as
valid JSON, THEN it SHALL write the following JSON-RPC parse error response to stdout and
continue the read loop (NOT exit):

```json
{"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}
```

---

## Uniqueness check

All requirement IDs are unique within this item. No duplicate EARS patterns.

- UBIQ-37-1: exactly one ubiquitous requirement for the flag
- EVT-37-2 through EVT-37-7: six event-driven requirements, each with a distinct trigger
- UNWANTED-37-5: exactly one unwanted behaviour (regression guard)

---

## Traceability to IDEATOR brief

| EARS ID | Maps to task |
|---------|-------------|
| UBIQ-37-1 | T37-2 (Config.mcp field + parser arm) |
| EVT-37-2 | T37-3 (run_stdio loop) + T37-4 (main.rs branch) |
| EVT-37-3 | T37-3 (EOF → break → Ok(())) |
| EVT-37-4 | T37-4 (--port warning + stdio branch) |
| UNWANTED-37-5 | T37-1 (mcp::dispatch refactor preserves HTTP path) |
| EVT-37-6 | T37-1 (mcp::dispatch) + T37-3 (call dispatch in loop) |
| EVT-37-7 | T37-3 (parse error → write -32700 response) |
