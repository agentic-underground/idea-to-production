---
description: Inspect the PUBLISH plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect PUBLISH.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the PUBLISH-specific checks
(charting-matrix single-source, reviewer wiring, engine fallback, publish front-door routing). Produce a
severity-ranked report; apply unambiguous CRITICAL fixes; capture the rest for `/publish:self-improve`.
