#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# clear-safe-reminder.sh — SessionStart injector for the CLEAR-SAFE covenant (EPIC 0071 / PLAN 0071.001).
#
# CLEAR-SAFE is a standing operating awareness alongside KAIZEN: EVERY PLAN/EPIC boundary must be a
# PROVEN-safe checkpoint the user can `/clear` and `resume` from. At each completion the agent proves —
# never merely claims — the four proofs (tree clean · upstream synced · learnings committed · 3-layer
# STATE current), states CLEAR-SAFE (or NOT, and fixes it), says what `resume` will do, and gives an
# HONEST fan-out advisement for the next items. Full canon: the covenant doc referenced below.
#
# Best-effort STEERING (advisory), not a block — the deterministic proof is scripts/verify-clear-safe.sh
# (EPIC 0071 / CS2). It emits the covenant into the agent's context once per session, touches ONLY the
# temp dir (a dedup sentinel), never reads or writes the repo, and always exits 0 (a reminder must never
# fail a session). Registered as a SessionStart hook by .claude/settings.json. --self-test drives CS1's checks.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

emit_reminder() {
  cat <<'MSG'
✅ CLEAR-SAFE (idea-to-production, alongside KAIZEN). EVERY PLAN/EPIC boundary is a PROVEN-safe
checkpoint the user can `/clear` and `resume` from. At each completion, PROVE — never merely claim —
the four: ① tree clean (`git status --porcelain` empty) ② upstream synced (`git rev-list --left-right
--count @{u}...HEAD` = 0 0) ③ learnings committed (`.claude/agent-memory/` clean) ④ 3-layer STATE
current (resume-memory names the next item; board matches). Then say CLEAR-SAFE (or NOT + fix it), what
`resume` will do, and an HONEST fan-out advisement — the next N items parallelize ONLY IF no-dependency
+ disjoint-files + serialized-GitHub-writes. `resume the next N in a workflow` = build them parallel
(worktree-isolated) → review → SERIALIZED merge + STATE update. Canon: plugins/deliver/knowledge/protocols/clear-safe.md
MSG
}

# once-per-session: dedup on the SessionStart session_id (best-effort; emit anyway if unparseable).
run_hook() {
  local payload="" sid tmp sentinel
  [ -t 0 ] || payload="$(cat 2>/dev/null || true)"
  sid="$(printf '%s' "$payload" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
  sid="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9-')"   # bound the sentinel filename to safe chars
  if [ -n "$sid" ]; then
    tmp="${TMPDIR:-/tmp}"; sentinel="$tmp/.claude-clear-safe-${sid}"
    [ -e "$sentinel" ] && exit 0          # already reminded this session
    : > "$sentinel" 2>/dev/null || true    # temp only — never the repo
  fi
  emit_reminder
  exit 0
}

# ── self-test (CS1): emits the covenant + the load-bearing terms, exits 0, mutates nothing ───────────
self_test() {
  local out rc fail=0
  out="$(emit_reminder)"; rc=$?
  printf "%s\n" "verify CLEAR-SAFE reminder"
  chk() { if printf '%s' "$out" | grep -qiF -- "$1"; then printf "  ✓ mentions: %s\n" "$1"; else printf "  ✗ MISSING: %s\n" "$1"; fail=1; fi; }
  if [ "$rc" -eq 0 ]; then printf "  ✓ emits, exit 0\n"; else printf "  ✗ non-zero exit\n"; fail=1; fi
  chk "CLEAR-SAFE"
  chk "/clear"
  chk "resume"
  chk "tree clean"
  chk "learnings committed"
  chk "fan-out"
  chk "resume the next N in a workflow"
  chk "clear-safe.md"
  # inertness: a dedup run writes only to \$TMPDIR, never the repo (asserted by construction — the only
  # write is the sentinel under \$TMPDIR; neither emit nor run has a repo-path write).
  if [ "$fail" -eq 0 ]; then printf "✓ self-test passed\n"; return 0; else printf "✗ self-test failed\n"; return 1; fi
}

case "${1:-}" in
  --self-test) self_test ;;
  -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
  *) run_hook ;;
esac
