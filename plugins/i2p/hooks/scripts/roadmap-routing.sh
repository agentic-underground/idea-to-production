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

ROUTING="To answer \"what's on the roadmap\" or read roadmap items, use the FLEET v2 pipeline at docs/roadmap/ — the AUTHORITATIVE, ~0-token path. If the 'pipeline' plugin is installed, answer from its deterministic surface (/pipeline:status, or pipeline-cron.sh status/next, pipeline-report). Otherwise parse STRUCTURALLY (not as prose): docs/roadmap/.pipeline.md manifest rows (leading-| columns order | epic | state) plus each EPIC_NNNN.md's section-scoped '## Plans' table. The .i2p/roadmap/ tree is LEGACY history (its backlog is being migrated into the v2 pipeline) — surface it only when explicitly asked for history, clearly labelled, never as the live roadmap. Do NOT ls/cat/head docs/roadmap files to compose a status answer when the pipeline surface can return it."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "$ROUTING" \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  esc="$ROUTING"; esc="${esc//\\/\\\\}"; esc="${esc//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
