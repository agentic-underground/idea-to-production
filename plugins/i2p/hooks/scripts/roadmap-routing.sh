#!/usr/bin/env bash
# roadmap-routing.sh — SessionStart hook (i2p front door). Emits the CANONICAL roadmap-read
# routing rule: "what's on the roadmap" is answered from the FLEET v2 pipeline (docs/roadmap/),
# NOT the legacy .i2p/roadmap/ tree. This rule lives in i2p (a surviving plugin) so it outlives
# the retirement of the flow plugin, whose onboard hook previously carried a (now stale)
# render_roadmap rule pointed at the legacy tree.
#
# PHASE-GATED (EPIC 0067 / PLAN 0067.002 — context-population RFC §3.3, EARS-002). This 192-word
# rule used to fire on EVERY SessionStart in every phase, inflating the phase-INDEPENDENT always-on
# core. It now emits ONLY in the roadmap-relevant phase (DELIVER — the phase that owns roadmapper +
# the pipeline). Out of that phase (or when the phase is unknown), it stays SILENT: strict
# single-phase population (under-loading is safe — the agent can still read docs/roadmap/ on demand,
# and the phase pointer names how to switch focus). So it is no longer counted against the §3.1
# always-on budget.
#
# Non-blocking, fail-silent, always exits 0 (verify-prereqs hook contract). Touches nothing in
# the user's repo.
set -uo pipefail

# Drain the SessionStart payload; we resolve the active phase from the env, not stdin.
[ -t 0 ] || cat >/dev/null 2>&1 || true

# ── Phase gate: emit only in the roadmap-relevant phase (DELIVER). ───────────────────────────────
# ROADMAP_ROUTING_PHASES lists the phase(s) in which the roadmap-read rule is in-phase; overridable
# via the env var (used by the behaviour test). The shared resolver (active-phase.sh) reads
# .i2p/focus → .i2p/lifecycle.json.
ROADMAP_ROUTING_PHASES="${ROADMAP_ROUTING_PHASES:-DELIVER}"
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
# shellcheck source=/dev/null
. "${HOOK_DIR}/active-phase.sh" 2>/dev/null || true
active=""
if command -v i2p_active_phase >/dev/null 2>&1; then
  active="$(i2p_active_phase "${CLAUDE_PROJECT_DIR:-$PWD}")"
fi
case " ${ROADMAP_ROUTING_PHASES} " in
  *" ${active:-__none__} "*) ;;   # in a roadmap-relevant phase → fall through and emit
  *) exit 0 ;;                     # out of phase / unknown → silent (strict single-phase)
esac

ROUTING="To answer \"what's on the roadmap\" or read roadmap items, use the FLEET v2 pipeline at docs/roadmap/ — the AUTHORITATIVE, ~0-token path. The 'pipeline' plugin is an EXTERNAL FLEET marketplace plugin (installed separately, like token-fairness; not shipped in this marketplace): if it is present, answer from its deterministic surface (/pipeline:status, or pipeline-cron.sh status/next, pipeline-report). If it is NOT installed: for a BOARD-mode repo (registry board:github_project — e.g. THIS repo) the GitHub Project (v2) board is AUTHORITATIVE for state — read status from the board (the docs/roadmap/EPIC_NNNN.md/PLAN_NNNN.md docs are the build instructions, NOT the state, and there is no .pipeline.md). For a MANIFEST-mode (local_file) repo, parse the artifacts STRUCTURALLY by their leading-| columns (never as prose): (a) the docs/roadmap/.pipeline.md manifest — columns 'order | epic | state | constructs | branch', one row per EPIC, for top-level state; then (b) each EPIC_NNNN.md's section-scoped '## Plans' table — columns 'order | plan | state' — for that EPIC's slices. order is always 4 digits. The .i2p/roadmap/ tree is LEGACY history (its backlog is migrating into the v2 pipeline) — surface it only when explicitly asked for history, clearly labelled, never as the live roadmap."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "$ROUTING" \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  esc="$ROUTING"; esc="${esc//\\/\\\\}"; esc="${esc//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
