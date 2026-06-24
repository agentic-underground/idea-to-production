#!/usr/bin/env bash
# generate.sh — deterministic, resumable image generation for the MODEL SURVEY.
#
# Reads $SURVEY_DIR/manifest.json (models × categories), and for every (model × category) cell not already
# 'done' in journal.jsonl: builds the txt2img+downscale graph, submits to ComfyUI, waits, downloads the full
# image + the GPU-made thumbnail, and appends a journal line. ZERO model tokens. Safe to run in the
# background and to re-run (idempotent — completed cells are skipped). Errors (e.g. a checkpoint that won't
# load) are journalled as data, never fatal.
#
# Usage: SURVEY_DIR=comfyui-experiment bash generate.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/comfyui-lib.sh"

# Resolve the survey dir (default: <repo>/comfyui-experiment).
find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
SURVEY_DIR="${SURVEY_DIR:-$(find_root)/comfyui-experiment}"
MANIFEST="$SURVEY_DIR/manifest.json"
JOURNAL="$SURVEY_DIR/journal.jsonl"
[ -f "$MANIFEST" ] || { echo "no manifest: $MANIFEST" >&2; exit 2; }
mkdir -p "$SURVEY_DIR/images" "$SURVEY_DIR/thumbs"; touch "$JOURNAL"

now() { date -u +%FT%TZ; }
jappend() { printf '%s\n' "$1" >> "$JOURNAL"; }

# cell_done <model> <category>: a journal line marks it done AND the full file exists.
cell_done() {
  local full="images/$1/$2.png"
  [ -f "$SURVEY_DIR/$full" ] || return 1
  jq -e -s --arg m "$1" --arg c "$2" \
    'any(.[]; .event=="cell" and .model==$m and .category==$c and .status=="done")' "$JOURNAL" >/dev/null 2>&1
}

cu_reachable || { echo "ComfyUI unreachable at $COMFYUI" >&2; exit 3; }

n_models=$(jq '.models | length' "$MANIFEST")
n_cats=$(jq '.categories | length' "$MANIFEST")
echo "survey: $n_models models × $n_cats categories → $((n_models*n_cats)) cells  ($COMFYUI)"

for mi in $(seq 0 $((n_models-1))); do
  M=$(jq ".models[$mi]" "$MANIFEST")
  mid=$(jq -r '.id'   <<<"$M"); ckpt=$(jq -r '.ckpt' <<<"$M")
  base=$(jq -r '.base'<<<"$M"); w=$(jq -r '.width'<<<"$M"); h=$(jq -r '.height'<<<"$M")
  steps=$(jq -r '.steps'<<<"$M"); cfg=$(jq -r '.cfg'<<<"$M")
  samp=$(jq -r '.sampler'<<<"$M"); sched=$(jq -r '.scheduler'<<<"$M")
  mkdir -p "$SURVEY_DIR/images/$mid" "$SURVEY_DIR/thumbs/$mid"

  for ci in $(seq 0 $((n_cats-1))); do
    C=$(jq ".categories[$ci]" "$MANIFEST")
    cid=$(jq -r '.id' <<<"$C"); pos=$(jq -r '.positive' <<<"$C"); neg=$(jq -r '.negative' <<<"$C")
    seed=$((1000 + ci))   # fixed per-category seed → models are comparable on identical noise

    if cell_done "$mid" "$cid"; then echo "  skip $mid/$cid (done)"; continue; fi
    echo "  gen  $mid/$cid …"

    tmp="$(mktemp --suffix=.json)"
    python3 "$HERE/build_graph.py" --ckpt "$ckpt" --pos "$pos" --neg "$neg" --seed "$seed" \
      --steps "$steps" --cfg "$cfg" --sampler "$samp" --scheduler "$sched" \
      --width "$w" --height "$h" --prefix "survey-$mid-$cid" > "$tmp"
    pid="$(cu_submit "$tmp")"; rm -f "$tmp"
    if [ -z "$pid" ]; then
      jappend "$(jq -nc --arg m "$mid" --arg c "$cid" --arg t "$(now)" '{event:"cell",model:$m,category:$c,status:"error",error:"submit-refused",ts:$t}')"
      echo "    submit refused"; continue
    fi
    if ! cu_wait "$pid" 240; then
      err="$(cu_error_msg "$pid")"; [ -z "$err" ] && err="timeout"
      jappend "$(jq -nc --arg m "$mid" --arg c "$cid" --arg e "$err" --arg t "$(now)" '{event:"cell",model:$m,category:$c,status:"error",error:$e,ts:$t}')"
      echo "    error: $err"; continue
    fi
    # download full (node 9) and thumb (node 11). '|' separator preserves an empty subfolder field.
    IFS='|' read -r fn sub typ   < <(cu_first_image "$pid" 9)
    IFS='|' read -r tfn tsub ttyp < <(cu_first_image "$pid" 11)
    cu_download "$fn" "$sub" "$typ" "$SURVEY_DIR/images/$mid/$cid.png"
    cu_download "$tfn" "$tsub" "$ttyp" "$SURVEY_DIR/thumbs/$mid/$cid.png"
    # Only mark done if the full image actually landed and is non-empty (never journal a phantom success).
    if [ -s "$SURVEY_DIR/images/$mid/$cid.png" ]; then
      jappend "$(jq -nc --arg m "$mid" --arg c "$cid" --arg k "$ckpt" --arg b "$base" --argjson s "$seed" \
        --arg f "images/$mid/$cid.png" --arg th "thumbs/$mid/$cid.png" --arg t "$(now)" \
        '{event:"cell",model:$m,category:$c,ckpt:$k,base:$b,seed:$s,status:"done",full:$f,thumb:$th,ts:$t}')"
      echo "    ok"
    else
      jappend "$(jq -nc --arg m "$mid" --arg c "$cid" --arg t "$(now)" '{event:"cell",model:$m,category:$c,status:"error",error:"download-empty",ts:$t}')"
      echo "    download empty"
    fi
  done
done

done_n=$(jq -s '[.[]|select(.event=="cell" and .status=="done")] | length' "$JOURNAL")
err_n=$(jq -s '[.[]|select(.event=="cell" and .status=="error")] | length' "$JOURNAL")
echo "generation pass complete: $done_n done, $err_n errored (of $((n_models*n_cats)) cells)"
