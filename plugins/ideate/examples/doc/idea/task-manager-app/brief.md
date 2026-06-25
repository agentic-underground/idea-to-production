# IDEA brief — TaskFlow

> Agent-facing. The single source of truth FOUNDRY ingests at its IDEA station. Every field is
> self-contained and actionable by a fresh agent with no conversation history.

- **TITLE** — TaskFlow — a simple task manager for indie developers
- **SLUG** — `task-manager-app`
- **DATE** — 2026-06-25

## PROBLEM

Indie developers juggling several side-projects keep their to-dos scattered across `TODO` comments,
sticky notes, GitHub issues, and their head. Heavyweight tools (Jira, Linear, Asana) demand setup,
teams, and workflow ceremony they don't need. They lose the thread of "what's the next thing to do on
project X" and context-switch badly. There is no friction-free, single-user, keyboard-first place to
capture a task and see what's next.

## ACTORS

- **Solo indie developer** — owns several personal/commercial code projects, works alone, lives in the
  terminal and the browser, values speed and keyboard control over collaboration features.

## IN-SCOPE (v1)

- Create a task with a title.
- Mark a task complete / reopen it.
- View an ordered list of open and completed tasks.
- Persist tasks locally so they survive a reload.

## OUT-OF-SCOPE (v1)

- Multi-user / sharing / assignments.
- Projects, labels, tags, priorities, due dates.
- Sync across devices, mobile app, notifications.
- Integrations (GitHub, calendar, Slack).

## CONSTRAINTS

- **Platform** — runs in a modern desktop browser; no install step.
- **Performance** — adding a task and seeing it in the list is perceptibly instant (< 100 ms).
- **Compliance** — single-user, no accounts, no PII collected; data stays on the user's machine.
- **Integration** — none required for v1 (deliberately standalone).
- **Budget** — buildable in a few focused sessions; zero recurring infra cost (local-first).

## SUCCESS-METRIC

A solo developer can capture a new task and mark it complete in **under 5 seconds, keyboard-only,
without leaving the keyboard or reading any documentation.**

## PRICE-BAND

Free core; a future paid tier ($3–5/mo) for sync — out of scope for v1, recorded for direction only.

## LANGUAGE/STACK

Vanilla JS + local persistence (browser `localStorage`) — maps to FOUNDRY's frontend value-handler.
No stack-fit flag fired; the slice is small and the stack is registered.

## FIRST-SLICE

See [`first-slice.md`](./first-slice.md) — "Add a task with a title and mark it complete."

## WILD-CARD

The keyboard-first capture box could later become a global hotkey / command-palette overlay, so a task
can be captured from anywhere without switching windows. Noted, not in v1.
