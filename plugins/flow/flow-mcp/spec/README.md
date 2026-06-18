# flow-mcp specification package

This directory is the **canonical, language-neutral behavioural contract** for the flow-mcp server —
the source of truth that the Ruby reference implementation, the executable FEATURE suite, and the
markdown fallback runbook all conform to. It exists because flow-mcp is being re-homed from a compiled
binary to an interpreted (Ruby 3.3.8) reference plus a by-hand fallback; pinning the behaviour in a
spec means the *behaviour* survives the implementation change and could be re-realised in any language
later.

## Contents

- **[`EARS.md`](EARS.md)** — the full EARS specification: 101 statements (`EARS-FLOW-001` …
  `EARS-FLOW-101`) covering the JSON-RPC/MCP transport, all 14 verbs, the WAIT/GO gate, token-spend
  ancestor roll-up, the dependency graph, the comment/rewrite loop, roadmap ingest, on-disk
  persistence + replay, observability, and the Ruby-runtime/fallback contract.
- **[`features/`](features/)** — the Gherkin FEATURE suite (14 files, 92 scenarios). Every EARS
  statement is covered by ≥1 `@EARS-FLOW-NNN`-tagged scenario across happy / unhappy / abuse paths.

## Conventions

EARS forms and the BDD house style follow foundry:
[`../../../foundry/knowledge/specs/ears.md`](../../../foundry/knowledge/specs/ears.md),
[`../../../foundry/knowledge/specs/bdd-gherkin.md`](../../../foundry/knowledge/specs/bdd-gherkin.md),
[`../../../foundry/knowledge/testing/test-policy.md`](../../../foundry/knowledge/testing/test-policy.md).

IDs are **permanent** — never reuse or renumber. When adding behaviour, increment from the highest
existing `EARS-FLOW-NNN`, add tagged scenarios, and reference the id from the implementing test
(`# @EARS-FLOW-NNN`).

## Coverage invariant

Every `EARS-FLOW-NNN` in `EARS.md` has at least one `@EARS-FLOW-NNN` scenario in `features/`, and
vice versa. Quick check:

```sh
diff \
  <(grep -oE 'EARS-FLOW-[0-9]{3}' EARS.md      | sort -u) \
  <(grep -rhoE '@EARS-FLOW-[0-9]{3}' features/ | sed 's/@//' | sort -u)
```

(empty diff = in sync). The Ruby reference implementation lives in `../lib/flow_mcp/` and is
test-driven against these features; the fallback procedure is the `flow-by-hand` skill.
