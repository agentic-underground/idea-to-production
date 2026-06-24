---
id: 31
title: "Commit-graph view (git-style, in the ITEM detail)"
status: COMPLETE
priority: LOW
added: 2026-06-14
depends_on: "#28"
completed: 2026-06-14
---

# [31] Commit-graph view (git-style, in the ITEM detail)

**Brief Description**
In the RHS item-detail, render the item's commits as a git-style graph — dots on a connecting line, each
clickable to reveal the full commit message (hash + message, monospace), readable in full with scroll.

### Acceptance Criteria
1. Given an item with commits, the detail shows a dot-and-line graph; clicking a dot reveals the full message.
2. Long commit messages are fully readable (scroll).

### Implementation Notes
- Consumes #28's panel; commit data from the server (`/api/events` or a commits field). JetBrains Mono for hashes. Plan §commit-graph.

### Development Plan Reference
`doc/FLOW_COMMIT_GRAPH_PLAN.md`
