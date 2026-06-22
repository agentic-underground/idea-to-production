#!/usr/bin/env bash
# register-with-fleet.sh — register THIS repo's v2 pipeline with the external FLEET
# continuous-delivery engine, so its hourly ticker can drain docs/roadmap/ and the engine can answer
# "what's on the roadmap" (/pipeline:status). Idempotent jq-merge into the per-machine registry — it
# never clobbers another project's entry.
#
# The registry is machine-local (~/.claude/pipeline-projects.json), NOT committed; this script is the
# reproducible, version-controlled way to (re)create i2p's entry on any box. The field values mirror the
# governance mapping in .foundry/governance.md (direct-merge → delivery:pr + admin_merge:true).
#
# Usage:  bash scripts/register-with-fleet.sh            # register/update
#         PIPELINE_DRY_RUN=1 bash scripts/register-with-fleet.sh   # print the entry, don't write
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
id="idea-to-production"
reg="${HOME}/.claude/pipeline-projects.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required (the registry is JSON)"; exit 1; }

# The project entry — standard v2 fields (no bespoke engine field; the FOUNDRY bridge rides in each
# PLAN's '## Construction process', which the engine's plan-build prompt reads). direct-merge governance
# → delivery:pr + admin_merge:true (the engine admin-merges its own PR). branch_prefix/merge_target/
# remote match this repo; forbidden_mutation guards the manifest the engine rewrites in place.
entry="$(jq -n --arg repo "$repo" '{
  repo: $repo,
  manifest: "docs/roadmap/.pipeline.md",
  epic_glob: "docs/roadmap/EPIC_{order}.md",
  verify: ".pipeline/verify",
  branch_prefix: "pipeline",
  merge_target: "main",
  remote: "origin",
  forbidden_mutation: "docs/roadmap/.pipeline.md",
  delivery: "pr",
  admin_merge: true,
  merge_mode: "merge",
  priority: 0
}')"

if [ "${PIPELINE_DRY_RUN:-0}" = 1 ]; then
  printf 'would register %s →\n%s\n' "$id" "$entry"
  exit 0
fi

mkdir -p "$(dirname "$reg")"
[ -f "$reg" ] || echo '{"version":1,"projects":{}}' > "$reg"
tmp="$(mktemp)"
jq --arg id "$id" --argjson p "$entry" '.projects[$id] = $p' "$reg" > "$tmp" && mv "$tmp" "$reg"
echo "registered '$id' in $reg"
