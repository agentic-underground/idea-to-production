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
- **Covenant version:** 1.1
- **Canonical home:** `knowledge/architecture/solid-covenant.md`
- **See also:** `architecture/solid.md` (the SOLID *principles* reference for code)

<!-- END SOLID REPLICATION FRAGMENT -->
---
