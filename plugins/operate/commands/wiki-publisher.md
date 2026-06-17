---
description: Construct a professional GitHub wiki (opt-in) from PRESSROOM's per-item docs → publish to the origin's .wiki.git.
---

Run the **wiki-publisher** skill.

Target from `$ARGUMENTS` (default: current repo): a project path with a GitHub origin.

Detect whether `origin` is a `github.com` remote and read the one-shot opt-in gate with
`bash "${CLAUDE_PLUGIN_ROOT}/skills/wiki-publisher/scripts/wiki-state.sh" --dir "$PWD"`. If the origin is
**not** GitHub, or a per-repo `declined` / global `optout` marker already exists, **stay silent** (clean
no-op). Otherwise make a **single** opt-in offer — name the count of completed-item docs and ask whether to
construct/refresh a professional wiki.

On **decline**, record the marker under `~/.claude/hook-state` (never the repo) so it is not re-offered. On
**opt-in**, publish the per-item documentation child #12 (PRESSROOM) produced — the docs under
`doc/articles/` with their embedded illustrations — to the origin's companion `.wiki.git` via
`bash "${CLAUDE_PLUGIN_ROOT}/skills/wiki-publisher/scripts/publish-wiki.sh" --dir "$PWD"`: clone the wiki,
map each doc to a page (title from its H1), rewrite + copy embedded figures, generate `Home.md` + a sidebar,
and push.

Degrade gracefully: when `doc/articles/` is empty there is **nothing PRESSROOM produced to publish** — say
so and stop rather than fabricate pages; when `git`/`gh` is unavailable or the wiki has never been enabled,
report the missing prerequisite — never a false "wiki published". Return the origin, the wiki URL, and the
page count.
