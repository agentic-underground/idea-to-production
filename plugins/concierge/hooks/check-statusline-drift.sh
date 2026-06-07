#!/usr/bin/env bash
# check-statusline-drift.sh — CONCIERGE SessionStart hook. Detects when the INSTALLED
# status line at ~/.claude/statusline-command.sh has drifted from the renderer this
# plugin ships (statusline/i2p-statusline.sh) — e.g. a renderer edit that never
# propagated to the installed copy. On drift it emits ONE once-per-session systemMessage
# offering /concierge:statusline to refresh. Identical (or not installed) → silent.
#
# Never blocks, always exits 0, never writes the user's repo or settings.json. The atomic
# once-per-session sentinel (mirrors offer-statusline.sh) means it never nags: at most one
# offer per session, and never re-offers for the same shipped+installed stamp pair.
set -uo pipefail

# Drain stdin (SessionStart payload); we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SHIPPED="${PLUGIN_ROOT}/statusline/i2p-statusline.sh"
INSTALLED="${HOME}/.claude/statusline-command.sh"
STATE_DIR="${HOME}/.claude/hook-state"

# Only meaningful when the status line is actually installed.
[ -r "$INSTALLED" ] || exit 0
[ -r "$SHIPPED" ]   || exit 0

# --- pull the version stamp from each copy (empty if unstamped) ---
stamp_of() { grep -m1 'i2p-statusline-version:' "$1" 2>/dev/null | grep -o '[0-9][0-9]*' | head -1; }
ship_stamp="$(stamp_of "$SHIPPED")"
inst_stamp="$(stamp_of "$INSTALLED")"

# --- md5 of each copy (so a same-stamp-but-different-body edit is still caught) ---
md5_of() { { md5sum "$1" 2>/dev/null || sha1sum "$1" 2>/dev/null; } | awk '{print $1}'; }
ship_md5="$(md5_of "$SHIPPED")"
inst_md5="$(md5_of "$INSTALLED")"

# Drift = bodies differ (md5). The stamp is the human-readable explanation of the drift.
[ -n "$ship_md5" ] && [ -n "$inst_md5" ] || exit 0
[ "$ship_md5" = "$inst_md5" ] && exit 0   # in sync → silent.

# --- once-per-session, never-nag gate ---------------------------------------------------
# Sentinel key includes both md5s, so a NEW drift (after a future renderer edit) can offer
# again, but the SAME unaddressed drift never re-fires within a session.
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
sig="$(printf '%s' "${ship_md5}-${inst_md5}" | { md5sum 2>/dev/null || sha1sum 2>/dev/null; } | awk '{print $1}')"
SENTINEL="${STATE_DIR}/concierge-statusline-drift-${sig}"
mkdir "$SENTINEL" 2>/dev/null || exit 0   # already offered this exact drift → silent no-op.

vstr=""
[ -n "$inst_stamp" ] && [ -n "$ship_stamp" ] && vstr=" (installed v${inst_stamp} → shipped v${ship_stamp})"
[ -z "$inst_stamp" ] && [ -n "$ship_stamp" ] && vstr=" (installed unstamped → shipped v${ship_stamp})"

MSG="↻ Your idea-to-production status line is out of date${vstr} — the installed copy has drifted from the version this plugin ships. Run /concierge:statusline to refresh it."
CTX="The installed status line (~/.claude/statusline-command.sh) has DRIFTED from the renderer the concierge plugin ships (statusline/i2p-statusline.sh): their md5 differs${vstr}. If the user is interested, tell them to run /concierge:statusline to re-copy the current renderer. Mention this at most once; do not nag; never edit settings.json yourself."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg m "$MSG" --arg c "$CTX" \
    '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  jsonesc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"; printf '%s' "$s"; }
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(jsonesc "$MSG")" "$(jsonesc "$CTX")"
fi
exit 0
