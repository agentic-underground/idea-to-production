---
id: 49
title: "PRESSROOM adopts comfyui-mcp — handler-comfyui switches curl → MCP"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "73"
---

# [49] PRESSROOM adopts comfyui-mcp — handler-comfyui switches curl → MCP

**Brief Description**
`handler-comfyui` currently talks raw HTTP to a live ComfyUI server (`$PRESSROOM_COMFYUI_URL`); the LAN
is the only trust boundary — a known Phase-0 gap. Once the secured **comfyui-mcp** server exists (the
build is item [73]), PRESSROOM's graphical value-handler switches from `curl` to the `mcp__comfyui__*`
tools, so generative figures flow through the allowlisted, validated, authenticated surface instead of an
open HTTP port. This item is PRESSROOM's *adoption* of that backend; the backend itself is built in [73].

### User Stories
- AS a PRESSROOM illustrator I WANT generative raster figures to go through the secured comfyui-mcp SO THAT
  I am not depending on an unauthenticated LAN service with arbitrary workflow execution.
- AS the marketplace owner I WANT handler-comfyui to degrade gracefully when comfyui-mcp is absent SO THAT
  the illustrator still falls back to vector handlers.

### EARS Specification
**Ubiquitous**
- The system SHALL drive ComfyUI generation through `mcp__comfyui__*` verbs when the comfyui-mcp server is
  available, never raw `curl` to a ComfyUI HTTP port.

**Event-driven**
- WHEN handler-comfyui needs a raster figure THE SYSTEM SHALL submit an allowlisted workflow template via
  comfyui-mcp and poll for the result through the MCP surface.

**Unwanted behaviour**
- IF the comfyui-mcp server is unreachable THEN THE SYSTEM SHALL decline the generative slot (so the
  orchestrator fills it with a vector option), never fall back to an unauthenticated raw-HTTP call.

### Acceptance Criteria
1. Given comfyui-mcp is running, When the illustrator requests a generative figure, Then handler-comfyui
   uses `mcp__comfyui__*` tools and no `curl` to a ComfyUI port appears in its trace.
2. Given comfyui-mcp is unreachable, When a generative figure is requested, Then handler-comfyui declines
   and the illustrator selects a vector handler instead, with the degrade disclosed.

### Implementation Notes
- Depends on [73] (the comfyui-mcp secured backend) shipping its `mcp__comfyui__*` verbs.
- Update `plugins/pressroom/agents/handler-comfyui.md` to prefer the MCP tools and keep the
  decline-on-absent path.
- Migrated from `plugins/pressroom/ROADMAP.md` (near-term) under roadmap item [47].
