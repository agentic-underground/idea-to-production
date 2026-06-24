---
id: 6
title: "Masthead progress bar + pac-man completion gauge + system-message feed"
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "#3"
---

# [6] Masthead progress bar + pac-man completion gauge + system-message feed

**Brief Description**
A progress bar across the top of the screen — in the spirit of the root README masthead graphic — wired to
the **actual** roadmap: completion is when no tickets remain and the project returns to "run and observe."
Alongside it, a "pac-man graph" that gradually fills to 100% as the roadmap empties, and a system-message
feed: a mini-blog of orchestrator updates on what's been happening in the value system.

### User Stories
- AS A builder I WANT a top-of-screen progress bar wired to the real roadmap SO THAT I always know how close
  the project is to "done / run and observe."
- AS A builder I WANT a pac-man gauge that fills to 100% SO THAT completion is glanceable and motivating.
- AS A builder I WANT a feed of orchestrator system messages SO THAT I can read what the value system has
  been doing.

### EARS Specification
**Ubiquitous**
- The system SHALL display a masthead progress bar and a pac-man completion gauge whose fill equals the
  fraction of roadmap items that are DONE.
- The system SHALL display a chronological feed of orchestrator system messages.
**Event-driven**
- WHEN the last open ticket closes THE SYSTEM SHALL render both gauges at 100% and indicate the return to
  "run and observe."
- WHEN the orchestrator emits a system message THE SYSTEM SHALL prepend it to the feed in realtime.

### Acceptance Criteria
1. Given N items with K done, Then both gauges read K/N.
2. Given the last item completes, Then both gauges read 100% and the "run and observe" state is shown.
3. Given an orchestrator message is emitted, Then it appears at the top of the feed without reload.

### Implementation Notes
- Reuse `docs/internal/image-craft-study/toolchain/src/build-masthead-svg.sh` for the bar's look; fill bound to the
  DONE fraction over the WebSocket stream; system messages come from the JSONL event log (#3).

### Human Interface Test Plan
- [Progress reflects roadmap]: mark an item DONE → verify both gauges advance without reload.
- [System feed]: trigger an orchestrator message → verify it appears at the top of the feed live.

### Development Plan Reference
`doc/MASTHEAD_PROGRESS_PACMAN_PLAN.md`
