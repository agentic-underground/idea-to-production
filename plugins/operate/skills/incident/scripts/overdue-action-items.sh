#!/usr/bin/env bash
# overdue-action-items.sh — the postmortem action-item FOLLOW-UP DETECTOR.
#
# WHAT IT DOES (DETECT → SURFACE — never auto-close, never gate):
#   Reads the append-only action-item LEDGER (<project>/.i2p/action-items.jsonl, written by
#   action-items.sh during `/incident postmortem`), reduces it to the latest state per id, and reports:
#     • OVERDUE  — status=open AND due date is in the PAST (today > due)
#     • OPEN     — status=open with no/future due date (still owed, not yet overdue)
#   Un-closed / overdue action items are a RE-ENTRY SIGNAL: a postmortem's contributing-cause fix that
#   was never landed is exactly the divergence `iterate` turns back into the lifecycle (OPERATE ↻).
#   This script PRINTS the finding and a re-entry hint; it NEVER writes, closes, or advances anything.
#
# EXIT: 0 when nothing is open/overdue (clean); 0 with a printed report otherwise (advisory, never a gate).
#   Pass --strict to exit 1 when there is at least one OVERDUE item (for an opt-in CI/gate caller).
#
# SAFE/GRACEFUL: absent or corrupt ledger / missing jq → a clear, non-crashing message, exit 0.
#
# Usage: overdue-action-items.sh [--dir <project>] [--strict]
set -uo pipefail

dir="."; strict=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dir="${2:-.}"; shift 2 ;;
    --strict) strict=1; shift ;;
    *) shift ;;
  esac
done

LEDGER="${dir%/}/.i2p/action-items.jsonl"

if ! command -v jq >/dev/null 2>&1; then
  echo "overdue-action-items: jq not found — cannot read the ledger; skipping (advisory only)."
  exit 0
fi
if [ ! -f "$LEDGER" ]; then
  echo "overdue-action-items: no ledger at $LEDGER — no postmortem action items recorded yet (clean)."
  exit 0
fi

today="$(date -u +%Y-%m-%d 2>/dev/null || echo "")"

# Reduce the append-only ledger to the latest state per id, tolerating malformed lines.
latest="$(jq -s '
  map(select(type=="object" and has("id")))
  | group_by(.id) | map(.[-1])
  | map(select(.status=="open"))' \
  <(grep -v '^[[:space:]]*$' "$LEDGER" 2>/dev/null | jq -c '.' 2>/dev/null) 2>/dev/null || echo "[]")"
[ -n "$latest" ] || latest="[]"

open_count="$(printf '%s' "$latest" | jq 'length' 2>/dev/null || echo 0)"
if [ "${open_count:-0}" -eq 0 ] 2>/dev/null; then
  echo "overdue-action-items: all postmortem action items are closed — clean."
  exit 0
fi

# Partition into OVERDUE (past due date) vs still-OPEN, using a lexical date compare (ISO YYYY-MM-DD).
overdue="$(printf '%s' "$latest" | jq -c --arg today "$today" \
  'map(select((.due // "") != "" and ($today != "") and (.due < $today)))' 2>/dev/null || echo "[]")"
overdue_count="$(printf '%s' "$overdue" | jq 'length' 2>/dev/null || echo 0)"

echo "overdue-action-items: ${open_count} open action item(s), ${overdue_count} OVERDUE (as of ${today:-unknown})."
echo ""
printf '%s' "$latest" | jq -r --arg today "$today" '
  sort_by(.due // "9999-12-31")
  | .[]
  | ((if (.due // "") != "" and $today != "" and (.due < $today) then "⚠ OVERDUE" else "  open   " end)
     + "  " + (.id // "?") + "  due=" + (.due // "-") + "  owner=" + (.owner // "-")
     + ("  [" + (.incident // "?") + "]") + "  " + (.title // ""))'

if [ "${overdue_count:-0}" -gt 0 ] 2>/dev/null; then
  cat <<EOF

⚠ RE-ENTRY SIGNAL — ${overdue_count} postmortem action item(s) are past due and still open.
An un-landed contributing-cause fix is a divergence between intended and actual reliability:
surface it via \`/iterate\` (incidents are one of its three re-entry sources) so it re-enters the
lifecycle instead of rotting. Close items as they land: \`action-items.sh close <dir> <id>\`.
EOF
  [ "$strict" -eq 1 ] && exit 1
fi
exit 0
