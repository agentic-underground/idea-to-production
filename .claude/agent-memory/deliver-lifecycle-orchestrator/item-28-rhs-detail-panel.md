---
name: item-28-rhs-detail-panel
description: Delivery notes for item [28] RHS detail panel — coverage gap pattern and Rust signature change complexity
metadata:
  type: project
---

Item [28] delivered on 2026-06-14 to branch feature/epic-27-kanban-uplift, commit c70d020.

**Why:** The flow canvas needed a detail panel for card inspection (issue text, PR linkage, deps).

**Key patterns observed:**

1. **Coverage gap — defensive branches:** `detail.js` defensive `||` fallbacks (e.g. `item.annotations || []`, `commit.hash || ''`) and null-checking guards required explicit tests for the falsy path. The v8 coverage reporter flagged these as uncovered branches on the first green run. Pattern: always test the null/undefined/empty variants of every `||` guard.

2. **Rust item_json signature change:** Changing `item_json(item: &Item)` to `item_json(item, deps, annotations)` required updating both `api.rs` handlers AND `mcp.rs`. The MCP module imports `item_json` from `api.rs` — always search for all import sites when changing a `pub(crate)` function signature.

3. **Two lock acquisitions in handlers:** `list_items` and `get_item` take two sequential async lock acquisitions — `snapshot().await` then `read_events().await`. This is safe for read-only paths (no invariant requires atomicity between them) but must not be done for write paths.

4. **STORY_PROVEN via integration tests:** Playwright wasn't available. Used Rust integration tests in `http_surface_intest.rs` with `tower::ServiceExt::oneshot` to prove the API story — this is the established pattern in this codebase.

**How to apply:** When extending item_json or any pub(crate) function used by both REST and MCP layers, always grep for all call sites before changing the signature. When authoring detail.js-style modules with many defensive branches, plan for a second round of branch-coverage tests after the first green run.
