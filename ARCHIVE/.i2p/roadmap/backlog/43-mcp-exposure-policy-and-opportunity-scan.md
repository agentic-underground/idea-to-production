---
id: 43
title: "MCP exposure policy + opportunity scan (present as choices)"
status: PENDING
priority: MEDIUM
added: 2026-06-15
depends_on: "#1 (flow-server verbs)"
---

# [43] MCP exposure policy + opportunity scan (present as choices)

**Brief Description**
Define and enforce which MCP actions agents may call, and build the capability to scan a project for MCP
opportunities and present them to the owner as choices for steering. Owner decision: expose all four
categories — roadmap read/query, stage transitions, who/what/cost telemetry — but **gate** the expensive
authoring/graph verbs behind explicit approval.

### User Stories
- AS the owner I WANT cheap/common MCP actions exposed and expensive ones gated SO THAT agents are fast for
  routine flow but I keep control of costly mutations.
- AS the owner I WANT a scan that surfaces candidate MCP actions as choices SO THAT I can steer where the
  MCP surface is headed.

### EARS Specification
**Ubiquitous**
- The system SHALL expose roadmap-read, stage-transition, and telemetry verbs to agents by default.

**Optional feature**
- WHERE a verb is classed expensive (e.g. `request_rewrite`, `mutate_connection`) THE SYSTEM SHALL require
  explicit approval before invocation.

**Event-driven**
- WHEN the owner runs the MCP-opportunity scan THE SYSTEM SHALL present candidate actions (common + expensive)
  as a choice list for approval/steering.

### Acceptance Criteria
1. Given the exposure policy, When an agent calls a gated verb without approval, Then it is refused with a
   clear reason.
2. Given the scan, When run, Then it lists candidate MCP actions grouped by common vs expensive for the owner
   to choose from.
3. The policy is documented (single source) and reflected in settings/registration.

### Implementation Notes
- Classify the existing 13 verbs (read/transition/telemetry = common; rewrite/graph = expensive).
- Approval-gating mechanism for expensive verbs; document in a knowledge doc.
- The scan presents choices (AskUserQuestion-style) — common activities and expensive ones are the candidates.
