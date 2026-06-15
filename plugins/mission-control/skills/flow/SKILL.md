---
name: flow
description: >
  Run the roadmap flow board — the live SVG governance UI (plugins/mission-control/flow-server). A managed
  daemon, driven by the mission-control SessionStart + ROADMAP-edit hooks, auto-starts the server bound to
  the network whenever the project roadmap has ≥1 item and stops it when the roadmap is empty; the clickable
  URL is advertised in the statusline and on session start. Trigger with /flow [start|stop|status|url|build]
  (or "is the flow board running?", "what's the board URL?", "start the roadmap board"). Reachable on the LAN,
  guarded by a bearer token.
---

# flow — the roadmap flow board daemon

The flow board ([`../../flow-server/`](../../flow-server/README.md)) renders the live roadmap as an
interactive SVG card-graph. This skill is the **manual front door**; day-to-day the board runs itself.

## Lifecycle (automatic)

`flow-server/bin/flowctl.sh` is the managed-daemon controller. Two mission-control hooks call its idempotent
`ensure`:

- **SessionStart** (`hooks/scripts/flow-advertise.sh`) — starts the board if the roadmap has items, then
  advertises the URL as a `systemMessage`.
- **PostToolUse(Edit|Write)** (`hooks/scripts/flow-roadmap-watch.sh`) — on a `ROADMAP.md` edit, re-drives
  `ensure`: **start** when the roadmap gains its first item, **stop** when it is emptied. (The watcher
  matches the legacy single-file `ROADMAP.md` only; for the `.i2p/roadmap/` tree the SessionStart
  `ensure` keeps the board current — extending the watcher to tree edits is tracked by item [39].)

State lives in the project's gitignored `.flow/` dir (`pid`, `port`, `token`, `flow-server.log`). The port is
a stable per-project value (so the URL is a durable bookmark). The clickable link also renders in the
statusline via a dropped widget (`~/.claude/state/statusline-widgets.d/flow.sh`), so no edit to the canonical
statusline renderer is needed.

## Manual control — `/flow [start|stop|status|url|build]`

Routes to `flowctl.sh`. `build` runs the one-time `cargo build` (the binary is not shipped — `target/` is
gitignored; the hooks otherwise kick a detached background build on first run).

## Security

`--host 0.0.0.0` makes the board reachable by anyone on the LAN. The **bearer token** (`.flow/token`,
gitignored) is the only guard and the advertised URL embeds it — treat the URL as a secret on a shared
network. `FLOW_HOST=127.0.0.1` binds localhost-only without code changes.

## Roadmap resolution

`flowctl` serves the project roadmap, resolved in order: `$FLOW_ROADMAP` (env override — **pinned** to
`.flow/roadmap` when set, so a project with a non-standard roadmap location keeps auto-running across
hook-driven sessions) → `.flow/roadmap` (a previously-pinned path) → the **`.i2p/roadmap/` tree** (the
authoritative file-per-item source, folder = status; roadmap [42]) → legacy `ROADMAP.md` → `doc/ROADMAP.md`
→ `docs/ROADMAP.md`. Item count is the number of `.md` files across the tree's status folders (or `## [N]`
headings for a legacy single file). The `.i2p/roadmap/` tree is auto-detected — no `FLOW_ROADMAP` pin needed.
