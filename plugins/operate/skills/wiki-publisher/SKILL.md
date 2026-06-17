---
name: wiki-publisher
description: >
  Construct a professional GitHub wiki (opt-in) — for any GitHub origin, ask the operator ONCE whether
  to stand up a wiki, then publish the per-item documentation and illustrations PUBLISH already produced
  (doc/articles/) to the repo's companion `.wiki.git`. Trigger with /wiki-publisher (or "publish the wiki",
  "build the GitHub wiki", "put the docs on the wiki"). Detects a github.com origin, makes a one-shot
  opt-in offer (decline recorded under ~/.claude/hook-state, never the repo), and on opt-in clones the
  origin's `.wiki.git`, maps each completed-item doc to a wiki page (rewriting embedded illustration paths),
  and pushes. Consumes PUBLISH's artifacts — it never re-runs the doc/illustration pipeline. Degrades
  gracefully: a clean no-op when the origin is not GitHub, when `gh`/`git` is unavailable, or when there
  is no PUBLISH output to publish — never failing the session, never inventing content.
metadata:
  type: publisher
  lens: documentation-distribution
  output: pushed wiki pages on the origin's .wiki.git (+ a short publish report)
  model: inherit
---

# WIKI-PUBLISHER

A live product earns a **professional wiki** — the readable, browsable face of the per-item documentation
that PUBLISH (child #12) already wrote. This skill is the **opt-in distributor**: it does not write docs,
it **publishes** the ones that exist to the repo's companion `.wiki.git`. Grounded in the OPERATE
discipline — distribution is hygiene, and it is the operator's choice, recorded once.

This skill is strictly a **consumer** of artifacts. It re-runs nothing, invents nothing, and writes the
**wiki**, not the user's repo (its only repo-local touch is reading `doc/articles/` and stat-reading state).

## When it runs — github origin + one-shot opt-in

The wiki is **opt-in**, offered **at most once per repo**, mirroring i2p's one-shot welcome offer
([`../../../i2p/hooks/offer-welcome.sh`](../../../i2p/hooks/offer-welcome.sh)): opt-out state
lives under `~/.claude/hook-state/`, **never** in the repo. The flow:

1. **Detect a GitHub origin.** Read `git remote get-url origin`; proceed only when the host is `github.com`
   (SSH `git@github.com:owner/repo.git` or HTTPS `https://github.com/owner/repo.git`). Any other host →
   **clean no-op** (the wiki target is GitHub-specific).
2. **Check the one-shot gate.** If a per-repo `declined` or a global `optout` marker exists, **stay silent**.
3. **Offer (once).** Ask the operator: *"This repo is on GitHub and has N completed-item docs — want me to
   construct/refresh a professional wiki from them?"* — a single offer, not a nag.
4. **On decline** → record the marker (see below) so it is never re-offered here.
5. **On opt-in** → publish (below).

Run the detection + gate read with the helper:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/wiki-publisher/scripts/wiki-state.sh" --dir "$PWD"
```

It prints a single status line — `github=<owner/repo|no> declined=<0|1> optout=<0|1> docs=<count>` — and the
exact marker paths to write on a decline. It **never** writes the repo and **never** writes state itself
(the agent writes the marker on the operator's say-so, exactly as i2p does):

```bash
# operator declines for THIS repo (never re-offer here):
mkdir -p "$HOME/.claude/hook-state/operate-wiki-declined/<repo-key>"
# operator declines EVERYWHERE (never offer in any repo):
mkdir -p "$HOME/.claude/hook-state/operate-wiki-optout"
```

The script emits the resolved `<repo-key>` so the marker path is unambiguous. Only ever write under
`~/.claude/hook-state` — never into the user's repository.

## What gets published — PUBLISH's per-item docs

The wiki **content source** is the documentation child #12 produces — the per-completed-item documents
written by PUBLISH's [WRITER](../../../publish/skills/writer/SKILL.md) (under `doc/articles/`, one
adaptive doc per item with how-to / UI / architecture sections as earned) with the figures
[ILLUSTRATOR](../../../publish/skills/illustrator/SKILL.md) embedded (SVG/PNG, typically beside the doc).
WIKI-PUBLISHER consumes these as-is:

| Repo artifact (from #12) | Wiki page |
|---|---|
| `doc/articles/<slug>.md` (or `doc/articles/<date>/<slug>.md`) | `<Title>.md` (title from the doc's H1) |
| embedded `![alt](diagrams/…svg\|png)` illustrations | copied alongside the page; the link is rewritten to the wiki-relative path |
| the set of all per-item docs | a generated `Home.md` index + a `_Sidebar.md` linking every page |

**Degrade gracefully when PUBLISH is absent.** If `doc/articles/` does not exist or is empty, there is
nothing #12 produced to publish: **do not fabricate pages** — report *"no PUBLISH output to publish; run
PUBLISH's `/publish` per completed item first"* and stop. If `doc/articles/` exists but holds free-form
articles rather than per-item docs, publish what is there and say so — never block on the distinction.

## Publishing to `.wiki.git`

GitHub exposes a repo's wiki as a sibling git repository: `<origin>.wiki.git` (e.g.
`https://github.com/owner/repo.wiki.git`). The publish, performed by the helper:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/wiki-publisher/scripts/publish-wiki.sh" --dir "$PWD"
```

does — idempotently, in a scratch clone under the system temp dir (never touching the user's repo):

1. **Derive** the wiki URL from `origin`; **prefer `gh`** for auth (`gh auth token`) when available, falling
   back to the ambient git credential helper.
2. **Clone** `<origin>.wiki.git` (a fresh wiki repo may be empty — handle the first-push case).
3. **Map** each `doc/articles/**.md` to a wiki page: title from the H1, body copied; **rewrite** each
   embedded illustration link to a wiki-relative path and copy the asset in beside the page.
4. **Generate** `Home.md` (an index of all items) and `_Sidebar.md` (navigation).
5. **Commit** with a clear message and **push** to the wiki's default branch (`master` on legacy wikis,
   else `main` — detected). On a push failure (wiki not yet enabled on the repo, auth missing) it **reports
   the cause and stops** — it never silently swallows the failure.

The helper is **read-only against the user's repo** and writes only the scratch wiki clone. If `git` is
absent, or the wiki has never been enabled on GitHub (`.wiki.git` clone is refused), it degrades to a clear
message naming the missing prerequisite — never a false success.

## Degraded capabilities (point-of-use)

When a tool needed here is **absent at point-of-use**, follow the degraded-capabilities discipline defined
once in [`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §5: **emit** a
`{capability, reason, since_phase}` record (e.g.
`{"capability":"wiki.publish","reason":"gh/git unavailable","since_phase":"OPERATE"}`), **route around** it
(skip publishing, leave the docs in-repo), and **disclose** the no-op as *partial* — never a false "wiki
published".

## Output

A short publish report: the origin, the wiki URL, the count of pages published (and skipped, with reason),
and the next step (the operator can browse `https://github.com/owner/repo/wiki`). On a no-op (non-GitHub,
declined, no PUBLISH output, or a missing tool), the report names exactly which precondition was unmet —
so the no-op is legible, not silent.

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). Every publish failure that surprised
us (a wiki not yet enabled, an illustration link that did not rewrite, a title collision) is the signal:
fold the handling in **once, upstream** — so the next publish is cleaner, quieter, and more complete by
default.
