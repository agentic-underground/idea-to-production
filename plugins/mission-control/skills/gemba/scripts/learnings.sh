#!/usr/bin/env bash
# learnings.sh — the GEMBA LEARNING LEDGER writer/reader (mirrors incident/action-items.sh).
#
# WHAT IT DOES
#   A learning captured by the gemba reflex (a test gap, a missing guard, a cross-repo defect) is
#   worthless if it evaporates after the session. This is the durable, append-only LEDGER each learning
#   lands in, so the `overdue-learnings.sh` detector (and `mission-control:iterate`) can later surface
#   un-filed / open learnings as a re-entry signal into the lifecycle.
#
# CARRIER: <project>/.i2p/learnings.jsonl — one JSON record per line (append-friendly, like the other
#   i2p artifact ledgers). Never rewritten in place; each event (`open`→`filed`→`closed`) appends a new
#   record for the same id, and the reader REDUCES records by id to the latest state (last-write-wins).
#
# RECORD SCHEMA (schema-versioned, like action-items/degraded-capabilities):
#   {"schema":"learnings/1.0","id":"<slug>","event":"open|filed|closed",
#    "origin":"<plugin|repo>","phase":"<lifecycle phase>","kind":"test-gap|guard|defect|...",
#    "target":"<org/repo>","verdict":"self|gemba","severity":"low|medium|high|critical|",
#    "title":"<one line>","brief_path":"doc/learnings/<slug>/","issue_url":"<url|>",
#    "status":"open|filed|closed","ts":"<ISO8601>"}
#
# USAGE
#   learnings.sh open  <dir> <id> <title> [--origin o] [--phase p] [--kind k] [--target t] \
#                                         [--verdict self|gemba] [--severity s] [--brief path]
#   learnings.sh filed <dir> <id> [--issue <url>]      # mark filed (records the issue_url)
#   learnings.sh close <dir> <id> [--note <note>]      # mark closed
#   learnings.sh list  <dir> [open|filed|closed|all]   # default: all (reduced to latest state)
#   learnings.sh get   <dir> <id>                      # → the latest reduced record (or {})
#
# Needs jq. Always exits 0 on the read path; degrades with a message when jq is absent.
set -uo pipefail

SCHEMA="learnings/1.0"
cmd="${1:-list}"; dir="${2:-.}"
dir="${dir%/}"
LEDGER="${dir}/.i2p/learnings.jsonl"

command -v jq >/dev/null 2>&1 || { echo "learnings: jq required (no-op without it)" >&2; exit 0; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo ""; }

# reduce_latest — fold the append-only ledger into the latest state per id (last record by id wins),
# tolerating malformed lines (skipped, not fatal). Emits a JSON array of current learning states.
reduce_latest() {
  [ -r "$LEDGER" ] || { echo "[]"; return; }
  jq -s '
    map(select(type=="object" and has("id")))
    | group_by(.id) | map(.[-1])' \
    <(grep -v '^[[:space:]]*$' "$LEDGER" 2>/dev/null | jq -c '.' 2>/dev/null) 2>/dev/null \
    || echo "[]"
}

# prior_for <id> — the latest reduced record for an id (or {}).
prior_for() { reduce_latest | jq -c --arg id "$1" 'map(select(.id==$id)) | .[0] // {}'; }

# parse_kv — pull --key value pairs from the remaining args into globals (origin/phase/...).
declare origin="" phase="" kind="" target="" verdict="" severity="" brief="" issue="" note="" title=""
parse_kv() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --origin)   origin="${2:-}"; shift 2 ;;
      --phase)    phase="${2:-}"; shift 2 ;;
      --kind)     kind="${2:-}"; shift 2 ;;
      --target)   target="${2:-}"; shift 2 ;;
      --verdict)  verdict="${2:-}"; shift 2 ;;
      --severity) severity="${2:-}"; shift 2 ;;
      --brief)    brief="${2:-}"; shift 2 ;;
      --issue)    issue="${2:-}"; shift 2 ;;
      --note)     note="${2:-}"; shift 2 ;;
      *)          shift ;;
    esac
  done
}

