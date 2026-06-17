#!/usr/bin/env bash
# offer-statusline.sh — SessionStart hook. ONE unobtrusive, one-time-per-machine nudge
# offering the idea-to-production status line. A splash, nothing more. Never blocks.
#
# Fires at most once (atomic sentinel), and never if the status line is already installed.
# On accept the user runs /i2p:statusline (which prints the merry toast). This hook
# only ASKS — it never writes settings.json (respects user agency).
set -uo pipefail

# Drain stdin (SessionStart payload); we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

SETTINGS="${HOME}/.claude/settings.json"
STATE_DIR="${HOME}/.claude/hook-state"
SENTINEL="${STATE_DIR}/i2p-statusline-offered"

# Already installed? (settings.json statusLine points at our renderer) → never offer.
if [ -f "$SETTINGS" ] && grep -q 'statusline-command.sh' "$SETTINGS" 2>/dev/null; then
  exit 0
fi

# One-time gate: mkdir succeeds for exactly one session, ever, on this machine.
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
mkdir "$SENTINEL" 2>/dev/null || exit 0   # lost the race / already offered → silent no-op.

MSG="👋 idea-to-production includes an optional rich status line (context & rate-limit gauges, the product-lifecycle phase, a reviewer-catch tally). Want it? Run /i2p:statusline"
CTX="i2p offers an optional status line. If the user shows interest, tell them to run /i2p:statusline (and /i2p:statusline off to remove it). Mention this at most once; do not nag."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg m "$MSG" --arg c "$CTX" \
    '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  printf '{"systemMessage":"👋 idea-to-production includes an optional rich status line. Run /i2p:statusline to enable it.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"i2p offers an optional status line; suggest /i2p:statusline once if the user is interested."}}\n'
fi
exit 0
