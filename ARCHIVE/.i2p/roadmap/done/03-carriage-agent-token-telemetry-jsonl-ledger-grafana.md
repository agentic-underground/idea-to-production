---
id: 3
title: "Carriage agent + token telemetry (JSONL ledger → Grafana)"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "#1"
---

# [3] Carriage agent + token telemetry (JSONL ledger → Grafana)

**Brief Description**
Every work item is backed by a carriage agent that annotates its card with who is processing it, what
they are processing, and how many tokens the ticket has cost. All of it is captured to append-only JSONL
log files and pushed to the local Grafana, and rolled up into reports of total token cost broken down by
work item and sub-item — for each atomic item and up the dependency tree of composite items.

### User Stories
- AS A builder I WANT each item's card to show who/what/token-cost in real time SO THAT I can see where
  value (and spend) is going.
- AS A builder I WANT token cost rolled up per atomic item and per composite item SO THAT I can read cost
  by work item and sub-item.
- AS the telemetry host I WANT the data as JSONL SO THAT reports and Grafana can consume it as a data source.

### EARS Specification
**Ubiquitous**
- The system SHALL record, for every item, the processing agent identity, the current activity, and a
  cumulative token tally.
- The system SHALL persist every telemetry event as a line in an append-only JSONL log and push it to the
  local Grafana.
**Event-driven**
- WHEN a carriage agent consumes tokens on an item THE SYSTEM SHALL add them to that item's tally and to
  every ancestor composite item's tally.
- WHEN a report is requested THE SYSTEM SHALL compute total token cost broken down by item and sub-item
  from the JSONL data sources.
**Unwanted behaviour**
- IF an item is in WAIT THEN THE SYSTEM SHALL NOT let its carriage agent advance value or accrue work tokens.

### Acceptance Criteria
1. Given a carriage agent processes item X, Then X's card shows the agent, the activity, and a rising token
   count, and a JSONL line is appended.
2. Given X is a child of composite C, When X accrues 1000 tokens, Then C's rolled-up tally rises by 1000.
3. Given the JSONL logs, When a token-cost report is generated, Then totals reconcile to the sum of events.

### Implementation Notes
- Carriage agent is a FOUNDRY-style value-handler bound to one item; reports status/spend via #1's MCP verbs.
- JSONL schema: `{ts, item_id, agent, activity, tokens_delta, tokens_total, ancestors[]}`. Grafana via the
  local agent/Loki already referenced in mission-control observability knowledge.

### Human Interface Test Plan
- [Carriage status on a card]: start processing an item → verify card shows agent name + activity + token
  badge incrementing → reload → verify last status persists from the JSONL log.

### Development Plan Reference
`doc/CARRIAGE_AGENT_TELEMETRY_PLAN.md`
