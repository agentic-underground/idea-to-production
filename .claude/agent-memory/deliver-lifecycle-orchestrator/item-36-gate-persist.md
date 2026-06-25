---
name: item-36-gate-persist
description: Sequencing trap and shape-change breaking pattern from gate persistence delivery
metadata:
  type: project
---

# Item [36] Gate Persistence — Delivery notes

**Sequencing trap (MUST HANDLE in similar items):** `Store::open()` replays JSONL
(restoring gates via `GateSet` events), then `ingest_roadmap()` calls `upsert_item()`
which resets each item's gate to `Go` (the `Item::new` default). Therefore
`restore_gates()` MUST run AFTER `ingest_roadmap()` in `main.rs`. This is a non-obvious
ordering dependency — test `restore_gates_after_ingest_roadmap_preserves_wait` pins it.

**Why:** Without this sequencing, `ingest_roadmap` silently clobbers any restored gates,
making the feature appear to work in isolation but fail in the real startup sequence.

**How to apply:** Any feature that introduces post-startup state restoration must check
whether `ingest_roadmap` or equivalent bulk-upsert calls follow `Store::open()` — if so,
the restore must run last.

---

**MCP response shape change breaking pattern:** Changing `list_items` from flat
`{"items":[...]}` to grouped shape broke two existing tests:
1. `mcp_contract_intest::mcp_list_items` — used `v["result"]["items"].as_array()`
2. `mcp_surface_intest::list_items_returns_seeded` — same issue

**Why:** The shape change is intentional (AC-3), but pre-existing tests embed the old
shape assumption. They must be updated alongside the implementation.

**How to apply:** When an MCP tool's response shape changes, grep all `*_intest.rs` files
for the old key name before running tests to find all consumers to update.

---

**Atomic write path:** `Path::with_extension("json.tmp")` on `gates.json` produces
`gates.json.tmp` (appends, not replaces extension). This is the correct tmp sibling.
Use `tokio::fs::rename()` — atomic on Linux when source and destination are in same dir.

**Coverage of warn-and-continue branch:** Simulate sidecar write failure by replacing
the target path with a directory (`std::fs::create_dir_all(dir.join("gates.json"))`).
The `rename()` onto a directory fails on Linux, exercising the warn path.

PR: https://github.com/agentic-underground/idea-to-production/pull/66
