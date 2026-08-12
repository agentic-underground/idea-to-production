#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# verify-clear-safe.sh — EPIC 0071 / PLAN 0071.002 (CS2) — the CLEAR-SAFE proof gate.
#
# Turns the CLEAR-SAFE covenant's report from an inline CLAIM into a PROVEN, reusable command. Runs the
# four checkpoint proofs and emits the CLEAR-SAFE table so a PLAN/EPIC boundary is proven safe to
# `/clear` and `resume` from — never merely asserted. The covenant it enforces is
# plugins/deliver/knowledge/protocols/clear-safe.md → "The four proofs":
#
#   1. Tree clean        — `git status --porcelain`                        must be empty
#   2. Upstream in sync  — `git rev-list --left-right --count @{u}...HEAD`  must be `0\t0` (and @{u} SET)
#   3. Learnings committed — `git status --porcelain .claude/agent-memory/` must be empty (tracked ledger)
#   4. 3-layer STATE current — resume-memory names the next item; board reachable
#
# Proofs 1–3 are DETERMINISTIC + OFFLINE and gate the exit code (this is the block). Proof 4 is
# best-effort (the resume-memory lives outside the repo, machine-local; the board is online) — it
# degrades to an ADVISORY ⚠ note, never a false PASS by silence and never a hard FAIL it cannot justify
# (absence of a "next" marker cannot be told apart from a legitimately-complete initiative). This mirrors
# verify-board-linkage.sh's gh-existence degradation exactly. House style (section/pass/fail, exit 0|1)
# matches verify-board-linkage.sh and verify-routing.sh.
#
# Test hooks (used by --self-test, all pure): CS_PORCELAIN overrides proof 1; CS_UPSTREAM overrides
# proof 2 (`__NOUPSTREAM__` simulates an unset @{u}); CS_AGENTMEM overrides proof 3; CS_STATE overrides
# proof 4's resume-pointer signal (`named:<text>` | `none`); CS_BOARD overrides board reachability
# (confirmed|offline|absent); CS_OFFLINE=1 skips gh; CS_MEMORY_DIR overrides the memory path.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; yellow=""; bold=""; dim=""; reset=""; }
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; }
warn() { printf "  %b⚠ %s%b\n" "$yellow" "$1" "$reset"; }
note() { printf "    %b%s%b\n" "$dim" "$1" "$reset"; }

# ── the four PURE classifiers — no git/gh/fs, so --self-test drives them with fixtures ────────────────

# proof_tree <porcelain-blob> → clean | dirty
proof_tree() { [ -z "$1" ] && echo clean || echo dirty; }

# proof_upstream <count-line> → synced | ahead | behind | diverged | no-upstream
#   count-line is git's "<behind>\t<ahead>" for @{u}...HEAD, or the sentinel __NOUPSTREAM__ when @{u} is unset.
#   NB: `--left-right --count @{u}...HEAD` prints LEFT(=behind @{u}) then RIGHT(=ahead of @{u}).
proof_upstream() {
  local line="$1" behind ahead
  [ "$line" = "__NOUPSTREAM__" ] && { echo no-upstream; return; }
  behind="${line%%[[:space:]]*}"; ahead="${line##*[[:space:]]}"
  [ -z "$behind" ] && behind=0; [ -z "$ahead" ] && ahead=0
  if [ "$behind" = 0 ] && [ "$ahead" = 0 ]; then echo synced
  elif [ "$behind" != 0 ] && [ "$ahead" != 0 ]; then echo diverged
  elif [ "$ahead" != 0 ]; then echo ahead
  else echo behind; fi
}

# proof_learnings <porcelain-of-agent-memory> → clean | dirty
proof_learnings() { [ -z "$1" ] && echo clean || echo dirty; }

# proof_state <state-signal> → named | unknown
#   state-signal is `named:<the next-item text>` when the resume-memory carries a NEXT pointer, else `none`.
proof_state() { case "$1" in named:*) echo named;; *) echo unknown;; esac; }

# ── I/O gatherers (overridable by env for the live run; bypassed entirely by --self-test) ─────────────

gather_porcelain() { [ -n "${CS_PORCELAIN+x}" ] && { printf '%s' "$CS_PORCELAIN"; return; }; git status --porcelain 2>/dev/null; }

# echo the count line, or __NOUPSTREAM__ when the branch tracks no upstream (rev-list errors).
gather_upstream() {
  [ -n "${CS_UPSTREAM+x}" ] && { printf '%s' "$CS_UPSTREAM"; return; }
  local out; out="$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)" \
    && [ -n "$out" ] && { printf '%s' "$out"; return; }
  printf '__NOUPSTREAM__'
}

gather_agentmem() {
  [ -n "${CS_AGENTMEM+x}" ] && { printf '%s' "$CS_AGENTMEM"; return; }
  git status --porcelain .claude/agent-memory/ 2>/dev/null
}

