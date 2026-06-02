# foundry — the production-house build system

`foundry` is the BUILD_SYSTEM the **FOUNDER** (COO) agent orchestrates. Where `frontend`
designs surfaces and `roadmapper` formalises features, `foundry` is the discipline that
moves any increment from **idea to product, one vertical slice at a time**, through a fixed
line of **value-stations** staffed by **value-handlers** (agents), with a non-negotiable,
performance-instrumented **test contract** at its heart.

## What's here
- `../../agents/founder.md` — the FOUNDER_COO orchestrator agent.
- `skills/founder-method/` — the station model, discovery protocol, and test contract.
- `skills/vertical-slice/` — how to cut and drive ONE thin end-to-end increment.
- `skills/value-station-handoff/` — exact input/exit contracts per station.
- `examples/expansion-redaction-scrubber.md` — a worked Mode-C expansion for market-scan idea #1.

## The test contract (why FOUNDER may refuse to build)
Five levels — **unit, module, boundary, system, STORY** — each emitting performance samples,
with a **gated perf-delta** that runs alongside the STORY tests. If the build system cannot
satisfy this, FOUNDER halts and reports `CONTRACT UNMET`. This is intentional: the contract
is the system owner's hard line.

## Using it
Invoke the agent: *"founder, plan this"* / *"explain what we're doing"* / *"expand the top-3"*.
FOUNDER runs discovery (`foundry -help`, `frontend -help`), emits a topology READOUT, then
asks which mode you want.

## Companion plugins (optional — graceful enhancement)
foundry's value artefact is **markdown**. Two cross-cutting concerns live in separate plugins in
the same marketplace and are used *automatically if installed*, with clean degradation if not:

- **SECURITY → [`sentinel`](../sentinel/)** — a pre-release gate (PII, secrets, dependency audit).
  When installed, foundry's release path can run `/security-gate` before DELIVERY; when absent,
  the gate is skipped with a noted recommendation.
- **PUBLISHING → [`pressroom`](../pressroom/)** — articles, standalone diagrams, and
  print-quality PDFs. When installed, foundry can hand markdown to `/publish` for richer output;
  when absent, foundry delivers markdown as-is.

These are referenced **by capability**, never by hard `${CLAUDE_PLUGIN_ROOT}` path across the
plugin boundary. See `VALUE_FLOW.md §4`. (`frontend`/DESIGN remains *inside* foundry — it is an
on-line station, not a cross-cutting companion.)
