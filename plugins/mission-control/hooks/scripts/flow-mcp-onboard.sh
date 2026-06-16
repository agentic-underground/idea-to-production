#!/usr/bin/env bash
# flow-mcp-onboard.sh — SessionStart hook. Two jobs, both non-blocking and fail-silent:
#
#   1. PRE-WARM the flow-server MCP binary in the background, so when the user approves
#      the server it starts instantly (no first-call download/compile that reads as a
#      transient "connecting/failed" in /mcp). Retrieve-only — never a cargo build.
#   2. A GENTLE, ONE-TIME-PER-VERSION nudge toward finishing the one-time MCP approval.
#      The visible message is a splash; the real work is the additionalContext, which
#      tells the agent to RECONCILE against its own mcp__flow-server__* tools — stay
#      silent when connected, guide only when not. Hooks cannot see MCP approval state,
#      so the agent's tool list is the reliable signal, not this hook.
#
# Modelled on concierge/hooks/offer-statusline.sh. Always exits 0 (verify-prereqs L).
set -uo pipefail

# Drain the SessionStart payload; we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

# In CI / automation there is no user to onboard and no point pre-fetching — skip both.
[ -n "${CI:-}" ] && exit 0

# CLAUDE_PLUGIN_ROOT (set for plugin hooks) = the mission-control plugin root; else derive.
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LAUNCHER="$PLUGIN/flow-server/bin/flow-server-mcp"

# 1. Pre-warm — detached, never blocks the hook's return. Its stderr (the resolve/verify
#    reason) is APPENDED to the flow-server prewarm log so a failed pre-warm is diagnosable
#    instead of vanishing (the launcher also self-logs structured reasons there, and surfaces
#    them via `flow-server-mcp --doctor`); stdout is dropped.
if [ -x "$LAUNCHER" ]; then
  PREWARM_LOG="${XDG_CACHE_HOME:-$HOME/.claude}/flow-server/prewarm.log"
  mkdir -p "$(dirname "$PREWARM_LOG")" 2>/dev/null || true
  ( "$LAUNCHER" --ensure-binary >/dev/null 2>>"$PREWARM_LOG" & ) >/dev/null 2>&1 || true
fi

# 2a. STANDING routing rule (R4 / item [92]) — emitted EVERY session as invisible
#     additionalContext so the agent always answers roadmap reads via the MCP, not by
#     ad-hoc ls/cat of the tree. This must NOT be one-time: a fresh agent in any later
#     session needs the rule too (that routing gap is the defect [92] L2).
ROUTING="To answer \"what's on the roadmap\" or read roadmap items, call the flow-server MCP verb render_roadmap (or list_items) — the ~0-token authoritative path. It is a DEFERRED tool: if mcp__…__flow-server__render_roadmap is not already in your tool list, ToolSearch for 'flow-server__render_roadmap' first. Do NOT ls/cat/head the .i2p/roadmap/ tree to answer roadmap questions; that raw-file path is the slow fallback. If render_roadmap returns empty against a non-empty .i2p/roadmap/ tree, the pinned MCP binary is stale — call the ping verb (it reports version/items/source) and suggest /mission-control:flow-setup."

# 2b. One-time-per-version SETUP nudge (the only VISIBLE part), gated by an atomic sentinel.
VER="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null | head -n1)"
STATE_DIR="${HOME}/.claude/hook-state"
SENTINEL="${STATE_DIR}/mission-control-flow-mcp-onboarded-${VER:-x}"
SETUP_MSG=""
SETUP_CTX=""
if mkdir -p "$STATE_DIR" 2>/dev/null && mkdir "$SENTINEL" 2>/dev/null; then
  SETUP_MSG="⬢ mission-control ships a roadmap MCP (flow-server). If \"what's on the roadmap\" isn't instant yet, run /mission-control:flow-setup to finish the one-time setup."
  SETUP_CTX=" SETUP: if you do NOT have mcp__…__flow-server__* tools, the server isn't connected — guide the user ONCE: (a) restart Claude Code if they just installed/updated mission-control; (b) run /mcp and approve 'flow-server' (a plugin MCP server requires this one-time approval — no setting, CLI, or flag can pre-approve it); the binary is pre-cached so it starts instantly; /mission-control:flow-setup gives a guided, verified walkthrough. Never nag."
fi

CTX="${ROUTING}${SETUP_CTX}"
if command -v jq >/dev/null 2>&1; then
  if [ -n "$SETUP_MSG" ]; then
    jq -cn --arg m "$SETUP_MSG" --arg c "$CTX" \
      '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
  else
    jq -cn --arg c "$CTX" \
      '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
  fi
else
  # No jq: emit the standing routing rule (ASCII-safe), drop the optional systemMessage.
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Answer roadmap questions via the flow-server MCP verb render_roadmap (ToolSearch for flow-server__render_roadmap if deferred); do not ls/cat the .i2p/roadmap/ tree. If it returns empty, the pinned binary is stale — call ping and run /mission-control:flow-setup."}}\n'
fi
exit 0
