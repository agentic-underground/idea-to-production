#!/usr/bin/env bash
# mcp-liveness.sh — SessionStart hook. Mid-session MCP-death detector for the OPERATE
# runtime surface.
#
# WHY A HOOK, NOT A SKILL. Per the heal-itself-circularity rule (the degraded-capabilities
# protocol, degraded-capabilities.md §2): a detector that lives inside a skill/MCP goes
# blind exactly when that surface crashes. This lives in the crash-surviving hook substrate
# (the same layer as inject-kaizen / the hook-heartbeat) so it survives the failure it detects.
#
# WHAT IT DOES (DETECT-ONLY — never restart, never install):
#   1. Enumerate the shipped MCP servers (marketplace plugins/*/.mcp.json, else the harness's
#      installed config under ~/.claude when discoverable).
#   2. For each, do a BOUNDED, NON-DESTRUCTIVE liveness probe: the launch command with a
#      --help/version flag under `timeout`. We never spawn the actual MCP server (it would
#      block waiting for an stdio client); we only confirm its launcher is reachable + runnable.
#   3. On a dead / no-response server, WRITE a DEGRADED_CAPABILITIES record (capability
#      mcp.<name>, a concrete reason, since_phase = current lifecycle phase) into
#      <project>/.i2p/degraded-capabilities.json — additive + idempotent per the contract
#      (plugins/foundry/knowledge/protocols/degraded-capabilities.md §1, "State file").
#
# HONESTY (degrade to silence): true MCP liveness — a live server actually answering an
# MCP request — is NOT reliably probeable from a SessionStart hook on this harness (the
# servers speak stdio JSON-RPC to the Claude client, not to us; spawning one would hang).
# So this is a best-effort *launcher-reachability* probe: it catches the common real death
# mode (the launch command / runner vanished — npx/uvx gone, a pinned package unresolvable),
# writes a structurally-correct degraded record for it, and stays SILENT when it cannot
# decide (no jq, no discoverable config, a probe that times out ambiguously). It NEVER
# writes a false-green and NEVER touches anything outside <project>/.i2p/.
#
# ALWAYS EXITS 0 (verify-prereqs check L smoke-tests this on a synthetic event).
set -uo pipefail

# ── 0. Hard guards: jq is required to write a well-formed record; without it, go silent ──
command -v jq >/dev/null 2>&1 || exit 0

# ── 1. Read the SessionStart payload (for cwd) ───────────────────────────────────────────
payload=""
[ -t 0 ] || payload="$(cat 2>/dev/null || true)"
payload_cwd=""
[ -n "$payload" ] && payload_cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"

# ── 2. Resolve the project dir (where .i2p/ lives) ──────────────────────────────────────
# Prefer the harness-provided CLAUDE_PROJECT_DIR (set by the sandbox in check L too), then
# the payload cwd, then the real cwd. We only ever write under <project>/.i2p/.
project_dir="${CLAUDE_PROJECT_DIR:-}"
[ -n "$project_dir" ] || project_dir="$payload_cwd"
[ -n "$project_dir" ] || project_dir="$PWD"
[ -d "$project_dir" ] || exit 0
I2P_DIR="${project_dir%/}/.i2p"

# ── 3. Discover the current lifecycle phase (for since_phase); default OPERATE ───────────
# This hook owns the OPERATE surface; a degradation it finds is, by default, observed in
# OPERATE. If a lifecycle.json names a current phase, prefer that (it's more specific).
current_phase="OPERATE"
LF="${I2P_DIR}/lifecycle.json"
if [ -f "$LF" ] && jq -e . "$LF" >/dev/null 2>&1; then
  p="$(jq -r '.current_phase // empty' "$LF" 2>/dev/null || true)"
  [ -n "$p" ] && current_phase="$p"
fi

# ── 4. Enumerate shipped MCP servers → newline list of "name<TAB>command" ────────────────
# Source A (preferred): the marketplace plugins/*/.mcp.json. The hook lives at
# plugins/i2p/hooks/scripts/; walk up to find a plugins/ tree with siblings.
# Source B (fallback): the harness's installed MCP config under ~/.claude, when present.
# Dedup by server name (the same server, e.g. context7, may ship in several plugins).
hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
servers=""   # accumulates "name\tcommand" lines

collect_from_mcp_json() {  # $1 = a .mcp.json path; $2 = plugin root for ${CLAUDE_PLUGIN_ROOT}
  local f="$1" root="${2:-}"
  [ -f "$f" ] || return 0
  jq -e . "$f" >/dev/null 2>&1 || return 0
  # Expand ${CLAUDE_PLUGIN_ROOT} (a plugin's own path — the only var shipped configs use) so a
  # resident-path launcher resolves to a real file the probe can stat. An unknown root stays literal
  # (the probe then declines rather than false-flagging it dead).
  jq -r --arg root "$root" '
    (.mcpServers // {}) | to_entries[]
    | "\(.key)\t\((.value.command // "") | gsub("\\$\\{CLAUDE_PLUGIN_ROOT\\}"; $root))"
  ' "$f" 2>/dev/null || true
}

# Source A — climb from the hook dir looking for a plugins/ dir, then read every sibling .mcp.json.
search="$hook_dir"
plugins_root=""
for _ in 1 2 3 4 5 6; do
  if [ -d "$search/plugins" ]; then plugins_root="$search/plugins"; break; fi
  case "$(basename "$search")" in plugins) plugins_root="$search"; break;; esac
  parent="$(dirname "$search")"; [ "$parent" = "$search" ] && break; search="$parent"
