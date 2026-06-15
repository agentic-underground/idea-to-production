# MISSION-CONTROL — Roadmap (moved)

> **The roadmap has moved.** The single source of truth is now the file-per-item tree at
> **[`.i2p/roadmap/`](../../.i2p/roadmap/)** — one file per item, the folder is the status
> (`backlog` / `do` / `doing` / `done`). See [`.i2p/roadmap/README.md`](../../.i2p/roadmap/README.md).

**Do not add items here.** Capture and carry items through the roadmapper skill and
`/mission-control:flow`; query "what's on the roadmap" via the roadmapper (flow-server `render_roadmap`
MCP, else a structured scan of the tree) — never by ad-hoc-reading files.

The 39 historical items (EPICs #0/#9/#16/#27/#32 and their children) were migrated verbatim into
`.i2p/roadmap/`. Their authoritative state lives there.

> **Transition note:** the flow-server is not yet tree-aware — wiring it to read `.i2p/roadmap/`
> (so its `render_roadmap` reflects the tree) is roadmap item **[42]**, and the SVG board it serves is
> slated for removal in item **[39]**. Until [42] lands, prefer the roadmapper's tree scan.
