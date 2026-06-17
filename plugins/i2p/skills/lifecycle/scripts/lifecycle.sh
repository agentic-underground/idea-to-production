#!/usr/bin/env bash
# lifecycle.sh — read/advance the idea-to-production product-lifecycle state for a project.
#
# State lives at <project>/.i2p/lifecycle.json:
#   {"product":"…","current_phase":"DISCOVER","phases":[…9…],"cycle":1,"started_at":"…",
#    "loop_state":"BUILD","loop_pass":1,"history":[{"phase","at"}]}
#
# The model is the v2 nine-phase cycle (knowledge/product-lifecycle.md):
#   DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE↻
# The three realisation phases BUILD/ASSURE/SECURE are a NATIVE LOOP, not a flat run: a failed
# ASSURE or SECURE gate re-enters BUILD (the `fail` back-edge), and the loop exits to PUBLISH only
# when all three are satisfied (BUILD→ASSURE→SECURE→PUBLISH walked through with no fail). The live
# loop position is tracked in `loop_state` (∈ BUILD/ASSURE/SECURE) and the iteration count in
# `loop_pass` — both ADDITIVE: a legacy 8-phase file without them still loads and reads.
#
# Usage (run from the project root, or pass --dir <path>):
#   lifecycle.sh init [product-name]   # create the state at DISCOVER (no-op if it exists)
#   lifecycle.sh get                   # print the current phase token
#   lifecycle.sh status                # print a human one-liner
#   lifecycle.sh set <PHASE>           # set current phase (must be a valid token)
#   lifecycle.sh done <PHASE>          # order-safe completion of PHASE → next (loop-aware)
#   lifecycle.sh fail <ASSURE|SECURE>  # loop back-edge: a failed gate re-enters BUILD (loop_pass++)
#   lifecycle.sh advance               # move to the next phase
#
# The canonical phases are defined in knowledge/product-lifecycle.md. Never destructive beyond
# .i2p/lifecycle.json; always exits 0 on read paths. Requires jq for writes (degrades with a message).
set -uo pipefail

PHASES="DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE"
FIRST_PHASE="${PHASES%% *}"   # DISCOVER — the cyclic re-entry target
LAST_PHASE="${PHASES##* }"    # OPERATE — wraps back to FIRST_PHASE (OPERATE ↻ DISCOVER)

# The BUILD ⇄ ASSURE ⇄ SECURE loop — the native loop sub-state-machine. LOOP_ENTRY is where the
# spine flows into the loop (from DESIGN); LOOP_EXIT is the single edge out of the loop (to PUBLISH).
LOOP_PHASES="BUILD ASSURE SECURE"
LOOP_ENTRY="BUILD"
in_loop() { case " $LOOP_PHASES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

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

# is_corrupt — the file EXISTS but is NOT parseable JSON. This distinguishes a
# truncated/corrupt state file (recoverable, must not be clobbered) from a genuinely
# absent one (a fresh project, fine to init). Without jq we cannot parse JSON, so we
# CANNOT prove corruption — we conservatively answer "not corrupt" (no false alarm,
# and the grep fallback in get_phase still degrades safely). The fix is only as strong
# as jq's presence; this is acceptable because writes require jq anyway (write_state).
is_corrupt() {
  [ -f "$LF" ] || return 1            # absent → not corrupt (it's "not started")
  have_jq || return 1                 # no jq → cannot decide; treat as not-corrupt
  jq -e . "$LF" >/dev/null 2>&1 && return 1 || return 0
}

# corrupt_msg — one clear diagnostic, to stderr, never confused with "not started".
corrupt_msg() {
  echo "lifecycle: $LF is corrupt — not overwriting; back it up and re-init / repair (e.g. mv '$LF' '$LF.bak' && /i2p:lifecycle)" >&2
}

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
    # Seed the loop fields additively: loop_state defaults to the loop entry (BUILD), loop_pass to 1.
    # They sit alongside the nine-phase spine; surfaces that never reach the loop simply ignore them.
    jq -n --arg p "$product" --arg ph "$phase" --arg t "$ts" --arg le "$LOOP_ENTRY" \
       --argjson phases "$(printf '%s\n' $PHASES | jq -R . | jq -s .)" \
       '{product:$p, current_phase:$ph, phases:$phases, cycle:1, started_at:$t,
         loop_state:$le, loop_pass:1, history:[{phase:$ph, at:$t}]}' \
       > "$tmp" 2>/dev/null && mv -f "$tmp" "$LF" || { rm -f "$tmp"; return 1; }
  else
    # On a normal phase update, keep loop_state in step with the live phase WHEN it is a loop phase,
    # so loop_state always reflects the BUILD/ASSURE/SECURE position once the lifecycle is in the loop.
    # Additive + safe on legacy files (the field is created if absent, untouched for non-loop phases).
    local in_loop_flag="false"; in_loop "$phase" && in_loop_flag="true"
    jq --arg ph "$phase" --arg t "$ts" --argjson inloop "$in_loop_flag" \
       '.current_phase=$ph
        | (if $inloop then .loop_state=$ph else . end)
        | .history += [{phase:$ph, at:$t}]' "$LF" \
       > "$tmp" 2>/dev/null && mv -f "$tmp" "$LF" || { rm -f "$tmp"; return 1; }
  fi
}

