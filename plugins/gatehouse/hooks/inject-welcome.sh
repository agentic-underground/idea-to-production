#!/usr/bin/env bash
# inject-welcome.sh — GATEHOUSE SessionStart hook. If the project being opened ships a
# welcome experience at `<project>/.claude/welcome.md`, emit it (wrapped in the runtime
# contract) as SessionStart additionalContext so the agent can greet the user and offer
# its decision tree. If there is no welcome.md, this is a silent no-op — which is what
# makes the hook safe to fire in EVERY repo the marketplace is installed in.
#
# The engine ships in the marketplace; the CONTENT is repo-local (mirrors how CLAUDE.md
# is repo-local while the harness is universal). Authoring a welcome.md is what
# /gatehouse:define-welcome does. This script reads only the plugin's preamble and the
# project's own welcome.md; it never writes anything.
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PREAMBLE_FILE="${PLUGIN_ROOT}/hooks/welcome-preamble.md"

# --- read the SessionStart stdin JSON (cwd); jq with a bash fallback ----------------
payload=""
[ -t 0 ] || payload="$(cat 2>/dev/null || true)"

json_field() {  # $1 = field name → first  "field":"value"  match, or empty
  printf '%s' "$payload" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//;s/\"\$//"
}

project_dir=""
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
  project_dir="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
fi
[ -n "$project_dir" ] || project_dir="$(json_field cwd)"
# Fallbacks: the env var Claude Code sets, then the shell's working dir.
[ -n "$project_dir" ] || project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

WELCOME_FILE="${project_dir}/.claude/welcome.md"
[ -f "$WELCOME_FILE" ] || exit 0    # this repo defines no welcome experience → no-op.

# --- assemble: runtime contract (preamble) + the project's welcome content ----------
preamble=""
[ -f "$PREAMBLE_FILE" ] && preamble="$(cat "$PREAMBLE_FILE")"
welcome="$(cat "$WELCOME_FILE")"
content="${preamble}"$'\n\n---\n\n'"${welcome}"

# --- emit as SessionStart additionalContext -----------------------------------------
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$content" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  # pure-bash JSON-escape fallback (markdown prose: handles \  "  tab  newline)
  esc="$content"
  esc="${esc//\\/\\\\}"
  esc="${esc//\"/\\\"}"
  esc="${esc//$'\t'/\\t}"
  esc="${esc//$'\n'/\\n}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
