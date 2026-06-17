#!/usr/bin/env bash
# smoke-pinned.sh — the regression guard for defect [92]. Boots the PINNED RELEASE binary
# (the exact artifact users run — named in bin/RELEASE, SHA-verified against bin/SHA256SUMS)
# against the repo's own .i2p/roadmap/ tree and asserts the MCP renders it NON-empty AND that
# the running binary self-reports the pinned crate version (so a stale/mispinned release fails).
#
# Why this exists: smoke-mcp.sh builds from SOURCE (always current) and stayed green while the
# shipped binary predated the tree ingest of item [42] → render_roadmap returned empty over MCP.
# CI tested the wrong binary. This pins the right one. It NEVER falls back to a source build
# (that would mask a stale pin): it uses `--ensure-binary` (retrieve-only) and fails if the
# pinned release can't be fetched/verified or renders empty.
#
# BOOTSTRAP WINDOW: between bumping bin/RELEASE and the release workflow publishing the assets +
# checksums, bin/SHA256SUMS has no line for this platform. In that window the guard cleanly SKIPs
# (exit 0) — it cannot test a release that does not exist yet. Once the checksums are committed it
# enforces. (verify-prereqs.sh guarantees the pin is well-formed and Cargo==tag regardless.)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$(cd "$SCRIPT_DIR/../.." && pwd)"          # plugins/flow
ROOT="$(cd "$PLUGIN/../.." && pwd)"                # repo root (where .i2p/roadmap lives)
FS_DIR="$PLUGIN/flow-mcp"
LAUNCHER="$SCRIPT_DIR/flow-mcp"
SUMS_FILE="$SCRIPT_DIR/SHA256SUMS"
TAG="$(tr -d '[:space:]' < "$SCRIPT_DIR/RELEASE")"
CARGO_VER="$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$FS_DIR/Cargo.toml" | head -n1)"
ext=""; case "$(uname -m)" in arm64|aarch64) arch=aarch64 ;; *) arch=x86_64 ;; esac
# Reconstruct the platform triple EXACTLY as the launcher's target_triple() and the release
# matrix do — Windows must map to pc-windows-msvc (+.exe), never the linux default, or the
# bootstrap-skip check would look up the wrong asset and silently pass on Windows.
case "$(uname -s)" in
  Linux)                os=unknown-linux-gnu ;;
  Darwin)               os=apple-darwin ;;
  MINGW*|MSYS*|CYGWIN*) os=pc-windows-msvc; ext=".exe" ;;
  *)                    os=unknown-linux-gnu ;;
esac
ASSET="flow-mcp-${arch}-${os}${ext}"

# Bootstrap-window skip: no committed checksum line for this platform yet → the pinned release
# has not been published. Cleanly pass (the guard goes live once bin/SHA256SUMS is finalized).
has_pin="$(awk -v a="$ASSET" '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
  ($2==a || $2=="*"a) && $1 ~ /^[0-9a-fA-F]{64}$/ { print "yes"; exit }
' "$SUMS_FILE" 2>/dev/null || true)"
if [ "$has_pin" != "yes" ]; then
  echo "smoke-pinned: SKIP — bin/SHA256SUMS has no line for ${ASSET} yet (pin ${TAG} not published)."
  echo "             This is the bootstrap window; the guard enforces once the checksums are committed."
  exit 0
fi

CACHE="$(mktemp -d)"
trap 'rm -rf "$CACHE"' EXIT

# 1. Retrieve ONLY (no source build) — downloads + SHA-verifies the pinned asset into $CACHE.
XDG_CACHE_HOME="$CACHE" CLAUDE_PLUGIN_ROOT="$PLUGIN" "$LAUNCHER" --ensure-binary 2>&1 | sed 's/^/  /'

BIN="$(find "$CACHE/flow-mcp" -type f -name "flow-mcp${ext}" 2>/dev/null | head -n1)"
if [ -z "$BIN" ] || [ ! -x "$BIN" ]; then
  echo "FAIL: could not retrieve + verify the pinned release binary ($TAG, ${arch}). A stale or"
  echo "      mispinned bin/RELEASE / bin/SHA256SUMS — or the release assets are missing."
  exit 1
fi

# 2. Run the PINNED binary --mcp from the repo root with a FRESH --data store. The fresh store
#    is essential: a persisted .flow/ would replay prior items and let a stale binary (no tree
#    ingest) pass by replay — masking the defect. With an empty store, the ONLY path to a
#    populated roadmap is the binary ingesting the .i2p/roadmap/ tree itself.
out="$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_roadmap","arguments":{}}}' \
  | ( cd "$ROOT" && timeout 60 "$BIN" --mcp --data "$CACHE/.flow" ) 2>/dev/null )"

# 3. Assert: ping version starts with the pinned Cargo version (catches a stale/mispinned asset)
#    AND render_roadmap returns a POSITIVE item count (what v0.1.0 failed).
printf '%s\n' "$out" | CARGO_VER="$CARGO_VER" TAG="$TAG" python3 -c '
import sys, os, json, re
want_ver = os.environ["CARGO_VER"]
items = None
ping_ver = None
rendered_ok = False
for ln in sys.stdin:
    ln = ln.strip()
    if not ln:
        continue
    o = json.loads(ln)
    r = o.get("result", {})
    if o.get("id") == 2 and isinstance(r, dict):
        items = r.get("items")
        ping_ver = r.get("version")
    if o.get("id") == 3 and isinstance(r.get("rendered"), str):
        rendered_ok = bool(re.search(r"\b[1-9]\d* item", r["rendered"]))
if ping_ver is None or not str(ping_ver).startswith(want_ver):
    sys.exit("FAIL: pinned release self-reports version %r but Cargo.toml pins %r — the published "
             "asset is stale or mispinned." % (ping_ver, want_ver))
if items is None or items < 1:
    sys.exit("FAIL: pinned release ping reports items=%s — the pinned binary does not ingest the "
             ".i2p/roadmap tree (stale release predating item [42]?)." % items)
if not rendered_ok:
    sys.exit("FAIL: pinned release render_roadmap did not return a populated roadmap.")
print("smoke-pinned: OK — pinned release %s (v%s) renders %d roadmap items over MCP."
      % (os.environ["TAG"], want_ver, items))
' || { echo "--- pinned binary output ---"; printf '%s\n' "$out"; exit 1; }
