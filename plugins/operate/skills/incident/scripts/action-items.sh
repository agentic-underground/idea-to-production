#!/usr/bin/env bash
# action-items.sh — the postmortem ACTION-ITEM LEDGER writer/reader.
#
# A blameless postmortem ends in "concrete, owned, dated action items" — but `incident` only WROTE
# them into POSTMORTEM-<id>.md prose; nothing tracked them to completion, so they quietly rotted.
# This is the durable, append-friendly LEDGER those action items land in, so the `overdue-action-items.sh`
# detector (and `iterate`) can later flag un-closed / overdue ones as a re-entry signal into the lifecycle.
#
# CARRIER: <project>/.i2p/action-items.jsonl — one JSON record per line (append-friendly, like the
#   other i2p artifact ledgers). Never rewritten in place; `close` appends a closure record so the
#   history is preserved (audit trail), and the reader reduces records by id to the latest state.
#
# RECORD SCHEMA (schema-versioned, like degraded-capabilities/scorecard):
#   {"schema":"action-items/1.0","id":"<incident-or-slug>:<n>","incident":"<INCIDENT id>",
#    "title":"<what to do>","owner":"<who>","due":"<YYYY-MM-DD>","severity":"SEV1..5|",
#    "status":"open|closed","event":"open|close","ts":"<ISO8601>"}
#
# USAGE:
#   action-items.sh add   <dir> <incident> <id> <title> [owner] [due:YYYY-MM-DD] [severity]
#   action-items.sh close <dir> <id> [note]
#   action-items.sh list  <dir> [open|closed|all]      # default: all (reduced to latest state)
#
# Needs jq. Always exits 0 on the read path; degrades with a message when jq is absent.
set -uo pipefail

SCHEMA="action-items/1.0"
cmd="${1:-list}"; dir="${2:-.}"
LEDGER="${dir%/}/.i2p/action-items.jsonl"

command -v jq >/dev/null 2>&1 || { echo "action-items: jq required (no-op without it)" >&2; exit 0; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo ""; }

# reduce_latest — fold the append-only ledger into the latest state per id (last record by id wins),
# tolerating malformed lines (skipped, not fatal). Emits a JSON array of current action-item states.
reduce_latest() {
  [ -r "$LEDGER" ] || { echo "[]"; return; }
  jq -s '
    map(select(type=="object" and has("id")))
    | group_by(.id) | map(.[-1])' \
    <(grep -v '^[[:space:]]*$' "$LEDGER" 2>/dev/null | jq -c '.' 2>/dev/null) 2>/dev/null \
    || echo "[]"
}

case "$cmd" in
  add)
    incident="${3:-}"; id="${4:-}"; title="${5:-}"
    owner="${6:-}"; due="${7:-}"; severity="${8:-}"
    [ -n "$id" ] && [ -n "$title" ] || { echo "action-items: add needs <incident> <id> <title> [owner] [due] [severity]" >&2; exit 0; }
    mkdir -p "${dir%/}/.i2p" 2>/dev/null || { echo "action-items: cannot create ${dir%/}/.i2p" >&2; exit 0; }
    rec="$(jq -nc --arg s "$SCHEMA" --arg id "$id" --arg inc "$incident" --arg t "$title" \
            --arg o "$owner" --arg d "$due" --arg sev "$severity" --arg ts "$(now)" \
            '{schema:$s, id:$id, incident:$inc, title:$t, owner:$o, due:$d, severity:$sev,
              status:"open", event:"open", ts:$ts}')"
    printf '%s\n' "$rec" >> "$LEDGER"
    echo "action-items: opened ${id} → ${LEDGER}"
    ;;

  close)
    id="${3:-}"; note="${4:-}"
    [ -n "$id" ] || { echo "action-items: close needs <id>" >&2; exit 0; }
    [ -r "$LEDGER" ] || { echo "action-items: no ledger at ${LEDGER}" >&2; exit 0; }
    # Carry the original title/owner/due forward into the closure record so a `list` of closed
    # items is self-contained (the append-only history stays intact above it).
    prior="$(reduce_latest | jq -c --arg id "$id" 'map(select(.id==$id)) | .[0] // {}')"
    rec="$(printf '%s' "$prior" | jq -c --arg s "$SCHEMA" --arg id "$id" --arg note "$note" --arg ts "$(now)" \
            '{schema:$s, id:$id, incident:(.incident//""), title:(.title//""), owner:(.owner//""),
              due:(.due//""), severity:(.severity//""), status:"closed", event:"close",
              note:$note, ts:$ts}')"
    printf '%s\n' "$rec" >> "$LEDGER"
    echo "action-items: closed ${id}"
    ;;

  list)
    filter="${3:-all}"
    items="$(reduce_latest)"
    case "$filter" in
      open)   items="$(printf '%s' "$items" | jq -c 'map(select(.status=="open"))')" ;;
      closed) items="$(printf '%s' "$items" | jq -c 'map(select(.status=="closed"))')" ;;
    esac
    printf '%s' "$items" | jq -r '
      if length==0 then "action-items: none\($filter==null|"")" else
        (["id","status","due","owner","title"] | @tsv),
        (.[] | [.id, .status, (.due//"-"), (.owner//"-"), .title] | @tsv)
      end' --arg filter "$filter" 2>/dev/null | column -t -s$'\t' 2>/dev/null \
      || printf '%s\n' "$items"
    ;;

  *)
    echo "usage: action-items.sh {add <dir> <incident> <id> <title> [owner] [due] [sev]|close <dir> <id> [note]|list <dir> [open|closed|all]}" >&2
    exit 2 ;;
esac
