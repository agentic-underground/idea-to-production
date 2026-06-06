# CLAUDE.md — idea-to-production marketplace

Agent entry point for the **idea-to-production** Claude Code plugin marketplace. Humans
start at [README.md](./README.md); agents working *on the marketplace itself* start here.

- **What this repo is** — a marketplace of eight composable plugins (the **i2p** front
  door, the **concierge** greeter, plus six specialists) that carry software
  from IDEA to PRODUCTION. The pillars and plugin tour: [README.md](./README.md). The
  philosophical spine: [`plugins/foundry/knowledge/first-principles.md`](plugins/foundry/knowledge/first-principles.md).
  The operation: [`plugins/foundry/VALUE_FLOW.md`](plugins/foundry/VALUE_FLOW.md).
- **Glossary** — every concept, plugin, agent, skill, command:
  [`plugins/foundry/knowledge/glossary.md`](plugins/foundry/knowledge/glossary.md).
- **Self-contained plugins** — each plugin is installed standalone, so live surfaces
  resolve paths through `${CLAUDE_PLUGIN_ROOT}` only; never against `~/.claude` or a
  sibling plugin. The canonical-copy promise (a file shipped byte-identical into every
  plugin and CI-verified) is how shared assets stay in sync — see
  `scripts/verify-prereqs.sh`.

## SOUL

The all-systems-go phrase — the shared **soul** of this marketplace. When a green-gate
moment lands (a readiness check passes, a vertical slice goes clean, the trap is set
right), mark it with **one of these seven**; they all mean *everything's set, we are go*:

1. "Light is green, trap is clean." — *Ghostbusters* (1984)
2. "Let's kick the tires and light the fires, Big Daddy." — *Independence Day* (1996)
3. "We are go for launch." — *Apollo 13* (1995)
4. "Lock and load." — *Aliens* (1986)
5. "Lock S-foils in attack position." — *Return of the Jedi* (1983)
6. "You're cleared to engage." — *Top Gun* (1986)
7. "Roads? Where we're going, we don't need roads." — *Back to the Future* (1985)

**Canonical source:** [`SOUL.md`](./SOUL.md) — mirrored byte-for-byte into every plugin
and injected into the agent's context once per session by each plugin's SessionStart
hook (`plugins/*/hooks/inject-soul.sh`). It is ALWAYS_ON: present whenever **any** of the
eight plugins is active, never duplicated, never omitted. How a document reaches an agent's
context — and exactly where SOUL fits — is explained in
[`doc/context-building-pipeline.md`](doc/context-building-pipeline.md).