done
if [ -n "$plugins_root" ]; then
  for f in "$plugins_root"/*/.mcp.json; do
    [ -f "$f" ] && servers="$servers$(collect_from_mcp_json "$f" "$(dirname "$f")")
"
  done
fi

# Source B — fallback to the installed harness config when no marketplace tree was found.
if [ -z "${servers//[$' \t\n']/}" ]; then
  for cfg in "${HOME:-/nonexistent}/.claude/mcp.json" "${HOME:-/nonexistent}/.claude.json"; do
    [ -f "$cfg" ] && servers="$servers$(collect_from_mcp_json "$cfg")
"
  done
fi

# Nothing discoverable → can't probe → silent exit 0 (the honest degrade-to-silence path).
[ -n "${servers//[$' \t\n']/}" ] || exit 0

# ── 5. Probe each (unique) server's launcher: bounded, non-destructive ───────────────────
TIMEOUT=""; command -v timeout >/dev/null 2>&1 && TIMEOUT="timeout 8"

probe_command() {  # $1 = launch command (npx|uvx|node|python|… or a resident path) → 0 live, 1 dead, 2 undecidable
  local launcher="$1"
  [ -n "$launcher" ] || return 2
  # A resident-path launcher (a plugin-shipped script/binary, e.g. a
  # ${CLAUDE_PLUGIN_ROOT}/.../<server> command) is checked as a FILE, not via PATH lookup.
  case "$launcher" in
    *'${'*) return 2 ;;                         # an unresolved variable → can't decide, stay silent
    */*)
      [ -x "$launcher" ] && return 0            # present + executable → launcher reachable
      return 1 ;;                                # missing / not executable → DEAD
  esac
  # The runner itself must be on PATH; if it isn't, the server cannot start → DEAD.
  command -v "$launcher" >/dev/null 2>&1 || return 1
  # Confirm the runner answers a trivial, NON-DESTRUCTIVE, network-free flag under a timeout.
  # --help / --version never install or fetch; we don't run the MCP package (that would hang
  # on stdio). An ambiguous timeout → undecidable (silence), never a false "dead".
  local rc
  case "$launcher" in
    npx|uvx|node|python|python3|deno|bun)
      $TIMEOUT "$launcher" --version >/dev/null 2>&1; rc=$?
      ;;
    *)
      $TIMEOUT "$launcher" --version >/dev/null 2>&1; rc=$?
      ;;
  esac
  if [ "$rc" -eq 0 ]; then return 0; fi
  # 124 = timeout's kill code → undecidable, not dead.
  [ "$rc" -eq 124 ] && return 2
  return 1
}

# Build the list of dead servers as {name,reason} pairs (dedup by name).
seen_names=" "
declare -a dead_names=() dead_reasons=()
while IFS=$'\t' read -r name command; do
  [ -n "$name" ] || continue
  case "$seen_names" in *" $name "*) continue;; esac
  seen_names="$seen_names$name "
  probe_command "$command"; verdict=$?
  if [ "$verdict" -eq 1 ]; then
    dead_names+=("mcp.$name")
    dead_reasons+=("launcher '$command' for MCP '$name' is not runnable (not on PATH or failed to start)")
  fi
  # verdict 0 (live) or 2 (undecidable) → write nothing (degrade to silence).
done <<< "$servers"

# No dead servers → nothing to record. Silent, idempotent, exit 0.
[ "${#dead_names[@]}" -gt 0 ] || exit 0

# ── 6. Write/merge the DEGRADED_CAPABILITIES state file (additive + idempotent) ──────────
mkdir -p "$I2P_DIR" 2>/dev/null || exit 0
STATE="${I2P_DIR}/degraded-capabilities.json"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"
emitter="i2p:sessionstart-mcp-liveness"

# Existing doc (tolerate absent/corrupt: corrupt → start fresh rather than crash).
base='{"schema":"degraded-capabilities/1.0","degraded":[]}'
if [ -f "$STATE" ] && jq -e . "$STATE" >/dev/null 2>&1; then
  base="$(cat "$STATE")"
fi

# Build the new records array.
new_records="[]"
for i in "${!dead_names[@]}"; do
  rec="$(jq -nc \
    --arg cap "${dead_names[$i]}" \
    --arg reason "${dead_reasons[$i]}" \
    --arg phase "$current_phase" \
    --arg emitter "$emitter" \
    --arg ts "$ts" \
    '{capability:$cap, reason:$reason, since_phase:$phase, emitter:$emitter}
       + (if $ts == "" then {} else {ts:$ts} end)')"
  new_records="$(printf '%s\n%s' "$new_records" "$rec" | jq -cs '.[0] + [.[1]]')"
done

# Append-merge: add a record only if no existing record already has that capability
# (idempotent per the contract — re-running the hook does not duplicate). since_phase of
# an already-recorded degradation is preserved (it tracks FIRST observation).
merged="$(printf '%s\n%s' "$base" "$new_records" | jq -cs '
  .[0] as $doc | .[1] as $new
  | ($doc.degraded // []) as $cur
  | ($cur | map(.capability)) as $have
  | {schema: ($doc.schema // "degraded-capabilities/1.0"),
     degraded: ($cur + [ $new[] | select(.capability as $c | ($have | index($c)) | not) ])}
')" || exit 0

# Atomic write.
tmp="$(mktemp "${I2P_DIR}/.degraded-XXXXXX" 2>/dev/null || echo "")"
if [ -n "$tmp" ]; then
  printf '%s\n' "$merged" > "$tmp" 2>/dev/null && mv -f "$tmp" "$STATE" 2>/dev/null || rm -f "$tmp" 2>/dev/null
fi

exit 0