# echo `named:<text>` when a resume-memory file carries a NEXT / RESUME-POINTER pointer, else `none`.
# Best-effort: the memory dir is machine-local and outside the repo. Derived from the project path slug
# ("/" → "-"), overridable by CS_MEMORY_DIR. We surface the pointer text (first match) for the report.
gather_state() {
  [ -n "${CS_STATE+x}" ] && { printf '%s' "$CS_STATE"; return; }
  local dir="${CS_MEMORY_DIR:-$HOME/.claude/projects/$(pwd | sed 's#/#-#g')/memory}" hit
  [ -d "$dir" ] || { printf 'none'; return; }
  # A pointer is a line naming the NEXT item: a `NEXT` marker, a `🔜`, or a `RESUME POINTER` heading.
  hit="$(grep -rhoiE '(RESUME POINTER|NEXT[[:space:]]*[:=]|🔜[[:space:]]*NEXT|^-?[[:space:]]*NEXT\b).*' "$dir" 2>/dev/null \
         | grep -vi 'resume probe' | head -1 | sed -E 's/[[:space:]]+$//')"
  [ -n "$hit" ] && printf 'named:%s' "$hit" || printf 'none'
}

# board reachability — best-effort read-only `gh`; degrades to advisory. echo confirmed|offline|absent.
gather_board() {
  [ -n "${CS_BOARD+x}" ] && { printf '%s' "$CS_BOARD"; return; }
  [ -n "${CS_OFFLINE:-}" ] && { printf 'offline'; return; }
  command -v gh >/dev/null 2>&1 || { printf 'offline'; return; }
  gh repo view --json name >/dev/null 2>&1 && printf 'confirmed' || printf 'offline'
}

# ── the live report — assemble the four proofs into the CLEAR-SAFE table + a verdict ──────────────────
run_report() {
  local clean_exit=0
  printf "%b%s%b\n" "$bold" "CLEAR-SAFE proof gate — EPIC 0071" "$reset"

  # Proof 1 — tree clean.
  local tree; tree="$(proof_tree "$(gather_porcelain)")"
  if [ "$tree" = clean ]; then pass "1. tree clean — 'git status --porcelain' empty"
  else fail "1. tree DIRTY — uncommitted changes present ('git status --porcelain' non-empty)"; clean_exit=1; fi

  # Proof 2 — upstream in sync.
  local up; up="$(proof_upstream "$(gather_upstream)")"
  case "$up" in
    synced)      pass "2. upstream in sync — 0 behind, 0 ahead of @{u}" ;;
    ahead)       fail "2. NOT synced — commits ahead of @{u} (push with -u)"; clean_exit=1 ;;
    behind)      fail "2. NOT synced — behind @{u} (pull/rebase)"; clean_exit=1 ;;
    diverged)    fail "2. NOT synced — DIVERGED from @{u} (both ahead and behind)"; clean_exit=1 ;;
    no-upstream) fail "2. NO upstream — @{u} unset; the branch is not pushed with -u"; clean_exit=1 ;;
  esac

  # Proof 3 — learnings committed (spotlight on proof 1's most-missed subset).
  local learn; learn="$(proof_learnings "$(gather_agentmem)")"
  if [ "$learn" = clean ]; then pass "3. learnings committed — '.claude/agent-memory/' clean"
  else fail "3. learnings UNCOMMITTED — '.claude/agent-memory/' dirty (a lost learning is an unclean tree)"; clean_exit=1; fi

  # Proof 4 — 3-layer STATE currency. BEST-EFFORT: advisory, never a false PASS by silence, never a
  # hard FAIL it cannot justify (a complete initiative legitimately has no "next").
  local state board; state="$(proof_state "$(gather_state)")"; board="$(gather_board)"
  if [ "$state" = named ]; then
    pass "4. STATE — resume-memory names the next item"
    note "$(gather_state | sed 's/^named://' | cut -c1-100)"
  else
    warn "4. STATE — no resume pointer found (advisory: complete initiative, or a stale/absent memory)"
    note "resume-memory should name the next item + its spec; verify by hand at this boundary"
  fi
  case "$board" in
    confirmed) note "board reachable via gh (Status currency is yours to confirm against the pointer)" ;;
    offline)   warn "board unreachable (gh offline/unavailable) — confirm board Status by hand — advisory" ;;
    absent)    warn "board repo not resolvable — confirm board Status by hand — advisory" ;;
  esac

  printf "\n"
  if [ "$clean_exit" -eq 0 ]; then
    printf "%b✓ CLEAR-SAFE — proofs 1–3 pass; safe to /clear and resume%b\n" "$green" "$reset"
    [ "$state" != named ] && note "(proof 4 is advisory — confirm the 3-layer STATE by hand)"
  else
    printf "%b✗ NOT clear-safe — fix the failing proof(s) above, then re-run%b\n" "$red" "$reset"
  fi
  return "$clean_exit"
}

