#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — tally the number of TIMES an adversarial reviewer
# caught something. Increments ~/.claude/state/adversarial-catches.total once per
# distinct catching report (deduped by content hash, so re-writing the same report
# never double-counts; a fresh review with new findings counts again).
#
# A "catch" = an adversarial-review artifact whose verdict is not PASS, or that
# lists at least one CRITICAL/HIGH/MEDIUM finding. Always exits 0; never blocks.
# Shipped by the `concierge` plugin and wired via hooks/hooks.json — works on any
# machine once the plugin is installed; feeds the status line's ⚔ caught widget.
set -uo pipefail

payload=""
[ -t 0 ] || payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

# --- which file did the tool touch? (jq, with a grep fallback) ---
fp=""
if command -v jq >/dev/null 2>&1; then
  fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
fi
[ -n "$fp" ] || fp="$(printf '%s' "$payload" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')"
[ -n "$fp" ] || exit 0

# --- is it an adversarial-review artifact? ---
# The artifact-name set is defined ONCE in statusline/adversarial-artifacts.lst (one glob
# per line) so new reviewers widen the HUD by editing data, not this script (P1-13).
bn="$(basename "$fp")"
lst="$(dirname "${BASH_SOURCE[0]}")/adversarial-artifacts.lst"
matched=0
if [ -r "$lst" ]; then
  while IFS= read -r glob || [ -n "$glob" ]; do
    glob="${glob%%#*}"                                   # strip trailing comments
    glob="$(printf '%s' "$glob" | tr -d '[:space:]')"    # trim whitespace
    [ -n "$glob" ] || continue
    case "$bn" in $glob) matched=1; break ;; esac
  done < "$lst"
else
  # Fallback to the historic built-in set if the list is somehow unreadable.
  case "$bn" in
    PR_REVIEW.md|I2P_REVIEW.md|SECURITY-REPORT.md|PII-REPORT.md|*_INSPECTION_REPORT.md) matched=1 ;;
  esac
fi
[ "$matched" -eq 1 ] || exit 0
[ -f "$fp" ] || exit 0

# --- did it CATCH something? (non-PASS verdict, or a real finding) ---
caught=0
grep -qiE 'verdict[^A-Za-z]*(BLOCK|NEEDS_REVISION|REVIEW)' "$fp" && caught=1
grep -qE '\b(CRITICAL|HIGH|MEDIUM)\b' "$fp" && caught=1
[ "$caught" -eq 1 ] || exit 0

state="${HOME}/.claude/state"
mkdir -p "$state" 2>/dev/null || exit 0
seen="${state}/adversarial-catches.seen"
total="${state}/adversarial-catches.total"
touch "$seen" "$total" 2>/dev/null || exit 0

# --- dedup this exact report by content hash ---
h="$( { sha1sum "$fp" 2>/dev/null || md5sum "$fp" 2>/dev/null; } | awk '{print $1}')"
[ -n "$h" ] || exit 0
grep -qx "$h" "$seen" 2>/dev/null && exit 0
printf '%s\n' "$h" >> "$seen"

cur="$(cat "$total" 2>/dev/null)"; case "$cur" in (''|*[!0-9]*) cur=0 ;; esac
printf '%s\n' "$((cur + 1))" > "${total}.tmp.$$" 2>/dev/null && mv -f "${total}.tmp.$$" "$total" 2>/dev/null || rm -f "${total}.tmp.$$" 2>/dev/null
exit 0
