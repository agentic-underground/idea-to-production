#!/usr/bin/env bash
# validate.sh — Phase A. Intersect the curated wishlist with the LIVE checkpoint list and dry-run each for
# loadability (a tiny 64×64 1-step job). Writes $SURVEY_DIR/manifest.json containing ONLY models that both
# exist and load — and journals every model's verdict (load-failures are findings, e.g. the SDXL-subfolder
# quirk, not silent drops). ZERO model tokens.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/comfyui-lib.sh"
find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
ROOT="$(find_root)"
SURVEY_DIR="${SURVEY_DIR:-$ROOT/doc/comfyui-experiment}"
WISH="${1:-$HERE/../references/manifest.example.json}"
JOURNAL="$SURVEY_DIR/journal.jsonl"
mkdir -p "$SURVEY_DIR"; touch "$JOURNAL"
now() { date -u +%FT%TZ; }

cu_reachable || { echo "ComfyUI unreachable at $COMFYUI" >&2; exit 3; }
echo "validating curated subset against $COMFYUI …"
live="$(cu_checkpoints)"

keep="[]"
n=$(jq '.models | length' "$WISH")
for i in $(seq 0 $((n-1))); do
  M=$(jq ".models[$i]" "$WISH"); mid=$(jq -r '.id' <<<"$M"); ckpt=$(jq -r '.ckpt' <<<"$M")
  if ! grep -Fxq "$ckpt" <<<"$live"; then
    echo "  ✗ $mid — not in live list"
    printf '%s\n' "$(jq -nc --arg m "$mid" --arg k "$ckpt" --arg t "$(now)" '{event:"validate",model:$m,ckpt:$k,loadable:false,error:"absent from live list",ts:$t}')" >> "$JOURNAL"
    continue
  fi
  if err="$(cu_validate_loadable "$ckpt")"; then
    echo "  ✓ $mid — loads"
    keep="$(jq -c --argjson m "$M" '. + [$m]' <<<"$keep")"
    printf '%s\n' "$(jq -nc --arg m "$mid" --arg k "$ckpt" --arg t "$(now)" '{event:"validate",model:$m,ckpt:$k,loadable:true,ts:$t}')" >> "$JOURNAL"
  else
    echo "  ✗ $mid — load failed: $err"
    printf '%s\n' "$(jq -nc --arg m "$mid" --arg k "$ckpt" --arg e "$err" --arg t "$(now)" '{event:"validate",model:$m,ckpt:$k,loadable:false,error:$e,ts:$t}')" >> "$JOURNAL"
  fi
done

jq --argjson keep "$keep" '{categories: .categories, models: $keep}' "$WISH" > "$SURVEY_DIR/manifest.json"
echo "manifest: $(jq '.models|length' "$SURVEY_DIR/manifest.json")/$n models loadable → $SURVEY_DIR/manifest.json"
