#!/usr/bin/env bash
# focus.sh — read/write the per-repo FOCUS declaration (.i2p/focus) for the context-routing gate.
# Subcommands:  (none)|status → report ; <PHASE> → set ; off → clear.
# The active phase is broadcast into every session by hooks/scripts/focus-routing.sh, which steers the
# agent to treat out-of-phase skills (by their metadata.phase) as dormant. See docs/guide/context-routing.md §4.
set -uo pipefail

DIR="${CLAUDE_PROJECT_DIR:-.}"
FOCUS="$DIR/.i2p/focus"
PHASES="DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE"

up() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
is_phase() { case " $PHASES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

cmd="${1:-status}"
case "$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')" in
  status|"")
    if [ -f "$FOCUS" ]; then
      ph="$(awk -F': *' '/^phase:/{print $2; exit}' "$FOCUS")"
      note="$(awk -F': *' '/^note:/{sub(/^note: */,""); print; exit}' "$FOCUS")"
      printf '🎯 FOCUS: %s\n' "$ph"
      [ -n "$note" ] && printf '   note: %s\n' "$note"
      printf '   (out-of-phase skills are steered dormant; /i2p:focus off to clear)\n'
    else
      printf '🎯 no FOCUS set — every installed skill is available. Set one with: /i2p:focus <PHASE>\n'
      printf '   phases: %s\n' "$PHASES"
    fi
    ;;
  off|clear|none)
    if [ -f "$FOCUS" ]; then rm -f "$FOCUS"; printf '🎯 FOCUS cleared — every skill is available again.\n'
    else printf '🎯 no FOCUS was set.\n'; fi
    ;;
  *)
    PH="$(up "$cmd")"
    if ! is_phase "$PH"; then
      printf '✗ "%s" is not a lifecycle phase. Choose one of: %s\n' "$cmd" "$PHASES" >&2
      exit 2
    fi
    mkdir -p "$DIR/.i2p"
    { printf 'phase: %s\n' "$PH"
      shift 2>/dev/null || true
      [ "$#" -gt 0 ] && printf 'note: %s\n' "$*"
    } > "$FOCUS"
    printf '🎯 FOCUS set to %s. Out-of-phase skills are now steered dormant (cross-cut stays available).\n' "$PH"
    printf '   The change is broadcast on the next session start / resume / clear. /i2p:focus off to clear.\n'
    ;;
esac
exit 0
