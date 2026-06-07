#!/usr/bin/env bash
# cost.sh — the token-cost ESTIMATOR + estimate↔actual CALIBRATION loop for a product lifecycle.
# Sibling to lifecycle.sh (single responsibility: lifecycle.sh owns phase state; this owns cost).
#
#   cost.sh estimate <dir>          # (re)seed per-phase estimates into <dir>/.i2p/cost.json
#   cost.sh close <dir> <PHASE>     # fold this phase's actual-vs-estimate into the global calibration
#   cost.sh record <dir> <PHASE> N  # add an authoritative external actual (e.g. FOUNDRY IDEA_COST) to a phase
#   cost.sh report <dir>            # print a per-phase actual/estimate table
#
# Estimates self-correct: estimate = BASE[phase] × calibration ratio_ewma[phase], where the ratio
# (actual/estimate) is learned globally across lifecycles in ~/.claude/state/i2p-cost/calibration.json.
# Actuals are MEASURED by the concierge capture-cost.sh Stop hook (writes <dir>/.i2p/cost.json).
# The canonical model + schema is i2p/knowledge/instrumentation.md. Needs jq.
set -uo pipefail

PHASES="DISCOVER IDEATE DESIGN BUILD ASSURE PUBLISH"
# Rough seed estimates (tokens). Intentionally approximate — the calibration loop corrects them.
base_for() { case "$1" in
  DISCOVER) echo 30000 ;; IDEATE) echo 40000 ;; DESIGN) echo 50000 ;;
  BUILD) echo 120000 ;; ASSURE) echo 25000 ;; PUBLISH) echo 30000 ;; *) echo 0 ;;
esac; }

EWMA_ALPHA=0.4
CAL="${HOME}/.claude/state/i2p-cost/calibration.json"

command -v jq >/dev/null 2>&1 || { echo "cost: jq required" >&2; exit 0; }

cmd="${1:-report}"; dir="${2:-.}"
CF="${dir%/}/.i2p/cost.json"

ratio_for() {  # echo learned ratio_ewma for a phase (default 1.0)
  [ -r "$CAL" ] || { echo "1.0"; return; }
  jq -r --arg p "$1" '(.[$p].ratio_ewma // 1.0)' "$CAL" 2>/dev/null || echo "1.0"
}

ensure_cf() { mkdir -p "${dir%/}/.i2p" 2>/dev/null; [ -r "$CF" ] || printf '{"phases":{},"totals":{}}\n' > "$CF"; }
recompute_totals() {
  jq '.totals.actual_tokens   = ([.phases[]?.actual_tokens   // 0] | add // 0)
    | .totals.actual_usd      = ([.phases[]?.actual_usd      // 0] | add // 0)
    | .totals.estimate_tokens = ([.phases[]?.estimate_tokens // 0] | add // 0)' \
    "$CF" > "${CF}.tmp.$$" && mv -f "${CF}.tmp.$$" "$CF"
}

case "$cmd" in
  estimate)
    ensure_cf
    for p in $PHASES; do
      b="$(base_for "$p")"; r="$(ratio_for "$p")"
      est="$(awk -v b="$b" -v r="$r" 'BEGIN{ printf "%d", (b*r)+0.5 }')"
      jq --arg p "$p" --argjson est "$est" \
         '.phases[$p] = ((.phases[$p] // {}) | .estimate_tokens = $est)' \
         "$CF" > "${CF}.tmp.$$" && mv -f "${CF}.tmp.$$" "$CF"
    done
    recompute_totals
    echo "cost: seeded estimates → $CF"
    ;;

  record)
    ph="${3:-}"; n="${4:-}"
    case "$n" in (''|*[!0-9]*) echo "cost: record needs <PHASE> <tokens>" >&2; exit 0 ;; esac
    ensure_cf
    jq --arg p "$ph" --argjson n "$n" \
       '.phases[$p] = ((.phases[$p] // {}) | .actual_tokens = ((.actual_tokens // 0) + $n))' \
       "$CF" > "${CF}.tmp.$$" && mv -f "${CF}.tmp.$$" "$CF"
    recompute_totals
    echo "cost: recorded ${n} actual tokens to ${ph}"
    ;;

  close)
    ph="${3:-}"; [ -r "$CF" ] || { echo "cost: no ledger at $CF" >&2; exit 0; }
    est="$(jq -r --arg p "$ph" '(.phases[$p].estimate_tokens // 0)' "$CF" 2>/dev/null)"
    act="$(jq -r --arg p "$ph" '(.phases[$p].actual_tokens // 0)' "$CF" 2>/dev/null)"
    case "$est" in (''|*[!0-9]*) est=0 ;; esac
    case "$act" in (''|*[!0-9]*) act=0 ;; esac
    [ "$est" -gt 0 ] 2>/dev/null && [ "$act" -gt 0 ] 2>/dev/null || { echo "cost: ${ph} not measurable (est=${est}, act=${act}) — calibration skipped"; exit 0; }
    ratio="$(awk -v a="$act" -v e="$est" 'BEGIN{ printf "%.4f", a/e }')"
    mkdir -p "$(dirname "$CAL")" 2>/dev/null
    [ -r "$CAL" ] || printf '{}\n' > "$CAL"
    jq --arg p "$ph" --argjson r "$ratio" --argjson alpha "$EWMA_ALPHA" '
      .[$p] = ((.[$p] // {samples:0, ratio_ewma:1.0})
        | .ratio_ewma = (if (.samples // 0) == 0 then $r else ($alpha*$r + (1-$alpha)*(.ratio_ewma // 1.0)) end)
        | .samples = ((.samples // 0) + 1)
        | .last_ratio = $r)' \
      "$CAL" > "${CAL}.tmp.$$" && mv -f "${CAL}.tmp.$$" "$CAL"
    new="$(jq -r --arg p "$ph" '.[$p].ratio_ewma' "$CAL" 2>/dev/null)"
    echo "cost: ${ph} closed — actual/estimate=${ratio}; calibration ratio_ewma now ${new} (future ${ph} estimates adjust)"
    ;;

  report)
    [ -r "$CF" ] || { echo "cost: no ledger (run /i2p-lifecycle, then it accrues)"; exit 0; }
    jq -r '
      "phase        est      actual",
      (.phases | to_entries[] | "\(.key)\t\(.value.estimate_tokens // 0)\t\(.value.actual_tokens // 0)"),
      "TOTAL\t\(.totals.estimate_tokens // 0)\t\(.totals.actual_tokens // 0)   $\(.totals.actual_usd // 0)"' \
      "$CF" 2>/dev/null | column -t 2>/dev/null || cat "$CF"
    ;;

  *) echo "usage: cost.sh {estimate <dir>|close <dir> <PHASE>|record <dir> <PHASE> N|report <dir>}" >&2; exit 2 ;;
esac
