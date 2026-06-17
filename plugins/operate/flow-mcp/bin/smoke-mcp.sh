#!/usr/bin/env bash
# smoke-mcp.sh — spawn the committed flow-mcp MCP launcher exactly as the plugin's
# .mcp.json registers it, and assert the JSON-RPC handshake completes. This catches the
# failure class where the shipped command can't start (the regression that motivated the
# retrieved-artifact work): a launcher that can't produce a runnable binary, or a binary
# that doesn't answer `initialize`/`tools/list`, fails here instead of silently in a session.
#
# Resolution is the launcher's own: a verified release binary if pinned, else a source build
# (CI/dev). Run from anywhere; exits non-zero on any handshake failure.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$SCRIPT_DIR/flow-mcp"

[ -x "$LAUNCHER" ] || { echo "FAIL: launcher not executable: $LAUNCHER"; exit 1; }

requests='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

# The launcher may compile from source on a cold machine; the timeout is a generous safety net.
out="$(printf '%s\n' "$requests" | timeout 300 "$LAUNCHER" --mcp 2>/dev/null || true)"

fail() { echo "FAIL: $1"; echo "--- launcher output ---"; printf '%s\n' "$out"; exit 1; }

printf '%s' "$out" | grep -q '"serverInfo"'     || fail "initialize did not return serverInfo (handshake incomplete)"
printf '%s' "$out" | grep -q '"protocolVersion"' || fail "initialize did not return a protocolVersion"
printf '%s' "$out" | grep -q '"render_roadmap"'  || fail "tools/list did not advertise render_roadmap"

echo "smoke-mcp: OK — handshake completed and tools advertised via the shipped launcher."
