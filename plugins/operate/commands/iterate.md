---
description: Close the build-measure-learn loop — turn a production signal into a new OPPORTUNITY that re-enters DISCOVER (↻).
---

Run the **iterate** skill.

Apply the **build-measure-learn** pivot-or-persevere test to a production signal (a stalled/regressed
**actionable** metric, an **incident** postmortem revealing a wrong assumption, or **user feedback**):

- **Persevere** → ordinary roadmap/maintenance work; stay in the operate loop.
- **Pivot / new opportunity** → frame an `OPPORTUNITY-<slug>.md` (the evidence, the problem, who has it,
  why it's worth a cycle) and **re-enter DISCOVER**. Hand off to `/market-scan` (market-scanner) for
  adversarial validation, or `/ideate` (ideator), when installed; otherwise the brief is the artefact.

When a genuine re-entry signal is confirmed and **i2p** is installed, advance the lifecycle so the status
line cycles OPERATE → DISCOVER (↻):

```bash
/i2p:lifecycle done OPERATE   # order-safe & idempotent — a no-op unless a lifecycle is running at OPERATE
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
