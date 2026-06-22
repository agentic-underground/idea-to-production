#!/usr/bin/env bash
# roadmap-routing.sh — SessionStart hook (i2p front door). Emits the CANONICAL roadmap-read
# routing rule every session: "what's on the roadmap" is answered from the FLEET v2 pipeline
# (docs/roadmap/), NOT the legacy .i2p/roadmap/ tree. This rule lives in i2p (a surviving plugin)
# so it outlives the retirement of the flow plugin, whose onboard hook previously carried a
# (now stale) render_roadmap rule pointed at the legacy tree.
#
# Non-blocking, fail-silent, always exits 0 (verify-prereqs hook contract). Touches nothing in
# the user's repo.
set -uo pipefail

# Drain the SessionStart payload; we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

ROUTING="To answer \"what's on the roadmap\" or read roadmap items, use the FLEET v2 pipeline at docs/roadmap/ — the AUTHORITATIVE, ~0-token path. The 'pipeline' plugin is an EXTERNAL FLEET marketplace plugin (installed separately, like token-fairness; not shipped in this marketplace): if it is present, answer from its deterministic surface (/pipeline:status, or pipeline-cron.sh status/next, pipeline-report). If it is NOT installed, parse the artifacts STRUCTURALLY by their leading-| columns (never as prose): (a) the docs/roadmap/.pipeline.md manifest — columns 'order | epic | state | constructs | branch', one row per EPIC, for top-level state; then (b) each EPIC_NNNN.md's section-scoped '## Plans' table — columns 'order | plan | state' — for that EPIC's slices. order is always 4 digits. The .i2p/roadmap/ tree is LEGACY history (its backlog is migrating into the v2 pipeline) — surface it only when explicitly asked for history, clearly labelled, never as the live roadmap."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "$ROUTING" \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  esc="$ROUTING"; esc="${esc//\\/\\\\}"; esc="${esc//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
