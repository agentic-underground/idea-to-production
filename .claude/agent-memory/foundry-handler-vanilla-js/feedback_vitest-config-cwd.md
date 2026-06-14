---
name: vitest-config-cwd
description: vitest discovers its config from the process CWD, so prefer npm --prefix over npx --prefix --dir
metadata:
  type: feedback
---

Vitest resolves `vitest.config.js` relative to the process working directory, NOT
relative to a `--dir`/`--prefix` test path. Running
`npx --prefix <pkg> vitest run --dir <pkg>` from a repo root runs WITHOUT the
package's config — so the jsdom `environment` is never applied and every DOM test
fails with "document is not defined".

**Why:** burned on the flow-canvas mandate — `npx --prefix … vitest --dir` gave 51
spurious failures (environment loaded in ~1ms = no jsdom), while the identical suite
was green from inside `static/`.

**How to apply:** to run a sub-package's vitest from a repo root, use
`npm --prefix <pkg> test` (npm sets the package dir as CWD, so the config IS found)
or `cd <pkg> && npx vitest run`. Never rely on `npx --prefix … vitest --dir` for a
package that needs its own config (jsdom env, coverage thresholds).
