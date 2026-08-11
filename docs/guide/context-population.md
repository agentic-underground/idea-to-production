# RFC — phase-scoped context population (a thin pointer, not an always-on dump)

*Maintainer-facing design.* This is the **knowledge-layer sequel** to the context-routing RFC
([`context-routing.md`](./context-routing.md), which made the *skill catalog* lean and phase-routed).
It builds directly on the doors-and-caching doctrine in
[`context-building-pipeline.md`](./context-building-pipeline.md). EPIC 0067 implements it.

## 1. The problem

Enabling all eight plugins weaves a growing **phase-independent core** into *every* SessionStart, in
*every* repo the marketplace is installed in — measured today at **~580 words** through the model-context
(`additionalContext`) door: KAIZEN (350w, all eight plugins, deduped once/session) + the i2p
`roadmap-routing` rule (192w) + `session-intro`'s context block (39w); a hook's user-visible
`systemMessage` is not model context and is not counted. Plus conditionals that stay silent unless their
trigger file exists. Two of those (`roadmap-routing`,
`session-intro`) are **ungated and un-deduped** — they re-emit in full on every SessionStart event.

Crucially, the **FOCUS layer routes *skills*, not *knowledge*.** `.i2p/focus` steers which skills are
dormant, but it does **not** gate or shrink what context is injected — so a `DELIVER`-focused session
still carries the same phase-independent core, including material only `DISCOVER`/`IDEATE` needs.

## 2. Why this matters (it is not mainly tokens)

Per the doctrine, a *small + static* document in the cached prefix is a **one-time token cost**, not a
per-turn burn. So the goal here is **not** saving tokens — caching mostly handles that. It is the three
things caching does *not* fix:

- **Attention** — even cached, out-of-phase rules are noise the model reasons around.
- **Growth** — the always-on set only ratchets up as the workflow grows.
- **Integration hygiene** — every host harness we are installed in inherits our full always-on core.

## 3. The model

