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
# Actuals are MEASURED by the i2p capture-cost.sh Stop hook (writes <dir>/.i2p/cost.json).
# The canonical model + schema is i2p/knowledge/instrumentation.md. Needs jq.
#
# CYCLE-INDEXED (P2-20, ADDITIVE — no destructive migration): a product loops OPERATE ↻ DISCOVER,
# and each new cycle must NOT clobber the prior cycle's cost. cost.json is therefore cycle-indexed:
# the active cycle is read from .i2p/lifecycle.json's `.cycle` field (default 1 when absent). The
# schema is additive — an OLD flat file {"phases":…,"totals":…} reads as CYCLE 1, so legacy files
# and the i2p Stop-hook writer (which keeps writing the flat shape) keep working untouched.
# Only when a cycle > 1 first accrues does the file grow a top-level `.cycles` map: the pre-existing
# flat phases/totals fold down into `.cycles["1"]` and the new cycle lands at `.cycles["<n>"]`. A
# reader of a cycle-indexed file with no lifecycle still defaults to cycle 1, never zeroing.
set -uo pipefail

PHASES="DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE"
# Rough seed estimates (tokens). Intentionally approximate — the calibration loop corrects them.
base_for() { case "$1" in
  DISCOVER) echo 30000 ;; IDEATE) echo 40000 ;; DESIGN) echo 50000 ;;
  BUILD) echo 120000 ;; ASSURE) echo 25000 ;; SECURE) echo 25000 ;;
  PUBLISH) echo 30000 ;; OPERATE) echo 40000 ;; *) echo 0 ;;
esac; }

EWMA_ALPHA=0.4
CAL="${HOME}/.claude/state/i2p-cost/calibration.json"

command -v jq >/dev/null 2>&1 || { echo "cost: jq required" >&2; exit 0; }

cmd="${1:-report}"; dir="${2:-.}"
CF="${dir%/}/.i2p/cost.json"
LF="${dir%/}/.i2p/lifecycle.json"

# Active cycle for this product — from lifecycle.json's `.cycle` (default 1 when absent/unstarted).
# Cycle 1 keeps the legacy FLAT shape (additive: no migration for the common case); cycle > 1 is
# what introduces the cycle-indexed `.cycles` map. This is the single source of cycle truth.
CYCLE="$( { [ -r "$LF" ] && jq -r '(.cycle // 1)' "$LF" 2>/dev/null; } || echo 1 )"
case "$CYCLE" in (''|*[!0-9]*) CYCLE=1 ;; esac

# cost.json node accessors — the ADDITIVE cycle-index reader/writer.
#   READER  (cycle_get): the active cycle's {phases,totals}. If the file has a `.cycles` map, read
#           .cycles[CYCLE]; otherwise the file IS flat and represents cycle 1, so cycle 1 reads the
#           top level and any other cycle reads empty. An old flat file therefore reads as cycle 1.
#   WRITER  (cycle_apply): apply a jq node-transform F to the active cycle's node. For cycle 1 on a
#           still-flat file it edits the top level in place (legacy-compatible). For any cycle once a
#           `.cycles` map exists (or cycle > 1 on a flat file), it lifts the flat top level down into
#           .cycles["1"] first (one-time, lossless), then edits .cycles[CYCLE] — prior cycles untouched.

ratio_for() {  # echo learned ratio_ewma for a phase (default 1.0)
  [ -r "$CAL" ] || { echo "1.0"; return; }
  jq -r --arg p "$1" '(.[$p].ratio_ewma // 1.0)' "$CAL" 2>/dev/null || echo "1.0"
}

ensure_cf() { mkdir -p "${dir%/}/.i2p" 2>/dev/null; [ -r "$CF" ] || printf '{"phases":{},"totals":{}}\n' > "$CF"; }

