#!/usr/bin/env bash
# mermaid-lint.sh — ADVISORY pre-render warnings for Mermaid .mmd files.
#
# This NEVER fails the build (exit 0 always). `mmdc` is the authoritative parser, and
# build-pdf.sh already fails fast on a real parse error (e.g. a reserved char, F12). This linter
# only flags the *silent-but-ugly* patterns mmdc renders without complaint — the ones a human
# reviewer would catch. Checks are deliberately conservative (scoped to specific contexts) to
# avoid false-positives; bash cannot truly parse Mermaid, so these are heuristics, not gospel.
#
# Usage:  mermaid-lint.sh <dir|file> [more…]   (a dir is scanned for *.mmd)
set -uo pipefail

warn() { printf '    ⚠ mermaid-lint %s: %s\n' "$1" "$2" >&2; }

scan() {
  local f="$1" ln rest
  # R-A4 / F11 — a shared edge label fanned across a '&' node-product (A & B -- "x" --> C & D):
  # the label is stamped on every edge of the product and overprints into a smear.
  grep -nE '&.*-[-.][^>]*"[^"]+".*-?-?>.*&' "$f" 2>/dev/null | while IFS=: read -r ln rest; do
    warn "$f:$ln" "shared edge label across a '&' node-product → doubles/overprints (R-A4/F11); label one group→group edge instead"
  done
  # F12 (early hint) — a ';' inside a Note will hard-fail mmdc; flag it before the render does.
  grep -nE '^[[:space:]]*[Nn]ote\b.*;' "$f" 2>/dev/null | while IFS=: read -r ln rest; do
    warn "$f:$ln" "';' inside a Note breaks the Mermaid parse (F12) — use a comma or em-dash"
  done
  # R-A5 (nudge) — multiple bar/line series in one xychart-beta: no legend/colour control, and a
  # small series vanishes on a linear axis. Only warns when 2+ series are present.
  if grep -qE '^[[:space:]]*xychart-beta' "$f" 2>/dev/null; then
    local series; series=$(grep -cE '^[[:space:]]*(bar|line)\b' "$f" 2>/dev/null || echo 0)
    [ "${series:-0}" -ge 2 ] && warn "$f" "xychart-beta with ${series} series — no legend/colour control; prefer a table with a ratio column (R-A5)"
  fi
}

for arg in "$@"; do
  if [ -d "$arg" ]; then
    for f in "$arg"/*.mmd; do [ -e "$f" ] && scan "$f"; done
  elif [ -e "$arg" ]; then
    scan "$arg"
  fi
done
exit 0   # advisory only — never blocks the build