case "$cmd" in
  open)
    id="${3:-}"; title="${4:-}"
    [ -n "$id" ] && [ -n "$title" ] || { echo "learnings: open needs <id> <title> [--origin … --target … …]" >&2; exit 0; }
    shift $(( $# >= 4 ? 4 : $# )); parse_kv "$@"
    mkdir -p "${dir}/.i2p" 2>/dev/null || { echo "learnings: cannot create ${dir}/.i2p" >&2; exit 0; }
    rec="$(jq -nc --arg s "$SCHEMA" --arg id "$id" --arg t "$title" \
            --arg o "$origin" --arg ph "$phase" --arg k "$kind" --arg tg "$target" \
            --arg v "$verdict" --arg sev "$severity" --arg bp "$brief" --arg ts "$(now)" \
            '{schema:$s, id:$id, event:"open", origin:$o, phase:$ph, kind:$k, target:$tg,
              verdict:$v, severity:$sev, title:$t, brief_path:$bp, issue_url:"",
              status:"open", ts:$ts}')"
    printf '%s\n' "$rec" >> "$LEDGER"
    echo "learnings: opened ${id} → ${LEDGER}"
    ;;

  filed)
    id="${3:-}"
    [ -n "$id" ] || { echo "learnings: filed needs <id> [--issue <url>]" >&2; exit 0; }
    [ -r "$LEDGER" ] || { echo "learnings: no ledger at ${LEDGER}" >&2; exit 0; }
    shift $(( $# >= 3 ? 3 : $# )); parse_kv "$@"
    prior="$(prior_for "$id")"
    rec="$(printf '%s' "$prior" | jq -c --arg s "$SCHEMA" --arg id "$id" --arg url "$issue" --arg ts "$(now)" \
            '{schema:$s, id:$id, event:"filed", origin:(.origin//""), phase:(.phase//""),
              kind:(.kind//""), target:(.target//""), verdict:(.verdict//""),
              severity:(.severity//""), title:(.title//""), brief_path:(.brief_path//""),
              issue_url:($url // (.issue_url//"")), status:"filed", ts:$ts}')"
    printf '%s\n' "$rec" >> "$LEDGER"
    echo "learnings: filed ${id}${issue:+ → $issue}"
    ;;

  close)
    id="${3:-}"
    [ -n "$id" ] || { echo "learnings: close needs <id> [--note <note>]" >&2; exit 0; }
    [ -r "$LEDGER" ] || { echo "learnings: no ledger at ${LEDGER}" >&2; exit 0; }
    shift $(( $# >= 3 ? 3 : $# )); parse_kv "$@"
    prior="$(prior_for "$id")"
    rec="$(printf '%s' "$prior" | jq -c --arg s "$SCHEMA" --arg id "$id" --arg note "$note" --arg ts "$(now)" \
            '{schema:$s, id:$id, event:"closed", origin:(.origin//""), phase:(.phase//""),
              kind:(.kind//""), target:(.target//""), verdict:(.verdict//""),
              severity:(.severity//""), title:(.title//""), brief_path:(.brief_path//""),
              issue_url:(.issue_url//""), status:"closed", note:$note, ts:$ts}')"
    printf '%s\n' "$rec" >> "$LEDGER"
    echo "learnings: closed ${id}"
    ;;

  get)
    id="${3:-}"
    [ -n "$id" ] || { echo "{}"; exit 0; }
    prior_for "$id"
    ;;

  list)
    filter="${3:-all}"
    items="$(reduce_latest)"
    case "$filter" in
      open)   items="$(printf '%s' "$items" | jq -c 'map(select(.status=="open"))')" ;;
      filed)  items="$(printf '%s' "$items" | jq -c 'map(select(.status=="filed"))')" ;;
      closed) items="$(printf '%s' "$items" | jq -c 'map(select(.status=="closed"))')" ;;
    esac
    printf '%s' "$items" | jq -r '
      if length==0 then "learnings: none" else
        (["id","status","verdict","target","issue_url","title"] | @tsv),
        (.[] | [.id, .status, (.verdict//"-"), (.target//"-"), (.issue_url//"-"), .title] | @tsv)
      end' 2>/dev/null | column -t -s$'\t' 2>/dev/null \
      || printf '%s\n' "$items"
    ;;

  *)
    echo "usage: learnings.sh {open <dir> <id> <title> [flags]|filed <dir> <id> [--issue url]|close <dir> <id> [--note n]|list <dir> [open|filed|closed|all]|get <dir> <id>}" >&2
    exit 2 ;;
esac
