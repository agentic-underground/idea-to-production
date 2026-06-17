#!/usr/bin/env bash
# fill.sh <template.json> <fills.json> -> ComfyUI POST body on stdout.
#
# Pure jq, ZERO model tokens. Sets each dot-path key from fills.json into the allowlisted graph, strips _meta,
# and wraps as the {"prompt": graph} body ComfyUI's POST /prompt expects.
#
# fills.json is a flat object of dot-path -> TYPED value, e.g.
#   { "4.inputs.ckpt_name": "model.safetensors", "3.inputs.seed": 1234, "10.inputs.scale_by": 1.5 }
# Keys are split on '.' into a setpath path; values keep their JSON type (string vs number). Node-id path
# segments stay strings (the graph is keyed by string ids), so we never coerce path components to numbers.
set -euo pipefail
[ -f "$1" ] || { echo "fill: no template $1" >&2; exit 2; }
[ -f "$2" ] || { echo "fill: no fills $2" >&2; exit 2; }
jq --argjson fills "$(cat "$2")" '
  reduce ($fills | to_entries[]) as $kv (.; setpath($kv.key | split("."); $kv.value))
  | del(._meta)
  | {prompt: ., client_id: "craft-study"}
' "$1"
