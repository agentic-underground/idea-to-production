---
id: 109
title: "Document flow-mcp verbs as the /flow bindings"
status: PENDING
priority: LOW
added: 2026-06-17
depends_on: "#97 (flow-mcp rename), #105"
---

# [109] Document flow-mcp verbs as the /flow bindings

**Brief Description**
Fold the slash-command catalog's MCP appendix into the `/flow` surface docs as the **deterministic
CPU-layer bindings** the flow plugin calls. The full verb set — `render_roadmap`, `list_items`, `get_item`,
`post_status`, `set_wait_go`, `append_spend`, `set_item_model`, `validate_connection`, `mutate_connection`,
`annotate`, `request_rewrite`, `append_sysmsg`, `list_events`, `ping` — is documented as the typed,
token-authenticated `flow-mcp` API that `/flow` verbs invoke under the hood, so the user-facing surface and
its deterministic backend are described in one place.

### User Stories
- AS a reader of the `/flow` docs I WANT to see which `flow-mcp` verbs each `/flow` verb calls SO THAT I
  understand the deterministic backend behind the command surface.
- AS the owner I WANT the catalog's MCP appendix to live with the flow plugin docs SO THAT the binding map
  stays next to the surface it describes.

### EARS Specification
**Ubiquitous**
- The flow plugin's `/flow` surface docs SHALL document the `flow-mcp` verb set as the deterministic
  CPU-layer bindings the `/flow` verbs call.

**Event-driven**
- WHEN the MCP appendix is folded into the `/flow` docs THE SYSTEM SHALL list each verb (`render_roadmap`,
  `list_items`, `get_item`, `post_status`, `set_wait_go`, `append_spend`, `set_item_model`,
  `validate_connection`, `mutate_connection`, `annotate`, `request_rewrite`, `append_sysmsg`,
  `list_events`, `ping`) with its role in the surface.

**Unwanted behaviour**
- IF a documented verb does not exist in the shipped `flow-mcp` binary (or vice versa) THEN the docs SHALL
  be treated as drifted and reconciled, never left describing a phantom verb.

### Acceptance Criteria
1. Given the `/flow` surface docs, When read, Then all fourteen `flow-mcp` verbs are documented as the
   deterministic bindings the `/flow` verbs call.
2. Given the slash-command catalog's prior MCP appendix, When this lands, Then that appendix is folded into
   the flow plugin docs (not duplicated in two places).
3. The documented verb list matches the shipped `flow-mcp` binary exactly (no phantom or missing verb).

### Implementation Notes
- Depends on [97] (verbs are documented under the renamed `flow-mcp`) and [105] (the `/flow` surface exists
  to host the bindings).
- Source the appendix from the existing catalog (`docs/SLASH_COMMANDS.md`) MCP section; move it into the
  flow plugin's surface docs rather than restating it — keep one canonical home.
- These are read/write verbs split: read (`render_roadmap`, `list_items`, `get_item`, `list_events`,
  `ping`, `validate_connection`) and mutating (`post_status`, `set_wait_go`, `append_spend`,
  `set_item_model`, `mutate_connection`, `annotate`, `request_rewrite`, `append_sysmsg`); note which
  `/flow` verbs (pull/carry/report/setup) bind which.
