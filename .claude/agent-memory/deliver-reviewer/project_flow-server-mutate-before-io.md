---
name: flow-server-mutate-before-io
description: flow-server Store mutates in-memory flow before a fallible .await? IO step with no rollback / no mutex poison — recurring consistency-window class
metadata:
  type: project
---

flow-server `Store` methods advance the in-memory `flow` (e.g. `advance_status` mutates `item.status` in place, `domain/model.rs`) BEFORE a fallible `.await?` IO step, with no rollback and `tokio::Mutex` (no poison). On IO Err the method returns early leaving memory advanced but the JSONL journal un-written → divergence that reverts on restore-from-JSONL.

**Why:** Surfaced reviewing PR #87 / item [42] — `post_status` (store.rs:225-227) added `write_status_to_tree` as a second pre-commit fallible step, widening the pre-existing `commit`-can-fail-after-advance window. Same shape as the baseline commit ordering.

**How to apply:** When reviewing any `Store` method that mutates `guard.flow` before an `.await?` (write-back, commit, persist), check the failure ordering — does memory roll back, or is the journal written first? Treat as a systemic KAIZEN class, not a per-method patch. Note: fs IO under the store lock is the ESTABLISHED, consistent pattern (commit does append_line+write_markdown under the lock; persist_gates uses tmp+rename) — do NOT flag IO-under-lock itself.

Related: [[flow-server-stdio-transport]], [[flow-server-tool-naming-drift]], [[flow-server-pin-parse]]
