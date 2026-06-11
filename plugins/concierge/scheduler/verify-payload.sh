#!/usr/bin/env bash
# verify-payload.sh — the PHASE-0 PROBE. The step the original guard skipped.
#
# Temporarily register this on a hook event (PreToolUse, Stop, SessionStart, …) to discover EXACTLY
# what the harness puts on that event's stdin — specifically whether `.rate_limits` is present. It
# appends one line per fire to ~/.claude/state/i2p-cost/payload-probe.jsonl: the event's top-level
# keys, whether rate_limits/cost/transcript_path are present, and the tool name when known. Read that
# log to answer the [VERIFY] questions in knowledge/token-aware-scheduling.md, then UNREGISTER it.
#
# Writes only under ~/.claude; never blocks; no-op without jq.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
state="${I2P_COST_STATE_DIR:-${HOME}/.claude/state/i2p-cost}"
log="${state}/payload-probe.jsonl"

# --report : summarise what the probe has captured so far — the answer to the [VERIFY] questions.
if [ "${1:-}" = "--report" ]; then
  if [ ! -r "$log" ]; then
    echo "No probe data yet at $log."
    echo "Register the probe (it's in .claude/settings.local.json) and use Claude normally — especially"
    echo "spawn a sub-agent or two so PreToolUse(Agent|Task) fires. Then re-run with --report."
    exit 0
  fi
  echo "Payload probe — does each hook event carry the LIVE .rate_limits signal?"
  echo "(source: $log)"
  echo
  jq -rs '
    group_by([.hook_event, .tool])[]
    | { event:(.[0].hook_event // "unknown"), tool:(.[0].tool // "—"),
        fires:length,
        with_rate_limits:(map(select(.has_rate_limits))|length),
        sample_pct:((map(.five_hour_pct)|map(select(.!=null))|first) // null),
        with_cost:(map(select(.has_cost))|length) }
    | "  \(.event)/\(.tool): \(.fires) fires · rate_limits in \(.with_rate_limits)/\(.fires) · cost in \(.with_cost)/\(.fires)\(if .sample_pct!=null then " · e.g. five_hour=\(.sample_pct)%" else "" end)"
  ' "$log"
  echo
  echo "Reading the result:"
  echo "  • rate_limits present on PreToolUse/Agent or /Task → preflight-fanout.sh can be a HARD backstop."
  echo "  • rate_limits absent there → rely on the orchestration discipline + the snapshot bridge."
  echo "When done, remove the \"hooks\" block from .claude/settings.local.json to unregister the probe."
  exit 0
fi

payload=""; [ -t 0 ] || payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

mkdir -p "$state" 2>/dev/null || exit 0
now="$(date +%s 2>/dev/null || echo 0)"

printf '%s' "$payload" | jq -c --argjson at "$now" '
  {
    at: $at,
    top_level_keys: (keys),
    has_rate_limits: (has("rate_limits")),
    five_hour_pct: (.rate_limits.five_hour.used_percentage // null),
    has_cost: (has("cost")),
    cost_usd: (.cost.total_cost_usd // null),
    has_transcript: (has("transcript_path")),
    tool: (.tool_name // .tool.name // null),
    hook_event: (.hook_event_name // .hookEventName // null)
  }' >> "$log" 2>/dev/null || true
exit 0
