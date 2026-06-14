---
name: coverage-await-question-regions
description: How to keep llvm-cov region coverage at 100% when adding code with `?` on async committing calls in flow-server
metadata:
  type: feedback
---

In the flow-server crate, the coverage floor is 100% line AND region for non-main, non-intest files, measured with `cargo llvm-cov --workspace --ignore-filename-regex 'main\.rs'`. main.rs is the only coverage-excluded shim.

Rule: a `?` on an `await` of a committing store verb creates a separate llvm-cov error-region that is only "covered" when that exact call site short-circuits with an error. If a method has TWO such committing `?` sites in sequence (e.g. upsert-then-post_status per item, or item-commit-then-edge-commit), only the FIRST is fault-reachable via a filesystem fault (corrupt `events.jsonl`/markdown to a directory) — the second can never be made to fault independently because both write the same paths under one call. That leaves an uncovered region.

**Why:** I hit this adding `Store::ingest_roadmap`. First design used `upsert_item().await?` then `post_status().await?` per item plus a per-edge `commit().await?` — three commit `?` sites, two structurally unreachable-to-fault, two uncovered regions.

**How to apply:** Funnel a batch ingest to a SINGLE `self.commit(...).await?` site: take the lock once, apply all flow mutations and collect `Vec<Event>` first, then commit them in one trailing loop. One commit `?` site is covered by a single "events.jsonl is a directory" fault test. Push pure classification (e.g. graph-refused-vs-applied edge) into a tiny non-generic helper returning a plain `bool`/value with NO `Err` arm, and unit-test both arms directly — mirrors the crate's existing `into_store_line` pattern. Note: store.rs carries ONE long-standing tolerated uncovered region — the `into_store_line(serde_json::to_string(&event))?` serialize `?` inside `commit` (an Event always serializes, so its Err path is unreachable through commit). Do not chase it; it predates any new work and the baseline already has it.

Related: [[verify-baseline-coverage-before-claiming-floor]]
