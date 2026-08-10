#!/usr/bin/env bash
# focus-routing.sh — SessionStart hook (i2p front door). If the repo declares a FOCUS (.i2p/focus),
# broadcast it so the agent treats out-of-phase skills as dormant — the C2 phase-gate of the
# context-routing layer (docs/guide/context-routing.md §4). Best-effort STEERING, not a hard gate.
#
# Non-blocking, fail-silent, always exits 0 (verify-prereqs hook contract). Touches nothing in the repo.
# No .i2p/focus → no injection (absent file = no gate), exactly like today's behaviour.
set -uo pipefail

# Drain the SessionStart payload; we read the project dir from the env, not stdin.
[ -t 0 ] || cat >/dev/null 2>&1 || true

FOCUS="${CLAUDE_PROJECT_DIR:-.}/.i2p/focus"
[ -f "$FOCUS" ] || exit 0

# SECURITY: this hook injects into every session's context, so it must NOT trust the file — .i2p/focus
# can be hand-edited or shipped in a cloned repo, and focus.sh's write-side validation does not protect
# this reader. Take ONLY the first whitespace-delimited token after `phase:` (a forged trailing clause
# cannot ride along), then re-validate it against the closed 9-phase allowlist. Anything else → no
# injection (fail closed on the untrusted value). An allowlisted phase is A–Z only, so no quote,
# backslash, control byte, or Unicode-whitespace payload can reach the injected string.
phase="$(awk '/^phase:/{sub(/^phase:[ \t]*/,""); print $1; exit}' "$FOCUS" 2>/dev/null | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
case " DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE " in
  *" $phase "*) ;;
  *) exit 0 ;;
esac

CTX="Active FOCUS: ${phase}. The user has declared this the active lifecycle phase for context routing. Apply the phase-gate rule: treat a skill as DORMANT iff ${phase} is NOT in (that skill's metadata.phase list ∪ {cross-cut}) — do not self-activate a dormant skill; invoke an out-of-phase skill only if the user runs its explicit /command or clearly asks for it by name. A skill with no metadata.phase is AVAILABLE (fail open). cross-cut skills are always available. This is best-effort focus, not a hard permission gate. To change or clear it: /i2p:focus <PHASE> | /i2p:focus off."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "$CTX" \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  esc="$CTX"; esc="${esc//\\/\\\\}"; esc="${esc//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
