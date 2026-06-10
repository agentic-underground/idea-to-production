#!/usr/bin/env bash
# rerun.sh — headlessly re-run every adapted graph the adapter classified 'rerunnable', on the live rig, and
# journal the outcome. The adapted graphs are mined community/official API graphs with their assets remapped
# to the rig (NOT the allowlisted templates) — this is the research re-run over the documented LAN trust
# boundary, exactly as Phase 2 specifies. Tolerant: a graph that errors (missing node / OOM / unresolved
# embedding) is journalled as DATA, never fatal. 0 model tokens. Rasters gitignored; the journal is tracked.
#
# Usage: bash rerun.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../../plugins/pressroom/skills/model-survey/scripts/comfyui-lib.sh"
JOURNAL_IN="$HERE/adaptation-journal.jsonl"
JOURNAL="$HERE/rerun-journal.jsonl"
OUT="$HERE/reruns"; mkdir -p "$OUT"; : > "$JOURNAL"
now() { date -u +%FT%TZ; }
cu_reachable || { echo "ComfyUI unreachable at $COMFYUI" >&2; exit 3; }

mapfile -t FILES < <(jq -r 'select(.classification=="rerunnable" and (.dropped|not)) | .adapted_file' "$JOURNAL_IN")
echo "rerun: ${#FILES[@]} rerunnable graphs  ($COMFYUI)"
ok=0; err=0
for rel in "${FILES[@]}"; do
  g="$HERE/$rel"; slug="$(basename "$rel" .json)"
  [ -f "$g" ] || { echo "  missing $rel"; continue; }
  # detect the output node: SaveImage, else PreviewImage
  snode=$(jq -r 'to_entries[]|select(.value.class_type=="SaveImage")|.key' "$g" | head -1)
  [ -z "$snode" ] && snode=$(jq -r 'to_entries[]|select(.value.class_type=="PreviewImage")|.key' "$g" | head -1)
  if [ -z "$snode" ]; then
    printf '%s\n' "$(jq -nc --arg s "$slug" --arg t "$(now)" '{slug:$s,status:"error",error:"no-output-node",ts:$t}')" >> "$JOURNAL"
    echo "  $slug: no output node"; err=$((err+1)); continue
  fi
  body="$(mktemp --suffix=.json)"
  jq '{prompt: ., client_id:"phase2-rerun"}' "$g" > "$body"
  echo "  run $slug (out=$snode) …"
  pid="$(cu_submit "$body")"; rm -f "$body"
  if [ -z "$pid" ]; then
    printf '%s\n' "$(jq -nc --arg s "$slug" --arg t "$(now)" '{slug:$s,status:"error",error:"submit-refused",ts:$t}')" >> "$JOURNAL"
    echo "    submit refused"; err=$((err+1)); continue
  fi
  if cu_wait "$pid" 600; then
    IFS='|' read -r fn sub typ < <(cu_first_image "$pid" "$snode")
    if cu_download "$fn" "$sub" "$typ" "$OUT/$slug.png" && [ -s "$OUT/$slug.png" ]; then
      printf '%s\n' "$(jq -nc --arg s "$slug" --arg f "reruns/$slug.png" --arg t "$(now)" '{slug:$s,status:"done",full:$f,ts:$t}')" >> "$JOURNAL"
      echo "    ok"; ok=$((ok+1))
    else
      printf '%s\n' "$(jq -nc --arg s "$slug" --arg t "$(now)" '{slug:$s,status:"error",error:"download-empty",ts:$t}')" >> "$JOURNAL"
      echo "    download empty"; err=$((err+1))
    fi
  else
    e="$(cu_error_msg "$pid")"; [ -z "$e" ] && e="timeout"
    printf '%s\n' "$(jq -nc --arg s "$slug" --arg e "$e" --arg t "$(now)" '{slug:$s,status:"error",error:$e,ts:$t}')" >> "$JOURNAL"
    echo "    error: $e"; err=$((err+1))
  fi
done
echo "rerun complete: $ok ok, $err errored (of ${#FILES[@]})"
