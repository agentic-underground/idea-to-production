---
id: 37
title: "Flow-server: stdio MCP transport (`--mcp` flag)"
status: COMPLETE
priority: HIGH
added: 2026-06-14
depends_on: "—"
completed: 2026-06-15
---

# [37] Flow-server: stdio MCP transport (`--mcp` flag)

**Brief Description**
The flow-server exposes MCP tools (`list_items`, `render_roadmap`, `post_status`, `set_gate`,
`append_spend`) via `POST /mcp` over HTTP. Claude Code expects MCP servers to speak JSON-RPC
over stdin/stdout (stdio transport). This item adds a `--mcp` flag: when passed, the binary
skips the HTTP listener and speaks the MCP protocol over stdio instead, exposing the same tool
set. This makes it registerable in `.claude/settings.json` like any other stdio MCP server.

### User Stories
- AS A Claude Code agent I WANT to call `list_items` and `render_roadmap` as native MCP tools
  SO THAT "what's on the roadmap" returns live, grouped data from the running server rather than
  a shell grep of ROADMAP.md.
- AS A developer I WANT to register the flow-server as an MCP server in project settings SO THAT
  the tools appear automatically in every session without manual configuration.

### EARS Specification

**Event-driven requirements:**
- WHEN the binary is invoked with `--mcp` THE SYSTEM SHALL speak JSON-RPC 2.0 over
  stdin/stdout (stdio MCP transport) and expose the tool set: `list_items`, `render_roadmap`,
  `post_status`, `set_gate`, `append_spend`.
- WHEN a tool call arrives over stdio THE SYSTEM SHALL resolve it against the in-memory store
  (loaded from `.flow/` on startup) and return the same response shape as the HTTP endpoint.

**Unwanted behaviour requirements:**
- IF `--mcp` is passed alongside HTTP-specific flags (e.g. `--port`) THE SYSTEM SHALL log a
  warning and ignore HTTP flags — stdio and HTTP are mutually exclusive modes.
- IF stdin closes THE SYSTEM SHALL exit cleanly with code 0.

**Optional feature requirements:**
- WHERE the binary is invoked without `--mcp` THE SYSTEM SHALL behave exactly as today
  (HTTP + WebSocket server) — no regression to existing behaviour.

### Acceptance Criteria
1. `flow-server --mcp` starts, reads a valid `tools/call list_items` JSON-RPC request from
   stdin, and writes the correct JSON-RPC response to stdout.
2. `flow-server --mcp` exposes all five tools: `list_items`, `render_roadmap`, `post_status`,
   `set_gate`, `append_spend`.
3. `flow-server` (no flag) continues to serve HTTP + WebSocket as before — zero regression.
4. stdin close causes a clean exit (code 0, no panic).
5. `--mcp` with `--port` logs a warning and starts in stdio mode.

### Implementation Notes
- Use the existing `mcp::handle` dispatch logic — extract it so both the HTTP handler and the
  stdio loop call the same function.
- Stdio loop: `tokio::io::stdin` / `tokio::io::stdout`, newline-delimited JSON-RPC frames.
- No new external crate required — the existing `serde_json` + `tokio` are sufficient.
- Keep `cargo test --workspace` at 100% coverage; add unit tests for the stdio dispatch path.

### Development Plan Reference
`doc/FLOW_SERVER_MCP_STDIO_PLAN.md`
