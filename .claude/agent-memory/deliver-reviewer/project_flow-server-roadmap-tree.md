---
name: flow-server-roadmap-tree
description: flow-server item [42] wired the server to the .i2p/roadmap/ tree; regression facts — apply_roadmap refactor is faithful, auto-ingest+write-back is a default-behaviour change, watch-hook trigger gap deferred to [39]
metadata:
  type: project
---

Item **[42]** (merged on branch `feat/42-flow-server-reads-roadmap-tree`) made
`flow-server` read AND write the `.i2p/roadmap/{backlog,do,doing,done}/` file-per-item
tree. Regression-review facts worth keeping:

- **`apply_roadmap` refactor is behaviourally faithful.** The old `ingest_roadmap` loop
  body was extracted verbatim into `apply_roadmap(&mut Inner, Roadmap)`; only change is
  `self.commit(&mut guard, ev)` → `self.commit(guard, ev)` (guard already `&mut`). Same
  upsert, `set_status_in_flow`, edge-skip-on-refusal, event order, commit/error
  propagation. The single-file path (`ingest_roadmap`) and its 3 contract tests
  (`ingest_roadmap_loads_*`, `_skips_rejected_edges_*`, `_commit_failure_propagates`) are
  intact. `roadmap_tree = Some(..)` is set ONLY in the tree path, never the single-file path.

- **Default-behaviour change (intended, documented, MEDIUM-grade surprise):** with NO
  `--roadmap` flag the server used to start an empty in-memory board that never touched
  disk. After [42], `ingest_source` auto-detects `.i2p/roadmap/` in cwd, ingests it, AND
  records the tree as the write-back root — so `post_status` (reachable via MCP `set` tool
  + HTTP `/api/items/:id/status`) now physically MOVES + rewrites item files on disk.
  Guarded (only acts when an `id:` matches in the tree). Collision risk on arbitrary
  consumer projects is low (the convention is i2p-specific). Documented in config.rs/README/
  SKILL.md. Not a regression bug — but the "moves files by default with no opt-in" is the
  thing to re-scrutinise if a future item changes the resolver.

- **`flowctl.sh resolve_roadmap` now returns a DIRECTORY** for a tree project. `item_count`
  on a dir uses `find .../{backlog,do,doing,done} -maxdepth 1 -name '*.md' | wc -l | tr -d
  ' '` → clean int. `start` passes `${rm:+--roadmap "$rm"}` and the server handles dirs. No
  other flowctl path assumes `$rm` is a file EXCEPT `FLOW_ROADMAP` env override + pinned
  `.flow/roadmap` (both still `[ -f ]`-gated, so the env override cannot point at a tree —
  pre-existing, by design since the tree is auto-detected).

- **Watch-hook trigger gap (deferred):** `hooks/scripts/flow-roadmap-watch.sh` fast-exits
  unless the edited file matches `*ROADMAP.md`. Tree item files (`42-foo.md`) never match,
  so editing the tree no longer re-drives `ensure` (auto start/stop on roadmap edit). The
  retired monolith `plugins/mission-control/ROADMAP.md` is deleted by this PR, so for THIS
  repo the edit-driven lifecycle is effectively dead until item **[39]** (which explicitly
  scopes updating `flow-roadmap-watch.sh`). SKILL.md line ~24 still says "on a ROADMAP.md
  edit, re-drives" — now stale for tree projects. SessionStart `flow-advertise.sh` still
  starts the board, so the board is not unreachable, just not edit-reactive.

- **Stale-target ghost tests:** a dirty `target/` showed phantom `zzz_attack_intest::*`
  tests (`attack_duplicate_id_two_folders`, `attack_in_place_rewrite_doing_to_doing`) that
  are NOT declared in `lib.rs` and not in any source file. `touch src/lib.rs && cargo test`
  makes them vanish. The real committed suite is exactly **341 lib + 3 stdio_story green**.
  When a flow-server test count looks inflated vs the packet, suspect a stale incremental
  build, not new tests — rebuild before trusting the count.

Related: [[flow-server-tool-naming-drift]] (set_wait_go vs set_gate), [[provenance-archive]]
(docs/internal/*_PLAN.md keep old monolith refs by design — not dangling).
