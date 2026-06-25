# TaskFlow — the IDEA dossier

> User-facing. The rich, persuade-and-align read you review and iterate on before committing. (When
> **publish** / **design** are installed, this dossier carries rendered charts, a user-flow, and a
> mockup of the capture view; here it degrades to structured markdown.)

## Here's TaskFlow

TaskFlow is a lightweight task manager for indie devs who want to get a thought out of their head and
back to coding — fast. No teams, no boards, no ceremony. You open it, type what you need to do, hit
Enter, and it's captured. Later you glance at the list, knock things off with a keystroke, and move on.
It's the to-do app for people who find to-do apps too much work.

## Why it exists

If you run a couple of side-projects, your tasks live everywhere: `// TODO` comments, a sticky note, a
half-remembered GitHub issue, the back of your mind. The "real" tools — Jira, Linear, Asana — are built
for teams and want you to configure workflows before you've written a line. That's friction you don't
need when you're solo. TaskFlow is the opposite: zero setup, single user, keyboard-first, local to your
machine. It does one thing — capture and complete — and gets out of the way.

## What you get in v1

- **Instant capture** — type a title, press Enter, done. The box clears and waits for the next one.
- **One-keystroke completion** — mark a task done (or reopen it) without touching the mouse.
- **A clear list** — open tasks up top, completed ones below.
- **It just remembers** — your tasks persist locally and survive a reload. No account, no sign-in.

The whole loop — capture → see it → complete it — is designed to take under five seconds, keyboard-only,
with nothing to read first.

## What we're deliberately leaving out (for now)

Projects, tags, priorities, due dates, sharing, mobile, and integrations are all out of v1 — on
purpose. The magic of TaskFlow is that it stays trivially simple. We'd rather nail the capture-complete
loop than ship a watered-down clone of the heavyweight tools you're trying to escape.

## Where it could go

- **Sync** — an optional paid tier (around $3–5/mo) to keep tasks in step across machines, for people
  who outgrow local-only.
- **Capture from anywhere** — a global hotkey / command-palette overlay so you can dump a task without
  switching windows.

## Naming candidates

- **TaskFlow** *(working name)* — clear, calm, says what it does.
- **Tasklet** — small and friendly; leans into the lightweight promise.
- **Nextup** — frames the product around the question it answers: "what's next?"

> A full naming search (availability across npm/PyPI/crates/GitHub + adversarial challenge) runs via
> `/ideate:name` before the name is locked.
