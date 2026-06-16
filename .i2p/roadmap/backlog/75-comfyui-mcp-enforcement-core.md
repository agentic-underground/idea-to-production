---
id: 75
title: "comfyui-mcp — enforcement core: template + param + model allowlists"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "#74"
---

# [75] comfyui-mcp — enforcement core: template + param + model allowlists

**Brief Description**
The server-side enforcement that earns the name: a **workflow-template allowlist** (`submit_prompt` takes a
`template_id`, never a node graph — removes arbitrary-node execution + SSRF via URL-loading nodes),
**input validation** (params schema-checked: steps/seed bounded, prompt length-capped, model ∈ allowlist),
and a **model allowlist** (only checkpoints physically in the bind-mounted `DIFFUSION_MODELS` are
selectable).

### User Stories
- AS a security owner I WANT the server to reject anything but allowlisted templates/models with validated
  params SO THAT a caller cannot execute an arbitrary node graph or load an arbitrary URL/model.

### EARS Specification
**Ubiquitous**
- The system SHALL accept only allowlisted `template_id`s and allowlisted models, with every param
  schema-validated within bounds.

**Unwanted behaviour**
- IF a request supplies a raw node graph, an out-of-bounds param, or a model not in `DIFFUSION_MODELS` THEN
  THE SYSTEM SHALL refuse it with a validation error, executing nothing.

### Acceptance Criteria
1. Given a node-graph payload, When submitted, Then it is refused (only `template_id` is accepted).
2. Given an out-of-range step/seed, an over-long prompt, or an unlisted model, When submitted, Then each is
   refused; given valid inputs, Then it is accepted.

### Implementation Notes
- Allowlist loaders read the shipped templates + the bind-mounted model set; param schema per template.
- This removes arbitrary-node execution and URL-loading-node SSRF.
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 1 §2, security model) under roadmap item [47].
