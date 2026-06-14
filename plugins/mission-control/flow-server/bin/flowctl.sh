#!/usr/bin/env bash
# flowctl — managed-daemon controller for the flow server (the SVG roadmap board).
#
# The flow board must be running and network-reachable whenever the project's roadmap
# has >= 1 item. `ensure` is the idempotent driver the hooks call: it starts the daemon
# (bound to the network) when the roadmap is non-empty and stops it when the roadmap is
# empty. State lives in the consuming project's .flow/ runtime dir (gitignored).
#
# Subcommands: ensure | start | stop | status | url | port | build | install-widget
#
# SECURITY: the daemon binds 0.0.0.0 (LAN-reachable) by default — the bearer token in
# .flow/token is the ONLY guard, and the advertised URL embeds it. Treat the URL as a
# secret on a shared network. Set FLOW_HOST=127.0.0.1 to bind localhost-only.
set -uo pipefail

# --- locations ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# CLAUDE_PLUGIN_ROOT (set in a hook) = the mission-control plugin root; else derive it
# (this script lives at <plugin>/flow-server/bin/flowctl.sh).
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$SCRIPT_DIR")")}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
FLOW="$PROJECT/.flow"
BIN="$PLUGIN/flow-server/target/debug/flow-server"
STATIC="$PLUGIN/flow-server/static"
MANIFEST="$PLUGIN/flow-server/Cargo.toml"
WIDGET_SRC="$PLUGIN/hooks/scripts/flow-statusline-widget.sh"
WIDGET_DST="${HOME}/.claude/state/statusline-widgets.d/flow.sh"
FLOW_HOST="${FLOW_HOST:-0.0.0.0}"
BASE_PORT=7421

# --- helpers -----------------------------------------------------------------
resolve_roadmap() {
  # 1. explicit env override (also persisted below so hook-driven ensure keeps finding it)
  if [ -n "${FLOW_ROADMAP:-}" ] && [ -f "$FLOW_ROADMAP" ]; then
    mkdir -p "$FLOW" 2>/dev/null && printf '%s' "$FLOW_ROADMAP" > "$FLOW/roadmap" 2>/dev/null || true
    printf '%s' "$FLOW_ROADMAP"; return 0
  fi
  # 2. a previously-pinned override (a project with a non-standard roadmap location)
  if [ -s "$FLOW/roadmap" ]; then
    local pinned; pinned="$(cat "$FLOW/roadmap" 2>/dev/null)"
    [ -f "$pinned" ] && { printf '%s' "$pinned"; return 0; }
  fi
  # 3. the conventional locations
  local c
  for c in "ROADMAP.md" "doc/ROADMAP.md" "docs/ROADMAP.md"; do
    [ -f "$PROJECT/$c" ] && { printf '%s' "$PROJECT/$c"; return 0; }
  done
  return 0   # none → empty
}

item_count() {
  local f="$1"
  [ -n "$f" ] && [ -f "$f" ] && grep -c '^## \[' "$f" 2>/dev/null || printf '0'
}

lan_ip() {
  local ip=""
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"                 # Linux
  [ -z "$ip" ] && ip="$(ipconfig getifaddr en0 2>/dev/null)"        # macOS
  [ -z "$ip" ] && ip="127.0.0.1"
  printf '%s' "$ip"
}

port_in_use() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 2>/dev/null; return 0; } || return 1; }

port() {
  if [ -s "$FLOW/port" ]; then cat "$FLOW/port"; return 0; fi
  local off p i
  off=$(printf '%s' "$PROJECT" | cksum | awk '{print $1 % 1000}')
  p=$((BASE_PORT + off))
  for i in $(seq 0 50); do
    port_in_use "$((p + i))" || { p=$((p + i)); break; }
  done
  mkdir -p "$FLOW"; printf '%s' "$p" > "$FLOW/port"; printf '%s' "$p"
}

alive() {
  local pid
  pid="$(cat "$FLOW/pid" 2>/dev/null)" || return 1
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
  rm -f "$FLOW/pid"; return 1
}

install_widget() {
  [ -f "$WIDGET_SRC" ] || return 0
  mkdir -p "$(dirname "$WIDGET_DST")" 2>/dev/null || return 0
  cp "$WIDGET_SRC" "$WIDGET_DST" 2>/dev/null || true
  chmod +x "$WIDGET_DST" 2>/dev/null || true
}

build_async() {
  command -v cargo >/dev/null 2>&1 || { echo "cargo-missing" > "$FLOW/build.lock" 2>/dev/null; return 0; }
  [ -f "$FLOW/build.lock" ] && return 0
  mkdir -p "$FLOW"
  ( touch "$FLOW/build.lock"
    cargo build --manifest-path "$MANIFEST" >>"$FLOW/flow-server.log" 2>&1
    rm -f "$FLOW/build.lock"
    "$SCRIPT_DIR/flowctl.sh" ensure
  ) </dev/null >/dev/null 2>&1 &
  setsid disown 2>/dev/null || disown 2>/dev/null || true
}

# --- subcommands -------------------------------------------------------------
start() {
  alive && return 0
  mkdir -p "$FLOW"
  if [ ! -x "$BIN" ]; then build_async; return 0; fi
  local rm p; rm="$(resolve_roadmap)"; p="$(port)"
  # shellcheck disable=SC2086
  setsid "$BIN" --host "$FLOW_HOST" --port "$p" \
      --data "$FLOW" --token "$FLOW/token" --static "$STATIC" \
      ${rm:+--roadmap "$rm"} </dev/null >>"$FLOW/flow-server.log" 2>&1 &
  echo $! > "$FLOW/pid"
  disown 2>/dev/null || true
  install_widget
  return 0
}

stop() {
  local pid; pid="$(cat "$FLOW/pid" 2>/dev/null)"
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
  rm -f "$FLOW/pid"
  return 0
}

ensure() {
  local rm n; rm="$(resolve_roadmap)"; n="$(item_count "$rm")"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then start; else stop; fi
}

url() {
  alive || return 1
  local tok; tok="$(cat "$FLOW/token" 2>/dev/null)"
  [ -n "$tok" ] || return 1
  printf 'http://%s:%s/?token=%s' "$(lan_ip)" "$(port)" "$tok"
}

status() {
  if alive; then echo "running — $(url 2>/dev/null)"; else
    [ -f "$FLOW/build.lock" ] && echo "building…" || echo "stopped"
  fi
}

build() { command -v cargo >/dev/null 2>&1 && cargo build --manifest-path "$MANIFEST"; }

case "${1:-status}" in
  ensure) ensure ;;
  start)  start ;;
  stop)   stop ;;
  status) status ;;
  url)    url || true ;;
  port)   port ;;
  build)  build ;;
  install-widget) install_widget ;;
  *) echo "usage: flowctl {ensure|start|stop|status|url|port|build|install-widget}" >&2 ;;
esac
exit 0
