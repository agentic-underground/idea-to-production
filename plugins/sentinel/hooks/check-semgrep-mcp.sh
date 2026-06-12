#!/usr/bin/env bash
# check-semgrep-mcp.sh — SessionStart hook. SENTINEL's `semgrep` MCP server launches the
# RESIDENT `semgrep-mcp` binary (see .mcp.json), because the ephemeral `uvx semgrep-mcp`
# transport is unreliable on many stacks (it fails the MCP initialize handshake). If that
# binary is not on PATH, the MCP server would fail with a cryptic error — so surface a
# one-time, actionable fix into the agent's context instead. SILENT when semgrep-mcp is
# present (e.g. a host that pre-installs it), so it never nags a correctly-set-up machine.
# Touches nothing outside reading PATH; never reads or writes the user's project.
set -uo pipefail

# Already installed → nothing to say.
command -v semgrep-mcp >/dev/null 2>&1 && exit 0

read -r -d '' MSG <<'EOF' || true
⚠️ SENTINEL: the `semgrep` MCP server needs the resident `semgrep-mcp` binary on PATH, and it was not found — semgrep code scanning will be unavailable until you install it. (SENTINEL's other audits — PII, secrets, dependencies — work without it.)

Fix it once, then restart your session:
  • uv (recommended):  uv tool install semgrep-mcp  &&  uv tool install semgrep
  • pipx:              pipx install semgrep-mcp  &&  pipx install semgrep

Why not `uvx semgrep-mcp`? The ephemeral transport is unreliable on many stacks (it stalls the MCP initialize handshake), so SENTINEL launches the resident binary on purpose.
EOF

# Emit as SessionStart additionalContext (jq, with a pure-bash JSON-escape fallback).
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$MSG" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  esc="$MSG"
  esc="${esc//\\/\\\\}"
  esc="${esc//\"/\\\"}"
  esc="${esc//$'\t'/\\t}"
  esc="${esc//$'\n'/\\n}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
