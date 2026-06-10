#!/usr/bin/env bash
# run-diagram-fail.sh — fresh, DATED evidence that diffusion garbles legible diagram TEXT, re-grounding the
# "route diagrams to vector" rule. Renders a handful of prompts that explicitly ask for readable labels/titles
# through the allowlisted basic template, downloads the rasters, and (separately) a montage makes the sheet.
# 0 model tokens. Raw rasters are gitignored; only the downsized sheet is committed as evidence.
#
# Usage: bash run-diagram-fail.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$HERE/../../../plugins/pressroom/skills/model-survey/scripts/comfyui-lib.sh"
FILL="$HERE/../../../plugins/pressroom/skills/craft-study/scripts/fill.sh"
TMPL="$HERE/../../../plugins/pressroom/knowledge/comfyui-workflows/txt2img-basic.json"
source "$LIB"
OUT="$HERE/images"; mkdir -p "$OUT"
CKPT="${1:-crystalClearXL_ccxl.safetensors}"
NEG="blurry, lowres, watermark, jpeg artifacts"

# id|positive  — each DEMANDS legible text, the exact thing diffusion cannot hold.
PROMPTS=(
  "flowchart|a clean technical flowchart on a white background, three connected boxes labeled \"START\", \"PROCESS\" and \"END\", arrows between them, crisp readable sans-serif text"
  "pipeline|a modern flat infographic titled \"DATA PIPELINE\", four numbered steps each with a short readable label, professional slide design"
  "barchart|a business bar chart with a y-axis labeled \"Revenue\" and an x-axis with categories \"Q1\" \"Q2\" \"Q3\" \"Q4\", a legend, clean readable text"
  "architecture|a software architecture diagram, three labeled nodes \"CLIENT\", \"SERVER\", \"DATABASE\" connected by arrows, clean vector style, readable labels"
)
cu_reachable || { echo "ComfyUI unreachable at $COMFYUI" >&2; exit 3; }
echo "diagram-fail: ${#PROMPTS[@]} prompts on $CKPT  ($COMFYUI)"
i=0
for row in "${PROMPTS[@]}"; do
  id="${row%%|*}"; pos="${row#*|}"; seed=$((4200+i)); i=$((i+1))
  echo "  gen $id …"
  fills="$(mktemp --suffix=.json)"; body="$(mktemp --suffix=.json)"
  jq -nc --arg ck "$CKPT" --arg pos "$pos" --arg neg "$NEG" --argjson s "$seed" \
    '{"4.inputs.ckpt_name":$ck,"6.inputs.text":$pos,"7.inputs.text":$neg,"3.inputs.seed":$s,"3.inputs.steps":30}' > "$fills"
  bash "$FILL" "$TMPL" "$fills" > "$body" 2>/dev/null
  pid="$(cu_submit "$body")"; rm -f "$fills" "$body"
  [ -z "$pid" ] && { echo "    submit refused"; continue; }
  if cu_wait "$pid" 240; then
    IFS='|' read -r fn sub typ < <(cu_first_image "$pid" 9)
    cu_download "$fn" "$sub" "$typ" "$OUT/$id.png" && echo "    ok" || echo "    dl failed"
  else echo "    error: $(cu_error_msg "$pid")"; fi
done
echo "done → $OUT"
