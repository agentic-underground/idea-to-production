---
description: Define this repository's welcome experience — read the repo, propose 2–4 conversational "lanes" with concrete decision trees, and write .claude/welcome.md so CONCIERGE greets and routes whoever opens it next.
---

Author this repository's welcome experience. Follow the
[`define-welcome` skill](../skills/define-welcome/SKILL.md):

1. Read the repo (README, CLAUDE.md/AGENTS.md, Makefile/scripts, runbooks, planning
   docs) to infer what it is, its voice, and the handful of things people come here to
   do.
2. Propose **2–4 top-level lanes** and confirm them with the user via AskUserQuestion.
3. Draft each lane's decision tree — leaves are concrete actions naming the repo's real
   commands and paths (verify they exist).
4. Write `.claude/welcome.md` in the format from
   [`knowledge/welcome-format.md`](../knowledge/welcome-format.md).
5. Tell the user it takes effect next session (reload), and that it is smart-gated —
   it greets only on a cold/vague open and steps aside for a concrete task.

If `$ARGUMENTS` names a focus (e.g. specific lanes or a tone), weave it in.
