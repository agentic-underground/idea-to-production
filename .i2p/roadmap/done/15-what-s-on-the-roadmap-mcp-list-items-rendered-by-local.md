---
id: 15
title: "\"What's on the roadmap\" → MCP list_items, rendered by local compute"
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "#1"
---

# [15] "What's on the roadmap" → MCP list_items, rendered by local compute

**Brief Description**
When the user asks "what's on the roadmap" (the ROADMAPPER §5 QUERY trigger), instead of the agent reading
and formatting `ROADMAP.md` with LLM tokens, the agent calls the flow server's MCP `list_items` verb; the
server renders a deterministic table/tree of items (status · priority · token cost) using **local compute**
and the agent shows that view in the conversation — near-zero LLM tokens, and authoritative (the same source
the board uses). If the server is unreachable, it falls back to reading the markdown directly, losing nothing.

### User Stories
- AS a builder I WANT "what's on the roadmap" to be answered by a local MCP call SO THAT the roadmap view is
  instant, deterministic, token-cheap, and identical to what the board shows.
- AS a builder on a project without the flow server running I WANT the query to still work SO THAT the
  behaviour degrades gracefully to reading the markdown.

### EARS Specification
**Event-driven**
- WHEN the user issues the "what's on the roadmap" query AND the flow server is reachable THE SYSTEM SHALL
  call the MCP `list_items` verb and present the server-rendered view, spending no LLM tokens on formatting.
- WHEN a filtered query is issued ("in progress", "check status", "what's next") THE SYSTEM SHALL pass the
  filter to the verb and present the filtered local-compute result.
**Unwanted behaviour**
- IF the flow server is unreachable or `list_items` errors THEN THE SYSTEM SHALL fall back to reading
  `ROADMAP.md` directly and say which path it used.
**Optional feature**
- WHERE the org/project configures it off THE SYSTEM SHALL keep the markdown-read path as the default.

### Acceptance Criteria
1. Given the flow server is running, When the user asks "what's on the roadmap", Then the list is produced by
   the MCP `list_items` verb (local compute) and shown, with no LLM-side formatting pass.
2. Given the server is down, When the user asks, Then the markdown-read fallback runs and the response notes
   the fallback.
3. Given a filtered query, Then the filter is honoured by the verb and the rendered result reflects it.

### Implementation Notes
- Reuses #1's `list_items` MCP verb (already in #1's surface); adds a deterministic renderer (table/tree)
  server-side so the output is byte-stable and token-free. The ROADMAPPER §5 QUERY path is taught to prefer
  the MCP verb, fall back to markdown.
- This is the query-path twin of the always-on governance ethos: authoritative state, local compute, minimal tokens.

### Human Interface Test Plan
- (Conversational/agent surface, not a browser UI; exercised via an MCP contract test: server-up returns the
  rendered view; server-down triggers the markdown fallback with a noted path.)

### Development Plan Reference
`doc/ROADMAP_QUERY_VIA_MCP_PLAN.md`
