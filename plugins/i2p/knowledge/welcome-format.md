# The `.claude/welcome.md` format

A repository's welcome experience is a single markdown file at `.claude/welcome.md` in
the project root. i2p's SessionStart hook injects it **verbatim** (wrapped in the
runtime contract from `hooks/welcome-preamble.md`) — there is no parser, so the format
is a convention for the agent and the maintainer, not a schema to satisfy. Keep it
short: it enters context every session, so it should be pointers and exact commands,
not prose.

## Structure

```markdown
<!-- i2p:welcome for_phase=<PHASE> cycle=<N> product=<slug> generated=<iso8601> -->
(stamp line — ONLY when an idea-to-production lifecycle is running; see "Lifecycle-aware welcomes")

# Welcome to <PROJECT> 👋

<One or two sentences: what this repository is and who operates it.>
<Optional: a green-gate one-liner for the tone — e.g. "Light is green, trap is clean.">

## Lanes

The 2–4 things people come here to do. Each becomes a top-level choice the agent
offers (via AskUserQuestion) on a cold open.

- **<Lane A name>** — <one-line description>
- **<Lane B name>** — <one-line description>

## <Lane A name>

A short decision tree. Each leaf is a CONCRETE action with the project's real command
or file path, so the agent can go straight from "I want X" to running it.

- **<intent / "I want to …">** → `<exact command>` (`<relevant file or runbook>`)
- **<intent>** → <next step + path>

## <Lane B name>

- **<intent>** → `<exact command>` / hand off to `<plugin or runbook>`
```

## Rules of thumb

- **2–4 lanes.** More than four and the front door stops being a front door. Group
  finer choices into the per-lane decision tree, not the top level.
- **Real commands, real paths.** Every leaf should name something that exists in the
  repo — a `make` target, a script, a playbook, a runbook under `docs/`/`procedures/`,
  or a downstream slash-command (`/ideate`, `/deliver`). Vague leaves waste the lane.
- **One concrete action per leaf.** The agent walks the tree by asking one focused
  follow-up at a time; design leaves so each ends at a thing it can actually do.
- **Lead with a greeting line** and, if the project has a voice (see its
  `CLAUDE.md`/`AGENTS.md`), match it. A green-gate one-liner is a nice closer.
- **Don't restate `CLAUDE.md`.** The welcome is wayfinding — "here's what you can do
  and how to start" — not a re-statement of conventions the agent already has.

## Lifecycle-aware welcomes

When the repo is in an idea-to-production lifecycle (`.i2p/lifecycle.json` present), the welcome is a
**living** document. It leads with a **phase stamp** —
`<!-- i2p:welcome for_phase=<PHASE> cycle=<N> product=<slug> generated=<iso8601> -->` — and its
content reflects the product's **emergent identity** at that phase: early on it leads with *what the
product is becoming and the next command* ("This repo is building **<Name>** — now at BUILD; next: …");
once the product is concrete it gives the full lanes. i2p reads the stamp on SessionStart and, when
the lifecycle has advanced past it, **auto-refreshes** the welcome (silently, via
`/i2p:define-welcome refresh`) so whoever opens the repo always meets a current front door. A
hand-authored welcome with **no** stamp is never auto-touched.

Authoring this file by hand is fine; `/i2p:define-welcome` will read the repo and
draft it with you.
