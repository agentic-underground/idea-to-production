#!/usr/bin/env bash
# flow-mcp-onboard.sh — SessionStart hook for the Ruby flow-mcp. Non-blocking,
# fail-silent, always exits 0 (verify-prereqs L). Two jobs:
#
#   1. A STANDING routing rule (every session, invisible additionalContext): answer
#      roadmap reads via the flow-mcp MCP verbs, not ad-hoc ls/cat of the tree.
#   2. A PROACTIVE, INSTRUCTIONAL SETUP OFFER when the server is not yet connected.
#      flow-mcp is now an interpreted Ruby server (>= 3.3.8, stdlib only) — there is
#      NO binary to pre-warm. The offer adapts to whether a compliant Ruby exists:
#        - Ruby present  -> finish the one-time /mcp approval (the server starts via
#          `ruby`, instantly).
#        - Ruby absent   -> install Ruby >= 3.3.8, OR use the markdown fallback
#          runbook (/flow:flow-by-hand) now.
#      Hooks cannot see MCP approval state, so the agent reconciles against its own
#      mcp__…__flow-mcp__* tool list. Opt-out discipline mirrors the i2p offers: a
#      durable marker under ~/.claude/hook-state suppresses it forever; a per-version
#      sentinel keeps an onboarded user from being re-offered every session.
set -uo pipefail

# Drain the SessionStart payload; we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

# In CI / automation there is no user to onboard — skip.
[ -n "${CI:-}" ] && exit 0

PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Detect a Ruby >= 3.3.8 (the launcher's resolution, in miniature).
RUBY_PRESENT=0
for c in "${FLOW_MCP_RUBY:-}" ruby ruby3.3 ruby3.4 \
         /opt/homebrew/opt/ruby/bin/ruby /usr/local/opt/ruby/bin/ruby \
         "${HOME}/.rbenv/shims/ruby" "${HOME}/.asdf/shims/ruby"; do
  [ -n "$c" ] || continue
  command -v "$c" >/dev/null 2>&1 || continue
  if "$c" -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.3.8") ? 0 : 1)' >/dev/null 2>&1; then
    RUBY_PRESENT=1
    break
  fi
done

# 1. STANDING routing rule — emitted every session (a fresh agent needs it too).
# NOTE: the canonical roadmap-read rule is now the v2 FLEET pipeline (docs/roadmap/), injected by the
# i2p plugin's SessionStart (hooks/scripts/roadmap-routing.sh). flow-mcp's render_roadmap reads the
# LEGACY .i2p/roadmap/ tree only and is being retired — do NOT re-point roadmap reads at it here.
ROUTING="To answer \"what's on the roadmap\" or read roadmap items, use the FLEET v2 pipeline at docs/roadmap/ — via the 'pipeline' plugin's deterministic surface (/pipeline:status, pipeline-cron.sh status/next) when installed, else a STRUCTURAL parse of docs/roadmap/.pipeline.md + each EPIC_NNNN.md '## Plans' table (leading-| columns order|epic|state — not prose). The .i2p/roadmap/ tree (and flow-mcp render_roadmap, which reads it) is LEGACY history; do not present it as the live roadmap."

# 2. PROACTIVE SETUP OFFER (visible splash + agent instructions), opt-out gated.
VER="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null | head -n1)"
STATE_DIR="${HOME}/.claude/hook-state"
OPTOUT="${STATE_DIR}/flow-flow-mcp-setup-optout"
SENTINEL="${STATE_DIR}/flow-flow-mcp-onboarded-${VER:-x}"
SETUP_MSG=""
SETUP_CTX=""
if [ ! -e "$OPTOUT" ] && mkdir -p "$STATE_DIR" 2>/dev/null && mkdir "$SENTINEL" 2>/dev/null; then
  if [ "$RUBY_PRESENT" = 1 ]; then
    SETUP_MSG="⬢ flow ships a roadmap MCP (flow-mcp, a Ruby server — no binary). If it isn't connected yet, finish the one-time setup: restart Claude Code, then /mcp → approve 'flow-mcp'."
    SETUP_CTX=" SETUP OFFER (proactive + instructional): FIRST reconcile against your OWN tools — if you HAVE mcp__…__flow-mcp__* tools the server is already connected, so say NOTHING about setup. If you do NOT have them, surface the offer ONCE with these exact steps: (a) restart Claude Code if flow was just installed/updated (a plugin's .mcp.json is read only at startup; /reload-plugins does NOT load new MCP servers); (b) run /mcp, find 'flow-mcp' (⏸ Pending approval), and approve it — this one-time approval cannot be pre-granted by any setting/flag (a Claude Code security gate). The server runs on the host's Ruby (>= 3.3.8), so it connects immediately. ON DECLINE (\"don't ask again\"): run  mkdir -p '${OPTOUT}'  — write ONLY under ~/.claude/hook-state, never the user's repo. Raise this at most once."
  else
    SETUP_MSG="⬢ flow ships a roadmap MCP (flow-mcp, a Ruby server). No Ruby >= 3.3.8 was found on this host. Either install Ruby >= 3.3.8, or use the markdown fallback runbook now: /flow:flow-by-hand."
    SETUP_CTX=" SETUP OFFER (no compliant Ruby): FIRST reconcile against your OWN tools — if you already HAVE mcp__…__flow-mcp__* tools, say NOTHING. Otherwise surface ONCE: flow-mcp needs Ruby >= 3.3.8 (Debian/Ubuntu: 'apt-get install ruby'; macOS: 'brew install ruby'; or rbenv/asdf), after which restart Claude Code and approve 'flow-mcp' in /mcp. UNTIL Ruby is installed, operate the roadmap via the markdown fallback runbook — load the /flow:flow-by-hand skill and follow its per-verb procedure over the .flow/ files directly (same semantics, slower, no server). ON DECLINE (\"don't ask again\"): run  mkdir -p '${OPTOUT}'  — write ONLY under ~/.claude/hook-state. Raise this at most once."
  fi
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
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Answer roadmap questions from the FLEET v2 pipeline at docs/roadmap/ — the pipeline plugin (/pipeline:status) when installed, else a structural parse of docs/roadmap/.pipeline.md + each EPIC_NNNN.md ## Plans table. The .i2p/roadmap/ tree (flow-mcp render_roadmap) is LEGACY history, not the live roadmap."}}\n'
fi
exit 0
