#!/usr/bin/env bash
# comfyui-lib.sh — deterministic ComfyUI REST client for the MODEL SURVEY.
#
# Pure imperative shell + curl + jq. ZERO model tokens: every byte of ComfyUI interaction lives here so the
# /loop never hand-crafts an API call. Sourced by generate.sh and used standalone for validation.
#
# Endpoint: $PRESSROOM_COMFYUI_URL (default the i9 workstation, ComfyUI port 8188).
set -uo pipefail

COMFYUI="${PRESSROOM_COMFYUI_URL:-http://10.0.1.19:8188}"

cu_reachable() { curl -sf -m 4 "$COMFYUI/system_stats" >/dev/null 2>&1; }

# cu_checkpoints — the live checkpoint list, exact names (with any subfolder), one per line.
cu_checkpoints() {
  curl -sf -m 10 "$COMFYUI/object_info/CheckpointLoaderSimple" \
    | jq -r '.CheckpointLoaderSimple.input.required.ckpt_name[0][]'
}

# cu_has_ckpt <ckpt> — is this exact name in the live list? (presence in the menu, not loadability)
cu_has_ckpt() { cu_checkpoints | grep -Fxq "$1"; }

# cu_submit <prompt_json_file> -> prompt_id  (POST /prompt; the graph is built by the caller from a template)
cu_submit() {
  curl -sf -m 15 "$COMFYUI/prompt" -X POST -H 'Content-Type: application/json' \
       --data @"$1" | jq -r '.prompt_id // empty'
}

# cu_status <prompt_id> -> success|error|pending  (reads /history)
cu_status() {
  local h; h="$(curl -sf -m 8 "$COMFYUI/history/$1")"
  [ -z "$h" ] && { echo pending; return; }
  printf '%s' "$h" | jq -r --arg p "$1" '
    (.[$p] // {}) as $e
    | if ($e.status.status_str // "") == "error" then "error"
      elif ($e.outputs // {}) != {} then "success"
      else "pending" end'
}

# cu_error_msg <prompt_id> -> a one-line error reason (node + exception), for journalling load-failures.
cu_error_msg() {
  curl -sf -m 8 "$COMFYUI/history/$1" | jq -r --arg p "$1" '
    (.[$p].status.messages // [])
    | map(select(.[0]=="execution_error") | .[1])
    | (.[0] // {}) | "\(.node_type // "?"): \(.exception_message // "unknown error")"' 2>/dev/null
}

# cu_wait <prompt_id> <timeout_s> -> 0 on success, 1 on error/timeout. Polls /history every 2s.
cu_wait() {
  local pid="$1" budget="${2:-180}" waited=0 s
  while [ "$waited" -lt "$budget" ]; do
    s="$(cu_status "$pid")"
    [ "$s" = "success" ] && return 0
    [ "$s" = "error" ]   && return 1
    sleep 2; waited=$((waited+2))
  done
  return 1
}

# cu_first_image <prompt_id> <save_node_id> -> "filename|subfolder|type" for that SaveImage node's first
# image. Joined with '|' (NOT a tab): tab is an IFS-whitespace char, so `read -r` COLLAPSES an empty
# subfolder field and mis-shifts type; a non-whitespace separator preserves the empty middle field. Parse
# with `IFS='|' read -r fn sub typ`. ComfyUI filenames/subfolders never contain '|'.
cu_first_image() {
  curl -sf -m 8 "$COMFYUI/history/$1" | jq -r --arg p "$1" --arg n "$2" '
    (.[$p].outputs[$n].images // [])[0] // {}
    | [(.filename // ""), (.subfolder // ""), (.type // "output")] | join("|")'
}

# cu_download <filename> <subfolder> <type> <out_path> -> 0/1. URL-encodes nothing fancy; ComfyUI accepts
# raw query values. Confines output to the caller's path.
cu_download() {
  curl -sf -m 30 --get "$COMFYUI/view" \
    --data-urlencode "filename=$1" --data-urlencode "subfolder=$2" --data-urlencode "type=$3" \
    -o "$4"
}

# cu_validate_loadable <ckpt> -> 0 if a tiny 64x64 1-step job loads the checkpoint; 1 otherwise (prints the
# error). This is the dry-run that surfaces the SDXL-subfolder load quirk as DATA, not a silent drop.
cu_validate_loadable() {
  local ckpt="$1" tmp pid
  tmp="$(mktemp --suffix=.json)"
  python3 "$(dirname "${BASH_SOURCE[0]}")/build_graph.py" \
    --ckpt "$ckpt" --pos "test" --neg "" --seed 1 --steps 1 --cfg 1.0 \
    --sampler euler --scheduler normal --width 64 --height 64 --no-thumb > "$tmp"
  pid="$(cu_submit "$tmp")"; rm -f "$tmp"
  [ -z "$pid" ] && { echo "submit-refused"; return 1; }
  if cu_wait "$pid" 60; then return 0; else cu_error_msg "$pid"; return 1; fi
}
