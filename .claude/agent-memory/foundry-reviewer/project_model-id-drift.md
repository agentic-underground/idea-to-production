---
name: model-id-drift
description: Literal model ids (claude-opus-4-8/sonnet-4-6) are restated inline across ~45 files despite a canon that says reference-don't-pin — KAIZEN systemic flag, not a per-PR gate
metadata:
  type: project
  type-note: KAIZEN-covenant pattern for foundry-reviewer
---

`plugins/foundry/knowledge/policy/model-selection.md` is the canonical model-tier table and says
explicitly: *"agents reference this table instead of pinning model IDs"* / *"update only this table
and the whole fleet re-tiers."* Yet the literal ids `claude-opus-4-8` and `claude-sonnet-4-6` are
restated inline in **~45 files** across every plugin (handlers, ds-step agents, inspectors, pressroom
SKILLs).

**Why:** This is the reference-over-restatement / single-source-of-truth law ([[kaizen-covenant-rename]])
applied to model ids. When an id rolls, all ~45 inline copies drift out of sync with the canon.

**How to apply:** When a PR adds *new* inline literal model ids (e.g. the flow-tracking-ui PR added 3
in pressroom illustrator/writer/craft-study SKILLs), do NOT gate the PR on it — inline restatement is
the pervasive pre-existing convention and the new sites cite the canon in prose. Record it as a
SUGGESTION + KAIZEN systemic flag. The right fix is systematic (one sweep replacing literals with a
reference to model-selection.md), tracked once for the covenant — not repeated per-PR corrections.
Relates to the canonical-copy discipline in [[plugin-count-drift]].
