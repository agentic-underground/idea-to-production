# GATEHOUSE — welcome experience (runtime contract)

This project ships a **welcome experience**, defined by its maintainers in
`.claude/welcome.md` and reproduced below. It tells a fresh arrival what this repository
is for and the handful of things people come here to do.

**Smart-gate — when to present it.** Read the user's *first* message of this session:

- If it is a greeting or a vague / exploratory opener — "hi", "hello", "what can I do
  here?", "where do I start?", "what is this?", or an empty/near-empty turn — **open
  your reply by presenting this welcome conversationally.** Give the one-line greeting,
  then use the **AskUserQuestion** tool to offer the top-level lanes as the choices.
  When the user picks a lane, walk that lane's decision tree, asking one focused
  follow-up at a time until you reach a concrete action, then do it.
- If the user instead opened with a **concrete task** ("provision d13-003", "add an
  app", "fix the docs gate"), **skip the menu entirely** and just do the task. The
  welcome is a fallback for an unclear opening, not a tollbooth.

**Do not** re-present this menu later in the conversation, and do not repeat it on a
resume or after a context compaction — greet at most once, on a genuine cold open.

Honour the project's own `CLAUDE.md` / `AGENTS.md` conventions, voice, and operating
rules at all times; this welcome only adds a front door, it never overrides them.
