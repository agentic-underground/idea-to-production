#!/usr/bin/env bash
# generate.sh — deterministic, resumable multi-stage image generation for the CRAFT STUDY.
#
# Reads $CRAFT_DIR/manifest.json (objectives x techniques) and, for every (objective x technique) cell not
# already 'done' in journal.jsonl: fills the allowlisted Phase-5 template for that technique, submits it to
# ComfyUI, waits, downloads the final image (the technique's SaveImage node), makes a local CPU thumbnail,
# and appends a journal line. ZERO model tokens. Safe to background and to re-run (idempotent — completed
# cells skip). Errors (a checkpoint/LoRA that will not load, a base/SDXL mismatch) are journalled as DATA,
# never fatal — a load-failure is a finding.
#
# Usage: CRAFT_DIR=image-craft-study/craft bash generate.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Reuse the proven REST client from the sibling model-survey skill (same plugin — self-contained).
source "$HERE/../../model-survey/scripts/comfyui-lib.sh"
TEMPL_DIR="$HERE/../../../knowledge/comfyui-workflows"   # plugins/publish/knowledge/comfyui-workflows

find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
CRAFT_DIR="${CRAFT_DIR:-$(find_root)/image-craft-study/craft}"
MANIFEST="$CRAFT_DIR/manifest.json"
JOURNAL="$CRAFT_DIR/journal.jsonl"
[ -f "$MANIFEST" ] || { echo "no manifest: $MANIFEST" >&2; exit 2; }
mkdir -p "$CRAFT_DIR/images" "$CRAFT_DIR/thumbs"; touch "$JOURNAL"

now() { date -u +%FT%TZ; }
jappend() { printf '%s\n' "$1" >> "$JOURNAL"; }
have() { command -v "$1" >/dev/null 2>&1; }

cell_done() {  # <objective> <technique>: a done journal line AND the final file exists
  local full="images/$1/$2.png"
  [ -f "$CRAFT_DIR/$full" ] || return 1
  jq -e -s --arg o "$1" --arg t "$2" \
    'any(.[]; .event=="cell" and .objective==$o and .technique==$t and .status=="done")' "$JOURNAL" >/dev/null 2>&1
}

# build_fills <objective_json> <technique_id> <technique_json> -> typed fills object on stdout
build_fills() {
  local obj="$1" tid="$2" tj="$3" tmpl
  tmpl=$(jq -r '.template' <<<"$tj")
  local ck pos neg w h
  ck=$(jq -r '.ckpt' <<<"$obj")
  if [ "$tmpl" = "tricomposite" ]; then
    # tricomposite ships its own region prompts; vary only ckpt + the four region/unify seeds.
    jq -nc --arg ck "$ck" --argjson s "$SEED" \
      '{"4.inputs.ckpt_name":$ck,"20.inputs.seed":$s,"21.inputs.seed":($s+1),"22.inputs.seed":($s+2),"40.inputs.seed":($s+3)}'
  else
    pos=$(jq -r '.positive' <<<"$obj"); neg=$(jq -r '.negative' <<<"$obj")
    w=$(jq -r '.width' <<<"$obj");      h=$(jq -r '.height' <<<"$obj")
    jq -nc --arg ck "$ck" --arg pos "$pos" --arg neg "$neg" --argjson s "$SEED" \
           --argjson w "$w" --argjson h "$h" --argjson knobs "$(jq -c '.knobs' <<<"$tj")" '
      {"4.inputs.ckpt_name":$ck,"6.inputs.text":$pos,"7.inputs.text":$neg,
       "3.inputs.seed":$s,"5.inputs.width":$w,"5.inputs.height":$h} + $knobs'
  fi
}

cu_reachable || { echo "ComfyUI unreachable at $COMFYUI" >&2; exit 3; }
SEED=$(jq -r '.seed' "$MANIFEST")
n_obj=$(jq '.objectives | length' "$MANIFEST")
total=$(jq '[.objectives[].techniques | length] | add' "$MANIFEST")
echo "craft-study: $n_obj objectives -> $total cells  ($COMFYUI)  seed=$SEED"