# Next phase after $1, wrapping the LAST phase back to the FIRST — the OPERATE ↻ DISCOVER
# cyclic re-entry that makes the lifecycle a cycle, not a dead-end.
next_phase() {
  local cur="$1" nxt="" found=0 x
  for x in $PHASES; do
    if [ "$found" = "1" ]; then nxt="$x"; break; fi
    [ "$x" = "$cur" ] && found=1
  done
  [ -n "$nxt" ] || nxt="$FIRST_PHASE"
  printf '%s' "$nxt"
}
get_cycle() { have_jq && [ -r "$LF" ] && jq -r '.cycle // 1' "$LF" 2>/dev/null || echo 1; }
bump_cycle() {  # increment the cycle counter on an OPERATE ↻ DISCOVER wrap
  have_jq || return 0
  local tmp="${LF}.tmp.$$"
  jq '.cycle = ((.cycle // 1) + 1)' "$LF" > "$tmp" 2>/dev/null && mv -f "$tmp" "$LF" || rm -f "$tmp"
}

# Loop accessors — ADDITIVE reads. A legacy file with no loop fields yields the safe defaults
# (loop_state = the loop entry BUILD, loop_pass = 1) without crashing or being rewritten.
get_loop_state() { have_jq && [ -r "$LF" ] && jq -r --arg le "$LOOP_ENTRY" '.loop_state // $le' "$LF" 2>/dev/null || echo "$LOOP_ENTRY"; }
get_loop_pass()  { have_jq && [ -r "$LF" ] && jq -r '.loop_pass // 1' "$LF" 2>/dev/null || echo 1; }

