---
<!-- SOLID REPLICATION FRAGMENT v1.1 — DO NOT EDIT THIS BLOCK IN PROJECT FILES -->
<!-- This fragment is emitted by the FOUNDRY plugin and travels with all documents in a project. -->
<!-- To propose changes, follow the self-improvement protocol carried by the FOUNDRY inspector. -->

## ♻️ SOLID Self-Improvement Covenant

This document is part of a project driven by the **FOUNDRY** plugin — the value-flow
production system. All documents in this project — READMEs, EARS specs, plans, feature
files, cost records, and inspection reports — carry this covenant. Its purpose is to keep the
project's document ecosystem alive, honest, and continuously improving. It is the document-level
expression of waste elimination (`pillars/waste-elimination.md`): a document that notices and
removes its own drift never accumulates it.

### The prime law of the covenant — halve the distance to perfection

> **Every component of the idea-to-production marketplace — every plugin, skill, agent, command,
> and knowledge doc — continuously asks how it can improve, and each iteration must at least HALVE
> the remaining distance to perfection.**

Perfection is asymptotic; the obligation is the *rate of approach*. Concretely, each pass should:
- **Eliminate waste aggressively** — find and remove the single largest source of rework,
  ambiguity, or drift remaining (`pillars/waste-elimination.md`, incl. *rediscovery*).
- **Hold quality first, absolutely** — never weaken a gate to make progress; raise the floor
  instead (`pillars/quality-first.md`).
- **Deepen knowledge-parity** — convert every recurring question into a written answer so it is
  never asked twice (`pillars/knowledge-parity.md`).
- **Fix upstream, once** — a gap that recurs is not an instance to patch but a process to repair at
  its source (a guardrail, a template, a sharper rule), so no future build pays for it again
  (`protocols/guardrails-ledger.md`).

A component that is not measurably closer to flawless than its previous version has not honoured
the covenant. The `inspector` agent audits the system against exactly this law.

### What this means for this document

1. **Single Responsibility**: This document does one thing. If it is trying to
   do more than one thing, split it.

2. **Open for Extension**: When new information emerges, add a new section
   rather than rewriting existing sections. Rewrites lose history.

3. **Liskov Substitution**: This document should be substitutable for a
   manually written equivalent without breaking any downstream tool or agent
   that consumes it.

4. **Interface Segregation**: Readers who only need one section of this document
   should not be forced to parse the whole thing. Sections are self-contained.

5. **Dependency Inversion**: Concrete details (names, versions, dates) depend
   on the abstract structure (the brief, the spec, the plan) — not the other
   way around. If the structure changes, update the abstract before the concrete.

### Self-cleaving — when the defect is *breadth*

"Halve the distance" usually means going *deeper*. But sometimes the largest remaining defect is
**breadth**: an element has grown to do **more than one thing**, violating Single-Responsibility (1).
The covenant's answer is **self-cleaving** — the element *splits itself* into smaller, more
SOLID-adherent elements that each do one thing better, and rewrites itself accordingly. Cleaving is
*how* you halve the distance when the problem is scope, not depth.

> **IMPORTANT — THE ONLY WAY:** A self-cleave is still a covenant change — it is **proposed, reviewed,
> and merged**, never silently self-applied. The scope decides the destination:
>
> - **A marketplace element** (an agent, skill, command, or knowledge doc that ships in a FOUNDRY
>   plugin) cleaves on a **branch**, passes the always-on adversarial gate (`/foundry:pr-review`), and
>   is **raised as a PR** under the marketplace's merge governance (`protocols/merge-governance.md`) —
>   so **every user of the marketplace inherits the improvement** on merge. The `inspector` flags the
>   opportunities, and a dedicated `self-improve` skill is the intended driver of this loop.
> - **A project document** (a README, plan, spec in a user's project) cleaves **locally** — split the
>   section, leave a pointer, keep history — under this same covenant, no marketplace PR involved.

A cleave that loses information, breaks a downstream consumer (Liskov, 3), or trades one over-broad
element for two tangled ones has **not** honoured the covenant. Cleave along the seam of
responsibility, not down the middle of a sentence.

### Periodic self-review prompt

At natural checkpoints (end of a milestone, before a major refactor, after a
FOUNDRY cycle), ask your AI assistant:

> "Review this document against the SOLID covenant above. Are there sections
> that have drifted from their stated purpose? Are there gaps that should be
> filled? Propose a Version 2 of any section that needs improvement, and flag
> it for my review."

The assistant applies FOUNDRY's self-improvement protocol (the same discipline the
`inspector` agent runs against the system itself) and returns a proposed update for your
approval before any change is applied.

### Lineage

- **System:** FOUNDRY plugin — the value-flow production system
- **Covenant version:** 1.3 (adds **self-cleaving** — halving the distance when the defect is breadth)
- **Canonical home:** `knowledge/architecture/solid-covenant.md` (in the FOUNDRY plugin)
- **See also (in the plugin):** `knowledge/architecture/solid.md` (the SOLID *principles* reference for code), `knowledge/first-principles.md` (the philosophical spine), and the marketplace `knowledge/glossary.md`. (Bare paths, not links — this fragment travels into project files where relative links would not resolve.)

<!-- END SOLID REPLICATION FRAGMENT -->
---
