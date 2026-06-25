---
description: Inspect the DISCOVER plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect DISCOVER.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the DISCOVER-specific checks
(scoring-taxonomy coverage, kill-ledger schema, goal contract, handoff integrity). Produce a severity-ranked
report; apply unambiguous CRITICAL fixes; capture the rest for `/discover:self-improve`.
