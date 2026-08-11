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
#   branch<TAB><order> | trailer<TAB><issue#> | exempt<TAB><reason> | unlinked
# GENUINE linkage (branch, then trailer) wins over an exemption, so a stray [no-board] mention cannot
# mask real linkage. Patterns are ANCHORED — the [no-board] marker must be a trailer (line start), and
# Board/Refs must be a word (leading boundary) — so prose like "rework the dashboard #7" or a commit that
# merely *describes* [no-board] does NOT count as linkage (the false-PASS holes CORRECTNESS caught).
# Pure function (no git/gh) so --self-test can drive it with fixtures.
classify_linkage() {
  local branch="$1" msgs="$2" m
  # 1) pipeline/NNNN[.SSS]{-,/}... branch name self-declares linkage.
  if printf '%s' "$branch" | grep -qE '^pipeline/[0-9]{4}(\.[0-9]{3})?[-/]'; then
    printf 'branch\t%s\n' "$(printf '%s' "$branch" | grep -oE '[0-9]{4}(\.[0-9]{3})?' | head -1)"; return
  fi
  # 2) a Board:/Refs #<n> trailer — leading word boundary so "dashboard #7"/"clipboard #12" do NOT match.
  m="$(printf '%s\n' "$msgs" | grep -oiE '(^|[^[:alnum:]])(Board|Refs):?[[:space:]]*#[0-9]+' | grep -oE '#[0-9]+' | tr -d '#' | head -1)"
  if [ -n "$m" ]; then printf 'trailer\t%s\n' "$m"; return; fi
  # 3) a [no-board] exemption — anchored to a line start (a trailer), not a prose mention of the marker.
  m="$(printf '%s\n' "$msgs" | grep -iE '^[[:space:]]*\[no-board\]:' | head -1)"
  if [ -n "$m" ]; then
    printf 'exempt\t%s\n' "$(printf '%s' "$m" | sed -E 's/^[[:space:]]*\[no-board\]:[[:space:]]*//I; s/[[:space:]]*$//')"; return
  fi
  printf 'unlinked\n'
}

# best-effort: is issue <n> a real issue on this repo? echo one of confirmed|absent|unknown.
# BL_EXISTS overrides for --self-test; otherwise a read-only `gh issue view` pinned to the origin repo.
verify_issue_exists() {
  local n="$1" out rc repo
  [ -n "${BL_EXISTS:-}" ] && { echo "$BL_EXISTS"; return; }
  [ -n "${BL_OFFLINE:-}" ] && { echo unknown; return; }
  command -v gh >/dev/null 2>&1 || { echo unknown; return; }
  repo="${BL_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)}"
  [ -n "$repo" ] && out="$(gh issue view "$n" --repo "$repo" --json state,title 2>&1)" || out="$(gh issue view "$n" --json state,title 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then echo confirmed; return; fi
  # a definitive "no such issue" is a real defect; anything else (auth/network) is unknown → advisory.
  printf '%s' "$out" | grep -qiE 'could not resolve|no issues? found|does not exist' && { echo absent; return; }
  echo unknown
}

# report_verdict <verdict> <what-was-checked> : print the outcome, return 0 pass / 1 fail.
# Shared by the pre-push gate (run_gate) and the CI backstop (pr_body_gate) — one decision, two callers.
report_verdict() {
  local verdict="$1" what="$2" kind arg
  kind="${verdict%%$'\t'*}"; arg="${verdict#*$'\t'}"
  case "$kind" in
    exempt)
      [ -z "$arg" ] && { fail "[no-board] with no reason — exemptions must state why"; return 1; }
      pass "exempt via [no-board] — logged, not silent"; note "reason: $arg"; return 0 ;;
    branch)
      pass "linked by $what (board order $arg)"; return 0 ;;
    trailer)
      case "$(verify_issue_exists "$arg")" in
        confirmed) pass "linked to issue #$arg (verified on GitHub)";;
        absent)    fail "declares 'Board/Refs #$arg' but no such issue exists — fix the reference"; return 1;;
        unknown)   pass "linked to issue #$arg"; note "existence unverified (gh offline/unavailable) — advisory";;
      esac
      return 0 ;;
    *)
      fail "no board linkage found in $what"
      note "declare it: a 'Board: #<issue>' or 'Refs #<issue>' trailer, a 'pipeline/NNNN-*' branch,"
      note "or — trivial work only — a '[no-board]: <reason>' marker. See CLAUDE.md → BOARD LINKAGE."
      return 1 ;;
  esac
}