for oi in $(seq 0 $((n_obj-1))); do
  OBJ=$(jq -c ".objectives[$oi]" "$MANIFEST")
  oid=$(jq -r '.id' <<<"$OBJ")
  mkdir -p "$CRAFT_DIR/images/$oid" "$CRAFT_DIR/thumbs/$oid"
  for tid in $(jq -r '.techniques[]' <<<"$OBJ"); do
    if cell_done "$oid" "$tid"; then echo "  skip $oid/$tid (done)"; continue; fi
    TJ=$(jq -c --arg t "$tid" '.techniques[$t]' "$MANIFEST")
    tmpl=$(jq -r '.template' <<<"$TJ"); save_node=$(jq -r '.save_node' <<<"$TJ")
    tfile="$TEMPL_DIR/$tmpl.json"
    [ -f "$tfile" ] || { jappend "$(jq -nc --arg o "$oid" --arg t "$tid" --arg ts "$(now)" '{event:"cell",objective:$o,technique:$t,status:"error",error:"template-missing",ts:$ts}')"; echo "    no template $tmpl"; continue; }
    echo "  gen  $oid/$tid  ($tmpl) …"
    fills="$(mktemp --suffix=.json)"; body="$(mktemp --suffix=.json)"
    build_fills "$OBJ" "$tid" "$TJ" > "$fills"
    bash "$HERE/fill.sh" "$tfile" "$fills" > "$body" 2>/dev/null || { echo "    fill failed"; rm -f "$fills" "$body"; continue; }
    pid="$(cu_submit "$body")"; rm -f "$fills" "$body"
    if [ -z "$pid" ]; then
      jappend "$(jq -nc --arg o "$oid" --arg t "$tid" --arg ts "$(now)" '{event:"cell",objective:$o,technique:$t,status:"error",error:"submit-refused",ts:$ts}')"
      echo "    submit refused"; continue
    fi
    if ! cu_wait "$pid" 600; then
      err="$(cu_error_msg "$pid")"; [ -z "$err" ] && err="timeout"
      jappend "$(jq -nc --arg o "$oid" --arg t "$tid" --arg e "$err" --arg ts "$(now)" '{event:"cell",objective:$o,technique:$t,status:"error",error:$e,ts:$ts}')"
      echo "    error: $err"; continue
    fi
    IFS='|' read -r fn sub typ < <(cu_first_image "$pid" "$save_node")
    cu_download "$fn" "$sub" "$typ" "$CRAFT_DIR/images/$oid/$tid.png"
    if [ -s "$CRAFT_DIR/images/$oid/$tid.png" ]; then
      # local CPU thumbnail (0 GPU, 0 model tokens) for contact sheets
      if have magick; then magick "$CRAFT_DIR/images/$oid/$tid.png" -resize 512x512 "$CRAFT_DIR/thumbs/$oid/$tid.png" 2>/dev/null; fi
      ck=$(jq -r '.ckpt' <<<"$OBJ")
      jappend "$(jq -nc --arg o "$oid" --arg t "$tid" --arg tm "$tmpl" --arg k "$ck" --argjson s "$SEED" \
        --arg f "images/$oid/$tid.png" --arg th "thumbs/$oid/$tid.png" --arg ts "$(now)" \
        '{event:"cell",objective:$o,technique:$t,template:$tm,ckpt:$k,seed:$s,status:"done",full:$f,thumb:$th,ts:$ts}')"
      echo "    ok"
    else
      jappend "$(jq -nc --arg o "$oid" --arg t "$tid" --arg ts "$(now)" '{event:"cell",objective:$o,technique:$t,status:"error",error:"download-empty",ts:$ts}')"
      echo "    download empty"
    fi
  done
done

done_n=$(jq -s '[.[]|select(.event=="cell" and .status=="done")] | length' "$JOURNAL")
err_n=$(jq -s '[.[]|select(.event=="cell" and .status=="error")] | length' "$JOURNAL")
echo "craft-study generation pass complete: $done_n done, $err_n errored (of $total cells)"
