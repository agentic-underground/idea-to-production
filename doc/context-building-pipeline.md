# The context-building pipeline — how documents reach a Claude Code agent

*A "learning to Claude" note.* This explains the mechanisms by which text becomes part of
an agent's working context in Claude Code, what each one costs, and how this marketplace
uses them — concretely, how [`SOUL.md`](../SOUL.md) is **always on** without burning tokens.

It is learner-facing material for anyone working on the marketplace; it is not shipped to
or read by the installed plugins at runtime.

## The mental model: a context window is a budget, a cache, and a set of doors

Everything the model "knows" in a turn is the **context window** — a finite token budget.
Text enters it through a small number of *doors*. The engineering question is never just
"can I get my document in?" but "**through which door, at what token cost, and how
reliably?**" The doors differ along three axes that matter:

| Axis | What it means |
|---|---|
| **When it loads** | At session start? On every prompt? Only when a file is touched? |
| **Token cost** | Paid once and cached, or re-billed each turn? |
| **Reliability** | Guaranteed present, or only when some condition holds? |

The crucial enabler underneath all of them is **prompt caching**.

## Prompt caching — why "always on" is not "always expensive"

Claude Code sends a large, **stable prefix** every turn: the system prompt, tool
definitions, and loaded memory/context. That prefix is cached. A cache **write** (first
time) costs a one-time premium; every subsequent **read** of that unchanged prefix costs a
small fraction of full input price. So a small static document that lives in the stable
prefix is paid for **once per cache lifetime**, not re-billed in full on every message.

> The intuition "if it's in context every turn, it burns tokens every turn" is **wrong for
> static content**. What burns tokens is content that *changes* every turn (busting the
> cache) or content that is *large*. Keep shared canon **small and stable** and it is
> effectively a one-time cost. (Prompt caching, platform.claude.com →
> `/docs/build-with-claude/prompt-caching`.)

This single fact dissolves the usual tension — *"I don't want to constantly re-append a
file, but I don't want to ever omit it."* A small, stable file in the cached prefix is
neither re-appended per turn nor omitted.

## The doors, ranked by how this marketplace thinks about them

### 1. Memory files — `CLAUDE.md` and `@imports`

`CLAUDE.md` (user-level `~/.claude/CLAUDE.md`, project-level `./CLAUDE.md`, and nested
ones) is read at session start into the stable prefix. The `@path/to/file` syntax inline-
**imports** another file at load time (recursively). It is the simplest always-on door.

- **When:** session start. **Cost:** in the cached prefix → one-time. **Reliability:**
  always, *for that scope*.
- **Limit for our goal:** scope. A project `CLAUDE.md` only loads in *that* project; a
  user `CLAUDE.md` only on *that* machine and does not travel with an installed plugin.
  **Plugins cannot ship a `CLAUDE.md` that auto-loads** — `plugin.json` has no such field.
  So memory files are right for *repo-local* canon (this marketplace's own
  [`CLAUDE.md`](../CLAUDE.md)), but cannot be the always-on mechanism for *installed*
  plugins. (Memory, code.claude.com → `/docs/en/memory`.)

### 2. SessionStart hooks with `additionalContext` — the plugin-native always-on door

A plugin auto-discovers `hooks/hooks.json`. A **SessionStart** hook runs a command at
session start and may print JSON whose `hookSpecificOutput.additionalContext` field is
**injected into the session's initial context** — i.e. into the cached prefix. This is the
*only* mechanism by which an **installed plugin** can reliably place text in context.

- **When:** session start — and again on `resume`, `clear`, and `compact` (each carries a
  `source`). **Cost:** lands in the cached prefix → one-time per event. **Reliability:**
  deterministic; runs whenever the plugin is enabled. (Hooks, code.claude.com →
  `/docs/en/hooks`.)
- **The catch at marketplace scale:** if six installed plugins each ship the same
  SessionStart hook, the canon injects **six times**. The fix is dedup — see below.

### 3. UserPromptSubmit hooks — inject *per prompt*

