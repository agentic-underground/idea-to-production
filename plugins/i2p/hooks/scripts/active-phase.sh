#!/usr/bin/env bash
# active-phase.sh — SOURCED helper (NOT a standalone hook). The single audited resolver of the
# active lifecycle phase for the EPIC 0067 context-population hooks (phase-pointer.sh and the
# now phase-gated roadmap-routing.sh). One copy so the untrusted-input parse cannot drift between
# the two readers.
#
# SIGNAL PRECEDENCE (docs/guide/context-population.md §3.5) — the state the marketplace already
# maintains, never a new file:
#   1. <project>/.i2p/focus         (FOCUS, primary)
#   2. <project>/.i2p/lifecycle.json .current_phase   (lifecycle, fallback)
#   3. ""                            (unknown → the caller's safe default)
#
# SECURITY: .i2p/focus is UNTRUSTED (hand-editable / shipped in a cloned repo); its write-side
# validation does not protect this reader. Take ONLY the first whitespace-delimited token after a
# line-anchored `phase:` (a forged trailing clause cannot ride along), then re-validate against the
# closed 9-phase allowlist. An allowlisted phase is A–Z only, so no quote, backslash, control byte,
# or Unicode-whitespace payload can reach the returned string. lifecycle.json is parsed only as
# validated JSON via jq. Anything outside the allowlist → "" (fail closed on the untrusted value).
# Mirrors the hardened parse in focus-routing.sh; kept identical on purpose.
#
# Usage:  . "<dir>/active-phase.sh";  phase="$(i2p_active_phase "$PROJECT_DIR")"
#         Prints the UPPERCASE phase name, or nothing if unknown/invalid. Always returns 0.

i2p_active_phase() {
  local proj="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"
  local allow=" DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE "
  local phase="" focus="${proj%/}/.i2p/focus" lf="${proj%/}/.i2p/lifecycle.json"

  # 1) FOCUS (primary) — hardened untrusted parse: first token after `phase:`, uppercased.
  if [ -f "$focus" ]; then
    phase="$(awk '/^phase:/{sub(/^phase:[ \t]*/,""); print $1; exit}' "$focus" 2>/dev/null \
      | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
  fi

  # 2) lifecycle.json (fallback) — only validated JSON, only .current_phase.
  if [ -z "$phase" ] && [ -f "$lf" ] && command -v jq >/dev/null 2>&1 && jq -e . "$lf" >/dev/null 2>&1; then
    phase="$(jq -r '.current_phase // empty' "$lf" 2>/dev/null | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
  fi

  # 3) Re-validate against the closed allowlist; anything else → unknown ("").
  case "$allow" in
    *" $phase "*) printf '%s' "$phase" ;;
    *) printf '' ;;
  esac
  return 0
}
