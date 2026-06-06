---
description: Inspect the SENTINEL plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect SENTINEL.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the SENTINEL-specific checks
(command↔skill parity, gate composition, pattern-reference integrity, scanner-by-capability). Produce a
severity-ranked report; apply unambiguous CRITICAL fixes; capture the rest for `/sentinel:self-improve`.
