---
description: Inspect the ATELIER plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect ATELIER.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the ATELIER-specific checks (canon
coverage, design-fitness rubric single-source, reviewer-lens wiring, Playwright-by-capability). Produce a
severity-ranked report; apply unambiguous CRITICAL fixes; capture the rest for `/atelier:self-improve`.
