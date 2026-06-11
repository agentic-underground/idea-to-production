#!/usr/bin/env bash
# startup-report.sh — SessionStart hook. Session-SAFE scheduled jobs: nothing is silently lost to a
# crash or restart. On every session start it (1) resets armed-state (a fresh session has no live
# crons — CronCreate is session-only), (2) prints a brief report of the durable scheduled jobs + the
# estimator's convergence, and (3) injects context telling the agent to RE-ARM any durable cron so it
# fires again. Silent when there is nothing scheduled and no calibration yet (never nags an empty repo).
set -uo pipefail

payload=""; [ -t 0 ] || payload="$(cat 2>/dev/null || true)"
cwd=""
if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
fi
[ -n "$cwd" ] || cwd="$(pwd 2>/dev/null || echo .)"

SCHED_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/scheduler"
REG="${SCHED_DIR}/jobs-registry.sh"
REPORT="${SCHED_DIR}/report.sh"
[ -r "$REG" ] && [ -r "$REPORT" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Fresh session ⇒ no cron is live yet. Reset armed flags so the report tells the truth.
bash "$REG" reset-armed "$cwd" >/dev/null 2>&1 || true

brief="$(bash "$REPORT" "$cwd" --brief 2>/dev/null || true)"
[ -n "$brief" ] || exit 0   # nothing scheduled, no calibration → stay silent

ctx="CONCIERGE token-scheduler — session-safe startup. Durable scheduled jobs live in ${cwd}/.i2p/scheduled-jobs.json (ledgers in .i2p/jobs/). The DURABLE arming path is OS-cron (\`bash ${SCHED_DIR}/install-oscron.sh ${cwd} <id>\`, then \`jobs-registry.sh arm ${cwd} <id> oscron\`) — it survives Claude being closed (machine awake). A job shown as '⚠ NOT armed' should be offered OS-cron (or, ephemerally, an in-session CronCreate re-arm). Full picture: \`bash ${SCHED_DIR}/report.sh ${cwd}\`. When the user asks 'how's the estimator doing?', run \`bash ${SCHED_DIR}/report.sh ${cwd} --estimator\`."

# Key indicators: the (≤2) dashboard lines, verbatim.
msg="$brief"

# Periodic tip (line 3) — throttled to ~once/day so it teaches without nagging.
tipfile="${HOME}/.claude/hook-state/scheduler-tip-last"
now_epoch="$(date +%s 2>/dev/null || echo 0)"
last_tip=0; [ -r "$tipfile" ] && last_tip="$(cat "$tipfile" 2>/dev/null | tr -dc '0-9')"; [ -n "$last_tip" ] || last_tip=0
if [ $(( now_epoch - last_tip )) -ge 72000 ]; then   # 20 h
  msg="${msg}"$'\n'"💡 ask \"how's the estimator doing?\" for the full convergence report"
  mkdir -p "$(dirname "$tipfile")" 2>/dev/null && printf '%s' "$now_epoch" > "$tipfile" 2>/dev/null || true
fi

jq -cn --arg m "$msg" --arg c "$ctx" \
  '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
exit 0
