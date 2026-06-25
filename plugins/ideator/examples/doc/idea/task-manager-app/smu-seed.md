# SMU seed — TaskFlow

> Agent-facing. The subject-matter-understanding seed — the domain parity FOUNDRY's builder-lead
> expands into the full SMU. ~200 words.

**Domain.** Personal task management for a single technical user. The product is a local-first to-do
list, not a project-management suite.

**Key concepts.** A *task* has a title, a *state* (open or done), and a created-at ordering. The *list*
shows open tasks first, then completed ones. There are no projects, tags, or due dates in the v1 model —
deliberately, to keep the mental model trivial.

**User mental model.** The indie dev thinks "I just thought of a thing — let me dump it and forget it,"
then later "what's next?" They expect capture to be instant and frictionless (type, Enter, gone) and
completion to be one keystroke. They do not want to *organise*; they want to *offload and triage*.

**Technical landscape.** Browser-based, vanilla JS, `localStorage` for persistence. No backend, no
accounts, no network. State is a single array of task objects serialised to JSON. Keyboard handling and
fast DOM updates are the only real engineering concerns.

**Success / failure.** Success: capture-to-complete in under 5 seconds, keyboard-only, no docs. Failure:
any required mouse use, any setup step, any lag between typing a task and seeing it appear.
