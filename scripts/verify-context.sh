#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# verify-context.sh — EPIC 0067 / PLAN 0067.004 — the always-on leanness gate.
#
# Keeps the phase-INDEPENDENT SessionStart injection lean forever, so a future well-meaning addition
# cannot silently re-inflate every host harness the marketplace is installed in. The context-population
# analog of the routing suite's R6 description budget (docs/guide/context-population.md §3.1). Four checks:
#
#   C1. ALWAYS-ON BUDGET (hard)     — KAIZEN + the safe-default phase pointer ≤ the §3.1 word budget
#                                     (KAIZEN ~350 + pointer ≤60 = ~420). FAIL names the largest offender.
#   C2. POINTER ≤ 60 WORDS (hard)   — the pointer stays ≤60 words in the safe-default AND in-phase forms
#                                     (§3.2 pointer contract) — the pointer cannot grow unbounded.
#   C3. PHASE-GATING INTACT (hard)  — roadmap-routing.sh + focus-routing.sh emit NO model context with no
#                                     `.i2p/focus` (they must stay phase-gated). Catches "an ungated blob"
#                                     re-entering the always-on core (EARS-001 offender).
#   C4. KNOWLEDGE COVERAGE (WARN)   — every knowledge module resolves to a phase (PLAN 0067.003); orphans
#                                     WARN (advisory / warn-then-flip, like the routing suite's R9).
#
# Deterministic + offline (house style of verify-routing.sh / verify-board-linkage.sh). Exit 0 on pass
# (a C4 warn does NOT fail); exit 1 if a HARD check (C1–C3) fails. Touches only temp dirs.
#
# Test hooks (used by --self-test): VC_BUDGET overrides the word budget; VC_COMPONENTS_DIR feeds C1 a
# fixture set of component files instead of the live KAIZEN+pointer; VC_KNOWLEDGE_ROOT points C4 at a
# fixture tree. `--self-test` drives the budget PASS/FAIL(+offender) and orphan-WARN rows via fixtures.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; yellow=""; bold=""; dim=""; reset=""; }
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; RC=1; }
warn() { printf "  %b⚠ %s%b\n" "$yellow" "$1" "$reset"; }
note() { printf "    %b%s%b\n" "$dim" "$1" "$reset"; }
section() { printf "\n%b%s%b\n" "$bold" "$1" "$reset"; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POINTER="$REPO/plugins/i2p/hooks/scripts/phase-pointer.sh"
ROADMAP="$REPO/plugins/i2p/hooks/scripts/roadmap-routing.sh"
FOCUSHOOK="$REPO/plugins/i2p/hooks/scripts/focus-routing.sh"
KAIZEN="$REPO/plugins/i2p/KAIZEN.md"
RESOLVER="$REPO/scripts/context/resolve_knowledge_phase.py"
BUDGET="${VC_BUDGET:-420}"

wordcount() { printf '%s' "${1-}" | wc -w | tr -d '[:space:]'; }

# ctx_of <json> : extract .hookSpecificOutput.additionalContext (empty if none / silent / no jq).
ctx_of() {
  [ -z "${1-}" ] && { printf ''; return; }
  if command -v jq >/dev/null 2>&1; then printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null
  else printf '%s' "$1"; fi
}

# run_pointer [focus-phase] : run phase-pointer.sh in a hermetic project; echo its additionalContext.
run_pointer() {
  local d out; d="$(mktemp -d)"; mkdir -p "$d/.i2p"
  [ -n "${1-}" ] && printf 'phase: %s\n' "$1" > "$d/.i2p/focus"
  out="$(CLAUDE_PROJECT_DIR="$d" bash "$POINTER" </dev/null 2>/dev/null)"; rm -rf "$d"
  ctx_of "$out"
}

# run_hook_nofocus <script> : run a hook with NO .i2p/focus; echo its additionalContext (empty if silent).
run_hook_nofocus() {
  local d out; d="$(mktemp -d)"; mkdir -p "$d/.i2p"
  out="$(CLAUDE_PROJECT_DIR="$d" bash "$1" </dev/null 2>/dev/null)"; rm -rf "$d"
  ctx_of "$out"
}

# ── C0. preflight — the measured artifacts must EXIST (fail-closed, not fail-open) ───────────────
# A leanness backstop must never greenlight a broken injection pipeline: a missing KAIZEN.md or a
# renamed/removed hook would otherwise measure 0 words and PASS. Guard every artifact the hard checks
# depend on. Skipped when C1 is fed fixture components (VC_COMPONENTS_DIR), which don't touch live hooks.
check_artifacts() {
  section "C0. Preflight — always-on artifacts present [hard gate]"
  [ -n "${VC_COMPONENTS_DIR:-}" ] && { note "fixture components in use — live-artifact preflight skipped"; return; }
  local ok=1
  [ -s "$KAIZEN" ]     && pass "KAIZEN.md present + non-empty"            || { fail "KAIZEN.md missing or empty: $KAIZEN"; ok=0; }
  [ -f "$POINTER" ]    && pass "phase-pointer.sh present"                 || { fail "phase-pointer.sh missing: $POINTER"; ok=0; }
  [ -f "$ROADMAP" ]    && pass "roadmap-routing.sh present"               || { fail "roadmap-routing.sh missing: $ROADMAP"; ok=0; }
  [ -f "$FOCUSHOOK" ]  && pass "focus-routing.sh present"                 || { fail "focus-routing.sh missing: $FOCUSHOOK"; ok=0; }
  return $((1 - ok))
}

# ── C1. always-on budget ─────────────────────────────────────────────────────────────────────────
check_budget() {
  section "C1. Always-on budget — phase-independent injection ≤ ${BUDGET} words [hard gate]"
  local total=0 offender="" omax=-1 name w
  declare -A comp=()
  if [ -n "${VC_COMPONENTS_DIR:-}" ]; then
    # self-test: components come from fixture files (name = basename without .txt).
    for f in "$VC_COMPONENTS_DIR"/*.txt; do
      [ -f "$f" ] || continue
      name="$(basename "$f" .txt)"; comp[$name]="$(wordcount "$(cat "$f")")"
    done
  else
    # live: the two phase-independent injections of §3.1 (KAIZEN is emitted verbatim by inject-kaizen).
    comp[KAIZEN]="$(wordcount "$(cat "$KAIZEN" 2>/dev/null)")"
    comp[pointer]="$(wordcount "$(run_pointer)")"
    # Fail-closed on a broken emitter: a 0-word KAIZEN/pointer is a defect, not a lean win.
    [ "${comp[KAIZEN]}" -gt 0 ] || fail "KAIZEN emitted 0 words — inject-kaizen source broken/empty"
    [ "${comp[pointer]}" -gt 0 ] || fail "phase-pointer emitted 0 words — pointer broken (would false-PASS the budget)"
  fi
  for name in "${!comp[@]}"; do
    w=${comp[$name]}; total=$((total + w))
    if [ "$w" -gt "$omax" ]; then omax=$w; offender=$name; fi
    note "$name = ${w}w"
  done
  if [ "$total" -le "$BUDGET" ]; then
    pass "phase-independent always-on injection = ${total}w ≤ ${BUDGET}w"
  else
    fail "phase-independent always-on injection = ${total}w > ${BUDGET}w — largest component: '${offender}' (${omax}w)"
  fi
}

# ── C2. pointer ≤ 60 words in every form ─────────────────────────────────────────────────────────
check_pointer_size() {
  section "C2. Pointer ≤ 60 words (safe-default + in-phase) — §3.2 pointer contract [hard gate]"
  local sd inp wsd winp
  sd="$(run_pointer)"; inp="$(run_pointer DELIVER)"
  wsd="$(wordcount "$sd")"; winp="$(wordcount "$inp")"
  if [ "$wsd" -le 60 ]; then pass "safe-default pointer = ${wsd}w ≤ 60w"; else fail "safe-default pointer = ${wsd}w > 60w"; fi
  if [ "$winp" -le 60 ]; then pass "in-phase pointer = ${winp}w ≤ 60w"; else fail "in-phase pointer = ${winp}w > 60w"; fi
}

# ── C3. phase-gating intact ──────────────────────────────────────────────────────────────────────
check_phase_gating() {
  section "C3. Phase-gating intact — roadmap-routing/focus-routing silent with no FOCUS [hard gate]"
  local r f
  r="$(run_hook_nofocus "$ROADMAP")"; f="$(run_hook_nofocus "$FOCUSHOOK")"
  [ -z "$r" ] && pass "roadmap-routing.sh emits no model context with no FOCUS (phase-gated)" \
                || fail "roadmap-routing.sh re-emitted ungated context with no FOCUS (re-inflation)"
  [ -z "$f" ] && pass "focus-routing.sh emits no model context with no FOCUS (conditional)" \
                || fail "focus-routing.sh emitted context with no FOCUS"
}

# ── C4. knowledge-phase coverage (advisory) ──────────────────────────────────────────────────────
check_coverage() {
  section "C4. Knowledge-phase coverage — every module resolves (PLAN 0067.003) [warn-then-flip]"
  local root="${VC_KNOWLEDGE_ROOT:-$REPO}"
  if ! command -v python3 >/dev/null 2>&1; then warn "python3 absent — coverage not checked (advisory)"; return; fi
  if python3 "$RESOLVER" --check --root "$root" >/dev/null 2>&1; then
    pass "every knowledge module resolves to a phase (own tag or inherited)"
  else
    local n; n="$(python3 "$RESOLVER" --orphans --root "$root" 2>/dev/null | wc -l | tr -d '[:space:]')"
    warn "${n} knowledge module(s) resolve to no phase — tag them (metadata.phase) [advisory]"
    python3 "$RESOLVER" --orphans --root "$root" 2>/dev/null | sed 's/^/    /'
  fi
}

run_gate() {
  RC=0
  printf "%bAlways-on leanness gate — EPIC 0067 / PLAN 0067.004%b\n" "$bold" "$reset"
  # VC_* are TEST-ONLY overrides. Outside the self-test (which stamps VC_SELFTEST=1 on its child runs),
  # a stray exported VC_BUDGET/VC_COMPONENTS_DIR/VC_KNOWLEDGE_ROOT would silently mask the live measurement
  # — refuse to honor them: warn loudly and reset to real defaults, so a leaked env can never false-PASS.
  if [ -z "${VC_SELFTEST:-}" ] && [ -n "${VC_BUDGET:-}${VC_COMPONENTS_DIR:-}${VC_KNOWLEDGE_ROOT:-}" ]; then
    warn "ignoring VC_* test override(s) present in a live run — measuring the real injection (use --self-test to drive fixtures)"
    unset VC_BUDGET VC_COMPONENTS_DIR VC_KNOWLEDGE_ROOT
    BUDGET=420
  fi
  check_artifacts
  check_budget
  check_pointer_size
  check_phase_gating
  check_coverage
  if [ "$RC" -eq 0 ]; then printf "\n%b✓ context gate passed%b\n" "$green" "$reset"
  else printf "\n%b✗ context gate FAILED (a hard budget/gating check did not pass)%b\n" "$red" "$reset"; fi
  return "$RC"
}

# ── self-test: budget PASS / FAIL(+offender) + orphan WARN, via fixtures ─────────────────────────
self_test() {
  local failures=0 fxdir="$REPO/scripts/context/fixtures"
  check() { # $1 expected-exit $2 label ; reads $3 as the command output already captured
    if [ "$_rc" -eq "$1" ]; then printf "  %b✓%b %s\n" "$green" "$reset" "$2"
    else printf "  %b✗ %s (exit %s, wanted %s)%b\n" "$red" "$2" "$_rc" "$1" "$reset"; failures=$((failures+1)); fi
  }
  printf "%bverify-context.sh --self-test%b\n" "$bold" "$reset"

  # Row 1 — budget within limit → C1 PASS (exit 0). Fixture components sum ≤ budget.
  _out="$(VC_SELFTEST=1 VC_BUDGET=100 VC_COMPONENTS_DIR="$fxdir/context-budget/pass" VC_KNOWLEDGE_ROOT="$fxdir/knowledge-phase-clean" bash "$0" --run 2>&1)"; _rc=$?
  check 0 "budget within limit → PASS"
  printf '%s' "$_out" | grep -q "≤ 100w" || { printf "  %b✗ expected a within-budget PASS line%b\n" "$red" "$reset"; failures=$((failures+1)); }

  # Row 2 — an ungated blob pushes it over budget → C1 FAIL (exit 1) naming the offender.
  _out="$(VC_SELFTEST=1 VC_BUDGET=100 VC_COMPONENTS_DIR="$fxdir/context-budget/fail" VC_KNOWLEDGE_ROOT="$fxdir/knowledge-phase-clean" bash "$0" --run 2>&1)"; _rc=$?
  check 1 "over-budget ungated blob → FAIL"
  printf '%s' "$_out" | grep -q "ungated-blob" || { printf "  %b✗ FAIL did not name the 'ungated-blob' offender%b\n" "$red" "$reset"; failures=$((failures+1)); }

  # Row 3 — an orphan knowledge module → C4 WARN (advisory), gate still exits 0 (budget ok).
  _out="$(VC_SELFTEST=1 VC_BUDGET=100 VC_COMPONENTS_DIR="$fxdir/context-budget/pass" VC_KNOWLEDGE_ROOT="$fxdir/knowledge-phase" bash "$0" --run 2>&1)"; _rc=$?
  check 0 "orphan present → advisory WARN, gate still PASSes"
  printf '%s' "$_out" | grep -q "resolve to no phase" || { printf "  %b✗ expected an orphan WARN line%b\n" "$red" "$reset"; failures=$((failures+1)); }
  printf '%s' "$_out" | grep -qi "✗ context gate FAILED" && { printf "  %b✗ a C4 warn must NOT fail the gate%b\n" "$red" "$reset"; failures=$((failures+1)); } || true

  if [ "$failures" -eq 0 ]; then printf "%b✓ self-test passed%b\n" "$green" "$reset"; return 0
  else printf "%b✗ self-test: %d row(s) failed%b\n" "$red" "$failures" "$reset"; return 1; fi
}

case "${1:---run}" in
  --run) run_gate ;;
  --self-test) self_test ;;
  *) printf "unknown argument: %s (supported: --run, --self-test)\n" "$1" >&2; exit 2 ;;
esac
