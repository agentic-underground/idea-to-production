---
description: Define this repository's welcome experience — read the repo, propose 2–4 conversational "lanes" with concrete decision trees, and write .claude/welcome.md so i2p greets and routes whoever opens it next.
---

Author this repository's welcome experience. Follow the
[`define-welcome` skill](../skills/define-welcome/SKILL.md):

1. Detect the lifecycle context — if `.i2p/lifecycle.json` exists, read the current phase and the
   product's emergent artifact(s) for it (so the welcome reflects what the product is *becoming*). Then
   read the repo (README, CLAUDE.md/AGENTS.md, Makefile/scripts, runbooks, planning docs) for its purpose
   and voice.
2. Propose **2–4 top-level lanes** and confirm them with the user via AskUserQuestion.
3. Draft each lane's decision tree — leaves are concrete actions naming the repo's real
   commands and paths (verify they exist).
4. Write `.claude/welcome.md` in the format from
   [`knowledge/welcome-format.md`](../knowledge/welcome-format.md), and — when a lifecycle is running —
   lead it with the phase stamp `<!-- i2p:welcome for_phase=… cycle=… product=… generated=… -->`.
5. Tell the user it takes effect next session (reload), and that it is smart-gated —
   it greets only on a cold/vague open and steps aside for a concrete task.

**`refresh` mode:** if `$ARGUMENTS` is `refresh`, run the skill's silent, artifact-driven Refresh mode
instead — no AskUserQuestion; re-derive the welcome from the current lifecycle phase's artifacts, preserve
still-valid user lanes, restamp, and emit `↻ refreshed the welcome for <PHASE>`. (i2p invokes this
automatically to keep a managed welcome current.) Otherwise, if `$ARGUMENTS` names a focus (specific lanes
or a tone), weave it in.