# cycle_get '<jq node expression>' — evaluate a jq filter against the ACTIVE cycle's node.
# e.g. cycle_get '.phases[$p].estimate_tokens // 0'  (with --arg already inapplicable; use literals)
cycle_get() {
  jq -r --arg cyc "$CYCLE" --argjson filter_marker 0 "
    ( if has(\"cycles\") then (.cycles[\$cyc] // {})
      elif \$cyc == \"1\" then .
      else {} end ) | ( $1 )" "$CF" 2>/dev/null
}

# cycle_apply '<jq node transform>' — apply transform F (operating on a {phases,totals} node) to the
# ACTIVE cycle's node, additively. Extra jq args are forwarded after the filter string.
cycle_apply() {
  local F="$1"; shift
  jq --arg cyc "$CYCLE" "$@" "
    def node_xform: ( $F );
    if has(\"cycles\") then
      .cycles[\$cyc] = ((.cycles[\$cyc] // {phases:{},totals:{}}) | node_xform)
    elif \$cyc == \"1\" then
      node_xform                                  # legacy flat path — cycle 1 edits the top level
    else
      # First write to a cycle > 1 on a still-flat file: fold the flat top level into cycle 1,
      # then create/edit this cycle. The pre-existing cycle-1 data is preserved verbatim.
      { cycles: ( { \"1\": { phases: (.phases // {}), totals: (.totals // {}) } }
                  + { (\$cyc): ( ({phases:{},totals:{}}) | node_xform ) } ) }
    end" "$CF" > "${CF}.tmp.$$" && mv -f "${CF}.tmp.$$" "$CF"
}

recompute_totals() {
  cycle_apply '.totals.actual_tokens   = ([.phases[]?.actual_tokens   // 0] | add // 0)
    | .totals.actual_usd      = ([.phases[]?.actual_usd      // 0] | add // 0)
    | .totals.estimate_tokens = ([.phases[]?.estimate_tokens // 0] | add // 0)'
}

case "$cmd" in
  estimate)
    ensure_cf
    for p in $PHASES; do
      b="$(base_for "$p")"; r="$(ratio_for "$p")"
      est="$(awk -v b="$b" -v r="$r" 'BEGIN{ printf "%d", (b*r)+0.5 }')"
      cycle_apply '.phases[$p] = ((.phases[$p] // {}) | .estimate_tokens = $est)' \
         --arg p "$p" --argjson est "$est"
    done
    recompute_totals
    echo "cost: seeded estimates → $CF (cycle ${CYCLE})"
    ;;

  record)
    ph="${3:-}"; n="${4:-}"
    case "$n" in (''|*[!0-9]*) echo "cost: record needs <PHASE> <tokens>" >&2; exit 0 ;; esac
    ensure_cf
    cycle_apply '.phases[$p] = ((.phases[$p] // {}) | .actual_tokens = ((.actual_tokens // 0) + $n))' \
       --arg p "$ph" --argjson n "$n"
    recompute_totals
    echo "cost: recorded ${n} actual tokens to ${ph} (cycle ${CYCLE})"
    ;;

  close)
    ph="${3:-}"; [ -r "$CF" ] || { echo "cost: no ledger at $CF" >&2; exit 0; }
    est="$(cycle_get ".phases[\"$ph\"].estimate_tokens // 0")"
    act="$(cycle_get ".phases[\"$ph\"].actual_tokens // 0")"
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
    [ -r "$CF" ] || { echo "cost: no ledger (run /i2p:lifecycle, then it accrues)"; exit 0; }
    # Report the ACTIVE cycle's node (defaults to cycle 1 for a flat/legacy file). When the file is
    # cycle-indexed, label the cycle so prior cycles are visibly preserved, not clobbered.
    label="$(jq -r --arg cyc "$CYCLE" 'if has("cycles") then "  (cycle \($cyc) of \(.cycles|keys|length))" else "" end' "$CF" 2>/dev/null)"
    jq -r --arg cyc "$CYCLE" '
      ( if has("cycles") then (.cycles[$cyc] // {phases:{},totals:{}}) else . end ) as $n
      | "phase        est      actual",
        ($n.phases | to_entries[] | "\(.key)\t\(.value.estimate_tokens // 0)\t\(.value.actual_tokens // 0)"),
        "TOTAL\t\($n.totals.estimate_tokens // 0)\t\($n.totals.actual_tokens // 0)   $\($n.totals.actual_usd // 0)"' \
      "$CF" 2>/dev/null | column -t 2>/dev/null || cat "$CF"
    [ -n "$label" ] && echo "cost: report is for cycle ${CYCLE}${label}"
    ;;

  *) echo "usage: cost.sh {estimate <dir>|close <dir> <PHASE>|record <dir> <PHASE> N|report <dir>}" >&2; exit 2 ;;
esac
