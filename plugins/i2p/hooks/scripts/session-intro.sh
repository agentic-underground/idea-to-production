#!/usr/bin/env bash
# i2p SessionStart hook — introduce the marketplace once per session.
#
# Emits a user-visible one-liner (systemMessage) plus context for the model
# (additionalContext) so it can give a brief conversational intro if the user
# has not been oriented yet. Always prints valid JSON; never blocks a session.
#
# Docs: https://code.claude.com/docs/en/hooks.md (SessionStart output schema)
set -euo pipefail

# Drain any hook input on stdin (we don't need it) so we never hang on a pipe.
if [ ! -t 0 ]; then cat >/dev/null 2>&1 || true; fi

read -r -d '' MSG <<'EOF' || true
💡 idea-to-production is online — type /i2p:help to browse what you can do (or /i2p:flow to see the pipeline, /i2p:review for a full review).
EOF

read -r -d '' CTX <<'EOF' || true
The idea-to-production marketplace (front door plugin "i2p") is active. If the user has not yet been oriented this session, give a one-line conversational intro and mention that /i2p:help browses every installed capability. Do not repeat this on later turns.
EOF

# jq builds correctly-escaped JSON; fall back to a static payload if jq is absent.
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg msg "$MSG" --arg ctx "$CTX" '{
    systemMessage: $msg,
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
else
  printf '{"systemMessage":"💡 idea-to-production is online — type /i2p:help to browse what you can do.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"The idea-to-production marketplace is active; mention /i2p:help once if the user is not yet oriented."}}\n'
fi
