#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# verify-board-linkage.sh — EPIC 0066 / PLAN 0066.002 — the board-linkage pre-push gate.
#
# Fails a FEATURE branch that neither declares a board item nor logs a trivial-work exemption, so
# substantive work cannot ship off-board (the context-routing initiative, PRs #269–#281, did — see
# EPIC 0066). The convention it enforces is defined in CLAUDE.md → "BOARD LINKAGE":
#
#   • Linked   — a `Board: #<n>` OR `Refs #<n>` trailer in a commit/PR, OR a `pipeline/NNNN-*` branch.
#   • Exempt   — a `[no-board]: <reason>` marker (trivial work only; the reason is LOGGED, not silent).
#
# Deterministic + offline for the DECLARATION check (this is the block). Best-effort + online (via `gh`)
# for whether the declared issue EXISTS on the project — degrading to an advisory note when gh/network is
# absent, never a false PASS by silence. No-ops on the default branch / detached HEAD (linkage is a
# per-feature-branch contract). House style mirrors verify-routing.sh (section/pass/fail, exit 0|1).
#
# Test hooks (used by --self-test): BL_BRANCH, BL_MSGS, BL_DEFAULT override git; BL_OFFLINE=1 skips gh.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; yellow=""; bold=""; dim=""; reset=""; }
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; }
warn() { printf "  %b⚠ %s%b\n" "$yellow" "$1" "$reset"; }
note() { printf "    %b%s%b\n" "$dim" "$1" "$reset"; }

# classify_linkage <branch> <commit-messages-blob> : echo one of
#   exempt<TAB><reason> | branch<TAB><order> | trailer<TAB><issue#> | unlinked
# Pure function (no git/gh) so --self-test can drive it with fixtures.
classify_linkage() {
  local branch="$1" msgs="$2" m
  # 1) exemption wins if present (trivial work, logged).
  m="$(printf '%s\n' "$msgs" | grep -oiE '\[no-board\]:[[:space:]]*[^|]*' | head -1)"
  if [ -n "$m" ]; then printf 'exempt\t%s\n' "$(printf '%s' "${m#*:}" | sed 's/^[[:space:]]*//')"; return; fi
  # 2) pipeline/NNNN[-...] or pipeline/NNNN.SSS-... branch name self-declares linkage.
  if printf '%s' "$branch" | grep -qE '^pipeline/[0-9]{4}(\.[0-9]{3})?[-/]'; then
    printf 'branch\t%s\n' "$(printf '%s' "$branch" | grep -oE '[0-9]{4}(\.[0-9]{3})?' | head -1)"; return
  fi
  # 3) Board: #<n> or Refs #<n> trailer in any commit.
  m="$(printf '%s\n' "$msgs" | grep -oiE '(Board|Refs):?[[:space:]]*#[0-9]+' | grep -oE '#[0-9]+' | tr -d '#' | head -1)"
  if [ -n "$m" ]; then printf 'trailer\t%s\n' "$m"; return; fi
  printf 'unlinked\n'
}

# best-effort: is issue <n> a real EPIC/PLAN on this repo? echo one of confirmed|absent|unknown
verify_issue_exists() {
  local n="$1"
  [ -n "${BL_OFFLINE:-}" ] && { echo unknown; return; }
  command -v gh >/dev/null 2>&1 || { echo unknown; return; }
  local out rc
  out="$(gh issue view "$n" --json state,title 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then echo confirmed; return; fi
  # a definitive "no such issue" is a real defect; anything else (auth/network) is unknown.
  printf '%s' "$out" | grep -qiE 'could not resolve|not found|no issue' && { echo absent; return; }
  echo unknown
}

run_gate() {
  local branch default range msgs verdict kind arg
  printf "%b%s%b\n" "$bold" "Board-linkage pre-push gate — EPIC 0066" "$reset"
  branch="${BL_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')}"
  default="${BL_DEFAULT:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}"
  [ -z "$default" ] && default="main"

  if [ -z "$branch" ] || [ "$branch" = "HEAD" ] || [ "$branch" = "$default" ]; then
    pass "on '$branch' — linkage is a per-feature-branch contract; nothing to check"
    return 0
  fi

  if [ -n "${BL_MSGS:-}" ]; then
    msgs="$BL_MSGS"
  else
    range="$default..HEAD"
    git rev-parse --verify -q "origin/$default" >/dev/null 2>&1 && range="origin/$default..HEAD"
    msgs="$(git log --format='%B' "$range" 2>/dev/null)"
  fi

  verdict="$(classify_linkage "$branch" "$msgs")"
  kind="${verdict%%$'\t'*}"; arg="${verdict#*$'\t'}"

  case "$kind" in
    exempt)
      pass "exempt via [no-board] — logged, not silent"
      note "reason: ${arg:-<none given>}"
      [ -z "$arg" ] && { warn "[no-board] with no reason — exemptions must state why"; return 1; }
      return 0 ;;
    branch)
      pass "linked by branch name '$branch' (board order $arg)"
      return 0 ;;
    trailer)
      case "$(verify_issue_exists "$arg")" in
        confirmed) pass "linked to issue #$arg (verified on GitHub)";;
        absent)    fail "declares 'Board/Refs #$arg' but no such issue exists — fix the reference"; return 1;;
        unknown)   pass "linked to issue #$arg"; note "existence unverified (gh offline/unavailable) — advisory";;
      esac
      return 0 ;;
    *)
      fail "no board linkage on branch '$branch'"
      note "declare it: a 'Board: #<issue>' or 'Refs #<issue>' trailer, a 'pipeline/NNNN-*' branch,"
      note "or — trivial work only — a '[no-board]: <reason>' marker. See CLAUDE.md → BOARD LINKAGE."
      return 1 ;;
  esac
}

