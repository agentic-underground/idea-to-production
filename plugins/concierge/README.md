# CONCIERGE — repo welcome & the idea-to-production status line

> The **arrival layer** of the [idea-to-production](../../README.md) marketplace. A
> repository should greet whoever opens it — and the suite should be visible at a glance.

When a developer or operator opens a repo in an agent harness, they meet a wall of
files and have to *guess* where to start. CONCIERGE turns the opening moment into a
conversation: a one-line greeting and a short decision tree of the handful of things
people actually come here to do — **operate** the software, or **evolve** it — that
routes the user straight to the right command, runbook, or downstream plugin.

The engine ships in the marketplace; the **content is repo-local**, exactly like
`CLAUDE.md`. A maintainer authors `.claude/welcome.md` once (by hand, or with
`/concierge:define-welcome`), and every future session of that repo gets the front door.

## How it works

- **`hooks/inject-welcome.sh`** — a `SessionStart` hook. If the project being opened
  has a `.claude/welcome.md`, it injects it (wrapped in the runtime contract from
  `hooks/welcome-preamble.md`) as `additionalContext`. If there is no welcome file, it
  is a **silent no-op** — which is why it is safe to have enabled in every repo.
- **Smart-gated.** The runtime contract tells the agent to present the welcome only on
  a *cold, vague open* ("hi", "what can I do here?") and to **step aside** the moment
  the user opens with a concrete task. It greets at most once — never mid-conversation,
  never on a resume or compaction. A front door, not a tollbooth.
- **`/concierge:define-welcome`** — the authoring tool. Reads the repo, infers what it
  is and its voice, proposes 2–4 lanes with concrete decision trees, and writes
  `.claude/welcome.md` for you. See [`skills/define-welcome`](skills/define-welcome/SKILL.md).

## The `.claude/welcome.md` format

A single, short markdown file: a greeting line, a `## Lanes` list (2–4), and a
decision-tree section per lane whose leaves are **real commands and paths**. Injected
verbatim — no schema to satisfy. Full spec and rules of thumb:
[`knowledge/welcome-format.md`](knowledge/welcome-format.md).

## The status line

CONCIERGE also ships the idea-to-production **status line** — a rich two-line ANSI bar:

- **Line 1** — `user@host:cwd`, git branch, repo, PR + review state, model, version, output style,
  vim mode, effort/thinking, session, worktree, agent (each shown only when present).
- **Line 2** — wide gauges for context-window and 5h/7d rate limits, the **product-lifecycle phase**
  (once a project has a `.i2p/lifecycle.json` — see `/i2p-help`), and a **⚔ caught** tally of the times
  an adversarial reviewer caught something.

Turn it on with **`/concierge:statusline`** (and `/concierge:statusline off` to remove it). On first
activation CONCIERGE makes a single, unobtrusive offer — a splash, nothing more. The renderer
([`statusline/i2p-statusline.sh`](statusline/i2p-statusline.sh)) ships in the plugin and is copied to
`~/.claude/` on install (so it is portable and `settings.json`, which can't expand `${CLAUDE_PLUGIN_ROOT}`,
points at a stable path). The **⚔ caught** tally is fed automatically by a PostToolUse hook
([`statusline/count-adversarial-catches.sh`](statusline/count-adversarial-catches.sh)) — no setup needed.

**Extensible.** Any plugin can add a segment by dropping an executable printer in
`~/.claude/state/statusline-widgets.d/*.sh`; each is fed the same stdin JSON and prints one already-colored
segment. A failing or empty widget is silently skipped, so it can never break the bar.

## Companions

CONCIERGE stands alone. When [`ideator`](../ideator) and [`foundry`](../foundry) are
installed, the "evolve the software" lane of a welcome can route vague ideas to
`/ideate` → `/foundry` and concrete next-steps to the repo's own roadmap and runbooks.

## Quick start

1. Open your repo and run `/concierge:define-welcome` (or hand-write `.claude/welcome.md`
   per the format doc).
2. Reload the session. On your next cold open, the agent greets you and offers the
   lanes.

_Light is green, trap is clean._
