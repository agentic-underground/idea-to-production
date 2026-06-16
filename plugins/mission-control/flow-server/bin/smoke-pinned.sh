#!/usr/bin/env bash
# smoke-pinned.sh — the regression guard for defect [92]. Boots the PINNED RELEASE binary
# (the exact artifact users run — named in bin/RELEASE, SHA-verified against bin/SHA256SUMS)
# against the repo's own .i2p/roadmap/ tree and asserts the MCP renders it NON-empty.
#
# Why this exists: the existing smoke-mcp.sh builds from SOURCE (always current) and was
# green while the PINNED binary (flow-server-v0.1.0) predated the tree ingest of item [42]
# → render_roadmap returned empty over MCP. CI tested the wrong binary. This test pins the
# right one. It NEVER falls back to a source build (that would mask a stale pin): it uses
# `--ensure-binary` (retrieve-only) and fails if the pinned release can't be fetched/verified
# or renders empty.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$(cd "$SCRIPT_DIR/../.." && pwd)"          # plugins/mission-control
ROOT="$(cd "$PLUGIN/../.." && pwd)"                # repo root (where .i2p/roadmap lives)
LAUNCHER="$SCRIPT_DIR/flow-server-mcp"
TAG="$(tr -d '[:space:]' < "$SCRIPT_DIR/RELEASE")"
ext=""; case "$(uname -m)" in arm64|aarch64) arch=aarch64 ;; *) arch=x86_64 ;; esac
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ext=".exe" ;; esac

CACHE="$(mktemp -d)"
trap 'rm -rf "$CACHE"' EXIT

# 1. Retrieve ONLY (no source build) — downloads + SHA-verifies the pinned asset into $CACHE.
XDG_CACHE_HOME="$CACHE" CLAUDE_PLUGIN_ROOT="$PLUGIN" "$LAUNCHER" --ensure-binary 2>&1 | sed 's/^/  /'

BIN="$(find "$CACHE/flow-server" -type f -name "flow-server${ext}" 2>/dev/null | head -n1)"
if [ -z "$BIN" ] || [ ! -x "$BIN" ]; then
  echo "FAIL: could not retrieve + verify the pinned release binary ($TAG, ${arch}). A stale or"
  echo "      mispinned bin/RELEASE / bin/SHA256SUMS — or the release assets are missing."
  exit 1
fi

# 2. Run the PINNED binary --mcp from the repo root with a FRESH --data store. The fresh
#    store is essential: a persisted .flow/ would replay prior items and let a stale binary
#    (no tree ingest) pass by replay — masking the defect. With an empty store, the ONLY
#    path to a populated roadmap is the binary ingesting the .i2p/roadmap/ tree itself.
out="$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_roadmap","arguments":{}}}' \
  | ( cd "$ROOT" && timeout 60 "$BIN" --mcp --data "$CACHE/.flow" ) 2>/dev/null )"

# 3. Assert the pinned binary renders the tree NON-empty (this is what v0.1.0 failed).
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
    sys.exit("FAIL: pinned release ping reports items=%s — the pinned binary does not ingest the "
             ".i2p/roadmap tree (stale release predating item [42]?)." % items)
if not rendered_ok:
    sys.exit("FAIL: pinned release render_roadmap did not return a populated roadmap.")
print("smoke-pinned: OK — pinned release %s renders %d roadmap items over MCP." % ("'"$TAG"'", items))
' || { echo "--- pinned binary output ---"; printf '%s\n' "$out"; exit 1; }
