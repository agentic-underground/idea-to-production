# doc/historical — maintainer-facing archive

This folder is **not part of any marketplace plugin**. It is repo-level material for
**source-maintainers** working on the `idea-to-production` marketplace — inspection reports,
historical notes, and other artefacts that should be visible while developing the repo but are not
shipped to or read by the installed plugins at runtime.

> **On `~/.claude`.** Some material here (and in `plugins/*/docs/HISTORY.md|MIGRATION.md|DEPRECATED.md`
> and `plugins/foundry/examples/`) references a `~/.claude` config-repo origin. That environment is
> **no longer a concern of the marketplace plugins** — the plugins are **self-improving** and run
> wherever they are installed (`${CLAUDE_PLUGIN_ROOT}` / the invoked project), never against a
> user's home config. `~/.claude` appears **only** in historical/provenance material, as record, not
> as runtime coupling. No live plugin surface references it.

## Contents

| File | What it is |
|---|---|
| `FOUNDRY_INSPECTION_REPORT-YYYY-MM-DD.md` | A dated snapshot from `/foundry:inspect` — the inspector's severity-ranked audit of the plugins at that point in time. Superseded by later runs; kept as the audit trail. |
