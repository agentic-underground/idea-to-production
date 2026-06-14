#!/usr/bin/env bash
# SessionStart hook: ensure the flow board is running when the roadmap has items,
# and advertise its clickable URL to the user. Detect-and-drive only; never blocks
# (a missing binary triggers a detached background build via flowctl). Always exit 0.
set +e
input="$(cat 2>/dev/null)"
cwd="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
export CLAUDE_PROJECT_DIR="$cwd"

FLOWCTL="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/flow-server/bin/flowctl.sh"
[ -x "$FLOWCTL" ] || [ -f "$FLOWCTL" ] || exit 0

bash "$FLOWCTL" ensure >/dev/null 2>&1

url="$(bash "$FLOWCTL" url 2>/dev/null)"
emit() { printf '%s' "$1"; exit 0; }

if [ -n "$url" ]; then
  emit "{\"systemMessage\":\"⬢ flow board: ${url}\",\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"The roadmap flow board is live and network-reachable at ${url} (also shown as a clickable link in the statusline). It auto-starts whenever the roadmap has items and stops when it is empty.\"}}"
elif [ -f "$cwd/.flow/build.lock" ]; then
  emit "{\"systemMessage\":\"⬢ flow board: building (first run) — it will appear in the statusline shortly.\"}"
fi
exit 0
