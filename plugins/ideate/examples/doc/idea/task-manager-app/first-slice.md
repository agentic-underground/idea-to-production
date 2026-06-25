# First vertical slice — TaskFlow

> Agent-facing. The smallest shippable, end-to-end increment that proves the core value, so DELIVER can
> cut a thin slice immediately rather than boil the ocean.

## Slice

**Add a task with a title, and mark it complete.**

This is the irreducible loop of the product: capture → see it → complete it. It exercises the full
stack end-to-end (input → state → persistence → render) on the smallest possible surface.

## EARS statement

```
WHEN the user types a non-empty title into the capture box and presses Enter,
THE SYSTEM SHALL add the task to the top of the open-tasks list and clear the capture box.

WHEN the user activates the complete control on an open task,
THE SYSTEM SHALL mark that task done and move it into the completed section.

WHILE the application is loaded,
THE SYSTEM SHALL persist all tasks so they survive a page reload.
```

## Acceptance criteria

- [ ] Typing a title and pressing Enter adds the task and appears in the list in < 100 ms.
- [ ] Pressing Enter with an empty (or whitespace-only) title adds nothing.
- [ ] The capture box clears and keeps focus after a successful add (ready for the next task).
- [ ] An open task can be marked complete with a single keyboard action; it moves to the completed
      section.
- [ ] A completed task can be reopened.
- [ ] Reloading the page shows the same tasks in the same states (persisted).
- [ ] Capture-to-complete on one task is achievable keyboard-only in under 5 seconds.

## Stack hint

Vanilla JS, single `index.html` + module. State is an array of `{ id, title, done, createdAt }`
serialised to `localStorage` under one key. No build step required; no backend. Maps to DELIVER's
frontend value-handler.
