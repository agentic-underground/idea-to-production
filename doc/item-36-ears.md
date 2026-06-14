# EARS Requirements — Item [36]: Persist gate state across restarts

> Authored: 2026-06-14
> Item: [36] Persist gate state: WAIT/GO survives restart + surfaces in roadmap view
> Handler: handler-rust
> Source ACs: see FLOW_GATE_PERSIST_PLAN.md §2

---

## Requirement Statements

### EARS-G36-01 — Atomic write on gate change

**WHEN** `Store::set_gate()` is called with any valid item ID and a gate value (WAIT or GO),
**THEN** the system SHALL atomically write the complete id→gate map to `.flow/gates.json`
(via a write-to-tmp then rename) before returning to the caller.

*Acceptance criterion:* After `set_gate(id, Wait)` returns, `.flow/gates.json` exists and
contains a valid JSON object with the item's id mapped to `"wait"`. After `set_gate(id, Go)`
returns, the same file maps the id to `"go"`.

*Rationale:* The sidecar file is the fast restore path on startup, bypassing full JSONL
replay. It must be consistent with the last acknowledged gate change. Atomic write
(tmp + rename) prevents readers from seeing a partial write.

---

### EARS-G36-02 — Restore gate state on startup (happy path)

**WHEN** the flow-server starts **AND** a valid `.flow/gates.json` file is present,
**THEN** the system SHALL call `Store::restore_gates()` after `ingest_roadmap()` completes
and SHALL restore each known item's gate to the value recorded in the file.

*Acceptance criterion:* Set item `X` to WAIT → restart server → `GET /api/items` returns
`gate: "wait"` for item `X`. The `list_items` MCP tool's `pending.wait` sub-list contains
item `X`.

*Rationale:* The primary acceptance criterion of this item: gate state must survive restart.
`restore_gates()` runs after `ingest_roadmap()` to avoid the sequencing trap where
`upsert_item()` resets gate to `Go`.

---

### EARS-G36-03 — Resilient cold start: missing gates file

**IF** `.flow/gates.json` does not exist **WHEN** `Store::restore_gates()` is called,
**THEN** the system SHALL return without error and all items SHALL default to gate `go`.

*Acceptance criterion:* Starting the server against a `.flow/` directory that contains no
`gates.json` produces no error; `GET /api/items` returns `gate: "go"` for all items.

*Rationale:* Fresh deployments and directories created before this feature have no
`gates.json`. Startup must never be blocked by a missing optional sidecar.

---

### EARS-G36-04 — Resilient cold start: corrupt gates file

**IF** `.flow/gates.json` exists but contains invalid JSON **WHEN**
`Store::restore_gates()` is called,
**THEN** the system SHALL log a warning to stderr, return without error, and leave all
items at gate `go`.

*Acceptance criterion:* Writing arbitrary bytes (e.g. `{not valid}`) to `.flow/gates.json`
then starting the server: server starts, `GET /api/items` returns HTTP 200 with all items
at `gate: "go"`, and a warning is printed to stderr.

*Rationale:* Corrupt sidecars must never prevent service startup. The JSONL replay in
`Store::open()` provides an independent recovery path for gate events.

---

### EARS-G36-05 — Stale item IDs silently discarded

**WHEN** `Store::restore_gates()` is called **AND** `.flow/gates.json` contains an item ID
that is not present in the current flow,
**THEN** the system SHALL silently discard that entry and continue restoring remaining
known items.

*Acceptance criterion:* A `gates.json` containing `{"ghost-item": "wait", "real-item": "wait"}`
where `ghost-item` is absent from the roadmap: `real-item` is restored to WAIT; no error is
raised; `ghost-item` is ignored.

*Rationale:* Items are removed from the roadmap over time. Stale sidecar entries are
harmless and must not crash or warn on every restart.

---

### EARS-G36-06 — `list_items` MCP tool groups PENDING items by gate

**WHEN** the `list_items` MCP tool is called,
**THEN** the system SHALL return a JSON object with the following shape:
```json
{
  "pending": {
    "wait": [ ...items with status DO and gate WAIT... ],
    "go":   [ ...items with status DO and gate GO... ]
  },
  "in_progress": [ ...items with status DOING... ],
  "done":        [ ...items with status DONE... ]
}
```
**AND** every item object within each group SHALL include the same fields as the existing
`item_json` serializer (`id`, `title`, `status`, `gate`, `tokens`, `model`, `deps`,
`annotations`).

*Acceptance criterion:* With one PENDING/WAIT, one PENDING/GO, one DOING/GO, one DONE/GO
item in the store: `list_items` result has `pending.wait` length 1, `pending.go` length 1,
`in_progress` length 1, `done` length 1. Empty groups are empty arrays, not null/absent.

*Rationale:* The current flat `{"items": [...]}` shape does not expose gate grouping at a
glance. Agents consuming `list_items` need to identify gated items without filtering.

---

### EARS-G36-07 — Non-fatal warn-and-continue on sidecar write failure

**WHEN** `Store::set_gate()` is called **AND** the atomic write of `.flow/gates.json` fails
(e.g. disk full, permissions error),
**THEN** the system SHALL log a warning to stderr, complete the in-memory gate change and
the JSONL event append normally, and return success to the caller (the sidecar is not the
source of truth).

*Acceptance criterion:* When the `.flow/` directory is replaced with a read-only mount or
the `.flow/gates.json.tmp` path is unwritable, `set_gate()` still returns `Ok(())`, the
in-memory gate is updated, the JSONL event is appended, and a warning appears on stderr.

*Rationale:* Failing the user's gate toggle because a sidecar write faulted would be a bad
UX. The JSONL log is authoritative; the sidecar is an optimisation. Warn and continue.

---

### EARS-G36-08 (sequencing invariant) — restore_gates runs after ingest_roadmap

**WHEN** the flow-server starts with a roadmap path configured,
**THEN** `Store::restore_gates()` SHALL be called in `main.rs` strictly AFTER
`store.ingest_roadmap()` returns, so that gate values applied by `restore_gates()` are
not overwritten by the `Item::new` defaults used inside `upsert_item()`.

*Acceptance criterion:* Start server with a roadmap containing item `X`, with an existing
`gates.json` showing `X` as WAIT. After startup, item `X` has gate `wait` (not `go`). If
`restore_gates()` ran before `ingest_roadmap()`, item `X` would be `go` (a sequencing bug).

*Rationale:* This is the critical sequencing invariant identified in the plan. The EARS
statement makes it an explicit, testable requirement rather than an implementation note.

---

## Traceability Matrix

| EARS ID       | AC # | Source |
|---------------|------|--------|
| EARS-G36-01   | AC-1, AC-2 | item [36] ACs 1 and 2 |
| EARS-G36-02   | AC-1, AC-2 | item [36] ACs 1 and 2 |
| EARS-G36-03   | AC-4 | item [36] AC 4 |
| EARS-G36-04   | AC-5 | item [36] AC 5 |
| EARS-G36-05   | AC-6 | item [36] AC 6 |
| EARS-G36-06   | AC-3 | item [36] AC 3 |
| EARS-G36-07   | AC-1, AC-2 (warn-continue) | FOUNDRY plan §6 Risk 5 |
| EARS-G36-08   | AC-1 (sequencing) | FOUNDRY plan §6 Risk 1 |

---

## Uniqueness Check

All 8 requirement IDs are unique: EARS-G36-01 through EARS-G36-08.
No two statements share the same trigger/response pair.
Each maps to a distinct, independently testable behavior.
