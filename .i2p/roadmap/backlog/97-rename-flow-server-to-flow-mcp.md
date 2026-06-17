---
id: 97
title: "Rename flow-server → flow-mcp"
status: PENDING
priority: MEDIUM
added: 2026-06-17
depends_on: "#95 (operate rename)"
---

# [97] Rename flow-server → flow-mcp

**Brief Description**
Rename the roadmap MCP service from `flow-server` to `flow-mcp`. Since the web UI was removed (#39), the
service is a data-only MCP server, so `flow-mcp` is the accurate name — `flow-server` implied a hosted UI
that no longer exists. Low blast radius (the MCP server **id** in `.mcp.json`, the launcher `bin/` paths,
`bin/RELEASE`, `bin/SHA256SUMS`, the `bin/smoke-*.sh` scripts, and the README), but it **gates Stream 3**,
where the `flow` / `flow-setup` commands move out of `operate` into this standalone. Depends on #95 because
the launcher now lives under `plugins/operate/`.

### User Stories
- AS a maintainer I WANT the service named `flow-mcp` SO THAT the name reflects what it is — a data-only MCP
  server with no web UI — and Stream 3 can carve it out cleanly.
- AS a user wiring the roadmap MCP I WANT the `.mcp.json` server id to read `flow-mcp` SO THAT the registered
  server name matches the binary and the docs.

### EARS Specification
**Ubiquitous**
- The MCP server SHALL be identified as `flow-mcp` in `plugins/operate/.mcp.json`, and its launcher binary
  and smoke scripts SHALL use the `flow-mcp` name (e.g. `flow-mcp-mcp`→`flow-mcp` launcher, `smoke-mcp.sh`).
- The README and release/checksum manifests SHALL refer to the service as `flow-mcp`.

**Event-driven**
- WHEN the renamed MCP server is launched THE SYSTEM SHALL connect under the id `flow-mcp` and serve the same
  read/mutate verbs (`list_items`, `list_events`, `render_roadmap`, `ping`, …) unchanged.

**Unwanted behaviour**
- IF any `flow-server` reference (server id, `bin/` launcher path, `RELEASE`/`SHA256SUMS` entry, smoke-script
  path, README mention) survives THEN `bash scripts/verify-prereqs.sh` and the smoke scripts SHALL be red
  until it is fixed.

### Acceptance Criteria
1. Given the renamed service, When `bash scripts/verify-prereqs.sh` runs, Then it ends green — including the
   pinned-binary / SHA256SUMS guard that tracks `bin/` (the names it checks must be updated in lockstep).
2. Given `plugins/operate/.mcp.json`, When the MCP server starts, Then it registers as `flow-mcp` and
   `ping` succeeds.
3. Given the smoke scripts, When `bash plugins/operate/flow-mcp/bin/smoke-mcp.sh` (renamed path) runs, Then
   it passes against the renamed binary.

### Implementation Notes
- Depends on #95: the directory now is `plugins/operate/flow-server/`. Either keep the subdir name or
  `git mv` it to `flow-mcp/`; pick one and apply it consistently. Recommended: rename the subdir to
  `flow-mcp/` so dir, server id, and binary all agree.
- Update `plugins/operate/.mcp.json`: the server key `"flow-server"` → `"flow-mcp"`, and `command` to the
  renamed launcher path under `${CLAUDE_PLUGIN_ROOT}/flow-mcp/bin/` (still `${CLAUDE_PLUGIN_ROOT}`-relative,
  never sibling/absolute).
- Rename `bin/flow-server-mcp` → the `flow-mcp` launcher and update `bin/RELEASE`, `bin/SHA256SUMS` (recompute
  if the binary path/name is embedded), `bin/smoke-mcp.sh`, `bin/smoke-pinned.sh`, and `bin/flowctl.sh` to the
  new name; the deterministic pinned-binary CI guard must stay green.
- Update the flow-server README and any `plugins/operate/` docs that name the service.
- The MCP tool ids surfaced to clients (e.g. `mcp__…_flow-server__*`) change to the `flow-mcp` name —
  update any skill/doc that names those tool ids.
- This item renames the service only; moving the `flow`/`flow-setup` commands into a standalone is Stream 3.
- ONE atomic PR; must end green on `bash scripts/verify-prereqs.sh` and the smoke scripts.
