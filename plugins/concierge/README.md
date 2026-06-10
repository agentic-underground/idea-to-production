# CONCIERGE — repo welcome & the idea-to-production status line

![A warm lantern-lit arched doorway at night — amber light spilling from hanging and wall lanterns across a teal-dark entrance hall with a wooden floor — a warm light at the door, welcoming whoever arrives.](diagrams/hero.jpg)

> The **arrival layer** of the [idea-to-production](../../README.md) marketplace. A
> repository should greet whoever opens it — and the suite should be visible at a glance.

When a developer or operator opens a repo in an agent harness, they meet a wall of
files and have to *guess* where to start. CONCIERGE turns the opening moment into a
conversation: a one-line greeting and a short decision tree of the handful of things
people actually come here to do — **operate** the software, or **evolve** it — that
routes the user straight to the right command, runbook, or downstream plugin.

![The CONCIERGE welcome card assembling, then greeting: the four status widgets tick into place one by one — ◆ lifecycle (BUILD), ◇ session (12.4k tok), ◈ life (94% est), and ⚔ caught (7) glow from dim to teal/amber — then a warm amber greeting line unfurls left-to-right beneath them, "welcome — concierge has the door. what brings you in: operate, or evolve?", and the card settles with a teal "✓ at the door". The motion teaches that CONCIERGE both renders the at-a-glance status bar and greets whoever opens the repo.](../../doc/images/concierge-welcome.gif)

The engine ships in the marketplace; the **content is repo-local**, exactly like
`CLAUDE.md`. A maintainer authors `.claude/welcome.md` once (by hand, or with
`/concierge:define-welcome`), and every future session of that repo gets the front door.

## How it works

- **`hooks/inject-welcome.sh`** — a `SessionStart` hook. If the project being opened
  has a `.claude/welcome.md`, it injects it (wrapped in the runtime contract from
  `hooks/welcome-preamble.md`) as `additionalContext`. If there is no welcome file, it
  is a **silent no-op** — which is why it is safe to have enabled in every repo.
- **`hooks/offer-welcome.sh`** — its mirror image: a `SessionStart` hook that acts when there is **no**
  welcome (or a managed one has fallen out of date). On a cold/vague open it surfaces a smart-gated,
  **in-the-know** offer to author one — tailored from the repo's `CLAUDE.md`/`README` (and, under an active
  idea-to-production lifecycle, the product's emergent artifacts), so it reads "I can set up a greeting that
  routes people to X/Y/Z" rather than a bland "want a greeting?". On opt-in it hands off to
  `/concierge:define-welcome`. It re-offers on cold opens until you accept or decline; a per-repo decline
  and a global "never offer" opt-out (both under `~/.claude/hook-state`, written only on your say-so) stop
  it, and the hook never writes your repo.
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

## A living welcome (lifecycle-managed)

When a repo is built through the idea-to-production lifecycle (`.i2p/lifecycle.json`), the welcome is more
than a one-shot. `/concierge:define-welcome` stamps it with the phase it was written for and tailors it to
the product's **emergent identity** (DISCOVER opportunity → IDEATE IDEA package + name → BUILD
SMU/ROADMAP → … → OPERATE). As the lifecycle advances, CONCIERGE **auto-refreshes** the welcome —
silently, artifact-driven, with a one-line `↻` note — so whoever opens the repo always meets a *current*
front door, managed for you, with the same opt-outs. A hand-authored welcome with **no** stamp is never
auto-touched.

## The status line

CONCIERGE also ships the idea-to-production **status line** — a rich two-line ANSI bar:

- **Line 1** — `user@host:cwd`, git branch, repo, PR + review state, model, version, output style,
  vim mode, effort/thinking, session, worktree, agent (each shown only when present).
- **Line 2** — wide gauges for context-window and 5h/7d rate limits, the **product-lifecycle phase**
  (once a project has a `.i2p/lifecycle.json` — see `/i2p-help`), **token-cost** widgets (`◇ session`
  spend in tokens + $, and `◈ life` actual-vs-estimate when a lifecycle is running), and a **⚔ caught**
  tally of the times an adversarial reviewer caught something.

These two — the **⚔ catch counter** and the **token-cost tracker** — are the marketplace's *first-order
instruments*: always on, fed by deterministic hooks (a PostToolUse counter and a `Stop` cost-capture hook),
and self-calibrating. The token tracker compares each lifecycle phase's estimate to its measured actual and
folds the ratio back so estimates improve over time. Full contract:
[`i2p/knowledge/instrumentation.md`](../i2p/knowledge/instrumentation.md).

Turn it on with **`/concierge:statusline`** (and `/concierge:statusline off` to remove it). On first
activation CONCIERGE makes a single, unobtrusive offer — a splash, nothing more. The renderer
([`statusline/i2p-statusline.sh`](statusline/i2p-statusline.sh)) ships in the plugin and is copied to
`~/.claude/` on install (so it is portable and `settings.json`, which can't expand `${CLAUDE_PLUGIN_ROOT}`,
points at a stable path). The **⚔ caught** tally is fed automatically by a PostToolUse hook
([`statusline/count-adversarial-catches.sh`](statusline/count-adversarial-catches.sh)) — no setup needed.

**Extensible.** Any plugin can add a segment by dropping an executable printer in
`~/.claude/state/statusline-widgets.d/*.sh`; each is fed the same stdin JSON and prints one already-colored
segment. A failing or empty widget is silently skipped, so it can never break the bar.

## Check & inspect

Like every plugin in the marketplace, CONCIERGE carries its own integrity surfaces:

- **`/concierge:check`** — a fast ✓/✗ probe of the tools its hooks and status line use (`jq` for
  clean-JSON parsing, `bash`, optionally `git`), grouped by tier. Advisory by default (everything
  degrades to a pure-bash fallback, never failing the session); `--strict` exits non-zero on a missing
  required tool. Reads the canonical manifest [`skills/check/requirements.tsv`](skills/check/requirements.tsv).
- **`/concierge:inspect`** — runs the on-demand [`inspector`](agents/inspector.md) agent: an independent,
  critical audit of CONCIERGE's skills, agents, knowledge, commands, hooks, and the status line per the
  shared [`knowledge/inspection-core.md`](knowledge/inspection-core.md), plus CONCIERGE-specific checks
  (hook↔manifest parity, welcome lifecycle integrity, status-line portability + drift, the data-driven
  HUD instrument, canonical-copy integrity). Writes a severity-ranked `CONCIERGE_INSPECTION_REPORT.md`.

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