# ── self-test: exercise the four acceptance rows via fixtures (PLAN 0066.002) ────────────────────────
self_test() {
  local failures=0
  check() { # <expected-exit> <label> ; env already set
    local want="$1" label="$2" got
    ( run_gate ) >/dev/null 2>&1; got=$?
    if [ "$got" -eq "$want" ]; then printf "  %b✓%b %s\n" "$green" "$reset" "$label"
    else printf "  %b✗ %s (want exit %s, got %s)%b\n" "$red" "$label" "$want" "$got" "$reset"; failures=$((failures+1)); fi
  }
  printf "%b%s%b\n" "$bold" "verify-board-linkage.sh --self-test" "$reset"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="fix: a thing"$'\n\n'"Board: #123" \
    check 0 "trailer 'Board: #123' → PASS"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="fix: a thing"$'\n\n'"Refs #123" \
    check 0 "trailer 'Refs #123' → PASS"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=pipeline/0066-board-linkage-gate BL_MSGS="chore: x" \
    check 0 "branch 'pipeline/0066-*' → PASS"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=pipeline/0066.002-gate BL_MSGS="chore: x" \
    check 0 "composite branch 'pipeline/0066.002-*' → PASS"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="typo fix"$'\n\n'"[no-board]: one-line typo in a comment" \
    check 0 "exemption '[no-board]: <reason>' → PASS"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="fix: a thing with no linkage at all" \
    check 1 "no linkage, no exemption → FAIL"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="wip"$'\n\n'"[no-board]:" \
    check 1 "'[no-board]:' with no reason → FAIL"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=main BL_MSGS="anything" \
    check 0 "on default branch → no-op PASS"
  if [ "$failures" -eq 0 ]; then printf "%b✓ self-test passed (8 rows)%b\n" "$green" "$reset"; return 0
  else printf "%b✗ self-test: %d row(s) failed%b\n" "$red" "$failures" "$reset"; return 1; fi
}

case "${1:-}" in
  --self-test) self_test ;;
  -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
  "") run_gate ;;
  *) printf "unknown argument: %s (supported: --self-test)\n" "$1" >&2; exit 2 ;;
esac