# ── self-test: exercise the pure classifiers + the report's verdict wiring via fixtures ───────────────
self_test() {
  local failures=0
  # HERMETIC: clear any ambient CS_* so a caller's live-run env cannot leak into a fixture (the lesson
  # verify-board-linkage.sh's CI dogfood taught: leaked BL_BRANCH flipped a FAIL to a PASS).
  unset CS_PORCELAIN CS_UPSTREAM CS_AGENTMEM CS_STATE CS_BOARD CS_OFFLINE CS_MEMORY_DIR

  eq() { # <expected> <got> <label>
    if [ "$2" = "$1" ]; then printf "  %b✓%b %s\n" "$green" "$reset" "$3"
    else printf "  %b✗ %s (want '%s', got '%s')%b\n" "$red" "$3" "$1" "$2" "$reset"; failures=$((failures+1)); fi
  }
  printf "%b%s%b\n" "$bold" "verify-clear-safe.sh --self-test" "$reset"

  # Proof 1 — tree.
  eq clean "$(proof_tree '')"                  "proof_tree: empty porcelain → clean"
  eq dirty "$(proof_tree ' M scripts/x.sh')"   "proof_tree: non-empty porcelain → dirty"

  # Proof 2 — upstream (LEFT=behind, RIGHT=ahead).
  eq synced      "$(proof_upstream "$(printf '0\t0')")"  "proof_upstream: 0/0 → synced"
  eq ahead       "$(proof_upstream "$(printf '0\t2')")"  "proof_upstream: 0/2 → ahead"
  eq behind      "$(proof_upstream "$(printf '3\t0')")"  "proof_upstream: 3/0 → behind"
  eq diverged    "$(proof_upstream "$(printf '1\t1')")"  "proof_upstream: 1/1 → diverged"
  eq no-upstream "$(proof_upstream '__NOUPSTREAM__')"    "proof_upstream: unset @{u} → no-upstream"

  # Proof 3 — learnings.
  eq clean "$(proof_learnings '')"                                   "proof_learnings: empty → clean"
  eq dirty "$(proof_learnings ' M .claude/agent-memory/x/MEMORY.md')" "proof_learnings: dirty ledger → dirty"

  # Proof 4 — state signal.
  eq named   "$(proof_state 'named:🔜 NEXT = CS2 verify-clear-safe.sh')" "proof_state: named pointer → named"
  eq unknown "$(proof_state none)"                                        "proof_state: no pointer → unknown"

  # ── verdict wiring: proofs 1–3 gate the exit; proof 4 never does. Drive run_report via CS_* fixtures. ──
  vex() { # <expected-exit> <label> ; CS_* already exported by caller
    local want="$1" label="$2" got
    ( run_report ) >/dev/null 2>&1; got=$?
    if [ "$got" -eq "$want" ]; then printf "  %b✓%b %s\n" "$green" "$reset" "$label"
    else printf "  %b✗ %s (want exit %s, got %s)%b\n" "$red" "$label" "$want" "$got" "$reset"; failures=$((failures+1)); fi
  }
  # all clean + named + confirmed → CLEAR-SAFE (exit 0)
  CS_PORCELAIN='' CS_UPSTREAM="$(printf '0\t0')" CS_AGENTMEM='' CS_STATE='named:x' CS_BOARD=confirmed \
    vex 0 "all proofs pass → CLEAR-SAFE (exit 0)"
  # dirty tree → NOT clear-safe
  CS_PORCELAIN=' M f' CS_UPSTREAM="$(printf '0\t0')" CS_AGENTMEM='' CS_STATE='named:x' CS_BOARD=offline \
    vex 1 "dirty tree → NOT clear-safe (exit 1)"
  # ahead of upstream → NOT clear-safe
  CS_PORCELAIN='' CS_UPSTREAM="$(printf '0\t1')" CS_AGENTMEM='' CS_STATE='named:x' CS_BOARD=offline \
    vex 1 "unpushed commits (ahead) → NOT clear-safe (exit 1)"
  # unset upstream → NOT clear-safe
  CS_PORCELAIN='' CS_UPSTREAM='__NOUPSTREAM__' CS_AGENTMEM='' CS_STATE='named:x' CS_BOARD=offline \
    vex 1 "no upstream (@{u} unset) → NOT clear-safe (exit 1)"
  # dirty learnings → NOT clear-safe (the covenant's motivating hole)
  CS_PORCELAIN='' CS_UPSTREAM="$(printf '0\t0')" CS_AGENTMEM=' M .claude/agent-memory/x' CS_STATE='named:x' CS_BOARD=offline \
    vex 1 "uncommitted learnings → NOT clear-safe (exit 1)"
  # proof 4 unknown/offline must NOT sink an otherwise-clean boundary (advisory only)
  CS_PORCELAIN='' CS_UPSTREAM="$(printf '0\t0')" CS_AGENTMEM='' CS_STATE='none' CS_BOARD=offline \
    vex 0 "proofs 1–3 pass, proof 4 advisory unknown → still CLEAR-SAFE (exit 0)"
  unset CS_PORCELAIN CS_UPSTREAM CS_AGENTMEM CS_STATE CS_BOARD

  if [ "$failures" -eq 0 ]; then printf "%b✓ self-test passed (19 rows)%b\n" "$green" "$reset"; return 0
  else printf "%b✗ self-test: %d row(s) failed%b\n" "$red" "$failures" "$reset"; return 1; fi
}

case "${1:-}" in
  --self-test) self_test ;;
  -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
  "") run_report ;;
  *) printf "unknown argument: %s (supported: --self-test)\n" "$1" >&2; exit 2 ;;
esac
