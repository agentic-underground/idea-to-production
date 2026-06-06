# GATEHOUSE — define your repo's welcome experience

> The **arrival layer** of the [idea-to-production](../../README.md) marketplace. A
> repository should greet whoever opens it.

When a developer or operator opens a repo in an agent harness, they meet a wall of
files and have to *guess* where to start. GATEHOUSE turns the opening moment into a
conversation: a one-line greeting and a short decision tree of the handful of things
people actually come here to do — **operate** the software, or **evolve** it — that
routes the user straight to the right command, runbook, or downstream plugin.

The engine ships in the marketplace; the **content is repo-local**, exactly like
`CLAUDE.md`. A maintainer authors `.claude/welcome.md` once (by hand, or with
`/gatehouse:define-welcome`), and every future session of that repo gets the front door.

## How it works

- **`hooks/inject-welcome.sh`** — a `SessionStart` hook. If the project being opened
  has a `.claude/welcome.md`, it injects it (wrapped in the runtime contract from
  `hooks/welcome-preamble.md`) as `additionalContext`. If there is no welcome file, it
  is a **silent no-op** — which is why it is safe to have enabled in every repo.
- **Smart-gated.** The runtime contract tells the agent to present the welcome only on
  a *cold, vague open* ("hi", "what can I do here?") and to **step aside** the moment
  the user opens with a concrete task. It greets at most once — never mid-conversation,
  never on a resume or compaction. A front door, not a tollbooth.
- **`/gatehouse:define-welcome`** — the authoring tool. Reads the repo, infers what it
  is and its voice, proposes 2–4 lanes with concrete decision trees, and writes
  `.claude/welcome.md` for you. See [`skills/define-welcome`](skills/define-welcome/SKILL.md).

## The `.claude/welcome.md` format

A single, short markdown file: a greeting line, a `## Lanes` list (2–4), and a
decision-tree section per lane whose leaves are **real commands and paths**. Injected
verbatim — no schema to satisfy. Full spec and rules of thumb:
[`knowledge/welcome-format.md`](knowledge/welcome-format.md).

## Companions

GATEHOUSE stands alone. When [`ideator`](../ideator) and [`foundry`](../foundry) are
installed, the "evolve the software" lane of a welcome can route vague ideas to
`/ideate` → `/foundry` and concrete next-steps to the repo's own roadmap and runbooks.

## Quick start

1. Open your repo and run `/gatehouse:define-welcome` (or hand-write `.claude/welcome.md`
   per the format doc).
2. Reload the session. On your next cold open, the agent greets you and offers the
   lanes.

_Light is green, trap is clean._
