#!/usr/bin/env bash
# i2p UserPromptSubmit hook — surface a rotating "did you know?" tip now and then.
#
# Claude Code has no built-in tips feature, so we approximate it: a per-prompt
# counter persisted to disk fires one ≤25-word tip (as a user-visible
# systemMessage) every TIP_INTERVAL prompts, rotating through hooks/tips/tips.tsv.
# Always prints valid JSON; never blocks a prompt.
#
# Docs: https://code.claude.com/docs/en/hooks.md (UserPromptSubmit output schema)
set -euo pipefail

# Tip emitted once every N prompts.
TIP_INTERVAL=8

# Drain stdin (the prompt payload) — we gate on a counter, not on content.
if [ ! -t 0 ]; then cat >/dev/null 2>&1 || true; fi

empty_output() {
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit"}}\n'
  exit 0
}

emit_tip() {
  # $1 = tip text
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg msg "💡 Did you know? $1" \
      '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "UserPromptSubmit"}}'
  else
    # Best-effort static fallback; strip characters that would break naive JSON.
    safe=$(printf '%s' "$1" | tr -d '"\\')
    printf '{"systemMessage":"💡 Did you know? %s","hookSpecificOutput":{"hookEventName":"UserPromptSubmit"}}\n' "$safe"
  fi
  exit 0
}

TIPS_FILE="${CLAUDE_PLUGIN_ROOT:-.}/hooks/tips/tips.tsv"
[ -f "$TIPS_FILE" ] || empty_output

STATE_DIR="${HOME}/.claude/hook-state"
STATE_FILE="${STATE_DIR}/i2p-tips.count"
mkdir -p "$STATE_DIR" 2>/dev/null || empty_output

# Read + increment the counter, persisted atomically (write temp, then mv).
count=0
[ -f "$STATE_FILE" ] && count=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
case "$count" in (''|*[!0-9]*) count=0 ;; esac
count=$((count + 1))
tmp="${STATE_FILE}.$$"
printf '%s\n' "$count" > "$tmp" 2>/dev/null && mv -f "$tmp" "$STATE_FILE" 2>/dev/null || rm -f "$tmp" 2>/dev/null

# Only fire on every Nth prompt.
[ $((count % TIP_INTERVAL)) -eq 0 ] || empty_output

# Load tips (skip blank lines and # comments).
mapfile -t TIPS < <(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$TIPS_FILE" 2>/dev/null || true)
n=${#TIPS[@]}
[ "$n" -gt 0 ] || empty_output

# Rotate: the k-th fired tip (k = count / N) picks index (k-1) mod n.
k=$((count / TIP_INTERVAL))
idx=$(((k - 1) % n))
emit_tip "${TIPS[$idx]}"
