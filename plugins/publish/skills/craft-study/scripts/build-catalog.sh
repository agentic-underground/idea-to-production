#!/usr/bin/env bash
# build-catalog.sh — deterministic catalog.md from the journal, 0 model tokens. Lists every objective's A/B
# cells (status, template, ckpt), the gain under test, and (when the SCORE phase has appended them) the
# per-objective verdict + named gain. The catalog is the tracked durable record; the rasters are gitignored.
#
# Usage: CRAFT_DIR=image-craft-study/craft bash build-catalog.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
CRAFT_DIR="${CRAFT_DIR:-$(find_root)/image-craft-study/craft}"
MANIFEST="$CRAFT_DIR/manifest.json"; JOURNAL="$CRAFT_DIR/journal.jsonl"; OUT="$CRAFT_DIR/catalog.md"
[ -f "$MANIFEST" ] || { echo "no manifest" >&2; exit 2; }; touch "$JOURNAL"

cell_field() { # <objective> <technique> <field>
  jq -s -r --arg o "$1" --arg t "$2" --arg f "$3" \
    '[.[]|select(.event=="cell" and .objective==$o and .technique==$t)] | last | (.[$f] // "—")' "$JOURNAL"
}
verdict_for() { # <objective> -> last score line (named gain) for that objective, or ""
  jq -s -r --arg o "$1" '[.[]|select(.event=="score" and .objective==$o)] | last
    | if .==null then "" else "**\(.verdict // "?")** — \(.named_gain // "")" end' "$JOURNAL"
}

{
  echo "# Craft study — multi-stage technique catalog"
  echo
  echo "_Empirical, controlled single-variable A/B per objective. Baseline and treatment share ckpt / prompt / seed /"
  echo "base resolution; the only difference is the named stage. A gain counts only if it is **visible, named, and"
  echo "reproducible** over the baseline. Rasters are gitignored; this catalog + journal.jsonl are the tracked record._"
  echo
  echo "Rig endpoint: \`${PRESSROOM_COMFYUI_URL:-http://10.10.10.163:8188}\` · seed \`$(jq -r '.seed' "$MANIFEST")\`"
  echo
  n_obj=$(jq '.objectives | length' "$MANIFEST")
  for oi in $(seq 0 $((n_obj-1))); do
    OBJ=$(jq -c ".objectives[$oi]" "$MANIFEST"); oid=$(jq -r '.id' <<<"$OBJ")
    ckpt=$(jq -r '.ckpt' <<<"$OBJ"); gain=$(jq -r '.gain_under_test // "—"' <<<"$OBJ")
    echo "## $oid"
    echo
    echo "- **Checkpoint:** \`$ckpt\`"
    echo "- **Gain under test:** $gain"
    v="$(verdict_for "$oid")"; [ -n "$v" ] && echo "- **Verdict:** $v"
    [ -f "$CRAFT_DIR/contact-sheets/$oid.png" ] && echo "- **A/B sheet:** \`contact-sheets/$oid.png\`"
    echo
    echo "| technique | template | status | note |"
    echo "|---|---|---|---|"
    for tid in $(jq -r '.techniques[]' <<<"$OBJ"); do
      st=$(cell_field "$oid" "$tid" status); tm=$(cell_field "$oid" "$tid" template)
      lbl=$(jq -r --arg t "$tid" '.techniques[$t].label // ""' "$MANIFEST")
      note="$lbl"; [ "$st" = "error" ] && note="error: $(cell_field "$oid" "$tid" error)"
      echo "| \`$tid\` | \`$tm\` | $st | $note |"
    done
    echo
  done
  done_n=$(jq -s '[.[]|select(.event=="cell" and .status=="done")]|length' "$JOURNAL")
  err_n=$(jq -s '[.[]|select(.event=="cell" and .status=="error")]|length' "$JOURNAL")
  scored_n=$(jq -s '[.[]|select(.event=="score")]|length' "$JOURNAL")
  echo "---"
  echo
  echo "_Generated from journal.jsonl: $done_n cell(s) done, $err_n errored, $scored_n objective(s) scored._"
} > "$OUT"
echo "catalog → $OUT"
