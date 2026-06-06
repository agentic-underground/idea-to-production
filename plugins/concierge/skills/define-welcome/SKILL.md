---
name: define-welcome
description: >
  Define a custom welcome experience for THIS repository — the conversational front
  door a developer or operator meets when they open it in an agent harness. Reads the
  repo to infer what it is and the handful of things people come here to do, proposes
  2–4 top-level "lanes" with concrete decision trees, and writes `.claude/welcome.md`
  in the CONCIERGE format so the SessionStart hook can greet arrivals and route them.
  Trigger when the user says "define a welcome experience", "set up a greeting for this
  repo", "add a front door / concierge", "what should this repo say when opened", or
  invokes `/concierge:define-welcome`.
metadata:
  type: producer
  output: .claude/welcome.md
---

# DEFINE-WELCOME

You are authoring this repository's **welcome experience** — the file
`.claude/welcome.md` that CONCIERGE's SessionStart hook renders so a future agent can
greet whoever opens the repo and route them, conversationally, to what they came to do.
The format and its rules of thumb live in
[`knowledge/welcome-format.md`](../../knowledge/welcome-format.md) — read it first; this
skill is the *procedure* for producing a good one.

The goal: a short, high-signal front door. Pointers and exact commands, not prose. It
enters context every session, so every line must earn its place.

## Procedure

### 1. Understand the repository

Read enough to know what this repo is *for* and what people *do* here. Look at:

- `README.md`, and any `CLAUDE.md` / `AGENTS.md` (purpose, conventions, **voice**).
- The build/entry surface: `Makefile` targets, `package.json` scripts, `justfile`,
  `Taskfile`, top-level CLIs, primary playbooks/workflows.
- Runbooks / procedures (`docs/`, `procedures/`, `knowledge-base/`) — these usually map
  one-to-one onto the real "I want to …" intents.
- Any planning docs (`ROADMAP.md`, `*_PLAN.md`, `TODO`) — they reveal the "evolve the
  software" lane.

Infer the project's **voice** from its docs; the welcome should sound like the repo,
not generic. If the repo enjoys a motif (a film, a mascot, a green-gate phrase), use it.

### 2. Propose the lanes

Distil what you found into **2–4 top-level lanes** — the distinct *reasons* someone
opens this repo. A common and powerful split for a piece of software is:

- **Operate / use it** — run it, deploy it, maintain it, do the day-job tasks.
- **Evolve it** — change the software itself: ideas, features, fixes, refactors. When
  the `ideator` and `foundry` plugins are installed, this lane should route vague ideas
  to **`/ideate` → `/foundry`** and concrete next-steps to the repo's own roadmap/plan
  and add-a-thing runbooks.

But fit the lanes to the actual repo — a library, a service, a docs site, and a fleet
of machines each want different lanes. Confirm the lanes with the user with
**AskUserQuestion** before writing (offer your inferred set as the options; let them
adjust). Do not over-split: more than four top-level lanes is a smell.

### 3. Draft each lane's decision tree

For every lane, write a short tree whose **leaves are concrete actions** naming the
repo's *real* commands and paths — a `make` target, a script, a playbook, a runbook, a
downstream slash-command. Each leaf should take the agent from "I want X" straight to a
thing it can run. Verify the commands/paths you cite actually exist before writing them.

### 4. Write `.claude/welcome.md`

Compose the file per `knowledge/welcome-format.md`: a greeting line (matching the repo's
voice, optionally closing on a green-gate one-liner), a `## Lanes` summary list, and a
`## <Lane>` section per lane with its decision tree. Create the `.claude/` directory if
absent. Keep it tight.

### 5. Hand back

Tell the user the welcome experience is written, and that it takes effect on the **next
session** (the SessionStart hook reads it on a cold open) — they should reload to see
it. Note that it is smart-gated: it greets only on a vague/cold open and steps aside the
moment someone states a concrete task. Offer to refine any lane.

## Quality bar

- 2–4 lanes; each leaf ends at a real, runnable action.
- Every command/path cited exists in the repo (you checked).
- Sounds like the repo; doesn't restate `CLAUDE.md` conventions.
- Short enough to scan in seconds — it is paid for on every session.
