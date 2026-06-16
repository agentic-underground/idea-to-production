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

# 1. Pre-warm — detached, output discarded, never blocks the hook's return.
if [ -x "$LAUNCHER" ]; then
  ( "$LAUNCHER" --ensure-binary >/dev/null 2>&1 & ) >/dev/null 2>&1 || true
fi

# 2. One-time-per-version gentle nudge.
VER="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null | head -n1)"
STATE_DIR="${HOME}/.claude/hook-state"
SENTINEL="${STATE_DIR}/mission-control-flow-mcp-onboarded-${VER:-x}"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
mkdir "$SENTINEL" 2>/dev/null || exit 0   # already nudged for this version → silent no-op.

MSG="⬢ mission-control ships a roadmap MCP (flow-server). If \"what's on the roadmap\" isn't instant yet, run /mission-control:flow-setup to finish the one-time setup."
CTX="mission-control ships the flow-server MCP server (verbs: render_roadmap — answers \"what's on the roadmap\" by local compute at ~0 tokens — plus list_items, post_status, set_wait_go, …). RECONCILE against YOUR OWN available tools: if you have mcp__flow-server__* tools, the server is already connected — just use them and say NOTHING about setup. If you do NOT have those tools, it is not connected yet; the next time the user does anything roadmap-related (or asks how to enable it), guide them ONCE and briefly: (a) if they just installed or updated mission-control, Claude Code must be restarted to read the new MCP config; (b) run /mcp and approve 'flow-server' — a plugin MCP server requires this one-time interactive approval by design (no setting, CLI, or flag can pre-approve it); the binary is pre-cached so it starts instantly. They can also run /mission-control:flow-setup for a guided, verified walkthrough. Never nag; mention at most once per session."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg m "$MSG" --arg c "$CTX" \
    '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  printf '{"systemMessage":"⬢ mission-control ships a roadmap MCP (flow-server). Run /mission-control:flow-setup to finish the one-time setup.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"mission-control ships the flow-server MCP. If you lack mcp__flow-server__* tools, guide the user once: restart if just installed/updated, then /mcp approve flow-server (a one-time plugin-MCP approval that cannot be auto-granted). Offer /mission-control:flow-setup. If you already have the tools, say nothing."}}\n'
fi
exit 0
