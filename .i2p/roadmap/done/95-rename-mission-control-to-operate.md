---
id: 95
title: "Rename mission-control → operate"
status: COMPLETE
priority: HIGH
added: 2026-06-17
completed: 2026-06-17
depends_on: "—"
---

# [95] Rename mission-control → operate

**Brief Description**
Rename the `mission-control` plugin to `operate` so the plugin name names the OPERATE phase it serves
directly. Blast radius is roughly 87 files: the plugin directory carries the `flow-server/` subdir and a
`.mcp.json` whose server command points into `flow-server/bin/`, plus every `/mission-control:*` command
prefix across commands, skills, and docs. This item renames the plugin only — the `flow` and `flow-setup`
commands LEAVE `operate` for the `flow-mcp` standalone in Stream 3 (#97 renames the server; later stream
work moves the commands), so they stay in place here.

### User Stories
- AS a marketplace user I WANT the operations plugin called `operate` SO THAT its name matches the OPERATE
  phase of DISCOVER ▸ … ▸ OPERATE and I can find it by what it does.
- AS a user invoking operate tooling I WANT `/operate:operate-gate`, `/operate:incident`, `/operate:flow`, etc.
  SO THAT the command namespace is consistent with the phase name.

### EARS Specification
**Ubiquitous**
- The plugin SHALL be named `operate` consistently across its directory name, `plugin.json` `name`, and its
  `.claude-plugin/marketplace.json` entry (Check H).
- Every command, skill, and doc reference SHALL use the `/operate:` prefix and the `plugins/operate/` path.

**Event-driven**
- WHEN the plugin's `.mcp.json` is loaded THE SYSTEM SHALL resolve the server launcher under the renamed
  `plugins/operate/flow-server/bin/` path (still via `${CLAUDE_PLUGIN_ROOT}`, never a sibling/absolute path).

**Unwanted behaviour**
- IF any `mission-control` reference (dir path, `/mission-control:` prefix, manifest entry, `.mcp.json` path,
  doc link) survives THEN `bash scripts/verify-prereqs.sh` SHALL be red until it is fixed.

### Acceptance Criteria
1. Given the renamed plugin, When `bash scripts/verify-prereqs.sh` runs, Then it ends green — Check H
   (dir == name == entry) and Checks N/O (KAIZEN.md / inject-kaizen.sh byte-identical).
2. Given the `.mcp.json`, When the MCP server starts, Then its `command` resolves to
   `${CLAUDE_PLUGIN_ROOT}/flow-server/bin/flow-server-mcp` under the new `plugins/operate/` root and connects.
3. Given a repo-wide search, When grepping for `mission-control` and `/mission-control:`, Then no stale
   references remain in shipped plugin files, manifests, or docs.

### Implementation Notes
- `git mv plugins/mission-control plugins/operate` (the `flow-server/` subdir, `bin/`, skills, agents, hooks
  move with it); set `name` to `operate` in `plugins/operate/.claude-plugin/plugin.json` and update the
  matching `name` + `source: ./plugins/operate` entry in `.claude-plugin/marketplace.json` — Check H.
- `.mcp.json` `command` uses `${CLAUDE_PLUGIN_ROOT}/flow-server/bin/flow-server-mcp` — relative to the plugin
  root, so the path is unaffected by the dir rename; the MCP server **id** stays `flow-server` here (its rename
  is #97). Re-verify it loads under the new root.
- Re-sync the byte-mirrored `plugins/operate/KAIZEN.md` and `plugins/operate/hooks/inject-kaizen.sh` so md5sums
  match (Checks N/O).
- Sweep every `/mission-control:*` prefix and `plugins/mission-control/` path across commands, skills, hooks,
  and docs (README.md, VALUE_FLOW.md, glossary.md, docs/SLASH_COMMANDS.md, knowledge/) → `/operate:` and
  `plugins/operate/`. `foundry` companions do NOT reference mission-control, so no companion edit is needed.
- Leave `flow` and `flow-setup` commands in `operate` (Stream 3 moves them); do not touch them here beyond the
  prefix rename.
- ONE atomic PR; must end green on `bash scripts/verify-prereqs.sh`.
