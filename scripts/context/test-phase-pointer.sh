#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# test-phase-pointer.sh — EPIC 0067 / PLAN 0067.002 — behaviour test for the phase-aware
# context pointer injector (phase-pointer.sh) and the phase-gated roadmap-routing.sh.
#
# Proves the PLAN 0067.002 acceptance rows by running the real SessionStart scripts against
# fixtured .i2p/focus / .i2p/lifecycle.json states (a fresh temp project per row, drained stdin):
#
#   AC-1  focus=DELIVER   → pointer names phase=DELIVER; roadmap-routing EMITS (in-phase).
#   AC-1b focus=DESIGN    → pointer names phase=DESIGN; roadmap-routing SILENT (out-of-phase, EARS-002).
#   AC-2  no focus        → pointer emits the SAFE DEFAULT ("no phase set"); no phase-specific dump
#                           (EARS-004); pointer within the ≤60-word budget (§3.1).
#   AC-3  static shape     → the pointer block is byte-identical across repeated SessionStart events
#                           in one project (dedup/cache-friendliness, EARS-003 — no drift/re-emit).
#   +     lifecycle fallback: no focus but lifecycle.json current_phase=BUILD → pointer names BUILD.
#   +     untrusted focus: a forged `phase:` payload → fails closed to the safe default.
#
# Deterministic + offline. Every emission must be valid JSON. House style mirrors
# verify-board-linkage.sh (section/pass/fail, exit 0|1). No network, no tokens.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS="${HERE}/../../plugins/i2p/hooks/scripts"
POINTER="${HOOKS}/phase-pointer.sh"
ROADMAP="${HOOKS}/roadmap-routing.sh"

green=$'\033[32m'; red=$'\033[31m'; bold=$'\033[1m'; reset=$'\033[0m'
[ -t 1 ] || { green=""; red=""; bold=""; reset=""; }
failures=0
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; failures=$((failures+1)); }

# mkproj <focus-line|""> <lifecycle-phase|""> : echo a fresh temp project dir with .i2p state.
mkproj() {
  local focus="$1" lifecycle="$2"
  local d; d="$(mktemp -d "${TMPDIR:-/tmp}/pp-XXXXXX")" || return 1
  mkdir -p "$d/.i2p"
  [ -n "$focus" ] && printf '%s\n' "$focus" > "$d/.i2p/focus"
  [ -n "$lifecycle" ] && printf '{"current_phase":"%s"}\n' "$lifecycle" > "$d/.i2p/lifecycle.json"
  printf '%s' "$d"
}

# run_hook <script> <project-dir> [extra VAR=val ...] : run a SessionStart hook with drained stdin.
# Prints stdout (the JSON, or empty for a silent hook). Fails the suite on a non-zero exit.
run_hook() {
  local script="$1" proj="$2"; shift 2
  local out rc
  out="$(env "$@" CLAUDE_PROJECT_DIR="$proj" bash "$script" </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then fail "hook $(basename "$script") exited $rc (must always exit 0)"; fi
  printf '%s' "$out"
}

# valid_json <string> : 0 if empty (a silent hook) or parseable JSON; else 1.
valid_json() {
  [ -z "$1" ] && return 0
  if command -v jq >/dev/null 2>&1; then printf '%s' "$1" | jq -e . >/dev/null 2>&1; else return 0; fi
}

# ctx_of <json> : extract .hookSpecificOutput.additionalContext (empty if none / no jq).
ctx_of() {
  [ -z "$1" ] && { printf ''; return; }
  if command -v jq >/dev/null 2>&1; then printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null; else printf '%s' "$1"; fi
}

# word_count <string> : whitespace-delimited word count.
word_count() { printf '%s' "$1" | wc -w | tr -d '[:space:]'; }

printf "%b%s%b\n" "$bold" "test-phase-pointer.sh (PLAN 0067.002)" "$reset"

# ── AC-1: focus=DELIVER → pointer names DELIVER; roadmap-routing emits ────────────────────────────
p="$(mkproj 'phase: DELIVER' '')"
out="$(run_hook "$POINTER" "$p")"; ctx="$(ctx_of "$out")"
valid_json "$out" && pass "AC-1: pointer emits valid JSON" || fail "AC-1: pointer JSON invalid"
case "$ctx" in *"phase = DELIVER"*) pass "AC-1: pointer names phase = DELIVER";; *) fail "AC-1: pointer did not name DELIVER (got: $ctx)";; esac
rmout="$(run_hook "$ROADMAP" "$p")"
[ -n "$rmout" ] && pass "AC-1: roadmap-routing EMITS in DELIVER (in-phase)" || fail "AC-1: roadmap-routing was silent in DELIVER"
valid_json "$rmout" && pass "AC-1: roadmap-routing emits valid JSON" || fail "AC-1: roadmap-routing JSON invalid"
rm -rf "$p"

# ── AC-1b: focus=DESIGN → roadmap-routing SILENT (out-of-phase, EARS-002) ─────────────────────────
p="$(mkproj 'phase: DESIGN' '')"
ctx="$(ctx_of "$(run_hook "$POINTER" "$p")")"
case "$ctx" in *"phase = DESIGN"*) pass "AC-1b: pointer names phase = DESIGN";; *) fail "AC-1b: pointer did not name DESIGN (got: $ctx)";; esac
rmout="$(run_hook "$ROADMAP" "$p")"
[ -z "$rmout" ] && pass "AC-1b: roadmap-routing SILENT out-of-phase (EARS-002)" || fail "AC-1b: roadmap-routing leaked out-of-phase (got: $rmout)"
# And the DELIVER-only 192w rule must not be smuggled into the pointer.
case "$ctx" in *"FLEET v2 pipeline"*) fail "AC-1b: roadmap rule leaked into the pointer";; *) pass "AC-1b: roadmap rule absent from the pointer";; esac
rm -rf "$p"

