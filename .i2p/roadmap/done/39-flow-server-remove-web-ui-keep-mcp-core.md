---
id: 39
title: "Flow-server — remove the web UI, keep the MCP core"
status: PENDING
priority: HIGH
added: 2026-06-15
depends_on: "—"
---

# [39] Flow-server — remove the web UI, keep the MCP core

**Brief Description**
Remove the mission-control SVG governance web UI entirely, leaving the flow-server as a data-only
service that speaks the MCP protocol (and, optionally, non-UI REST reads). The web board (~8–9k LOC)
is cleanly separable from the MCP core (`mcp.rs`, `store.rs`, `domain/`). Reporting moves to a
separate on-demand tool (item [40]).

### User Stories
- AS the marketplace owner I WANT the live web board removed SO THAT the system is simpler and value-flow
  reporting is an on-demand snapshot, not a running server I must host.
- AS an agent I WANT the flow-server's MCP verbs to keep working unchanged SO THAT stage transitions and
  telemetry are unaffected by the UI removal.

### EARS Specification
**Ubiquitous**
- The flow-server SHALL expose its MCP verbs over stdio (`--mcp`) with no dependency on the web UI.

**Event-driven**
- WHEN the flow-server is built THE SYSTEM SHALL NOT compile or ship `static/`, `ws.rs`, or the
  UI-serving HTTP routes.

**Unwanted behaviour**
- IF a SessionStart hook would advertise a board URL THEN THE SYSTEM SHALL NOT (the board no longer exists).

### Acceptance Criteria
1. Given a built flow-server, When started with `--mcp`, Then all 13 MCP verbs respond and no HTTP
   listener / static server is started.
2. Given the repo, When inspected, Then `static/`, `src/ws.rs`, and `http_*_intest.rs` are gone and
   `cargo test --workspace` is green.
3. Given the three `flow-*` hooks, When a session starts, Then none attempt to advertise a board URL.

### Implementation Notes
- Delete `static/`, `src/ws.rs`, `src/http_surface_intest.rs`, `src/http_contract_intest.rs`,
  `ws_contract_intest.rs`; simplify `api.rs`/`main.rs` to drop `ServeDir` + `--static`.
- Keep `mcp.rs`, `store.rs`, `domain/`, `config.rs`, auth.
- Update `hooks/scripts/flow-advertise.sh`, `flow-roadmap-watch.sh`, `flow-statusline-widget.sh`.
- Coordinate with [42] (tree-aware) and [41] (the carry command).
