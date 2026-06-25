---
name: item-31-commit-graph
description: Delivery pattern for [31] commit-graph view — replacing a plain list renderer with a new module via one-line delegation in the consumer.
metadata:
  type: project
---

# Item [31] Commit-graph view — delivery notes

## Delivered: 2026-06-14, commit 7e17b88 on feature/epic-27-kanban-uplift

The plain-list `renderItemBottom` in `detail.js` was replaced by a one-line delegation to `renderCommitGraph` imported from `commit-graph.js`. This is the minimal-coupling upgrade pattern: the new module owns all the behavior; the consumer becomes a thin adapter.

**Why:** AC1 required dot-and-line graph with expand/collapse; the plain `<ul>` had no expand affordance.

**How to apply:** When upgrading a renderer inside a container module, create the new renderer as a pure exported function (no side effects, takes container + data), then replace the old renderer body with a single delegation call. This keeps the container module's test surface stable.

## Test class name migration

The [28]-era branch coverage tests in `detail.test.js` queried `.detail-commit-hash` and `.detail-commit-msg` (old plain-list classes). After [31], these classes no longer exist — replaced by `.commit-hash` and `.commit-summary`. The tests were updated in the same commit.

**Pattern:** When a renderer is replaced, scan the existing test file for class name references to the old renderer and update them. These are specification-driven updates (new class names from new EARS spec), not test accommodation.

## Single-expand constraint

The commit-graph implements single-expand via a closure-level `activeDot`/`activeBody` pair. Clicking any dot first collapses the active one, then opens the new one. Clicking the already-active dot collapses it and clears the tracker.

**Why:** The Gherkin scenario "clicking a second dot collapses the first" required this constraint. The test verifies it at the multi-commit level.

Related: [[item-28-rhs-detail-panel]]