A `UserPromptSubmit` hook can add context **on every user turn**. Powerful for *dynamic*
state (the current time, a build status), but for *static* canon it is the wrong door: it
re-injects each turn, changing the tail and working against the cache. Use it for things
that genuinely change turn-to-turn, not for a fixed document.

### 4. Skills — progressive disclosure (load-only-when-relevant)

A skill's `SKILL.md` frontmatter (name + description) is always cheaply in context; its
**body loads only when the skill is invoked**. This is the model for content that should
*not* be always on — large, situational knowledge that earns its tokens only when needed.
SOUL is the opposite case (tiny, universal), so it belongs in a door 1/2 mechanism, not a
skill — but the contrast is the whole point: **match the door to the document.**

## Where SOUL.md fits — the design, end to end

SOUL is small (a framing line + seven quotes) and universal (it should be present whenever
*any* plugin is active). That profile points squarely at **door 2 with dedup**:

```
  SOUL.md  (canonical, repo root)              ← single source of truth
     │  cp, byte-identical (CI Check E)
     ▼
  plugins/<each>/SOUL.md  ×6                    ← travels with each installed plugin
     ▲
     │  read by
  plugins/<each>/hooks/inject-soul.sh  ×6       ← byte-identical (CI Check F)
     │  SessionStart fires for every enabled plugin, together
     ▼
  atomic sentinel:  ${TMPDIR}/claude-soul/soul-<session_id>-<source>.lock
     │  mkdir succeeds for exactly ONE caller per (session, source) event
     ▼
  that one hook prints { hookSpecificOutput.additionalContext: <SOUL.md> }
     ▼
  SOUL lands in the cached prefix — ONCE per event, never 6×, never omitted
```

The properties this buys, mapped back to the three axes:

- **When:** every session start, and re-injected on `resume` / `clear` / `compact` —
  because `clear` wipes context and `compact` can drop earlier injections, the sentinel is
  keyed by `session_id` **and** `source`, so a fresh single injection restores SOUL after
  each. *Never omitted.*
- **Token cost:** one small injection per event, into the cached prefix → effectively
  one-time, not per-turn. *Not wasteful.*
- **Reliability:** fires whenever ≥1 plugin is enabled; the atomic `mkdir` lock guarantees
  exactly one of the six emits. *Never duplicated.*

### Why these specific choices

- **Why copy into each plugin instead of one shared file?** An installed plugin can only
  resolve `${CLAUDE_PLUGIN_ROOT}` — its own directory. It cannot reach a sibling plugin or
  the marketplace root at runtime. So each plugin must carry its own copy; the
  byte-identity is held by **CI verification, not a generator** (matching the repo's
  existing `check.sh` covenant). Single source of truth = the root `SOUL.md`; CI Checks
  E/F fail on any drift.
- **Why `mkdir` for the lock?** It is the portable atomic test-and-set — it succeeds for
  exactly one concurrent caller and fails for the rest, with no partial-write race a `>`
  redirect could leave.
- **Why no hard dependency on `jq`?** The hook runs on every session of every install;
  it parses and emits with `jq` when present and falls back to pure bash otherwise, so a
  missing tool degrades to "still works", and any failure at all degrades (via `|| true`)
  to "no SOUL this session" rather than a broken session start.

## The takeaway

Putting a document in front of the model is a *routing* decision, not a copy-paste:

- **Small + universal + static** → SessionStart `additionalContext` (or a memory file if
  the scope is a single repo/machine). Cached prefix makes it one-time. **← SOUL.md**
- **Small + dynamic** → UserPromptSubmit (pay per turn on purpose).
- **Large + situational** → a skill body (pay only when invoked).
- **Repo-local canon for agents working *on* the repo** → `CLAUDE.md` + `@imports`.

Match the door to the document, keep always-on content small and stable, and the cache
turns "always present" into "paid once."

---

**Sources** — Claude Code docs: hooks (`code.claude.com/docs/en/hooks`), memory
(`code.claude.com/docs/en/memory`), plugins (`code.claude.com/docs/en/plugins`,
`/plugins-reference`); prompt caching
(`platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`).
