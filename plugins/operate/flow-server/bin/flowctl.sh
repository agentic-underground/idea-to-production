#!/usr/bin/env bash
# flowctl — NEUTRALISED in roadmap #39 (the web governance board was removed).
#
# The flow-server no longer serves an HTTP/WebSocket board: it is an MCP stdio core only,
# launched by the harness via the plugin's .mcp.json (bin/flow-server-mcp --mcp). There is
# therefore no daemon to start/stop and no board URL to advertise. The flow-server binary no
# longer accepts --host/--port/--static, so the old start path would crash it.
#
# This script is kept as a graceful, harmless stub so any remaining caller (e.g. the /flow
# skill) degrades cleanly instead of launching a dead daemon. Every subcommand is a no-op that
# prints an explanatory line and exits 0. The roadmap is read through the flow-server MCP verbs
# (render_roadmap / list_items), not through a board.
set -uo pipefail

msg='flow board removed (roadmap #39): the flow-server is an MCP stdio core only — read the roadmap via the flow-server MCP verbs (render_roadmap / list_items), e.g. /operate:flow or /operate:flow-setup.'

case "${1:-status}" in
  ensure|start|stop|build|install-widget) : ;;   # no daemon to manage
  status) echo "no board — MCP stdio only (roadmap #39)" ;;
  url)    : ;;                                     # no URL to advertise (print nothing)
  port)   : ;;                                     # no port bound
  *) printf '%s\n' "$msg" >&2 ;;
esac
exit 0
