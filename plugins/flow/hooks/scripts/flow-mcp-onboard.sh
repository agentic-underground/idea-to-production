#!/usr/bin/env bash
# flow-mcp-onboard.sh — SessionStart hook. Two jobs, both non-blocking and fail-silent:
#
#   1. PRE-WARM the flow-mcp MCP binary in the background, so when the user approves
#      the server it starts instantly (no first-call download/compile that reads as a
#      transient "connecting/failed" in /mcp). Retrieve-only — never a cargo build.
#   2. A PROACTIVE, INSTRUCTIONAL SETUP OFFER toward finishing the one-time MCP approval
#      (item [108] — "if this needs user-intervention to set up, the user must be prompted
#      with instructions"). The visible message is a splash; the real work is the
#      additionalContext, which tells the agent to RECONCILE against its own mcp__flow-mcp__*
#      tools — stay silent when connected, guide with step-by-step instructions when not.
#      Hooks cannot see MCP approval state, so the agent's tool list is the reliable signal.
#      Mirrors the i2p offer scripts' opt-out discipline: a DURABLE decline marker under
#      ~/.claude/hook-state suppresses the offer forever; a per-version sentinel keeps an
#      already-onboarded user from being re-offered every session.
#
# Modelled on i2p/hooks/offer-statusline.sh + offer-welcome.sh (opt-out markers). Always
# exits 0 (verify-prereqs L).
set -uo pipefail

# Drain the SessionStart payload; we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

# In CI / automation there is no user to onboard and no point pre-fetching — skip both.
[ -n "${CI:-}" ] && exit 0

# CLAUDE_PLUGIN_ROOT (set for plugin hooks) = the flow plugin root; else derive.
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LAUNCHER="$PLUGIN/flow-mcp/bin/flow-mcp"

# 1. Pre-warm — detached, never blocks the hook's return. Its stderr (the resolve/verify
#    reason) is APPENDED to the flow-mcp prewarm log so a failed pre-warm is diagnosable
#    instead of vanishing (the launcher also self-logs structured reasons there, and surfaces
#    them via `flow-mcp --doctor`); stdout is dropped.
if [ -x "$LAUNCHER" ]; then
  PREWARM_LOG="${XDG_CACHE_HOME:-$HOME/.claude}/flow-mcp/prewarm.log"
  mkdir -p "$(dirname "$PREWARM_LOG")" 2>/dev/null || true
  ( "$LAUNCHER" --ensure-binary >/dev/null 2>>"$PREWARM_LOG" & ) >/dev/null 2>&1 || true
fi

# 2a. STANDING routing rule (R4 / item [92]) — emitted EVERY session as invisible
#     additionalContext so the agent always answers roadmap reads via the MCP, not by
#     ad-hoc ls/cat of the tree. This must NOT be one-time: a fresh agent in any later
#     session needs the rule too (that routing gap is the defect [92] L2).
ROUTING="To answer \"what's on the roadmap\" or read roadmap items, call the flow-mcp MCP verb render_roadmap (or list_items) — the ~0-token authoritative path. It is a DEFERRED tool: if mcp__…__flow-mcp__render_roadmap is not already in your tool list, ToolSearch for 'flow-mcp__render_roadmap' first. Do NOT ls/cat/head the .i2p/roadmap/ tree to answer roadmap questions; that raw-file path is the slow fallback. If render_roadmap returns empty against a non-empty .i2p/roadmap/ tree, the pinned MCP binary is stale — call the ping verb (it reports version/items/source) and suggest /flow:flow-setup."

# 2b. PROACTIVE SETUP OFFER (the VISIBLE part) — one prominent, instructional prompt to
#     finish the flow-mcp one-time setup when it is unconnected. Item [108]: the owner's
#     directive is "if this needs user-intervention to set up, the user must be prompted
#     with instructions." Two gates, both mirroring the i2p offer scripts' opt-out discipline:
#       - a DURABLE opt-out marker  ~/.claude/hook-state/flow-flow-mcp-setup-optout  — a user
#         who declined is NEVER re-prompted (the AGENT writes it, on the user's say-so, with
#         the exact command embedded in the context below);
#       - a per-version sentinel so an already-onboarded user isn't re-offered every session
#         (a version bump re-offers once, in case a new setup step landed).
#     Graceful: hooks cannot see MCP approval state, so the agent reconciles against its own
#     mcp__…__flow-mcp__* tool list — when CONNECTED it stays silent and writes nothing; the
#     visible splash and instructions only matter when the server is absent.
VER="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null | head -n1)"
STATE_DIR="${HOME}/.claude/hook-state"
OPTOUT="${STATE_DIR}/flow-flow-mcp-setup-optout"
SENTINEL="${STATE_DIR}/flow-flow-mcp-onboarded-${VER:-x}"
SETUP_MSG=""
SETUP_CTX=""
# Opt-out wins: a declined user is never re-prompted (no splash, no setup context).
if [ ! -e "$OPTOUT" ] && mkdir -p "$STATE_DIR" 2>/dev/null && mkdir "$SENTINEL" 2>/dev/null; then
  SETUP_MSG="⬢ flow ships a roadmap MCP (flow-mcp) that answers \"what's on the roadmap\" instantly at ~0 tokens. If it isn't connected yet, finish the one-time setup: run /flow:flow-setup (or restart Claude Code, then /mcp → approve 'flow-mcp')."
  SETUP_CTX=" SETUP OFFER (item [108], proactive + instructional): FIRST reconcile against your OWN tools — if you HAVE mcp__…__flow-mcp__* tools the server is already connected, so say NOTHING about setup and do not mention this offer. If you do NOT have them, the server isn't connected — surface the setup offer ONCE, with these exact steps: (a) restart Claude Code if flow was just installed/updated (a plugin's .mcp.json is read only at startup; /reload-plugins does NOT load new MCP servers); (b) run /mcp, find 'flow-mcp' (⏸ Pending approval), and approve it — this one-time approval cannot be pre-granted by any setting, CLI, or launch flag (a deliberate Claude Code security gate); the binary is pre-cached so it connects instantly; (c) /flow:flow-setup gives a guided, verified walkthrough that confirms the connection. ON DECLINE (user says \"don't ask again\" / \"stop offering this\"): run  mkdir -p '${OPTOUT}'  so this offer is never shown again — write ONLY under ~/.claude/hook-state, never into the user's repo. Never nag; raise this at most once."
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
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Answer roadmap questions via the flow-mcp MCP verb render_roadmap (ToolSearch for flow-mcp__render_roadmap if deferred); do not ls/cat the .i2p/roadmap/ tree. If it returns empty, the pinned binary is stale — call ping and run /flow:flow-setup."}}\n'
fi
exit 0
