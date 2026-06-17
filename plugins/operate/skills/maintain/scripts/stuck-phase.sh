#!/usr/bin/env bash
# stuck-phase.sh — stuck-phase / time-in-phase detector for the maintenance cadence
# (referenced from the maintain SKILL).
#
# WHAT IT DOES (DETECT → PROPOSE — never auto-advance):
#   Reads <project>/.i2p/lifecycle.json, computes how long the CURRENT phase has been active
#   (now − the timestamp of the most recent history[] entry whose .phase == current_phase),
#   and if that exceeds a sensible per-phase budget it PRINTS a proposal naming the elapsed
#   time and the exact command to investigate/advance. It NEVER writes, NEVER advances the
#   lifecycle — advancing is a human decision (/i2p-lifecycle done <PHASE>).
#
# BUDGETS (per-phase, calendar days). OPERATE is long-lived by design (a live product sits
# in OPERATE indefinitely) so its budget is generous; the build/assure phases should not sit
# for days. These are advisory defaults; override any with I2P_STUCK_BUDGET_<PHASE>_DAYS.
#
# SAFE/GRACEFUL: corrupt or absent lifecycle.json → a clear, non-crashing message, exit 0.
# Always exits 0 (it is advisory, never a gate).
#
# Usage: stuck-phase.sh [--dir <project>]   (default: current directory)
set -uo pipefail

dir="."
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dir="${2:-.}"; shift 2 ;;
    *) shift ;;
  esac
done

LF="${dir%/}/.i2p/lifecycle.json"

# ── Per-phase default budgets (days). OPERATE is deliberately long. ──────────────────────
default_budget() {
  case "$1" in
    DISCOVER)  echo 14 ;;
    IDEATE)    echo 14 ;;
    DESIGN)    echo 14 ;;
    BUILD)     echo 7  ;;
    ASSURE)    echo 5  ;;
    SECURE)    echo 5  ;;
    PUBLISH)   echo 3  ;;
    OPERATE)   echo 90 ;;
    *)         echo 14 ;;   # unknown phase → a moderate default
  esac
}

budget_for() {  # honour an env override I2P_STUCK_BUDGET_<PHASE>_DAYS, else the default
  local phase="$1" var val
  var="I2P_STUCK_BUDGET_${phase}_DAYS"
  val="${!var:-}"
  if [ -n "$val" ] && printf '%s' "$val" | grep -qE '^[0-9]+$'; then
    echo "$val"
  else
    default_budget "$phase"
  fi
}

# ── Graceful: absent vs corrupt vs unparseable ──────────────────────────────────────────
if [ ! -f "$LF" ]; then
  echo "stuck-phase: no lifecycle at $LF — nothing to check (run /i2p-lifecycle to start one)."
  exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "stuck-phase: jq not found — cannot read $LF; skipping (advisory only)."
  exit 0
fi
if ! jq -e . "$LF" >/dev/null 2>&1; then
  echo "stuck-phase: $LF is corrupt (not valid JSON) — cannot compute time-in-phase; repair it first. Not advancing anything."
  exit 0
fi

current_phase="$(jq -r '.current_phase // empty' "$LF" 2>/dev/null || true)"
if [ -z "$current_phase" ]; then
  echo "stuck-phase: $LF has no current_phase — nothing to check."
  exit 0
fi

# Timestamp the current phase was ENTERED: the most recent history[] entry for this phase.
# (history is append-ordered; the last matching entry is the current activation.)
entered_at="$(jq -r --arg p "$current_phase" \
  '[.history[]? | select(.phase == $p) | .at] | last // empty' "$LF" 2>/dev/null || true)"
[ -n "$entered_at" ] && [ "$entered_at" != "null" ] || entered_at="$(jq -r '.started_at // empty' "$LF" 2>/dev/null || true)"

if [ -z "$entered_at" ] || [ "$entered_at" = "null" ]; then
  echo "stuck-phase: phase $current_phase has no timestamp in history[] — cannot compute elapsed time (graceful skip)."
  exit 0
fi

# ── Compute elapsed days (epoch math; GNU `date -d` with a BSD fallback) ─────────────────
now_epoch="$(date -u +%s 2>/dev/null || echo "")"
entered_epoch="$(date -u -d "$entered_at" +%s 2>/dev/null \
  || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$entered_at" +%s 2>/dev/null \
  || echo "")"

if [ -z "$now_epoch" ] || [ -z "$entered_epoch" ]; then
  echo "stuck-phase: could not parse the phase timestamp ('$entered_at') on this system — graceful skip."
  exit 0
fi

elapsed_s=$(( now_epoch - entered_epoch ))
[ "$elapsed_s" -lt 0 ] && elapsed_s=0
elapsed_days=$(( elapsed_s / 86400 ))
budget="$(budget_for "$current_phase")"

# ── Verdict: within budget → silent-ish OK; over budget → PROPOSAL (never auto-advance) ──
if [ "$elapsed_days" -le "$budget" ]; then
  echo "stuck-phase: $current_phase active ${elapsed_days}d (budget ${budget}d) — within budget."
  exit 0
fi

cat <<EOF
stuck-phase: ⚠ PROPOSAL — phase $current_phase has been active ${elapsed_days}d, exceeding its ${budget}d budget.

A phase sitting far past budget is invisible drift, not progress. Investigate why it is stalled,
then either keep working it or advance it deliberately:

    /i2p-lifecycle done $current_phase     # advance when the phase's exit criteria are met

This is a proposal only — nothing has been advanced. (OPERATE is long-lived by design; for
shorter phases like BUILD/ASSURE, multi-day stalls usually mean a blocked item to surface.)
EOF
exit 0
