---
id: 35
title: "GitHub MCP setup prompt — yes / no / dontask installer for marketplace clients"
status: PENDING
priority: MEDIUM
added: 2026-06-14
depends_on: "—"
---

# [35] GitHub MCP setup prompt — yes / no / dontask installer for marketplace clients

**Brief Description**
When a developer installs the idea-to-production marketplace on a new machine and opens their
first session, the harness should ask once: "Set up GitHub MCP server now? [yes/no/dontask]".
`yes` runs a bundled shell script that checks Docker availability, collects a GitHub PAT (or
reuses `GH_TOKEN`), writes the `github` entry into `~/.claude/.mcp.json`, and confirms the
result. `no` skips this session. `dontask` persists a flag file so the prompt never appears
again. The script is idempotent — if the `github` entry already exists in `.mcp.json` it
does nothing and skips the prompt entirely.

### User Stories
- AS A marketplace developer installing idea-to-production for the first time I WANT a guided
  one-step prompt to wire up the GitHub MCP server SO THAT I can use GitHub-aware agents
  without having to find and edit config files manually.
- AS A developer who knows I don't want the GitHub MCP SO THAT I am never asked again I
  WANT to answer "dontask" once SO THAT the prompt disappears permanently.
- AS A developer whose machine lacks Docker SO THAT I still get a clear path I WANT the
  script to detect the missing dependency and offer an npx-based fallback or a plain
  explanation of what to install.

### EARS Specification

**Event-driven requirements:**
- WHEN a new i2p session starts AND `~/.claude/.mcp.json` does NOT already contain a `github`
  MCP entry AND the `dontask` flag file is absent THE SYSTEM SHALL invoke the GitHub MCP
  setup prompt (`scripts/setup-github-mcp.sh --prompt`).
- WHEN the user answers `yes` THE SYSTEM SHALL run the installer: detect Docker, collect or
  reuse a GitHub PAT, write the `github` entry to `~/.claude/.mcp.json`, and print a
  confirmation message.
- WHEN the user answers `no` THE SYSTEM SHALL exit the prompt without modifying any file and
  continue the session.
- WHEN the user answers `dontask` THE SYSTEM SHALL write
  `~/.claude/hook-state/github-mcp-dontask` and exit the prompt without modifying `.mcp.json`.

**Unwanted behaviour requirements:**
- IF `~/.claude/.mcp.json` already contains a valid `github` MCP entry THEN THE SYSTEM SHALL
  NOT display the prompt and SHALL return exit code 0 immediately (idempotent).
- IF Docker is absent AND npx is absent THEN THE SYSTEM SHALL print an installation guide
  for both and exit without modifying any file (detect-and-guide, not halt).
- IF the provided GitHub PAT is empty or contains only whitespace THEN THE SYSTEM SHALL
  reject it and re-prompt (or abort on second failure).

**State-driven requirements:**
- WHILE `~/.claude/hook-state/github-mcp-dontask` exists THE SYSTEM SHALL NOT invoke the
  setup prompt in any subsequent session.

**Optional feature requirements:**
- WHERE `GH_TOKEN` is already set in the environment THE SYSTEM SHALL offer to reuse it as
  the PAT rather than prompting for a new one.

### Acceptance Criteria
1. On a clean install with no `.mcp.json` and no dontask flag, opening a session triggers
   the prompt.
2. Answering `yes` with a valid PAT and Docker available: `.mcp.json` is created/updated
   with the correct `github` entry; next session start skips the prompt.
3. Answering `no`: no files are modified; next session start prompts again.
4. Answering `dontask`: `~/.claude/hook-state/github-mcp-dontask` is created; next session
   start does NOT prompt.
5. Running the script a second time when `.mcp.json` already has the `github` entry: exits 0
   silently with no changes to any file.
6. Docker absent, npx absent: a human-readable guide is printed; no files are modified; exit
   code 0 (non-blocking).
7. `GH_TOKEN` present in env: the script offers to reuse it; the user can accept or provide
   a different token.

### Implementation Notes
- **Script location:** `scripts/setup-github-mcp.sh` (marketplace root, not plugin-specific).
- **Harness hook:** SessionStart hook in the `i2p` front-door plugin
  (`plugins/i2p/hooks/setup-github-mcp-prompt.sh`) that delegates to the script when
  conditions are met (no existing entry, no dontask flag).
- **`.mcp.json` target:** `~/.claude/.mcp.json` (discovered in prior session — this is where
  Claude Code loads MCP server configs at startup).
- **Docker image:** `ghcr.io/github/github-mcp-server` — already verified working in this
  repo's local config.
- **npx alternative:** `npx @modelcontextprotocol/server-github` (fallback when Docker absent).
- **State file:** `~/.claude/hook-state/github-mcp-dontask` (follows existing hook-state
  convention used by the concierge welcome-declined flag).
- **JSON merge:** The script must merge into an existing `.mcp.json` if present (not
  overwrite), preserving other MCP server entries (e.g., existing ansible, playwright, etc.).
- **No i2p plugin internal paths:** the harness hook must not assume other plugins are
  installed; it reads only the state file and `~/.claude/.mcp.json`.

### Human Interface Test Plan
- [setup-github-mcp.sh --prompt, yes path]: invoke script → verify prompt appears with
  yes/no/dontask options → answer yes → provide PAT → verify `.mcp.json` gains `github`
  entry → re-run script → verify it exits silently (idempotent)
- [dontask path]: invoke script → answer dontask → verify
  `~/.claude/hook-state/github-mcp-dontask` created → re-invoke script → verify no prompt
- [Docker-absent path]: unset Docker, invoke script → verify diagnostic guide printed → verify
  no files modified

### Development Plan Reference
`doc/GITHUB_MCP_SETUP_PLAN.md`
