#!/usr/bin/env bash
# PostToolUse(Edit|Write) hook: when a ROADMAP.md is edited, re-drive the flow board
# lifecycle — start it when the roadmap gains its first item, stop it when emptied.
# Fast-exits unless the edited file is a ROADMAP.md. Always exit 0.
set +e
hook_json=""
[ -p /dev/stdin ] && hook_json="$(cat 2>/dev/null)"

# Extract the edited file path (tool_input.file_path); fast-exit if it is not a ROADMAP.md.
file="$(printf '%s' "$hook_json" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$file" ] || file="$(printf '%s' "$hook_json" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')"
case "$file" in
  *ROADMAP.md) : ;;
  *) exit 0 ;;
esac

cwd="$(printf '%s' "$hook_json" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
export CLAUDE_PROJECT_DIR="$cwd"

FLOWCTL="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/flow-server/bin/flowctl.sh"
[ -f "$FLOWCTL" ] && bash "$FLOWCTL" ensure >/dev/null 2>&1
exit 0