# run_gate — the PRE-PUSH gate: inspects the current feature branch's name + commit messages.
run_gate() {
  local branch default range msgs
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
  report_verdict "$(classify_linkage "$branch" "$msgs")" "branch name '$branch'"
}

# pr_body_gate <file> — the CI BACKSTOP: inspects a PR body (and the head ref via BL_BRANCH if set).
# Reuses the same classification, so pre-push and CI can never disagree on what "linked" means.
pr_body_gate() {
  local file="${1:-}" body what="the PR body"
  { [ -n "$file" ] && [ -f "$file" ]; } || { fail "PR body file not found: ${file:-<none>}"; return 2; }
  body="$(cat "$file")"
  printf "%b%s%b\n" "$bold" "Board-linkage CI backstop — PR body" "$reset"
  # if linkage comes from the head ref (BL_BRANCH), name that in the message, not "the PR body".
  printf '%s' "${BL_BRANCH:-}" | grep -qE '^pipeline/[0-9]{4}' && what="head branch '${BL_BRANCH}'"
  report_verdict "$(classify_linkage "${BL_BRANCH:-}" "$body")" "$what"
}

# ── self-test: exercise the four acceptance rows via fixtures (PLAN 0066.002) ────────────────────────
self_test() {
  local failures=0
  # HERMETIC: clear any ambient BL_* so a caller's env (e.g. CI sets BL_BRANCH/BL_OFFLINE for the live
  # run) cannot leak into a fixture and flip its verdict. Each row sets exactly what it needs. The CI
  # dogfood caught this: BL_BRANCH leaked into the body-only rows and turned a FAIL into a PASS.
  unset BL_BRANCH BL_MSGS BL_DEFAULT BL_OFFLINE BL_EXISTS BL_REPO
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
  # over-match holes CORRECTNESS caught — these must NOT count as linkage:
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="fix: rework the dashboard #7 layout" \
    check 1 "prose 'dashboard #7' is NOT a Board/Refs trailer → FAIL"
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="docs: describe the [no-board]: <reason> convention" \
    check 1 "a mid-line mention of [no-board] is NOT an exemption → FAIL"
  # genuine linkage wins over a stray marker mention (precedence branch/trailer > exempt):
  BL_OFFLINE=1 BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="feat: x"$'\n\n'"Board: #9"$'\n'"aside: the [no-board]: hatch exists" \
    check 0 "a real Board: trailer wins over a stray [no-board] mention → PASS"
  # online existence check (BL_EXISTS override stands in for gh):
  BL_EXISTS=confirmed BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="feat: x"$'\n\n'"Board: #284" \
    check 0 "trailer + issue confirmed on GitHub → PASS"
  BL_EXISTS=absent BL_DEFAULT=main BL_BRANCH=feat/x BL_MSGS="feat: x"$'\n\n'"Board: #999999" \
    check 1 "trailer + issue absent on GitHub → FAIL"
  # --pr-body CI-backstop mode (PLAN 0066.004): classify a PR body file.
  check_body() { # <expected-exit> <label> <body-text>
    local want="$1" label="$2" bodyfile got
    bodyfile="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/bl-body.$$")"; printf '%s' "$3" > "$bodyfile"
    ( BL_OFFLINE=1 pr_body_gate "$bodyfile" ) >/dev/null 2>&1; got=$?; rm -f "$bodyfile"
    if [ "$got" -eq "$want" ]; then printf "  %b✓%b %s\n" "$green" "$reset" "$label"
    else printf "  %b✗ %s (want exit %s, got %s)%b\n" "$red" "$label" "$want" "$got" "$reset"; failures=$((failures+1)); fi
  }
  check_body 0 "PR body 'Board: #284' → PASS" "## Summary"$'\n'"Board: #284"
  check_body 0 "PR body '[no-board]: docs typo' → PASS" "fix a typo"$'\n\n'"[no-board]: one-word docs typo"
  check_body 1 "PR body with no linkage → FAIL" "## Summary"$'\n'"just some prose about the dashboard #5"
  if [ "$failures" -eq 0 ]; then printf "%b✓ self-test passed (16 rows)%b\n" "$green" "$reset"; return 0
  else printf "%b✗ self-test: %d row(s) failed%b\n" "$red" "$failures" "$reset"; return 1; fi
}

case "${1:-}" in
  --self-test) self_test ;;
  --pr-body) pr_body_gate "${2:-}" ;;
  -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
  "") run_gate ;;
  *) printf "unknown argument: %s (supported: --self-test, --pr-body <file>)\n" "$1" >&2; exit 2 ;;
esac
