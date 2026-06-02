---
name: handoff-protocol
description: Use when one lifecycle agent transfers value to its downstream partner and must package artifacts, risks, review status, and next instructions in a strict schema. Complements the FOUNDRY context sentinel protocol — sentinels carry machine-readable state, handoffs carry human-readable intent.
---

# Handoff Protocol

Standardises the carry-over message between SDLC stage agents so execution is deterministic,
auditable, and resumable by a cold-start agent. This skill is the **trigger**; the canonical
schema, validation rules, and quality bar live once in:

> **`${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/handoff-schema.md`** — read it to emit or
> validate a handoff payload.

## When to read the schema
- You are a stage agent finishing work → emit the payload (schema §"Required payload").
- You are a stage agent starting work → validate the incoming payload (schema §"Validation rules").
- You are defining a new station → use the schema as the contract shape.

## The one rule worth repeating here
Sentinels prove **what was done** (`${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md`);
handoffs explain **what to do next**. Emit both. An empty `unresolved_risks` means "none
known" — never omit the field because you didn't check.

For the per-business-station input/exit contracts a gate-keeper verifies, see the
`value-station-handoff` skill.
