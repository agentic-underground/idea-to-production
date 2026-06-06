#!/usr/bin/env bash
# inject-soul.sh — SessionStart hook. Emits the marketplace SOUL canon into the agent's
# context EXACTLY ONCE per session-source event, even though every installed plugin's
# SessionStart hook fires together. Cross-plugin dedup is an atomic per-(session,source)
# sentinel; the canon re-injects on startup/resume/clear/compact so it is never omitted.
#
# CANONICAL COPY — byte-identical across all eight plugins (CI: scripts/verify-prereqs.sh
# Check F) and reads the byte-identical per-plugin SOUL.md (Check E). Edits start at the
# repo-root SOUL.md / this file and are mirrored outward. The script touches only the
# temp dir; it never reads or writes the user's project.
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SOUL_FILE="${PLUGIN_ROOT}/SOUL.md"
[ -f "$SOUL_FILE" ] || exit 0

# --- read the SessionStart stdin JSON (session_id + source); jq with a bash fallback ---
payload=""
[ -t 0 ] || payload="$(cat 2>/dev/null || true)"

json_field() {  # $1 = field name → first  "field":"value"  match, or empty
  printf '%s' "$payload" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//;s/\"\$//"
}

session_id=""; source_evt=""
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
  session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)"
  source_evt="$(printf '%s' "$payload" | jq -r '.source // empty' 2>/dev/null)"
fi
[ -n "$session_id" ] || session_id="$(json_field session_id)"
[ -n "$source_evt" ] || source_evt="$(json_field source)"
# Fallbacks: a stable per-launch key still dedups the 8 hooks rather than injecting 8x.
[ -n "$session_id" ] || session_id="noid-${PPID:-$$}"
[ -n "$source_evt" ] || source_evt="startup"
safe_key="$(printf '%s-%s' "$session_id" "$source_evt" | tr -c 'A-Za-z0-9._-' '_')"

# --- atomic cross-plugin dedup: mkdir succeeds for exactly ONE caller per event ----
cache_dir="${TMPDIR:-/tmp}/claude-soul"
mkdir -p "$cache_dir" 2>/dev/null || cache_dir="${TMPDIR:-/tmp}"
sentinel="${cache_dir}/soul-${safe_key}.lock"
mkdir "$sentinel" 2>/dev/null || exit 0   # lost the race → another plugin emits; no-op.

# --- emit the SOUL canon as SessionStart additionalContext --------------------------
soul_content="$(cat "$SOUL_FILE")"
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$soul_content" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  # pure-bash JSON-escape fallback (SOUL.md is plain prose: handles \  "  tab  newline)
  esc="$soul_content"
  esc="${esc//\\/\\\\}"
  esc="${esc//\"/\\\"}"
  esc="${esc//$'\t'/\\t}"
  esc="${esc//$'\n'/\\n}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
