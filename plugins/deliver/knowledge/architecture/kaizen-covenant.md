---
<!-- KAIZEN REPLICATION FRAGMENT v2.0 — DO NOT EDIT THIS BLOCK IN PROJECT FILES -->
<!-- This fragment is emitted by the DELIVER plugin and travels with all documents in a project. -->
<!-- To propose changes, follow the self-improvement protocol carried by the DELIVER inspector. -->

## ♻️ KAIZEN Self-Improvement Covenant

This document is part of a project driven by the **DELIVER** plugin — the value-flow
production system. All documents in this project — READMEs, EARS specs, plans, feature
files, cost records, and inspection reports — carry this covenant. Its purpose is to keep the
project's document ecosystem alive, honest, and continuously improving. **Kaizen** — *continuous
improvement* — is its spirit: it is the document-level expression of waste elimination
(`pillars/waste-elimination.md`, *muda · mura · muri*): a document that notices and removes its own
drift never accumulates it.

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

### The kaizen principles — how a document improves itself

The prime law is *what*; these are *how*. They are the standing discipline every document applies to
its own improvement.

1. **Kaizen — continuous, never finished**: improvement is a standing duty, not a phase. There is no
   "done"; there is only the current best and the next halving.

2. **PDCA — Plan ▸ Do ▸ Check ▸ Act**: change against a hypothesis, not a hunch. State what you
   expect the change to improve, make it, *measure* against the expectation, then standardise the win
   or revert and try again.

3. **Standardize, then improve**: capture the current best as the *written standard* (the template,
   the guardrail, the canonical doc), then raise the floor from there. You cannot improve what is not
   first stable — and a gate is never weakened to make progress (`pillars/quality-first.md`).

4. **Small incremental steps**: prefer many small, reversible improvements over a big rewrite. A
   rewrite loses history and hides regressions; an increment keeps the lineage legible and the blast
   radius small.

5. **Gemba — go and see**: improve from the *real* artifact and *real* downstream feedback, not from
   assumptions about either. The place the work actually happens — the failing build, the confused
   handoff, the reviewer's catch — is where the improvement is found.

6. **Eliminate muda · mura · muri**: hunt the three losses in the document ecosystem — **muda**
   (waste: restated knowledge, drift, dead sections), **mura** (unevenness: sections at wildly
   different depth, inconsistent structure across siblings), and **muri** (overburden: a document
   straining to do more than one thing).

7. **Everyone improves — respect for the maker**: every element participates in its own improvement,
   and a fix is folded back at the *source* so no future build pays for it again — **fix-upstream-once**,
   shipped to all users via PR (§6 of `first-principles.md`).

### The GEMBA reflex — capture and raise, *unprompted*

Principle 5 (*go and see*) is awareness; the **reflex** is the behaviour it demands when a station
actually hits a wall. When work meets a gap, a failure, a tooling thrash, a reviewer **BLOCK** (or a
repeated NEEDS_REVISION), or a **missing handler**, the agent does not merely route around it — it
**stops to capture and raise**, so the lesson lands once, upstream, for everyone:

1. **Capture at the gemba** — record what actually broke at the point it broke (the failing command,
   the absent capability, the contradicted contract), not a sanitised after-the-fact summary.
2. **Route by ownership** — if the gap is in **your own** element, fold it back and open a PR
   (`/<plugin>:self-improve`); if it belongs **elsewhere**, write it to the learning ledger
   (`.i2p/learnings.jsonl`) and raise a **consented** issue (auto-file same-repo; ask before a sibling
   repo).
3. **Close the loop** — an open learning is a re-entry signal: it surfaces for triage until a fix
   ships. A problem encountered and not captured is **rediscovery** waiting to happen.

The reflex is *always-on*: it fires without being asked, because the KAIZEN canon that names it is
injected into every session. The capture→route→raise machinery **will be** the GEMBA skill and the
issue-raiser (`raise-feedback.sh`), with the trigger points (incident action items, reviewer BLOCK,
the missing-handler gate) wired so the reflex cannot be silently skipped — delivered across epic #93's
Stream 4 (#18–#20, #22).

### Self-cleaving — when the defect is *breadth* (muri)

"Halve the distance" usually means going *deeper*. But sometimes the largest remaining defect is
**breadth** (*muri* — overburden): an element has grown to do **more than one thing**. The covenant's
answer is **self-cleaving** — the element *splits itself* into smaller, single-purpose elements that
each do one thing better, and rewrites itself accordingly. Cleaving is *how* you halve the distance
when the problem is scope, not depth.

> **IMPORTANT — THE ONLY WAY:** A self-cleave is still a covenant change — it is **proposed, reviewed,
> and merged**, never silently self-applied. The scope decides the destination:
>
> - **A marketplace element** (an agent, skill, command, or knowledge doc that ships in a DELIVER
>   plugin) cleaves on a **branch**, passes the always-on adversarial gate (`/deliver:pr-review`), and
>   is **raised as a PR** under the marketplace's merge governance (`protocols/merge-governance.md`) —
>   so **every user of the marketplace inherits the improvement** on merge. The `inspector` flags the
>   opportunities, and the `self-improve` skill is the driver of this loop.
> - **A project document** (a README, plan, spec in a user's project) cleaves **locally** — split the
>   section, leave a pointer, keep history — under this same covenant, no marketplace PR involved.

A cleave that loses information, breaks a downstream consumer, or trades one over-broad element for
two tangled ones has **not** honoured the covenant. Cleave along the seam of responsibility, not down
the middle of a sentence.

### Periodic self-review prompt

At natural checkpoints (end of a milestone, before a major refactor, after a
DELIVER cycle), ask your AI assistant:

> "Review this document against the KAIZEN covenant above. Are there sections
> that have drifted from their stated purpose? Is there muda (waste), mura
> (unevenness), or muri (overburden)? Propose a Version 2 of any section that
> needs improvement — small, measurable, standardised — and flag it for my review."

The assistant applies DELIVER's self-improvement protocol (the same discipline the
`inspector` agent runs against the system itself) and returns a proposed update for your
approval before any change is applied.

### Lineage

- **System:** DELIVER plugin — the value-flow production system
- **Covenant version:** 2.0 (kaizen: full reframe of the document principles around continuous improvement; supersedes the SOLID-of-documents framing of v1.x)
- **Canonical home:** `knowledge/architecture/kaizen-covenant.md` (in the DELIVER plugin)
- **See also (in the plugin):** `knowledge/architecture/solid.md` remains the SOLID *code-design* reference (this covenant governs continuous improvement of the document/marketplace ecosystem, not code structure); `knowledge/first-principles.md` (the philosophical spine); and the marketplace `knowledge/glossary.md`. (Bare paths, not links — this fragment travels into project files where relative links would not resolve.)

<!-- END KAIZEN REPLICATION FRAGMENT -->
---