Match each document to the right **door** (per the doctrine's four): the plugin-native **always-on door
is the SessionStart hook**; large situational knowledge belongs to the **skills door** (progressive
disclosure — the body loads only on invocation). The rule of this RFC:

> **Through the always-on door, put only KAIZEN + a thin phase pointer. Everything else loads through
> the skills/knowledge door, strictly gated to the active phase.**

### 3.1 The always-on footprint + its budget

The phase-independent SessionStart injection is exactly two things:

1. **KAIZEN** — the lean canon, `[cross-cut]`, unchanged (small, static, cached; its purpose *is*
   always-awareness — muda/mura/muri apply in every phase). The **one** deliberate always-on.
2. **The pointer** (§3.2) — a thin, phase-aware announcement.

**Budget:** the phase-independent injection SHALL stay **≤ ~420 words** (KAIZEN ~350 + a pointer of
**≤ 60 words**). A leanness gate (PLAN 0067.004) enforces it, so a future well-meaning addition cannot
silently re-inflate every host harness. `roadmap-routing` and `session-intro` **leave** the always-on
core (§4).

### 3.2 The pointer contract

The pointer is a single short block emitted at SessionStart. It names:

- **that i2p is active** and the **active phase** (from §3.5);
- **what is loadable for that phase** — the phase's skills (already `metadata.phase`-tagged) and the
  phase's knowledge modules (§3.4), *named, not inlined*;
- **how to act** — set/clear focus (`/i2p:focus`), and that out-of-phase material stays dormant.

It is ≤ 60 words, static in shape (cache-friendly), and **inlines no knowledge**. Example:

> *i2p active · phase = **BUILD**. Loadable for BUILD: `deliver:vertical-slice`, `deliver:frontend`,
> the test-first + architecture knowledge. Other phases are dormant — `/i2p:focus <phase>` to switch,
> `/i2p:help` to browse.*

### 3.3 Strict single-phase loading

Reuse the **existing `metadata.phase: [...]`** model (no new phase scheme). For active phase **X**:

- A module/skill is **eligible** iff its `metadata.phase` list **contains X**, or is `[cross-cut]`.
- **No group-warming.** A module needed across a loop is tagged with each phase it serves (e.g.
  `[ASSURE, SECURE]`) — it then loads under both, but the loop is not warmed wholesale.
- **KAIZEN is the sole always-ON** exception (§3.1).
- This is *strict single-phase* — the tightest option, chosen deliberately: switching `/i2p:focus`
  BUILD→ASSURE re-scopes what is loadable, rather than carrying both.

### 3.4 Knowledge-phase resolution

The 89 `plugins/*/knowledge/*.md` modules are **already lazy** (a skill/agent reads them on invocation —
the skills door). This RFC gives them a *phase* so the pointer can name the right ones:

- **Own tag** — a knowledge module MAY carry `metadata.phase` (authoritative).
- **Inherited (default)** — otherwise its phase is the **union of phases of the skills/agents that
  reference it**. (So we do *not* hand-tag 89 docs; a `deliver:code-quality`-referenced doc inherits
  `[ASSURE]`.) Two determinacy rules: a **`[cross-cut]` referrer makes the doc `[cross-cut]`** (always
  eligible — correct, since such docs, e.g. the glossary or the covenant, are genuinely phase-agnostic);
  and **doc→doc references do *not* propagate phase** — only skill/agent referrers count, so a doc
  reached only from another doc falls to the orphan rule below and is flagged for a deliberate own-tag.
- **Orphan** — a module that is untagged **and** referenced by no skill/agent resolves to no phase; the
  gate (0067.004) **flags** it, so it is tagged deliberately rather than treated as silently global.

### 3.5 The active-phase signal (and the safe default)

The active phase is read from state the marketplace already maintains — no new files:

- **`.i2p/focus`** (FOCUS) is primary; **`.i2p/lifecycle.json`** is the fallback.
- **Unknown phase** (neither present) → **safe default**: the pointer still emits (i2p active + how to
  set focus + `/i2p:help`), but **nothing phase-specific auto-loads**. Under-loading is safe (the agent
  can load on demand); over-loading is the harm we are removing.

## 4. What changes (the EPIC 0067 slices)

- **0067.001 (this RFC)** — the model + budget. No behaviour change.
- **0067.002** — the injector: shrink the i2p SessionStart always-on to **KAIZEN + the pointer**; demote
  `roadmap-routing` (loads only in a roadmap-relevant phase / on trigger); and **absorb `session-intro`
  into the pointer** — its "i2p is active · `/i2p:help` to browse" role is already the pointer's job
  (§3.2), so the ≤60-word pointer *replaces* the ~40-word intro (a net reduction). After 0067.002 the
  phase-independent injection is **exactly the two things** of §3.1 — nothing else survives always-on.
- **0067.003** — knowledge-phase resolution (§3.4) feeding the pointer.
- **0067.004** — the leanness gate `scripts/verify-context.sh`: enforce the §3.1 budget + phase-tag
  coverage, wired into `.pipeline/verify` (the context analog of the routing suite's R6).

## 5. Integration safety & non-goals

- **Nothing is written to `~/.claude/CLAUDE.md` or any global config** — audited, and this RFC keeps the
  always-on door (SessionStart) to a *bounded pointer* so it stays that way as we integrate elsewhere.
- **Reliability is preserved** — the pointer makes every active-phase module discoverable and loadable
  on demand; strict single-phase *under*-loads (safe), never starves (the agent loads what it names).
- **Relationship to context-routing** — that RFC governs *which skill activates* (routing); this one
  governs *what knowledge is even eligible to load* (population). Same `metadata.phase` spine; FOCUS is
  the shared active-phase signal. This RFC does not change skill routing or the C1–C5 checks.
- **Not a permission system** — like FOCUS, this is best-effort context hygiene; the deterministic
  guarantee is the budget gate on the always-on footprint, not a block on reading an out-of-phase file.
