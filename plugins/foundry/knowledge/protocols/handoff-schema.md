# Handoff Schema (canonical)

The human-readable intent-transfer payload every lifecycle agent emits to its downstream
partner. **Sentinels vs. handoffs:** sentinels (`context-sentinel.md`) are concise,
machine-readable phase state; handoffs are verbose, human-readable intent. Use both —
sentinels prove what was done; handoffs explain what to do next. Both exist so a cold-start
agent can proceed with zero conversation history (knowledge parity).

## Required payload

Every stage agent emits this at the end of its output, populated with concrete values
(no `"..."` placeholders):

```yaml
handoff:
  from_stage: step-x
  to_stage: step-y
  objective: "single sentence — what the receiving agent must achieve"
  artifacts:
    - path: "exact/file/path.ext"
      purpose: "what this artifact is and why the next agent needs it"
      version: "1.0 | updated | current"
  unresolved_risks:
    - "specific risk description"
    # empty list = none known — "none known" is not an excuse to omit the field
  quality_gates_passed:
    - "specific gate that was verified"
  reviewer_status:
    reviewed: true
    findings_summary: "what the reviewer found and how it was resolved"
    critical_open: 0   # must be 0 to proceed without orchestrator override
  next_agent_instructions:
    - "imperative instruction 1"
    - "imperative instruction 2"
```

## Validation rules (check the incoming handoff before starting work)
1. `from_stage` and `to_stage` match actual stage IDs in the routing table.
2. Every `artifacts[].path` is concrete and resolvable — no "the doc" / "previous output".
3. `unresolved_risks` is explicit — an empty list means "none known", not "I didn't check".
4. `reviewer_status.reviewed` is `true` for all document-generating stages.
5. `reviewer_status.critical_open` is `0` before advancing (or the orchestrator grants a
   documented exception).
6. `next_agent_instructions` are imperative (start with a verb) and testable (observable outcome).

## Quality bar
- No ambiguous references ("the doc", "previous output", "as above").
- No hidden assumptions about environment, tools, or prior knowledge.
- State compatibility/environment constraints if they exist.
- Concise but complete — every field serves a purpose.

## Two altitudes of handoff
- **Step handoff** (this schema): payload between engineering steps (`ds-step-*`).
- **Station contract** (`skills/value-station-handoff/`): the input/exit contract a
  gate-keeper verifies at each *business* value-station (VALIDATE/SPEC/DESIGN/SLICE/HARDEN/
  SHIP/LEARN). The two are complementary — the schema carries the message; the station
  contract defines what "done" means at the station boundary.

## Self-improvement
Carries the SOLID covenant (`../architecture/solid-covenant.md`). If handoff validation
failures recur (missing paths, `critical_open > 0` advancing anyway, vague instructions),
strengthen the validation rules here — each failure is evidence a rule needs tightening.
