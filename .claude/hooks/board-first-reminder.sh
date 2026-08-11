#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# board-first-reminder.sh — SessionStart tripwire (EPIC 0066 / PLAN 0066.003).
#
# The PLAN-TIME half of the board-linkage guardrails. It catches the gap where it actually opened: the
# context-routing initiative (PRs #269–#281) drifted off-board because nothing nudged the agent to
# capture it on the board at PLANNING time — a merge-time gate would only have blocked finished work.
#
# This is best-effort STEERING (advisory), not a block — the deterministic block is the pre-push gate
# scripts/verify-board-linkage.sh (PLAN 0066.002). It emits a short board-first reminder into the
# agent's context once per session. It touches ONLY the temp dir (a dedup sentinel); it never reads or
# writes the repo, and always exits 0 (a reminder must never fail a session).
#
# Registered as a SessionStart hook by .claude/settings.json.  --self-test drives PLAN 0066.003's checks.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

emit_reminder() {
  cat <<'MSG'
📋 BOARD-FIRST (idea-to-production self-hosts its own value flow). Substantive work in this repo is
captured on the GitHub Project board (project #4 "idea-to-production — pipeline") BEFORE branching — an
EPIC + a PLAN per slice, via /deliver:roadmapper — so no initiative ships off-board (see EPIC 0066).
Each branch then declares its board item — a `Board: #<n>` or `Refs #<n>` trailer, or a `pipeline/NNNN-*`
branch — or logs a `[no-board]: <reason>` exemption for trivial work. The pre-push gate
`scripts/verify-board-linkage.sh` enforces this; see CLAUDE.md → BOARD LINKAGE.
MSG
}

# once-per-session: dedup on the SessionStart session_id (best-effort; emit anyway if unparseable).
run_hook() {
  local payload="" sid tmp sentinel
  [ -t 0 ] || payload="$(cat 2>/dev/null || true)"
  sid="$(printf '%s' "$payload" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
  sid="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9-')"   # bound the sentinel filename to safe chars
  if [ -n "$sid" ]; then
    tmp="${TMPDIR:-/tmp}"; sentinel="$tmp/.claude-board-first-${sid}"
    [ -e "$sentinel" ] && exit 0          # already reminded this session
    : > "$sentinel" 2>/dev/null || true    # temp only — never the repo
  fi
  emit_reminder
  exit 0
}

# ── self-test (PLAN 0066.003): emits the reminder + the convention, exits 0, mutates nothing ─────────
self_test() {
  local out rc fail=0
  out="$(emit_reminder)"; rc=$?
  printf "%s\n" "verify board-first reminder"
  chk() { if printf '%s' "$out" | grep -qiF -- "$1"; then printf "  ✓ mentions: %s\n" "$1"; else printf "  ✗ MISSING: %s\n" "$1"; fail=1; fi; }
  if [ "$rc" -eq 0 ]; then printf "  ✓ emits, exit 0\n"; else printf "  ✗ non-zero exit\n"; fail=1; fi
  chk "BOARD-FIRST"
  chk "/deliver:roadmapper"
  chk "Board: #"
  chk "pipeline/NNNN-"
  chk "[no-board]:"
  chk "verify-board-linkage.sh"
  # inertness: a dedup run writes only to TMPDIR, never the repo (asserted here by construction — the
  # only write is the sentinel under \$TMPDIR; this harness has no repo-path write in emit or run).
  if [ "$fail" -eq 0 ]; then printf "✓ self-test passed\n"; return 0; else printf "✗ self-test failed\n"; return 1; fi
}

case "${1:-}" in
  --self-test) self_test ;;
  -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
  *) run_hook ;;
esac
