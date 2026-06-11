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

jobs="$(bash "$REG" list "$cwd" 2>/dev/null || echo '[]')"
njobs="$(printf '%s' "$jobs" | jq 'length' 2>/dev/null || echo 0)"

ctx="CONCIERGE token-scheduler — session-safe startup. Durable scheduled jobs live in ${cwd}/.i2p/scheduled-jobs.json with their ledgers in .i2p/jobs/. CronCreate is session-only, so on THIS fresh session none are armed. If the user wants them to keep running: for each job, FIRST run CronList to avoid duplicates, then CronCreate with the job's stored \`cron\` and the prompt from its \`prompt_file\`, then mark it armed via \`bash ${SCHED_DIR}/jobs-registry.sh arm ${cwd} <id>\`. To show the full picture run \`bash ${SCHED_DIR}/report.sh ${cwd}\` (scheduled jobs + estimator convergence). When the user asks 'how's the estimator doing?', run \`bash ${SCHED_DIR}/report.sh ${cwd} --estimator\`."

if [ "$njobs" -gt 0 ]; then
  msg="$(printf '%s' "$brief" | head -1)"$'\n'"   Re-arm with CronCreate to resume; I can do that for you. Ask \"how's the estimator doing?\" for convergence."
else
  msg="$(printf '%s' "$brief" | head -1)"
fi

jq -cn --arg m "$msg" --arg c "$ctx" \
  '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
exit 0
