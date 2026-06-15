# .i2p/roadmap/ — the roadmap (file-per-item, single source of truth)

This is the **authoritative roadmap** for the idea-to-production marketplace. Each work item is **one
file**; the **folder is its status**. This replaces the former monolithic `plugins/mission-control/ROADMAP.md`.

```
.i2p/roadmap/
  backlog/   PENDING / DEFERRED — captured, not yet started
  do/        groomed & next — ready to pull
  doing/     IN PROGRESS / SUSPENDED / AWAITING MERGE — being worked
  done/      COMPLETE — shipped
```

- **File name:** `{id}-{slug}.md` (e.g. `16-kaizen-uplift-….md`), `id` zero-padded for ordering.
- **Front-matter:** `id, title, status, priority, added, depends_on` (+ `completed`, `branch`, `deferred`
  when applicable), followed by the entry body (Brief / User Stories / EARS / Acceptance Criteria /
  Implementation Notes — see the roadmapper skill §3.3).
- **A status change = move the file** between folders **and** update its `status:` front-matter.

## How to query / carry — do NOT ad-hoc-read these files

- **"What's on the roadmap?"** is answered by the **roadmapper skill** → flow-server `render_roadmap`
  MCP verb (preferred, ~0 tokens), else a structured scan of this tree. Not by an agent reading files.
- **Carrying an item** through `roadmap → backlog → do → doing → done` (and reporting who is DOING /
  WHAT / cost) is the job of **`/mission-control:flow`** (see roadmap item [41]).

## Dependency tree (EPIC #0 and the families)

```
EPIC #0 Flow-Tracking Governance UI
 ├─ #1 Flow server (HTTP + WebSocket + MCP, one Rust binary)
 ├─ #2 SVG flow-canvas → blocks on #1
 ├─ #3 Carriage agent + token telemetry → blocks on #1
 ├─ #4 Comment / pause / annotate / rewrite loop → blocks on #2, #3
 ├─ #5 Roadmap history + git-log proxy synthesis
 ├─ #6 Masthead progress bar + completion gauge → blocks on #3
 ├─ #8 Per-job model selection → blocks on #1, #2, #3
 ├─ #15 "What's on the roadmap" → MCP list_items → blocks on #1
 └─ #7 The finale → blocks on all
EPIC #9  Process-Documentation & Git Governance  (#10–#14)
EPIC #16 KAIZEN Uplift: GEMBA reflex + missing-handler gate  (#17–#26)
EPIC #27 Flow board kanban uplift  (#28–#31)
EPIC #32 FOUNDRY lifecycle delivery hardening  (#33–#36)
Later (Part B captures): #39–#47 — UI removal, reporting repo, /flow carry, MCP exposure, taxonomy reorg, …
```

> **Note on the web UI:** EPIC #0's SVG governance board is slated for **removal** (item [39]); its
> MCP core is kept and a separate on-demand reporter replaces the board (item [40]).
