# DEGRADED_CAPABILITIES Contract (canonical)

> **Define-once spec.** The single source of truth for how the marketplace signals that a
> capability (a tool, an MCP server, a lens) is **unavailable at point-of-use** — so every
> downstream consumer routes around the gap and **discloses** it, and the scorecard never
> reports a silent PASS over a lens that did not run. Defined here ahead of the runtime items
> that implement against it (P1-15 point-of-use emit, P1-16 headless routing, P1-17 scorecard
> partial-coverage, P1-24 mid-session MCP liveness). Producers and consumers reference this
> doc; they do not restate it.

This complements [`context-sentinel.md`](context-sentinel.md): sentinels carry **phase
completion** state; a DEGRADED_CAPABILITIES record carries **capability availability** state.
A sentinel says *what was produced*; a degraded-capabilities record says *what could not be
produced, and why*. They are orthogonal and both may be present.

---

## 1 · The SHAPE of the signal

A degraded capability is a structured record with exactly three required fields:

| Field | Type | Meaning |
|---|---|---|
| `capability` | string | A stable, dotted identifier for the unavailable capability — e.g. `mcp.chrome-devtools`, `mcp.context7`, `lens.security`, `tool.mmdc`, `tool.browser`. Namespaced by kind (`mcp.` / `lens.` / `tool.`) so consumers can match on a family. |
| `reason` | string | A concrete, human-readable cause — not "unavailable". E.g. `"chrome-devtools MCP did not respond to liveness ping"`, `"no system browser on PATH"`, `"SECURITY not installed"`. |
| `since_phase` | string | The lifecycle/dev-system phase at which the degradation was first observed (e.g. `DESIGN`, `IMPL`, `OPERATE`, or a dev-system step id like `ds-step-5`). Lets a consumer tell a degradation that has persisted across phases from a fresh one. |

Optional fields a producer MAY add (consumers must tolerate their absence):

- `emitter` — who emitted it (agent/skill/hook id), for audit.
- `ts` — ISO-8601 timestamp of first observation.

### Two carriers, one schema

The same three-field record travels two ways depending on the producer's situation:

1. **Inline marker** (in agent/skill output, where there is no durable state to write — the
   point-of-use case). A single line, greppable, machine-parseable:

   ```
   DEGRADED_CAPABILITIES: [{"capability":"mcp.chrome-devtools","reason":"MCP did not respond","since_phase":"DESIGN"}]
   ```

   The value is a JSON array (one or more records) so multiple degradations accumulate on one
   marker. Downstream agents inherit it the same way they inherit sentinels — by reading the
   marker from accumulated context.

2. **State file** (the durable, cross-process case — a hook or operate writing a record
   that must survive a crashed skill/MCP and be read by a later process). Canonical path:

   ```
   <project>/.i2p/degraded-capabilities.json
   ```

   Schema — an additive, append-merge document (readers tolerate extra keys; a missing file
   means "no known degradation", **not** an error):

   ```json
   {
     "schema": "degraded-capabilities/1.0",
     "degraded": [
       { "capability": "mcp.chrome-devtools", "reason": "liveness ping timed out",
         "since_phase": "DESIGN", "emitter": "sessionstart-mcp-liveness", "ts": "2026-06-07T12:00:00Z" }
     ]
   }
   ```

   `<project>/.i2p/` is the established project state dir (same home as `lifecycle.json` and
   `cost.json`). The state file is the **authoritative** carrier; an inline marker is a hint that
   SHOULD be folded into the state file when a durable writer is available.

**Why this shape.** A structured record (not free prose) so consumers can match deterministically;
a `capability` namespace so a consumer can route on a *family* (`mcp.*`) without enumerating every
id; a `since_phase` so persistence is visible; **two carriers because the producers differ in
durability** — an agent mid-output has no safe place to write a file, while a crash-surviving hook
must persist across processes. One schema spans both so a consumer reads the same three fields
regardless of how the signal arrived. The state file is additive/versioned so the schema can grow
without a destructive migration (the same discipline as `cost.json` cycle-indexing, P2-20).

---

## 2 · EMIT points — who produces the signal

