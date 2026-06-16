---
description: Roadmap flow — ping/greet the flow-server MCP, check its status, or control the board daemon.
---

The **flow** command has two route families. Pick by `$ARGUMENTS` (default: `status`):

## MCP routes (go THROUGH the flow-server MCP — prove the roundtrip)

- **`hello`** / **`ping`** — call the MCP verb **`ping`** (`mcp__…__flow-server__ping`; it's a deferred
  tool — if it's not in your tool list, `ToolSearch` for `flow-server__ping` first). Then print, verbatim,
  the server's `message` — **"hello from the flow MCP"** — followed by its `version`, `items` (roadmap
  item count), and `source`. This proves the MCP is connected and serving the tree.
- **`status`** — report the MCP **and** the board:
  1. Call `ping`. Show `version` / `items` / `source`. **Flag staleness:** if `items` is 0 (or `source`
     is null) while `.i2p/roadmap/` has files on disk, OR `version` is below `0.2.0`, the running MCP
     binary is **stale** — the launcher always tracks `releases/latest`, so the live server is on an
     old **cached** binary; tell the user to restart Claude Code so it re-resolves latest (clearing
     `${XDG_CACHE_HOME:-~/.claude}/flow-server/` forces a fresh fetch), then re-verify via
     `/mission-control:flow-setup`. If you have no `mcp__…__flow-server__*` tools at all, it isn't
     connected — guide them: restart after install/update, then `/mcp` approve `flow-server`.
  2. Then run the board controller below with `status`.

## Board routes (the SVG governance UI daemon, via `flowctl.sh`)

- **`start`** — start the board now (if the roadmap has items); binds `0.0.0.0`, advertises the LAN URL.
- **`stop`** — stop the daemon.
- **`url`** — print the clickable `http://<LAN-IP>:<port>/?token=…` link.
- **`build`** — one-time `cargo build` of the flow-server binary (needed once per checkout; `target/` is gitignored).

```bash
# Board routes only (start|stop|status|url|build). For hello/ping, call the MCP verb above instead.
case "${ARGUMENTS:-status}" in
  hello|ping) : ;;  # handled via the MCP ping verb — do not shell out
  *) bash "${CLAUDE_PLUGIN_ROOT}/flow-server/bin/flowctl.sh" "${ARGUMENTS:-status}" ;;
esac
```

**Security:** the board binds `0.0.0.0` (LAN-reachable) — the bearer token in `.flow/token` is the only
guard and the URL embeds it, so treat the URL as a secret on a shared network. Set `FLOW_HOST=127.0.0.1`
to bind localhost-only.
