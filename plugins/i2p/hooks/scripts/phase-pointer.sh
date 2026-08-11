#!/usr/bin/env bash
# phase-pointer.sh — SessionStart hook (i2p front door). The phase-aware CONTEXT POINTER of
# EPIC 0067 (context-population RFC, docs/guide/context-population.md §3.2). It replaces the old
# session-intro context block (EARS-003: its "i2p is active · /i2p:help" role is subsumed here).
#
# WHAT IT EMITS — one thin, static-shape block naming: (a) that i2p is active, (b) the active phase,
# (c) what is loadable for that phase (named as a set, not inlined), (d) how to switch focus / browse.
# It is one of the TWO phase-independent always-on injections (KAIZEN is the other); it stays ≤ 60
# words and static in shape so prompt-caching keeps it effectively free. The §3.1 budget
# (KAIZEN + pointer ≤ ~420 words) is enforced by the leanness gate (PLAN 0067.004).
#
# ACTIVE PHASE — resolved by the shared helper active-phase.sh (.i2p/focus → .i2p/lifecycle.json →
# unknown). UNKNOWN phase → the SAFE DEFAULT (EARS-004): the pointer still emits (i2p active + how to
# set focus + /i2p:help), but nothing phase-specific is named — never a phase-specific dump.
#
# Non-blocking, fail-silent, always exits 0 (verify-prereqs hook contract). Touches nothing in the repo.
# Docs: https://code.claude.com/docs/en/hooks.md (SessionStart output schema)
set -uo pipefail

# Drain any SessionStart payload on stdin; we read the project dir from the env, not stdin.
[ -t 0 ] || cat >/dev/null 2>&1 || true

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
# shellcheck source=/dev/null
. "${HOOK_DIR}/active-phase.sh" 2>/dev/null || true

phase=""
if command -v i2p_active_phase >/dev/null 2>&1; then
  phase="$(i2p_active_phase "${CLAUDE_PROJECT_DIR:-$PWD}")"
fi

if [ -n "$phase" ]; then
  CTX="i2p active · phase = ${phase}. Loadable now: the ${phase}-phase skills and knowledge (those whose metadata.phase includes ${phase}, plus cross-cut); other phases stay dormant. /i2p:focus <phase> to switch · /i2p:help to browse · /i2p:flow for the pipeline."
else
  CTX="i2p active · no phase set. Nothing phase-specific auto-loads (safe default). /i2p:focus <phase> to set the active lifecycle phase · /i2p:help to browse every capability · /i2p:flow to see the pipeline."
fi

MSG="💡 idea-to-production is online — /i2p:help to browse, /i2p:flow for the pipeline, /i2p:review for a full review."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg msg "$MSG" --arg ctx "$CTX" '{
    systemMessage: $msg,
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $ctx }
  }'
else
  esc="$CTX"; esc="${esc//\\/\\\\}"; esc="${esc//\"/\\\"}"
  m="$MSG";  m="${m//\\/\\\\}";    m="${m//\"/\\\"}"
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$m" "$esc"
fi
exit 0