| Producer | When it emits | Carrier |
|---|---|---|
| **Agents / skills** (P1-15) | A tool/MCP/lens they need is unavailable **at point-of-use** — discovered when they reach for it, not at session start. They emit the inline marker in their handoff output AND, when a durable writer is reachable, merge it into the state file. | inline marker (+ state file when possible) |
| **operate** (P1-24, co-author) | It owns the OPERATE runtime surface; when an observability/incident lens cannot run because a declared MCP or telemetry source is dead, it emits a degraded record. operate owns the **canon and the consumer** of the OPERATE view — but per the heal-itself rule it does **not** host the liveness *detector* in its own skills (a crash would blind it). See [`operate/knowledge/operate-canon.md`](../../../operate/knowledge/operate-canon.md). | state file |
| **SessionStart hook substrate** (P1-24) | A **mid-session MCP-liveness ping** of each declared MCP server; on no-response it writes the record to the state file. It lives in the hook substrate (not inside any skill/MCP) precisely so it survives the crash it is detecting — the same crash-surviving layer as the P1-8 hook heartbeat. | state file |

**Detect-only.** Every emit point is DETECT, never auto-restart/auto-heal. Emitting the signal
is the heal-adjacent action; routing around it (below) is the consumer's job. No producer kills a
run because a capability is degraded — it records, discloses, and lets the consumer decide.

A capability that **recovers** SHOULD be removed from the state file by the producer that re-verifies
it (a degradation is current state, not an append-only log); absent any re-verification it persists,
which is the safe default (a stale "degraded" over-discloses; it never falsely PASSes).

---

## 3 · The CONSUMER contract

Any skill/agent/instrument that reads degraded-capabilities MUST honour all three:

1. **Route around it.** A downstream step whose required capability appears in
   `degraded` SKIPS that step (or takes its degraded-but-valid fallback path) instead of failing
   the run or — worse — silently producing an empty result that looks like success. Match on the
   `capability` family when routing (e.g. any `lens.security` degradation routes the security step
   to "not run").

2. **DISCLOSE.** The skip is surfaced to the user, never swallowed. The disclosure names the
   `capability`, the `reason`, and the `since_phase` (the three fields exist so the disclosure can
   be specific): *"Security lens did not run — SECURITY not installed (since DESIGN); coverage is
   PARTIAL, not PASS."* This is the marketplace's standing detect→degrade→**disclose** discipline,
   made machine-checkable.

3. **Never count a non-run as a pass.** The scorecard (P1-17) reads the state file and, for any
   measured dimension whose producing lens is degraded, marks coverage **PARTIAL** — it MUST NOT
   read "0 findings" as "0 problems" when the lens that finds them did not run. A degraded lens
   yields `partial`, never a silent `PASS`. (This is the concrete defence against the false-green
   class the marketplace's self-healing work exists to close.)

### Consumer reference points (implement against this doc)

- **P1-15** — agents emit at point-of-use; downstream skips route around + disclose (carrier §1, contract §3).
- **P1-16** — headless/CI routing reads `mcp.*` degradations to pick headless-safe phases.
- **P1-17** — scorecard reads the state file → marks the affected coverage dimension PARTIAL.
- **P1-24** — operate / SessionStart liveness ping is the MCP-death **emitter** (§2).

---

## 4 · Worked example

A DESIGN-phase mockup needs the chrome-devtools MCP to screenshot a route; the MCP died mid-session.

1. **Emit** — the SessionStart liveness ping already wrote to `<project>/.i2p/degraded-capabilities.json`:
   `{"capability":"mcp.chrome-devtools","reason":"liveness ping timed out","since_phase":"DESIGN"}`. The
   mockup skill, reaching for the MCP and finding it gone, also emits the inline marker in its handoff.
2. **Route** — the design step takes its no-MCP fallback (an SVG wireframe) instead of failing.
3. **Disclose** — output states: *"Rendered as a wireframe — chrome-devtools MCP unavailable (liveness ping
   timed out, since DESIGN). Screenshot-grade review skipped."*
4. **Score** — `/foundry:scorecard` reads the state file and marks the design-review coverage dimension
   **PARTIAL**, not PASS.

The run completes, nothing was silently dropped, and the gap is visible at every layer.
