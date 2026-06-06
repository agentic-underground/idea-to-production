---
description: Inspect the IDEATOR plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect IDEATOR.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`): read the skills, agents, and `knowledge/` docs; build a fresh critical-analysis
persona (per `knowledge/inspection-core.md`); and produce a severity-ranked report (SUGGESTION / WARNING /
CRITICAL) of what is wrong, missing, drifted, or improvable — including the IDEATOR-specific checks
(challenge-axis coverage, package-contract integrity, the naming token-contract, graceful degradation).
Apply unambiguous CRITICAL fixes directly; capture the rest for the next `/ideator:self-improve` pass.
