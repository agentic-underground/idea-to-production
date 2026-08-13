#!/usr/bin/env bash
# Launcher for the `board` Python component (PLAN 0072.014) — GitHub Project board lifecycle + rollup.
# Runtime is stdlib-only + the `gh` CLI (no third-party deps); resolves the package dir so the CLI runs
# from anywhere: `bash .../board/board.sh lifecycle <order> <transition>` | `... rollup <epic-order>`.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONPATH="$here${PYTHONPATH:+:$PYTHONPATH}" exec python3 -m board "$@"
