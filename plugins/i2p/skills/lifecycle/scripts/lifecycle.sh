#!/usr/bin/env bash
# lifecycle.sh — read/advance the idea-to-production product-lifecycle state for a project.
#
# State lives at <project>/.i2p/lifecycle.json:
#   {"product":"…","current_phase":"DISCOVER","phases":[…7…],"started_at":"…","history":[{"phase","at"}]}
#
# Usage (run from the project root, or pass --dir <path>):
#   lifecycle.sh init [product-name]   # create the state at DISCOVER (no-op if it exists)
#   lifecycle.sh get                   # print the current phase token
#   lifecycle.sh status                # print a human one-liner
#   lifecycle.sh set <PHASE>           # set current phase (must be a valid token)
#   lifecycle.sh advance               # move to the next phase
#
# The canonical phases are defined in knowledge/product-lifecycle.md. Never destructive beyond
# .i2p/lifecycle.json; always exits 0 on read paths. Requires jq for writes (degrades with a message).
set -uo pipefail

PHASES="DISCOVER IDEATE DESIGN BUILD ASSURE PUBLISH IN_PRODUCTION"

dir="."
# allow --dir <path> anywhere
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dir="${2:-.}"; shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
set -- "${args[@]:-}"
cmd="${1:-status}"

LF_DIR="${dir%/}/.i2p"
LF="${LF_DIR}/lifecycle.json"

# Sibling cost estimator/calibrator (best-effort — lifecycle works without it).
COST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cost.sh"
run_cost() { [ -r "$COST" ] && bash "$COST" "$@" >/dev/null 2>&1 || true; }

now() { date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo ""; }
have_jq() { command -v jq >/dev/null 2>&1; }

valid_phase() { case " $PHASES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

get_phase() {
  [ -r "$LF" ] || { echo ""; return; }
  if have_jq; then jq -r '.current_phase // empty' "$LF" 2>/dev/null; else
    grep -o '"current_phase"[[:space:]]*:[[:space:]]*"[^"]*"' "$LF" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
  fi
}

write_state() {  # $1=product $2=current_phase $3=mode(init|update)
  have_jq || { echo "lifecycle: jq required to write state" >&2; return 1; }
  mkdir -p "$LF_DIR" 2>/dev/null || { echo "lifecycle: cannot create $LF_DIR" >&2; return 1; }
  local product="$1" phase="$2" mode="$3" ts; ts="$(now)"
  local tmp="${LF}.tmp.$$"
  if [ "$mode" = "init" ] || [ ! -f "$LF" ]; then
    jq -n --arg p "$product" --arg ph "$phase" --arg t "$ts" \
       --argjson phases "$(printf '%s\n' $PHASES | jq -R . | jq -s .)" \
       '{product:$p, current_phase:$ph, phases:$phases, started_at:$t, history:[{phase:$ph, at:$t}]}' \
       > "$tmp" 2>/dev/null && mv -f "$tmp" "$LF" || { rm -f "$tmp"; return 1; }
  else
    jq --arg ph "$phase" --arg t "$ts" \
       '.current_phase=$ph | .history += [{phase:$ph, at:$t}]' "$LF" \
       > "$tmp" 2>/dev/null && mv -f "$tmp" "$LF" || { rm -f "$tmp"; return 1; }
  fi
}

case "$cmd" in
  get)
    get_phase ;;
  status)
    p="$(get_phase)"
    if [ -n "$p" ]; then
      n=0; idx=0; for x in $PHASES; do n=$((n+1)); [ "$x" = "$p" ] && idx=$n; done
      echo "lifecycle: ${p} (${idx}/${n}) — $LF"
    else
      echo "lifecycle: not started (run: /i2p-lifecycle  or  lifecycle.sh init)"
    fi ;;
  init)
    if [ -f "$LF" ]; then echo "lifecycle: already initialised at $(get_phase) — $LF"; exit 0; fi
    product="${2:-$(basename "$(cd "$dir" 2>/dev/null && pwd || echo product)")}"
    write_state "$product" "DISCOVER" init && echo "lifecycle: started '$product' at DISCOVER — $LF"
    run_cost estimate "$dir" ;;   # seed calibration-aware per-phase token estimates
  set)
    ph="${2:-}"; valid_phase "$ph" || { echo "lifecycle: invalid phase '$ph' (valid: $PHASES)" >&2; exit 1; }
    [ -f "$LF" ] || { echo "lifecycle: not initialised; run init first" >&2; exit 1; }
    write_state "" "$ph" update && echo "lifecycle: → $ph" ;;
  advance)
    cur="$(get_phase)"; [ -n "$cur" ] || { echo "lifecycle: not initialised; run init first" >&2; exit 1; }
    nxt=""; found=0
    for x in $PHASES; do
      if [ "$found" = "1" ]; then nxt="$x"; break; fi
      [ "$x" = "$cur" ] && found=1
    done
    [ -n "$nxt" ] || { echo "lifecycle: already at terminal phase ($cur)"; exit 0; }
    write_state "" "$nxt" update && echo "lifecycle: $cur → $nxt" ;;
  done)
    # Order-safe completion: advance to the next phase ONLY IF we are at PHASE.
    # Idempotent and decoupled — every owner plugin calls `done <its-phase>` when its
    # station completes; a no-op when the lifecycle isn't started or isn't at PHASE, so
    # it can never jump the lifecycle out of order or auto-start it. Always exits 0.
    ph="${2:-}"; valid_phase "$ph" || { echo "lifecycle: invalid phase '$ph' (valid: $PHASES)" >&2; exit 0; }
    cur="$(get_phase)"
    [ -n "$cur" ] || { echo "lifecycle: not started — no change"; exit 0; }
    [ "$cur" = "$ph" ] || { echo "lifecycle: at ${cur}, not ${ph} — no change"; exit 0; }
    nxt=""; found=0
    for x in $PHASES; do
      if [ "$found" = "1" ]; then nxt="$x"; break; fi
      [ "$x" = "$cur" ] && found=1
    done
    [ -n "$nxt" ] || { echo "lifecycle: ${cur} is terminal — no change"; exit 0; }
    run_cost close "$dir" "$cur"   # fold this phase's actual-vs-estimate into the calibration ledger
    write_state "" "$nxt" update && echo "lifecycle: ${cur} done → ${nxt}" ;;
  *)
    echo "usage: lifecycle.sh [--dir <path>] {init [name]|get|status|set <PHASE>|done <PHASE>|advance}" >&2; exit 2 ;;
esac