# loop_back — the loop's BACK-EDGE. A failed ASSURE/SECURE gate re-enters BUILD: current_phase and
# loop_state both return to the loop entry, and loop_pass increments (the iteration is recorded). The
# transition is appended to history with the failing gate so the loop's path is auditable. ADDITIVE:
# loop_pass is created (defaulting to 1, then +1 = 2 for the first recorded fail) if it was absent.
loop_back() {  # $1 = the failing gate (ASSURE|SECURE)
  have_jq || { echo "lifecycle: jq required to write state" >&2; return 1; }
  local gate="$1" ts; ts="$(now)"
  local tmp="${LF}.tmp.$$"
  jq --arg le "$LOOP_ENTRY" --arg gate "$gate" --arg t "$ts" \
     '.current_phase=$le
      | .loop_state=$le
      | .loop_pass=((.loop_pass // 1) + 1)
      | .history += [{phase:$le, at:$t, via:("fail "+$gate)}]' "$LF" \
     > "$tmp" 2>/dev/null && mv -f "$tmp" "$LF" || { rm -f "$tmp"; return 1; }
}

case "$cmd" in
  get)
    # A corrupt file is NOT "no phase": say so on stderr (keep stdout empty/parseable).
    if is_corrupt; then corrupt_msg; exit 1; fi
    get_phase ;;
  status)
    # Distinguish corrupt from not-started — a corrupt file must never read as "not started".
    if is_corrupt; then echo "lifecycle: corrupt — $LF is not valid JSON (back it up and re-init / repair)"; exit 1; fi
    p="$(get_phase)"
    if [ -n "$p" ]; then
      n=0; idx=0; for x in $PHASES; do n=$((n+1)); [ "$x" = "$p" ] && idx=$n; done
      cyc="$(get_cycle)"; if [ "${cyc:-1}" -gt 1 ] 2>/dev/null; then cycstr=" · cycle ${cyc}"; else cycstr=""; fi
      # In the BUILD ⇄ ASSURE ⇄ SECURE loop, surface the loop pass (iteration) so a re-entry is visible.
      if in_loop "$p"; then
        lp="$(get_loop_pass)"; if [ "${lp:-1}" -gt 1 ] 2>/dev/null; then loopstr=" · loop pass ${lp}"; else loopstr=" · loop"; fi
      else loopstr=""; fi
      echo "lifecycle: ${p} (${idx}/${n})${cycstr}${loopstr} — $LF"
    else
      echo "lifecycle: not started (run: /i2p:lifecycle  or  lifecycle.sh init)"
    fi ;;
  init)
    # Refuse to clobber a corrupt-but-recoverable state file with a fresh init.
    if is_corrupt; then corrupt_msg; exit 1; fi
    if [ -f "$LF" ]; then echo "lifecycle: already initialised at $(get_phase) — $LF"; exit 0; fi
    product="${2:-$(basename "$(cd "$dir" 2>/dev/null && pwd || echo product)")}"
    write_state "$product" "DISCOVER" init && echo "lifecycle: started '$product' at DISCOVER — $LF"
    run_cost estimate "$dir" ;;   # seed calibration-aware per-phase token estimates
  set)
    ph="${2:-}"; valid_phase "$ph" || { echo "lifecycle: invalid phase '$ph' (valid: $PHASES)" >&2; exit 1; }
    if is_corrupt; then corrupt_msg; exit 1; fi   # REFUSE to write over a recoverable corrupt file
    [ -f "$LF" ] || { echo "lifecycle: not initialised; run init first" >&2; exit 1; }
    write_state "" "$ph" update && echo "lifecycle: → $ph" ;;
  advance)
    if is_corrupt; then corrupt_msg; exit 1; fi   # REFUSE to advance/clobber a corrupt file
    cur="$(get_phase)"; [ -n "$cur" ] || { echo "lifecycle: not initialised; run init first" >&2; exit 1; }
    nxt="$(next_phase "$cur")"
    write_state "" "$nxt" update || exit 1
    if [ "$cur" = "$LAST_PHASE" ]; then bump_cycle; echo "lifecycle: $cur → $nxt (cycle $(get_cycle) ↻)"
    else echo "lifecycle: $cur → $nxt"; fi ;;
  done)
    # Order-safe completion: advance to the next phase ONLY IF we are at PHASE.
    # Idempotent and decoupled — every owner plugin calls `done <its-phase>` when its
    # station completes; a no-op when the lifecycle isn't started or isn't at PHASE, so
    # it can never jump the lifecycle out of order or auto-start it. Always exits 0.
    # At the LAST phase (OPERATE) the next phase wraps to the FIRST (DISCOVER) — the
    # cyclic re-entry — and the cycle counter bumps: a learning became a new opportunity.
    ph="${2:-}"; valid_phase "$ph" || { echo "lifecycle: invalid phase '$ph' (valid: $PHASES)" >&2; exit 0; }
    # REFUSE to clobber a corrupt-but-recoverable state. Unlike the normal no-op (exit 0),
    # corruption is a real fault: diagnose to stderr and exit non-zero so it is never
    # mistaken for "advanced" or for the benign not-started/not-at-phase no-ops below.
    if is_corrupt; then corrupt_msg; exit 1; fi
    cur="$(get_phase)"
    [ -n "$cur" ] || { echo "lifecycle: not started — no change"; exit 0; }
    [ "$cur" = "$ph" ] || { echo "lifecycle: at ${cur}, not ${ph} — no change"; exit 0; }
    nxt="$(next_phase "$cur")"
    run_cost close "$dir" "$cur"   # fold this phase's actual-vs-estimate into the calibration ledger
    write_state "" "$nxt" update || exit 0
    if [ "$cur" = "$LAST_PHASE" ]; then
      bump_cycle   # OPERATE ↻ DISCOVER — the next value cycle begins
      echo "lifecycle: ${cur} done → ${nxt} (cycle $(get_cycle) ↻)"
    else
      echo "lifecycle: ${cur} done → ${nxt}"
    fi ;;
  fail)
    # The loop BACK-EDGE — distinct from `done`. A failed ASSURE or SECURE gate re-enters BUILD
    # (loop_state → BUILD, loop_pass++), rather than advancing toward PUBLISH. The verb only accepts
    # the two loop GATES (ASSURE|SECURE); a BUILD/non-loop/invalid argument is rejected without
    # touching state. Order-safe: it only acts when the lifecycle is actually AT that gate, so a
    # stray `fail` cannot drag a non-loop phase backwards. Idempotent in spirit: re-running at BUILD
    # (already re-entered) is a benign no-op. The corrupt-vs-not-started distinction is preserved.
    gate="${2:-}"
    case "$gate" in
      ASSURE|SECURE) : ;;
      *) echo "lifecycle: fail takes a failing gate (ASSURE|SECURE), not '${gate}'" >&2; exit 0 ;;
    esac
    if is_corrupt; then corrupt_msg; exit 1; fi   # REFUSE to clobber a recoverable corrupt file
    cur="$(get_phase)"
    [ -n "$cur" ] || { echo "lifecycle: not started — no change"; exit 0; }
    [ "$cur" = "$gate" ] || { echo "lifecycle: at ${cur}, not ${gate} — no change"; exit 0; }
    loop_back "$gate" || exit 0
    echo "lifecycle: ${gate} failed → re-enter ${LOOP_ENTRY} (loop pass $(get_loop_pass))" ;;
  *)
    echo "usage: lifecycle.sh [--dir <path>] {init [name]|get|status|set <PHASE>|done <PHASE>|fail <ASSURE|SECURE>|advance}" >&2; exit 2 ;;
esac
