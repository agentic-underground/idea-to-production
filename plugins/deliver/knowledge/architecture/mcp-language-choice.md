# MCP language choice — don't compile a plugin's MCP server

> **Rule of thumb:** a Claude Code **plugin** MCP server should be written in an **interpreted**
> language (Ruby, Python, Node…), **not** a compiled one (Rust, Go, C++…). This is a post-mortem of the
> marketplace's own mistake — shipping `flow-mcp` as a compiled Rust binary — and the reasoning that
> overturned it. If you are scaffolding an MCP for a plugin and reach for a compiled language, read this
> first.
>
> **Historical note.** The `flow` plugin and its `flow-mcp` server (and all `plugins/flow/…` paths
> referenced below) have since been **fully retired** — the FLEET continuous-delivery engine superseded
> them. This document is kept as the language-choice post-mortem; its `flow-mcp` references are history,
> not live code.

## What we did, and why it failed

`flow-mcp` (the flow plugin's roadmap MCP) was first built as a **Rust binary**, distributed as a
per-platform **GitHub release**, pinned by tag (`bin/RELEASE`) and SHA256-verified against a committed
`bin/SHA256SUMS` by a launcher that downloaded and cached the right asset. It was careful, deterministic,
and **chronically broken**. The failure modes were structural, not incidental:

- **Release-sync friction.** Shipping a change meant a multi-step ceremony: bump the crate version, push
  a tag, let CI cross-compile five platforms, then *manually* copy the published checksums back into the
  repo and commit to "activate" the release. A bootstrap window existed on every cut where destinations
  without a toolchain could not run the server at all. Defect [92] shipped precisely because the source
  and the published binary could drift out of step.
- **Stale binary caches.** The launcher cached the verified binary per machine. A re-cut tag, a bumped
  pin, a half-finalized `SHA256SUMS` — each was a new way for a machine to run *yesterday's* bytes while
  the repo said otherwise. We added cache-key fingerprints and re-verification to fight it; the
  complexity itself became a liability.
- **Undead binaries.** Cached artifacts outlived the source that produced them, on machines no one was
  looking at, answering with old behaviour.
- **Zero visibility.** When a call misbehaved there was **nothing to see** — no stack trace, no readable
  log, no way to add a `print` and re-run. A compiled binary is opaque at exactly the moment you need it
  to be transparent.

## Why interpreted wins for a plugin MCP

- **No artifact-drift.** There is nothing to build, pin, checksum, download, or cache. The source *is*
  the program. The repo and what runs are the same thing, always.
- **Immediate fault-finding.** A bad call emits a real stack trace to stderr; you can add logging and
  re-run in seconds. Investigation is a session, not a release.
- **Trivial distribution.** The launcher finds the interpreter already on the host and execs the source.
  No CI release pipeline, no per-platform matrix, no signing dance.
- **Graceful absence.** If the interpreter is missing, you can fall back to a documented by-hand runbook
  (flow-mcp ships `/flow:flow-by-hand`) — impossible when the unit of distribution is an opaque binary.

The cost — a runtime interpreter dependency and somewhat slower execution — is **negligible** for a
plugin MCP, which is IO-bound (files, JSON-RPC over stdio) and never on a hot numerical path.

## What good looks like

- **Pick an interpreted language with a sane floor.** flow-mcp is **Ruby ≥ 3.3.8, standard library
  only** — zero gems at runtime, so there is no dependency resolution either. The Debian-13 fleet ships
  that Ruby as its system interpreter.
- **Pin the *behaviour*, not the binary.** Write the contract as an EARS spec + a Gherkin FEATURE suite
  (see [`../specs/ears.md`](../specs/ears.md), [`../specs/bdd-gherkin.md`](../specs/bdd-gherkin.md)). That
  is what survives an implementation change — and what lets you re-realise the server in another language
  later if you ever must. flow-mcp's is in `plugins/flow/flow-mcp/spec/`.
- **Launcher resolves the interpreter, not an artifact.** Find the interpreter (honour a `*_RUBY`-style
  override, then distro names, then version-manager shims), assert the floor, exec the source. No
  download ladder.
- **Tests run on the bare host interpreter.** No `gem install` / `bundle` / `pip install` required to
  test; use the bundled test framework + stdlib coverage.

## If you are about to choose Rust (or another compiled language) for a plugin MCP

**Don't** — unless you have a specific, measured reason the work is CPU-bound enough that an interpreter
cannot keep up, *and* you are prepared to own a release pipeline, a pinning/verification scheme, a cache
invalidation story, and the loss of call visibility. For the overwhelmingly common case (a tool surface
over stdio that reads/writes files and speaks JSON), an interpreted server is the correct, boring choice.
flow-mcp tried the compiled path so you don't have to.
