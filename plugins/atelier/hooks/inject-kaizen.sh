#!/usr/bin/env bash
# inject-kaizen.sh — SessionStart hook. Emits the marketplace KAIZEN canon (the always-aware
# lean operating awareness: muda·mura·muri, the seven wastes, and continuous improvement) into
# the agent's context EXACTLY ONCE per session-source event, even though every installed plugin's
# SessionStart hook fires together. Cross-plugin dedup is an atomic per-(session,source) sentinel;
# the canon re-injects on startup/resume/clear/compact so it is never omitted.
#
# CANONICAL COPY — byte-identical across all nine plugins (CI: scripts/verify-prereqs.sh
# Check O) and reads the byte-identical per-plugin KAIZEN.md (Check N). Edits start at the
# repo-root KAIZEN.md / this file and are mirrored outward. The script touches only the
# temp dir; it never reads or writes the user's project. It uses an independent sentinel
# namespace (claude-kaizen) so a re-run or other hook never collides.
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
KAIZEN_FILE="${PLUGIN_ROOT}/KAIZEN.md"
[ -f "$KAIZEN_FILE" ] || exit 0

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
cache_dir="${TMPDIR:-/tmp}/claude-kaizen"
mkdir -p "$cache_dir" 2>/dev/null || cache_dir="${TMPDIR:-/tmp}"
sentinel="${cache_dir}/kaizen-${safe_key}.lock"
mkdir "$sentinel" 2>/dev/null || exit 0   # lost the race → another plugin emits; no-op.

# --- emit the KAIZEN canon as SessionStart additionalContext ------------------------
kaizen_content="$(cat "$KAIZEN_FILE")"
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$kaizen_content" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  # pure-bash JSON-escape fallback (KAIZEN.md is plain prose: handles \  "  tab  newline)
  esc="$kaizen_content"
  esc="${esc//\\/\\\\}"
  esc="${esc//\"/\\\"}"
  esc="${esc//$'\t'/\\t}"
  esc="${esc//$'\n'/\\n}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
