---
id: 42
title: "Flow-server reads the .i2p/roadmap/ tree as its source"
status: COMPLETE
priority: HIGH
added: 2026-06-15
completed: 2026-06-16
branch: feat/42-flow-server-reads-roadmap-tree
depends_on: "—"
---

# [42] Flow-server reads the .i2p/roadmap/ tree as its source

**Brief Description**
Make the flow-server read the `.i2p/roadmap/{backlog,do,doing,done}/` tree (file-per-item, folder = status)
as its roadmap source, so `render_roadmap` / `list_items` reflect the tree that is now the single source of
truth. Closes the transition gap left by the roadmap migration (the server currently reads the retired
monolith path).

### User Stories
- AS an agent I WANT `render_roadmap` to reflect the `.i2p/roadmap/` tree SO THAT "what's on the roadmap"
  is authoritative and ~0-token via local compute.
- AS the owner I WANT a status change to be a file move between folders SO THAT git history is the audit trail.

### EARS Specification
**Ubiquitous**
- The flow-server SHALL treat `.i2p/roadmap/` (folder = status) as the authoritative roadmap source.

**Event-driven**
- WHEN `post_status` changes an item's stage THE SYSTEM SHALL move the item file between folders and update
  its `status:` front-matter atomically.
- WHEN `list_items`/`render_roadmap` is called THE SYSTEM SHALL enumerate the tree and group by folder.

**Unwanted behaviour**
- IF the tree is absent THEN THE SYSTEM SHALL report an empty roadmap explicitly (no crash, no stale cache).

### Acceptance Criteria
1. Given the tree, When `render_roadmap` is called, Then the output matches the tree's items grouped by stage.
2. Given `post_status N doing`, Then `N`'s file is in `doing/` with `status: IN PROGRESS`.
3. `cargo test --workspace` green; the retired monolith path is no longer read.

### Implementation Notes
- Replace the single-`ROADMAP.md` reader with a tree loader (parse front-matter; folder→status).
- Parser must tolerate the migrated schema (front-matter + body).
- After this lands, the roadmapper's flow-server path is preferred again; delete the monolith pointer.
