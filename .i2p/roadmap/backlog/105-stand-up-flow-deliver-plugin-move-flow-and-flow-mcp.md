---
id: 105
title: "Stand up the flow (DELIVER) plugin; move flow + flow-mcp out of operate"
status: PENDING
priority: HIGH
added: 2026-06-17
depends_on: "#95 (operate rename), #97 (flow-mcp rename)"
---

# [105] Stand up the flow (DELIVER) plugin; move flow + flow-mcp out of operate

**Brief Description**
The owner's decision (epic [93]) is to **expose a `/flow` command surface while keeping foundry as the
internal BUILD engine** — not a whole-plugin foundry rename (agent prefixes stay `foundry:*`). Today the
`flow` and `flow-setup` commands live in `mission-control` (→ being renamed `operate` in [95]) and the
`flow-server` MCP binary (→ `flow-mcp` in [97]) is its subdir. This item stands up a **new DELIVER-stage
plugin** at `plugins/flow/` and **relocates** those surfaces into it: the `flow` + `flow-setup` commands
and the `flow-mcp` binary become the new plugin's, with a fresh `marketplace.json` entry and a green
`verify-prereqs.sh` Check H. The working plugin name is `flow` (alternative `deliver`) — **confirm the name
with the owner at scaffold time** before committing the directory.

This is a **relocation/rename of already-shipped work**, not new behaviour: the web-UI removal ([39]) and
the carry/report repurpose of the `flow` command ([41]) are **already shipped**. This stream moves and
renames that work; it does not redo it.

### User Stories
- AS the owner I WANT flow to be its own DELIVER-stage plugin SO THAT the value-flow spine has a clear home
  separate from the operate (ex-mission-control) plugin.
- AS the owner I WANT the `flow-mcp` binary to ship inside the flow plugin SO THAT the `/flow` command and
  its deterministic MCP backend live together.

### EARS Specification
**Ubiquitous**
- The flow plugin SHALL be a self-contained, standalone-installable plugin whose directory name equals its
  `plugin.json` `name` equals its `marketplace.json` entry (Check H).
- The flow plugin SHALL own the DELIVER lifecycle phase as its phase-of-record.

**Event-driven**
- WHEN the flow plugin is scaffolded THE SYSTEM SHALL move the `flow` and `flow-setup` commands and the
  `flow-mcp` binary out of `operate` (ex-mission-control) and into `plugins/flow/`, leaving no orphaned copy
  behind in operate.
- WHEN the relocation lands THE SYSTEM SHALL add a `marketplace.json` entry for the flow plugin and
  re-sync the canonical-copy assets (`KAIZEN.md`, `hooks/inject-kaizen.sh`) into it byte-for-byte.

**Unwanted behaviour**
- IF the plugin name is not yet confirmed with the owner THEN THE SYSTEM SHALL NOT commit the directory,
  and SHALL surface the working name `flow` (alt `deliver`) for a decision first.
- IF any moved surface still resolves a path against `operate`, `~/.claude`, or a sibling plugin THEN THE
  SYSTEM SHALL treat it as a defect — live surfaces resolve through `${CLAUDE_PLUGIN_ROOT}` only.

### Acceptance Criteria
1. Given the scaffolded plugin, When `scripts/verify-prereqs.sh` runs, Then Check H is green
   (dir name = plugin.json name = marketplace.json entry) and the canonical-copy checks (N/O) pass.
2. Given the relocation, When operate (ex-mission-control) is inspected, Then it no longer ships the `flow`
   / `flow-setup` commands or the `flow-mcp` binary, and the flow plugin ships all three.
3. Given the new plugin, When installed standalone, Then `/flow` and `/flow setup` resolve and run against
   the bundled `flow-mcp` binary with no dependency on operate.
4. The owner has confirmed the final plugin name before the directory is committed.

### Implementation Notes
- Depends on [95] (operate rename) and [97] (flow-mcp rename) landing first, so the move starts from the
  renamed source paths (`plugins/operate/…`, `flow-mcp`).
- One atomic PR: directory creation + command/binary move + `marketplace.json` edit + canonical re-sync +
  removal from operate. Run `verify-prereqs.sh` green before merge.
- Preserve the already-shipped [41] carry/report behaviour verbatim during the move — relocate the
  `flow` skill + command, do not re-author them.
- Confirm `flow` vs `deliver` as the directory/`name` with the owner at scaffold.
