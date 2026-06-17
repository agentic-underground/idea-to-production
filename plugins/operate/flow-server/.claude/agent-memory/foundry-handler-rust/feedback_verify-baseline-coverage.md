---
name: verify-baseline-coverage-before-claiming-floor
description: Measure the pre-change coverage baseline (non-git) before asserting a 100% floor in flow-server
metadata:
  type: feedback
---

When a task says "non-main, non-intest files at 100% region", do NOT assume the baseline already meets it. The flow-server baseline has 28 missed regions TOTAL (api.rs 6, mcp.rs 8, store.rs 1, ws.rs 1, ws_contract_intest.rs 12) and 12 missed lines — it is NOT at 100% region.

**Why:** I almost chased a store.rs uncovered region that turned out to be pre-existing (the `commit` serialize `?`). Establishing the true baseline reframed the goal correctly: get MY new code to 100% and introduce ZERO new uncovered regions, rather than fix pre-existing gaps the task didn't ask me to touch (and that aren't in my files).

**How to apply:** Before editing, or when a region looks stubborn, snapshot the baseline. The task here forbade git (no stash) — so copy the target files to /tmp, reconstruct the pre-change version of the file(s) under test (strip your additions with a small python edit), run `cargo llvm-cov --ignore-filename-regex 'main\.rs' --summary-only`, note the per-file missed-region counts, then restore your version from the /tmp copies. Compare final vs baseline missed-region counts per file; they must match for files you didn't intend to improve, and your new files must be 100%.

Related: [[coverage-await-question-regions]]
