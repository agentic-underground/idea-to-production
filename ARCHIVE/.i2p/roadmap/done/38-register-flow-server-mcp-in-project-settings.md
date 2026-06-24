---
id: 38
title: "Register flow-server MCP in project settings"
status: COMPLETE
priority: HIGH
added: 2026-06-14
depends_on: "#37"
completed: 2026-06-15
---

# [38] Register flow-server MCP in project settings

**Brief Description**
Once the flow-server speaks stdio MCP (`--mcp` flag, item [37]), register it in the project's
`.claude/settings.json` so the `list_items`, `render_roadmap`, and governance tools appear
automatically in every Claude Code session for this repo. Also document the startup convention
(the server must be running for HTTP mode; `--mcp` mode is invoked on-demand by the harness).

### User Stories
- AS A builder in this repo I WANT `list_items` and `render_roadmap` to appear as native tools
  in every session SO THAT "what's on the roadmap" uses live MCP data without me having to
  configure anything.
- AS A new contributor I WANT the MCP registration to be checked in to the repo SO THAT I get
  the tools automatically after cloning.

### EARS Specification

**Event-driven requirements:**
- WHEN Claude Code starts a session in this repo THE SYSTEM SHALL load the flow-server MCP
  entry from `.claude/settings.json` and make `list_items`, `render_roadmap`, `post_status`,
  `set_gate`, and `append_spend` available as tools.
- WHEN the flow-server binary is not found (not built yet) THE SYSTEM SHALL surface a clear
  error rather than silently failing — the MCP entry must include a descriptive `name` and the
  binary path relative to the repo root.

**Unwanted behaviour requirements:**
- IF the flow-server binary is absent the harness error MUST NOT prevent the session from
  starting — MCP server failures are non-fatal in Claude Code.

### Acceptance Criteria
1. `.claude/settings.json` (project-scoped) contains an `mcpServers` entry for `flow-server`
   pointing to the compiled binary with the `--mcp` flag.
2. In a fresh session, `list_items` appears as an available MCP tool (confirmed via `/mcp` or
   tool listing).
3. Calling `list_items` returns the live grouped roadmap (PENDING items split by WAIT/GO,
   COMPLETE items listed).
4. The binary path uses a relative-to-repo-root convention and is documented in a `doc/`
   runbook so contributors know to `cargo build` first.
5. Session startup is not blocked if the binary hasn't been built yet.

### Implementation Notes
- **Settings file:** `.claude/settings.json` at the repo root (project-scoped, checked in).
- **Entry shape:**
  ```json
  {
    "mcpServers": {
      "flow-server": {
        "command": "./plugins/mission-control/flow-server/target/release/flow-server",
        "args": ["--mcp"],
        "description": "Mission-control flow canvas — list_items, render_roadmap, post_status, set_gate, append_spend"
      }
    }
  }
  ```
- **Build step:** add a note to `plugins/mission-control/flow-server/README.md` (or create it)
  instructing contributors to run `cargo build --release` before the MCP tools become available.
- **Debug build fallback:** document `target/debug/flow-server --mcp` as the dev-mode alternative.

### Development Plan Reference
`doc/FLOW_SERVER_MCP_REGISTER_PLAN.md`
