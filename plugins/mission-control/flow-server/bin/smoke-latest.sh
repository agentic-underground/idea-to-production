#!/usr/bin/env bash
# smoke-latest.sh — the regression guard for defect [92], adapted to the no-pin policy.
# Boots the LATEST RELEASE binary (the exact artifact users run — resolved by the launcher
# from GitHub's `releases/latest` and SHA-verified against that release's own SHA256SUMS)
# against the repo's own .i2p/roadmap/ tree and asserts the MCP renders it NON-empty.
#
# Why this exists: the existing smoke-mcp.sh builds from SOURCE (always current) and was
# green while a STALE release binary (flow-server-v0.1.0) predated the tree ingest of item
# [42] → render_roadmap returned empty over MCP. CI tested the wrong binary. This test boots
# the SAME binary an end user gets. It NEVER falls back to a source build (that would mask a
# bad release): it uses `--ensure-binary` (retrieve-only) and fails if the latest release
# can't be resolved/fetched/verified or renders empty.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$(cd "$SCRIPT_DIR/../.." && pwd)"          # plugins/mission-control
ROOT="$(cd "$PLUGIN/../.." && pwd)"                # repo root (where .i2p/roadmap lives)
LAUNCHER="$SCRIPT_DIR/flow-server-mcp"
REPO="agentic-underground/idea-to-production"
ext=""; case "$(uname -m)" in arm64|aarch64) arch=aarch64 ;; *) arch=x86_64 ;; esac
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ext=".exe" ;; esac

# Resolve the latest tag for the success message (best-effort; the launcher resolves its own).
TAG="$(curl -fsSL -o /dev/null -w '%{url_effective}' --connect-timeout 10 --max-time 30 \
      "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)"
case "$TAG" in */releases/tag/*) TAG="${TAG##*/tag/}" ;; *) TAG="latest" ;; esac

CACHE="$(mktemp -d)"
trap 'rm -rf "$CACHE"' EXIT

# 1. Retrieve ONLY (no source build) — resolves latest, downloads + SHA-verifies into $CACHE.
XDG_CACHE_HOME="$CACHE" CLAUDE_PLUGIN_ROOT="$PLUGIN" "$LAUNCHER" --ensure-binary 2>&1 | sed 's/^/  /'

BIN="$(find "$CACHE/flow-server" -type f -name "flow-server${ext}" 2>/dev/null | head -n1)"
if [ -z "$BIN" ] || [ ! -x "$BIN" ]; then
  echo "FAIL: could not resolve + retrieve + verify the latest release binary (${TAG}, ${arch})."
  echo "      The latest release is missing assets, its SHA256SUMS, or could not be reached."
  exit 1
fi

# 2. Run the LATEST binary --mcp from the repo root with a FRESH --data store. The fresh
#    store is essential: a persisted .flow/ would replay prior items and let a stale binary
#    (no tree ingest) pass by replay — masking the defect. With an empty store, the ONLY
#    path to a populated roadmap is the binary ingesting the .i2p/roadmap/ tree itself.
out="$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_roadmap","arguments":{}}}' \
  | ( cd "$ROOT" && timeout 60 "$BIN" --mcp --data "$CACHE/.flow" ) 2>/dev/null )"

# 3. Assert the latest binary renders the tree NON-empty (this is what v0.1.0 failed).
printf '%s\n' "$out" | python3 -c '
import sys, json, re
items = None
rendered_ok = False
for ln in sys.stdin:
    ln = ln.strip()
    if not ln:
        continue
    o = json.loads(ln)
    r = o.get("result", {})
    if o.get("id") == 2 and "items" in r:
        items = r["items"]
    if o.get("id") == 3 and isinstance(r.get("rendered"), str):
        # Require a POSITIVE item count in the render itself: "0 item(s)" must NOT pass, so
        # the guard does not hinge on the items check alone (defence in depth, no apostrophes
        # here because this whole block is inside python3 -c with single quotes).
        rendered_ok = bool(re.search(r"\b[1-9]\d* item", r["rendered"]))
if items is None or items < 1:
    sys.exit("FAIL: latest release ping reports items=%s — the binary does not ingest the "
             ".i2p/roadmap tree (stale release predating item [42]?)." % items)
if not rendered_ok:
    sys.exit("FAIL: latest release render_roadmap did not return a populated roadmap.")
print("smoke-latest: OK — latest release %s renders %d roadmap items over MCP." % ("'"$TAG"'", items))
' || { echo "--- latest binary output ---"; printf '%s\n' "$out"; exit 1; }
