#!/usr/bin/env bash
# overdue-learnings.sh — the GEMBA learning FOLLOW-UP DETECTOR (mirrors overdue-action-items.sh).
#
# WHAT IT DOES (DETECT → SURFACE — never auto-file, never gate):
#   Reads the append-only LEARNING LEDGER (<project>/.i2p/learnings.jsonl, written by learnings.sh),
#   reduces it to the latest state per id, and reports learnings that are still OWED:
#     • OVERDUE  — status=open AND captured more than <threshold> hours ago (never filed)
#     • OPEN     — status=open, captured recently (still within the threshold)
#   An open-but-UNFILED learning is a RE-ENTRY SIGNAL: a captured gap whose feedback issue was never
#   raised is exactly the divergence `mission-control:iterate` turns back into the lifecycle (OPERATE ↻).
#   `filed` and `closed` learnings have done their job and are NOT surfaced. This script PRINTS the
#   finding and a re-entry hint; it NEVER writes, files, or advances anything.
#
# THRESHOLD: open learnings older than --hours (default 24) are flagged OVERDUE. The age is the time
#   since the learning's latest record `ts` (a learning sitting un-filed for a day is a stale signal).
#
# EXIT: 0 when nothing is open (clean); 0 with a printed report otherwise (advisory, never a gate).
#   Pass --strict to exit 1 when there is at least one OVERDUE (un-filed past threshold) learning.
#
# SAFE/GRACEFUL: absent or corrupt ledger / missing jq → a clear, non-crashing message, exit 0.
#
# Usage: overdue-learnings.sh [--dir <project>] [--hours <n>] [--strict]
set -uo pipefail

dir="."; strict=0; hours=24
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)    dir="${2:-.}"; shift 2 ;;
    --hours)  hours="${2:-24}"; shift 2 ;;
    --strict) strict=1; shift ;;
    *)        shift ;;
  esac
done

dir="${dir%/}"
LEDGER="${dir}/.i2p/learnings.jsonl"

if ! command -v jq >/dev/null 2>&1; then
  echo "overdue-learnings: jq not found — cannot read the ledger; skipping (advisory only)."
  exit 0
fi
if [ ! -f "$LEDGER" ]; then
  echo "overdue-learnings: no ledger at $LEDGER — no learnings captured yet (clean)."
  exit 0
fi

now_epoch="$(date -u +%s 2>/dev/null || echo 0)"
# Cutoff: anything captured before this epoch is OVERDUE.
cutoff=$(( now_epoch - hours * 3600 ))

# Reduce the append-only ledger to the latest state per id, keep only status=open (un-filed).
latest="$(jq -s '
  map(select(type=="object" and has("id")))
  | group_by(.id) | map(.[-1])
  | map(select(.status=="open"))' \
  <(grep -v '^[[:space:]]*$' "$LEDGER" 2>/dev/null | jq -c -R 'fromjson? // empty' 2>/dev/null) 2>/dev/null || echo "[]")"
[ -n "$latest" ] || latest="[]"

open_count="$(printf '%s' "$latest" | jq 'length' 2>/dev/null || echo 0)"
if [ "${open_count:-0}" -eq 0 ] 2>/dev/null; then
  echo "overdue-learnings: every captured learning has been filed or closed — clean."
  exit 0
fi

# Annotate each open learning with its epoch age, partition OVERDUE (age ≥ threshold) vs still-OPEN.
# A record with an unparseable/empty ts is treated as OVERDUE (it has no provable freshness).
# `<=` so an age exactly at the threshold (and the --hours 0 "everything open is overdue" case) flags.
annotated="$(printf '%s' "$latest" | jq -c --argjson cutoff "$cutoff" '
  map(. + {_ts: (try (.ts | sub("\\.[0-9]+Z$";"Z") | fromdateiso8601) catch 0)})
  | map(. + {_overdue: (._ts == 0 or ._ts <= $cutoff)})')"

overdue_count="$(printf '%s' "$annotated" | jq '[.[] | select(._overdue)] | length' 2>/dev/null || echo 0)"

echo "overdue-learnings: ${open_count} open (un-filed) learning(s), ${overdue_count} OVERDUE (>${hours}h, as of $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null))."
echo ""
printf '%s' "$annotated" | jq -r '
  sort_by(._ts)
  | .[]
  | ((if ._overdue then "⚠ OVERDUE" else "  open   " end)
     + "  " + (.id // "?") + "  verdict=" + (.verdict // "-")
     + "  target=" + (.target // "-") + "  " + (.title // ""))'

if [ "${overdue_count:-0}" -gt 0 ] 2>/dev/null; then
  cat <<EOF

⚠ RE-ENTRY SIGNAL — ${overdue_count} captured learning(s) have sat un-filed past ${hours}h.
A captured gap whose feedback issue was never raised is a divergence between what production
taught and what re-entered the lifecycle: surface it via \`/iterate\` (it turns a production
signal into a new OPPORTUNITY) so it re-enters DISCOVER instead of rotting. Raise + record the
filing: \`raise-feedback.sh\` then \`learnings.sh filed <dir> <id> --issue <url>\`.
EOF
  [ "$strict" -eq 1 ] && exit 1
fi
exit 0
