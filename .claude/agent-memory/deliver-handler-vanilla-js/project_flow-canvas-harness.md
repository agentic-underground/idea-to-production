---
name: flow-canvas-harness
description: The vanilla-JS SVG flow-canvas (mission-control roadmap #2) and its vitest harness under flow-server/static
metadata:
  type: project
---

The mission-control flow-canvas (roadmap #2) is the vanilla-JS frontend served by
the Rust flow-server (#1). It lives at `plugins/mission-control/flow-server/static/`.

Structure (ES modules, NO framework, NO build step):
- `src/layout.js` — PURE core: column assignment, dependency topo-order, autoAlign
  placement, bezierPath connector geometry, zoomAboutCursor transform. Highest-value
  coordinates; unit-tested directly.
- `src/model.js` — PURE core (roadmap #8): MODEL_ALLOWLIST (4 marketplace ids,
  frozen), shortModel/modelLabel, isAllowed(model, list), resolveModel(item) →
  `{model, default, isOverride}`. See [[flow-server-item-contract]] for the
  default-vs-override rule.
- `src/api.js` — token resolve/persist (localStorage key `flow.token`) + fetch wrappers
  (getItems, setGate, setModel, validateConnection, annotate, rewrite, getEvents).
- `src/progress.js` — PURE core (roadmap #6): doneFraction/donePercent/isComplete over
  items (status==="done"), sysMessages(events) → kind==="sys_msg" newest-first.
- `src/masthead.js` — DOM (roadmap #6): mountMasthead(root,{items,api}) → progressbar +
  pac-man gauge (role=img, data-percent) + role=log feed; degrades on getEvents error.
- `src/comment.js` — DOM (roadmap #4): mountCommentPanel(root,{item,api,onPaused,onDraft})
  — pause-on-first-keystroke (setGate wait), Ctrl-Enter → setGate go + annotate + clear,
  Rewrite button → rewrite → draft# from returned {draft}. Never mutates the item.
- `src/card.js` — one SVG rounded-rect card, badges, keyboard-operable WAIT/GO toggle,
  and a model-badge button (onPickModel intent; inert text when no handler wired).
- `src/canvas.js` — mounts boards/cards/connectors; wheel-zoom-about-cursor, pan,
  card drag, auto-align, gate toggle, model picker (accessible listbox popup over
  the canvas), tryConnect(from,to) (validates before commit).
- `app.js` / `index.html` / `app.css` — browser bootstrap (excluded from coverage;
  story-tested via Playwright) + dark-mode tokens.

**Why:** the governance/observability surface the human steers value through.
**How to apply:** test the canvas LOGIC against `test/fixtures.js` (no live server);
extract pure logic from the DOM so coverage hits the 100% line+branch floor. Coverage
config in `vitest.config.js` excludes only `src/app.js`.

Mandated run: `npm --prefix plugins/mission-control/flow-server/static test`
(or `cd static && npm i && npx vitest run`). 164 tests (110 from #2/#8 + 20 comment #4
+ 14 masthead #6 + 14 progress #6 + 6 added api), 100% across all metrics. app.js wires
the masthead (always) and a focused-card comment panel (on card focusin) — story-layer only.
`static/node_modules` + `static/coverage` are gitignored in the crate `.gitignore`.
See [[vitest-config-cwd]] and [[flow-server-item-contract]].
