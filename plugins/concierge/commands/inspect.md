---
description: Inspect the CONCIERGE plugin itself — audit skills, agents, knowledge, commands, hooks, and the status line for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect CONCIERGE.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the CONCIERGE-specific checks
(hook↔manifest parity, welcome lifecycle integrity, status-line portability + drift detection, the
data-driven HUD instrument, and canonical-copy / four-mirror integrity). Produce a severity-ranked
report; apply unambiguous CRITICAL fixes; capture the rest for `/concierge:self-improve` (when present).