# ── AC-2: no focus → SAFE DEFAULT pointer, no phase dump, within ≤60-word budget ──────────────────
p="$(mkproj '' '')"
out="$(run_hook "$POINTER" "$p")"; ctx="$(ctx_of "$out")"
valid_json "$out" && pass "AC-2: pointer emits valid JSON with no focus" || fail "AC-2: pointer JSON invalid"
case "$ctx" in *"no phase set"*) pass "AC-2: safe-default pointer emitted (EARS-004)";; *) fail "AC-2: no safe-default pointer (got: $ctx)";; esac
# A safe default must NOT name any concrete phase as loadable.
if printf '%s' "$ctx" | grep -qE 'phase = (DISCOVER|IDEATE|DELIVER|DESIGN|BUILD|ASSURE|SECURE|PUBLISH|OPERATE)'; then
  fail "AC-2: safe default leaked a phase-specific dump"
else pass "AC-2: safe default names no specific phase (nothing phase-specific auto-loads)"; fi
wc_ctx="$(word_count "$ctx")"
[ "$wc_ctx" -le 60 ] && pass "AC-2: pointer within ≤60-word budget (${wc_ctx}w)" || fail "AC-2: pointer over budget (${wc_ctx}w > 60)"
# roadmap-routing must be silent when phase is unknown too.
[ -z "$(run_hook "$ROADMAP" "$p")" ] && pass "AC-2: roadmap-routing silent when phase unknown" || fail "AC-2: roadmap-routing emitted with unknown phase"
rm -rf "$p"

# ── AC-3: static shape — pointer byte-identical across repeated SessionStart events ───────────────
p="$(mkproj 'phase: BUILD' '')"
a="$(ctx_of "$(run_hook "$POINTER" "$p")")"
b="$(ctx_of "$(run_hook "$POINTER" "$p")")"
[ "$a" = "$b" ] && pass "AC-3: pointer is static across repeated events (cache-friendly, EARS-003)" || fail "AC-3: pointer drifted between events"
rm -rf "$p"

# ── lifecycle fallback: no focus, lifecycle.json current_phase=BUILD → pointer names BUILD ─────────
if command -v jq >/dev/null 2>&1; then
  p="$(mkproj '' 'BUILD')"
  ctx="$(ctx_of "$(run_hook "$POINTER" "$p")")"
  case "$ctx" in *"phase = BUILD"*) pass "fallback: pointer reads lifecycle.json current_phase";; *) fail "fallback: lifecycle.json not honoured (got: $ctx)";; esac
  # focus must win over lifecycle when both present.
  p2="$(mkproj 'phase: PUBLISH' 'BUILD')"
  ctx2="$(ctx_of "$(run_hook "$POINTER" "$p2")")"
  case "$ctx2" in *"phase = PUBLISH"*) pass "precedence: .i2p/focus wins over lifecycle.json";; *) fail "precedence: focus did not win (got: $ctx2)";; esac
  rm -rf "$p" "$p2"
else
  printf "    (skipped lifecycle-fallback rows: jq absent)\n"
fi

# ── untrusted focus: only a bare allowlisted first token survives; everything else fails closed ───
# (a) A space-separated trailing clause is dropped — the first token "DELIVER" is kept, the rest gone.
p="$(mkproj 'phase: DELIVER evil trailing "clause"' '')"
ctx="$(ctx_of "$(run_hook "$POINTER" "$p")")"
case "$ctx" in
  *"phase = DELIVER"*) case "$ctx" in *evil*|*trailing*|*clause*) fail "untrusted: forged trailing clause rode along";; *) pass "untrusted: first token kept, trailing clause dropped";; esac ;;
  *) fail "untrusted: unexpected pointer (got: $ctx)" ;;
esac
rm -rf "$p"
# (b) A payload GLUED to the phase token (no space, e.g. shell metachars) → not allowlisted → fail closed.
p="$(mkproj 'phase: DELIVER;rm -rf /' '')"
ctx="$(ctx_of "$(run_hook "$POINTER" "$p")")"
case "$ctx" in *"no phase set"*) pass "untrusted: glued metachar payload → safe default (fail closed)";; *) fail "untrusted: glued payload not rejected (got: $ctx)";; esac
rm -rf "$p"
# (c) A wholly-invalid phase value → safe default (fail closed).
p="$(mkproj 'phase: NOTAPHASE' '')"
ctx="$(ctx_of "$(run_hook "$POINTER" "$p")")"
case "$ctx" in *"no phase set"*) pass "untrusted: non-allowlisted phase → safe default (fail closed)";; *) fail "untrusted: bad phase not rejected (got: $ctx)";; esac
rm -rf "$p"

if [ "$failures" -eq 0 ]; then
  printf "%b✓ all phase-pointer behaviour rows passed%b\n" "$green" "$reset"; exit 0
else
  printf "%b✗ %d row(s) failed%b\n" "$red" "$failures" "$reset"; exit 1
fi
