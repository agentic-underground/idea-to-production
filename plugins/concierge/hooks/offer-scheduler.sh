#!/usr/bin/env bash
# offer-scheduler.sh — SessionStart hook. ONE unobtrusive, one-time-per-machine nudge introducing the
# token-aware job scheduler. A splash, nothing more. Never blocks, never nags.
#
# Mirrors offer-statusline.sh: atomic one-time sentinel under ~/.claude/hook-state. The scheduler
# protects a solo builder's usage meter from wide fan-outs that can cause a paid lockout — worth
# surfacing once, never again.
set -uo pipefail

# Drain stdin (SessionStart payload); not needed.
[ -t 0 ] || cat >/dev/null 2>&1 || true

STATE_DIR="${HOME}/.claude/hook-state"
SENTINEL="${STATE_DIR}/concierge-scheduler-offered"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
mkdir "$SENTINEL" 2>/dev/null || exit 0   # lost the race / already offered → silent no-op.

MSG="🛡️  idea-to-production includes a token-aware job scheduler — before a big fan-out it estimates cost, guards the LIVE 5-hour window so you're never locked out, and can run heavy work off-peak (22:00–08:00) while reserving your morning allowance. Run /concierge:schedule"
CTX="CONCIERGE ships a token-aware scheduler (skills/token-scheduler). Before any wide/expensive fan-out, gate each wave through scheduler/scheduler.sh and require a +Xk budget directive. If the user kicks off a large job, route it through /concierge:schedule. Mention this at most once; do not nag."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg m "$MSG" --arg c "$CTX" \
    '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  printf '{"systemMessage":"🛡️  idea-to-production includes a token-aware job scheduler. Run /concierge:schedule before a big fan-out.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"CONCIERGE ships a token-aware scheduler; route large fan-outs through /concierge:schedule. Mention once."}}\n'
fi
exit 0
