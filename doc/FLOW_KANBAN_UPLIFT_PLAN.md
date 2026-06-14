# FLOW KANBAN UPLIFT PLAN — Epic [27]
## Items [28] [29] [30] [31]
### Date: 2026-06-14 | Branch: feature/epic-27-kanban-uplift

---

## 1. SUBJECT MATTER UNDERSTANDING

### 1.1 System state at cycle start

The flow-server is a Rust (axum + tokio) binary serving:

- A REST API at `/api/items` (GET list, GET single) and a set of POST verbs
  (`/gate`, `/status`, `/spend`, `/model`, `/annotate`, `/rewrite`)
- A WebSocket endpoint at `/ws?token=` that fans out every domain `Event` as
  a JSONL text frame to every connected client
- A static-file fallback serving the Vanilla JS single-page app from
  `static/` via `ServeDir`

The frontend is a Vanilla JS SVG canvas (`canvas.js`) mounted from `app.js`.
It renders DO/DOING/DONE columns as SVG `<rect>` backgrounds, items as SVG
card groups, and dependency edges as Bézier `<path>` connectors. The vitest
suite has 164 passing tests at 100% coverage (all four thresholds).

### 1.2 What each key file does

| File | Role |
|---|---|
| `src/api.rs` | Axum router + all HTTP handlers. `item_json()` is the canonical item shape returned by every REST/MCP endpoint. |
| `src/domain/model.rs` | Pure domain: `Item`, `Status`, `WaitGate`, `Edge`, `Flow`. No IO. Item fields: `id, title, status, gate, tokens, model, draft, synthesized`. |
| `src/domain/event.rs` | Event enum (JSONL + WS frame format). 10 variants tagged with `"kind"`. `StatusPosted {id, status}` is the variant the canvas must react to for [29]. |
| `src/store.rs` | Single serialized writer. `post_status` → broadcasts `StatusPosted`. `annotate` → appends to plan doc + broadcasts `Annotated`. |
| `src/ws.rs` | WS upgrade + delta fan-out loop. Endpoint: `GET /ws?token=<token>`. Each event is serialized via `event.to_jsonl()` and sent as a text frame. |
| `src/main.rs` | Binary entrypoint. Wires config, store, router. No broadcast channel exposure at this level — the store owns the `broadcast::Sender`. |
| `static/src/canvas.js` | Mounts the SVG canvas. Owns: pan/zoom, card drag (repositions within canvas), WAIT/GO toggle, model picker, connection validation, `refresh()`. Currently has **no WS subscription** and **no column-drop status logic**. |
| `static/src/card.js` | Pure render function: `renderCard(item, pos, handlers)` → SVG `<g>`. Badge row has tokens, status, draft, model. No REDO badge yet. |
| `static/src/api.js` | `createApi(token)` → thin fetch wrappers. Methods: `getItems, setGate, setModel, validateConnection, annotate, rewrite, getEvents`. No `postStatus` yet. |
| `static/src/layout.js` | Pure geometry: `COLUMNS`, `COL_X`, `autoAlign`, `columnForStatus`, `bezierPath`, `zoomAboutCursor`. The column detection function `columnForStatus(status)` maps `do/doing/done` to column names. `COL_X = {done:40, doing:400, do:760}` (derived from `CARD_W=240, COL_GAP=120`). |
| `static/app.css` | Design tokens. `--redo: #fb6a5e` and `--redo-glow` already defined. No `.redo-badge` CSS rule yet. |

### 1.3 The data gap — what `item_json` is missing

Current `item_json` in `api.rs` (line 296–305) returns only:
```
{ id, title, status, gate, tokens, model }
```

For the RHS detail panel ([28]) the frontend needs:

| Field | Source | Available? |
|---|---|---|
| `pr_title` | Not on `Item` struct — not stored anywhere in the domain | **MISSING** |
| `pr_body` | Not on `Item` struct | **MISSING** |
| `pr_labels` | Not on `Item` struct | **MISSING** |
| `pr_assignees` | Not on `Item` struct | **MISSING** |
| `issue_text` | Reconstructable from `Annotated` events in the JSONL log | **Available via events API** |
| `nested_items` (deps) | `Flow::edges()` — available in the store snapshot | **Available but not exposed** |
| `commits` | No domain model for commits. Not stored as events. Not in `Item` struct. | **MISSING** |
| `draft` | On `Item` struct, already on the live working copy | **Available** (already in items returned by `refresh()`) |

**Critical finding:** PR fields (`pr_title, pr_body, pr_labels, pr_assignees`) and commits have **no backing storage** in the current domain model or event log. They are not persisted anywhere. This is a fundamental data-availability constraint.

**Resolution strategy for [28]:** The plan must scope the RHS panel to data that actually exists:

1. **`deps` (nested items)**: Expose via `item_json` by querying `flow.edges()` filtered by `from == item.id`, collecting `to` ids as the item's dependency list. This is available now.
2. **`issue_text`**: Reconstruct from `Annotated` events filtered to the item's id. Available via `GET /api/events?kind=annotated`. The panel reads the text field of the most recent `Annotated` event for the item.
3. **PR fields**: Not available. The panel for EPIC items shows a "PR not linked" placeholder. Future work (a separate PR-linkage item) would add these fields to the domain model.
4. **Commits**: Not available as a domain entity. The panel for ITEM commit-graph ([31]) shows commits from `Annotated` events whose text matches a commit-hash pattern, OR adds a dedicated `commits` field to `item_json` backed by a new minimal data structure in the `Item` domain. Since [31] is the lower-priority dependent of [28], the plan adds a `commits` array field to `item_json` that returns an empty array now and is populated by a future ingest step. This keeps the API shape stable.

**Decision: extend `item_json` with available fields now; stub missing ones with empty/null.**

The extended `item_json` shape:
```json
{
  "id": "...",
  "title": "...",
  "status": "...",
  "gate": "...",
  "tokens": 0,
  "model": "...",
  "draft": 0,
  "deps": ["dep-id-1", "dep-id-2"],
  "annotations": ["latest annotation text"],
  "commits": [],
  "pr": null
}
```

`deps`: ids where `edge.from == item.id` (items this item depends on — matches the existing `deps` field the frontend canvas already uses from its working copy).
`annotations`: array of annotation text strings from `Annotated` events for this item, newest-last.
`commits`: empty array `[]` for now (populated by future PR-linkage work).
`pr`: `null` for now.

### 1.4 WS message format

Every event broadcast by the store is serialized via `event.to_jsonl()` — the same serde-tagged JSONL format as the log. A WS frame for a status change looks like:

```json
{"kind":"status_posted","id":"svg-flow-canvas","status":"doing"}
```

The `"kind"` field uses `snake_case` (serde `rename_all = "snake_case"`). The canvas must switch on `kind` to decide how to handle each frame.

The WS URL is constructed as `ws://<host>/ws?token=<token>`. Because this is a browser WS upgrade, the token is passed as a query parameter (the browser cannot set `Authorization` headers on `WebSocket`). The `ws.rs` handler reads `?token` and validates it against the stored `Token` before upgrading.

### 1.5 Column detection in the SVG coordinate system

`layout.js` exports:
- `COL_X = { done: 40, doing: 400, do: 760 }` (world units)
- `CARD_W = 240`, `COL_GAP = 120`
- `columnForStatus(status)` — maps server status string to column name

Column boundaries (world units, for drop detection):
- DONE: x ∈ [COL_X.done - 16, COL_X.done + CARD_W + 16] = [24, 296]
- DOING: x ∈ [384, 656]
- DO: x ∈ [744, 1016]

The column a dropped card belongs to is determined by the card's world-coordinate `x` position at pointer-up. The world position is computed by inverting the canvas pan/zoom transform: `worldX = (clientX - svgRect.left - transform.x) / transform.scale`. The nearest column is found by comparing `worldX` to each `COL_X[col] + CARD_W/2`.

The existing card drag handler in `wireCardDrag` (`canvas.js` lines 267–291) handles `pointerdown/pointermove/pointerup`. It repositions the card freely within the canvas. The drop handler at `pointerup` is currently a no-op (just removes listeners). The drag-to-column feature ([29]) extends `onUp` to:
1. Compute world X of the dropped card
2. Find the nearest column
3. If column differs from the card's current status column, call `api.postStatus(id, newStatus)`
4. Show a drop-zone glow on the target column during drag (via CSS class on the column `<g>` element)

---

## 2. ARCHITECTURE DECISIONS

### [28] RHS Detail Panel

**Decision:** HTML `<aside>` overlay beside the SVG canvas, not an SVG group.

Rationale: The panel contains scrollable text content (PR body, issue text, commit messages). SVG `<foreignObject>` is notoriously unreliable for scrollable text across browsers. An HTML `<aside>` with `overflow-y: auto` is correct here. The panel is positioned absolutely to the right of the canvas with CSS `width: 35%; right: 0; top: 0; bottom: 0`.

**New file:** `static/src/detail.js` — exports `mountDetailPanel(root, { api })` returning `{ show(item, allItems), hide() }`. This is the shared infrastructure that [31] (commit-graph) consumes.

**No new Rust files.** Only `api.rs` is extended (the `item_json` function).

**No new Rust routes.** The existing `GET /api/items/:id` route returns the extended shape. The frontend calls `api.getItems()` on refresh and already has the full item set; the detail panel reads from the in-memory item list (no extra round-trip for the panel open).

### [29] Drag-between-columns + WS live-update

**Decision:** Extend `canvas.js` in place. No new file for drag logic.

Rationale: The drag handler is already embedded in `wireCardDrag`. Adding column-drop detection and the WS subscription to the same closure keeps the module coherent. Splitting drag into a new file would require sharing `transform`, `positions`, and `items` state, adding complexity with no reuse benefit.

**New API method:** `postStatus(id, status)` added to `api.js`. This is the shared infrastructure consumed by both [29] and [30] (REDO modal also calls `postStatus` after comment entry).

**WS connection:** Mounted in `mountCanvas` before the initial `refresh()`. The `WebSocket` is constructed with `ws://<host>/ws?token=<token>` (or `wss://` when `location.protocol === 'https:'`). The WS URL derivation uses `location.host` + the token passed into `mountCanvas`.

**Drop-zone glow:** A CSS class `board--drop-active` added to the target column `<g>` during drag-over. The class is added on `pointermove` when `sourceCol !== targetCol` and removed on `pointerup`. CSS rule in `app.css` applies a border/glow to `.board--drop-active .board-bg`.

### [30] REDO badge + required-comment modal

**Decision:** Modal as an HTML `<dialog>` element overlay; the REDO badge as a new SVG badge added by `renderCard`.

Rationale: `<dialog>` with `showModal()` gives native focus trapping and backdrop at no cost. It pairs cleanly with the existing HTML overlay pattern established by the comment panel and model listbox.

**The REDO badge** is added in `card.js` as a new badge rendered when `item.redo === true`. The badge uses the existing `--redo` CSS token. It occupies the top-right of the card (x=180, y=16 in card-local coordinates).

**Shared infrastructure from [29]:** `api.postStatus` is already available. The modal calls `api.annotate(id, comment)` (already in `api.js`) then `api.postStatus(id, targetStatus)`.

**No new Rust changes** for [30].

### [31] Commit-graph view

**Decision:** SVG `<g>` rendered inside the `detail.js` panel's bottom section, not a separate canvas.

Rationale: Inline SVG within the HTML panel allows the dot-and-line graph to be rendered with SVG precision while the surrounding text (commit messages) remains HTML for scrollability. The graph is a simple vertical timeline: dots connected by a line, each dot clickable to expand the message below it.

**Consumes [28]'s `detail.js`:** The `show(item)` function in `detail.js` is extended to render a commit-graph SVG in the bottom section when the item has commits. [31] is purely an extension of [28]'s panel — no new files beyond what [28] creates.

---

## 3. SHARED INFRASTRUCTURE MAP

| Component | Needed by | Build in | Notes |
|---|---|---|---|
| Extended `item_json` (deps, annotations, commits, pr fields) | [28], [29] (for WS reconcile), [30] (for redo state), [31] | [28] | Rust change in `api.rs`. All downstream items benefit immediately. |
| `api.postStatus(id, status)` | [29], [30] | [29] | New method in `api.js`. [30] depends on [29] being complete, so it can rely on this. |
| `static/src/detail.js` — `mountDetailPanel` | [28], [31] | [28] | The panel module. [31] extends `show()` with the commit-graph SVG renderer. |
| Fixture extension for `deps/annotations/commits` | [28], [29], [30], [31] test suites | [28] | `test/fixtures.js` gains richer item shapes. |
| Drop-zone glow CSS (`.board--drop-active`) | [29], [30] (visual feedback during redo drag) | [29] | One CSS rule in `app.css`. |
| REDO badge CSS (`.redo-badge`) | [30] | [30] | `app.css` — uses existing `--redo` token. |
| `<dialog>` modal CSS | [30] | [30] | New CSS block in `app.css`. |

Token cost of building once vs. N times:
- `item_json` extension: ~4k tokens once vs. ~16k if each item rediscovered/re-extended it
- `detail.js`: ~6k tokens once vs. ~12k if [31] had to build its own panel from scratch
- `api.postStatus`: ~1k tokens once vs. ~2k if [30] independently added the same method

---

## 4. WORK DECOMPOSITION

### Item [28] — RHS Detail Panel

**Tier:** PRIMARY
**Priority status:** MEDIUM
**Token budget estimate:** ~28k tokens
**Estimation basis:** Heuristic — new HTML module + Rust extension + vitest coverage, comparable complexity to the comment panel (roadmap #4, ~22k) with additional Rust work
**Depends on:** none (atomic)
**Parallel-safe with:** [29]

**Step 0 — EARS statements**
Write EARS acceptance statements covering:
- WHEN a user clicks an EPIC card, the RHS panel SHALL display pr_title, pr_body, pr_labels (as chips), pr_assignees (as chips) in the top section and the deps list (with count) in the bottom section.
- WHEN a user clicks an ITEM card, the RHS panel SHALL display the item's annotations (latest first) in the top section and the item's commits list in the bottom section.
- WHERE the top or bottom section content overflows, EACH section SHALL independently scroll.
- WHEN the panel has no active selection, it SHALL be hidden.
- WHEN the server returns no annotations for an item, the top section SHALL display "No issue text recorded."
- WHEN the server returns no commits for an item, the bottom section SHALL display "No commits yet."
- WHEN `item_json` is called, the response SHALL include `deps` (array of ids), `annotations` (array of strings), `commits` (array), and `pr` (null or object).

**Step 1 — Gherkin scenarios**
File: `test/features/rhs-detail-panel.feature`
Scenarios:
- EPIC card click shows PR placeholder and deps list
- ITEM card click shows latest annotation and empty commits placeholder
- Panel sections scroll independently on overflow
- Panel hidden when no selection

**Step 2 — Rust: extend `item_json`**

In `api.rs`, change `item_json` to accept the full `Flow` reference (not just `&Item`) so it can query edges. OR: accept a pre-computed `deps: Vec<&str>` slice so the function remains pure and testable. The preferred approach is to pass `deps` and `annotations` as computed slices from the handler, keeping `item_json` a pure serialiser.

Specifically:
- `list_items` handler: compute `deps` by filtering `flow.edges()` for `edge.from == item.id`, collect `edge.to` strings. Compute `annotations` by filtering `store.read_events()` for `Annotated { id }` events for this item. Return as part of item JSON.
- `get_item` handler: same computation.
- `item_json` signature change: add `deps: &[&str]`, `annotations: &[&str]`, `commits: &[serde_json::Value]`, `pr: Option<serde_json::Value>` parameters.
- The existing `mcp.rs` usages of `item_json` must be updated consistently.

New fields in the JSON response:
```
deps: ["id1", "id2"]           // ids of items this item depends on
annotations: ["latest text"]   // Annotated event texts, newest-last
commits: []                    // empty array (future work)
pr: null                       // null (future work)
```

**Important:** `read_events()` acquires the lock. To avoid double-locking, the handler must read events in the same lock scope as the snapshot OR read them separately. The cleanest approach is: `list_items` calls `store.snapshot().await` for the flow, then `store.read_events().await` for annotations — two sequential lock acquisitions, which is safe because there is no invariant requiring atomicity between them for this read-only path.

New Rust tests in `api.rs` (unit) and `http_surface_intest.rs` (integration):
- `item_json_includes_deps_and_annotations`: verifies the JSON contains the new fields
- `list_items_returns_deps_from_edges`: integration test
- `get_item_returns_annotations`: integration test

**Step 3 — Frontend: `detail.js` module**

New file: `static/src/detail.js`

Exports:
```javascript
export function mountDetailPanel(root, { api }) -> { show(item, allItems), hide() }
```

Panel structure (HTML, appended to `root`):
```html
<aside class="detail-panel" hidden aria-label="Item detail">
  <button class="detail-close" aria-label="Close detail">×</button>
  <section class="detail-top" aria-label="Primary content">
    <!-- EPIC: PR title + body + label chips + assignee chips -->
    <!-- ITEM: annotation text -->
  </section>
  <section class="detail-bottom" aria-label="Secondary content">
    <!-- EPIC: nested items list with count -->
    <!-- ITEM: commits (plain list in [28], dot-graph in [31]) -->
  </section>
</aside>
```

`show(item, allItems)`:
- Determines item type: if `item.pr !== null` → EPIC mode; else → ITEM mode
- Since `pr` is always `null` in this cycle, ITEM mode is the only active path
- EPIC mode: renders pr_title, pr_body, label chips, assignee chips (top); filters `allItems` by ids in `item.deps` and renders a count + list (bottom). If pr is null, renders "PR not linked yet."
- ITEM mode: renders `item.annotations` joined with a separator (top); renders `item.commits` list (bottom, plain list in [28], upgraded to graph in [31])
- Makes the panel visible, applies aria-expanded
- Called by canvas when a card is clicked

`hide()`: sets `hidden`, clears content

`show` and `hide` handle their own content clearing — no stale data leaks between selections.

**Step 4 — CSS for detail panel**

In `app.css`, add CSS block for `.detail-panel`:
- `position: absolute; right: 0; top: 0; bottom: 0; width: 35%; min-width: 280px`
- `background: var(--surface-2); backdrop-filter: blur(12px)`
- `border-left: 1px solid var(--line-strong)`
- `display: flex; flex-direction: column; gap: 0; overflow: hidden`
- `.detail-top { flex: 3; overflow-y: auto; padding: ... }` (larger share)
- `.detail-bottom { flex: 1; overflow-y: auto; padding: ...; border-top: 1px solid var(--line) }`
- `.detail-close { ... }` (top-right close button, `min-height: 44px`)
- Label chips: `.detail-label { background: var(--surface); border: 1px solid var(--line-strong); border-radius: 999px; ... }`
- Assignee chips: `.detail-assignee { ... }`

When the detail panel is open, the SVG canvas should shrink to `width: 65%`. This is controlled by a CSS class on the `#app` container: `.has-detail .flow-canvas { right: 35%; }` — set by `mountDetailPanel` when `show()` is called.

**Step 5 — Wire into canvas.js**

In `mountCanvas`:
- Import and call `mountDetailPanel(root, { api })` to get `{ show, hide }`
- Add a `'click'` event listener on `cardsLayer` that delegates: find the `[data-id]` ancestor of the click target, look up the item by id, call `show(item, items)`
- The click must NOT fire during a drag (use a `dragging` flag or compare pointerdown/pointerup positions)
- Close-button in the panel calls `hide()`

**Step 6 — Tests**

New test file: `test/detail.test.js`

Tests covering:
- `show()` with ITEM mode renders annotation text in top section
- `show()` with no annotations renders "No issue text recorded." placeholder
- `show()` with EPIC mode (pr not null) renders PR title
- `show()` with pr null renders "PR not linked yet." in top section
- `show()` renders deps count + list in bottom section for EPIC mode
- `show()` renders commits placeholder in bottom section for ITEM mode
- `hide()` hides the panel
- `hide()` called before `show()` does not throw

Extend `test/canvas.test.js`:
- Clicking a card opens the detail panel and calls `show`
- Clicking the close button calls `hide`
- A click that is a drag (delta > threshold) does not open the panel

**VALUE_HANDLERS required:** RUST-AGENT, JS-AGENT
**Reviewers:** SECURITY-REVIEWER (new HTML overlay + no XSS surface), COVERAGE-REVIEWER

---

### Item [29] — Drag-between-columns + WS live-update

**Tier:** PRIMARY
**Priority status:** MEDIUM
**Token budget estimate:** ~26k tokens
**Estimation basis:** Heuristic — canvas.js extension + WS wiring + api.js extension + coverage maintenance. Comparable to the model-picker feature (~20k), with the WS path adding complexity.
**Depends on:** none (atomic; [28] is parallel)
**Parallel-safe with:** [28]

**Step 0 — EARS statements**
- WHEN a card is dragged to a different column and released, the system SHALL POST the new status to `POST /api/items/:id/status` and update the card's `data-status` and badge colour.
- WHEN a drag is in progress over a column different from the card's current column, the target column SHALL display a drop-active visual glow.
- WHEN the drop is to the same column the card started in, no status POST SHALL occur.
- WHEN the status POST fails, the card SHALL return to its original column and an error SHALL be announced.
- WHEN a `StatusPosted` WS event is received, the system SHALL update the affected card's column position and badge without a page reload.
- WHEN the WS connection drops and reconnects, the system SHALL call `api.getItems()` and re-render.
- WHEN the WS connection is established, the system SHALL use the URL pattern `ws[s]://<host>/ws?token=<token>`.

**Step 1 — Gherkin scenarios**
File: `test/features/drag-columns.feature`
Scenarios:
- Card dragged to different column posts new status
- Same-column drop is a no-op
- Drop-zone glow appears during cross-column drag
- API failure reverts card to original column
- StatusPosted WS event moves card without reload
- WS reconnect triggers refresh

**Step 2 — `api.js`: add `postStatus`**

```javascript
async postStatus(id, status) {
  const res = await postJson(`/api/items/${id}/status`, { status })
  if (!res.ok) throw new Error(`postStatus failed: ${res.status}`)
  return res.json()
}
```

New tests in `test/api.test.js`:
- `postStatus` POSTs `{status}` to `/api/items/:id/status`
- `postStatus` rejects on non-ok response

**Step 3 — `canvas.js`: column-drop detection in `wireCardDrag`**

Extend `onUp` in `wireCardDrag` to:
1. Compute world X from `positions[id].x` (which was updated during drag by `onMove`)
2. Determine target column by finding `col` where `Math.abs(positions[id].x - COL_X[col])` is minimum — or more robustly, check which column's x-range the card center falls within
3. Determine source column from `item.status` via `columnForStatus`
4. If `targetCol !== sourceCol`:
   a. Optimistically update `item.status` to the status for `targetCol` (`do/doing/done`)
   b. Re-render card with updated status
   c. Call `api.postStatus(id, newStatus)` — on error: rollback `item.status`, re-render, announce error
5. Remove drop-active class from all column `<g>` elements

Add `onMove` extension for glow: during `pointermove`, compute current target column and add `board--drop-active` class to that column's `<g>`; remove it from others.

**Step 4 — `canvas.js`: WS subscription**

Add WS setup inside `mountCanvas` after the no-token guard. The setup:
1. Build WS URL: `const proto = location.protocol === 'https:' ? 'wss:' : 'ws:'; const wsUrl = \`\${proto}//\${location.host}/ws?token=\${token}\``
2. Create `new WebSocket(wsUrl)`
3. `ws.onmessage = (e) => { ... }` — parse `JSON.parse(e.data)`, switch on `kind`:
   - `'status_posted'`: find item in `items` by `id`, update `item.status`, re-render the card at its current position, reroute edges
   - Other kinds: no-op for now (future extensibility)
4. `ws.onclose = () => { ... }` — schedule a reconnect after 2 seconds; on reconnect call `refresh()` to re-fetch and re-render
5. `ws.onerror = () => { ... }` — same as onclose; log to `announce` briefly

The WS object must be cleaned up if the canvas is destroyed. Since `mountCanvas` does not currently expose a `destroy()` method, add a `disconnect()` method to the returned handle. Set `ws.onclose = null` before calling `ws.close()` in `disconnect()` to prevent the reconnect loop from firing on intentional close.

**Step 5 — CSS: drop-zone glow and WS status**

In `app.css`:
```css
/* drop-zone glow during cross-column drag */
.board--drop-active .board-bg {
  stroke: var(--accent);
  stroke-width: 2;
  filter: drop-shadow(0 0 12px var(--done-glow));
  transition: filter var(--motion), stroke var(--motion);
}
```

**Step 6 — Tests**

Extend `test/canvas.test.js`:
- Card dragged to a different column calls `api.postStatus` with the new status
- Card dragged to the same column does not call `api.postStatus`
- A cross-column drag applies `board--drop-active` class to the target column during `pointermove` and removes it on `pointerup`
- API failure (postStatus rejects) reverts the card's `data-status` and announces the error
- Optimistic update: card's `data-status` changes before the API call resolves

New test file: `test/ws.test.js`

Tests covering:
- `StatusPosted` message updates the card's `data-status` in the DOM
- `StatusPosted` message for an unknown id is ignored (no crash)
- WS close triggers a `refresh()` after a timeout (mock timers)
- WS URL is constructed correctly using `location.host` and the token
- `disconnect()` closes the WS without triggering the reconnect loop

Extend `test/api.test.js`:
- `postStatus` POSTs `{status}` to the correct endpoint
- `postStatus` rejects on non-ok

**Fixture extension:** Add `postStatus: vi.fn()` to `makeApi()` in `canvas.test.js`.

**VALUE_HANDLERS required:** JS-AGENT
**Reviewers:** COVERAGE-REVIEWER, SECURITY-REVIEWER (WS token in query string)

---

### Item [30] — REDO badge + required-comment modal

**Tier:** SECONDARY
**Priority status:** MEDIUM
**Token budget estimate:** ~18k tokens
**Estimation basis:** Heuristic — modal HTML + CSS + badge extension of card.js + canvas.js integration. Simpler than [29] (no WS, no Rust changes). Comparable to the comment panel (roadmap #4, ~15k) with the badge rendering added.
**Depends on:** [29] must be complete (uses `api.postStatus`)
**Parallel-safe with:** [28] (but [28] must also be complete before [30] starts, since [30]'s canvas.js changes assume column-drop logic from [29] is in place)

**Step 0 — EARS statements**
- WHEN a card is dropped from the DONE column to the DO or DOING column, the system SHALL display a modal dialog requiring a comment before committing the status change.
- WHILE the REDO comment modal is open, the card SHALL be shown at its dropped position with an overlay blocking interaction.
- WHEN the user submits a non-empty comment in the REDO modal, the system SHALL POST the comment via `annotate`, POST the new status via `postStatus`, close the modal, and render a coral REDO badge on the card.
- WHEN the user dismisses the REDO modal without submitting a comment, the card SHALL return to the DONE column and no status change SHALL occur.
- WHEN a card carries a REDO badge and is moved to the DONE column, the REDO badge SHALL be removed.

**Step 1 — Gherkin scenarios**
File: `test/features/redo-modal.feature`
Scenarios:
- DONE-to-DO drag triggers the REDO modal
- DONE-to-DOING drag triggers the REDO modal
- Empty comment cannot be submitted
- Valid comment stores annotation and posts status
- Modal dismissal reverts the card to DONE
- Moving a REDO-badged card to DONE removes the REDO badge

**Step 2 — `card.js`: REDO badge**

Add conditional rendering in `renderCard`:
```javascript
if (item.redo) {
  g.appendChild(badge(CARD_W - 44, 16, 'REDO', 'redo'))
}
```

CSS in `app.css`:
```css
.badge.redo {
  fill: var(--redo);
  font: 700 10px/1 var(--mono);
  text-transform: uppercase;
  letter-spacing: 0.1em;
}
```

The `item.redo` flag is a frontend-only flag (not from the server). It is set on the canvas's working copy of the item when the REDO comment is submitted successfully. It is cleared when the item is moved to DONE. It is not persisted to the server (the annotation serves as the durable record).

**Step 3 — `canvas.js`: intercept DONE→DO/DOING drops**

Extend the column-drop handler from [29]:
- When `sourceCol === 'done'` and `targetCol !== 'done'`: instead of calling `api.postStatus` directly, open the REDO modal
- The `mountCanvas` function imports `mountRedoModal` from a new file `static/src/redo.js`

**Step 4 — `static/src/redo.js`: modal module**

New file: `static/src/redo.js`

Exports:
```javascript
export function mountRedoModal(root) -> { open(onConfirm, onCancel) }
```

Modal structure:
```html
<dialog class="redo-modal" aria-labelledby="redo-title">
  <h2 id="redo-title">Why are you moving this back?</h2>
  <p class="redo-subtitle">A backward move requires a "why" comment.</p>
  <textarea class="redo-input" rows="4" placeholder="Explain the regression or change of plan..."></textarea>
  <div class="redo-actions">
    <button class="redo-cancel" type="button">Cancel</button>
    <button class="redo-submit" type="button">Submit</button>
  </div>
</dialog>
```

`open(onConfirm, onCancel)`:
- Calls `dialog.showModal()`
- Clears textarea
- Submit button: validates non-empty text, calls `onConfirm(text)`, calls `dialog.close()`
- Cancel button: calls `onCancel()`, calls `dialog.close()`
- `Escape` key (native `<dialog>` behavior): calls `onCancel()`, ensures card reverts

`onConfirm(text)` is provided by the canvas and does:
1. `await api.annotate(id, text)`
2. `await api.postStatus(id, newStatus)`
3. Set `item.redo = true`
4. Re-render card (shows REDO badge)

`onCancel()` is provided by the canvas and does:
1. Revert `positions[id]` to the pre-drag snapshot
2. Place card back at original position

**Step 5 — CSS for REDO modal**

In `app.css`:
```css
.redo-modal {
  border: 1px solid var(--redo);
  border-radius: var(--radius);
  background: var(--surface-2);
  backdrop-filter: blur(12px);
  color: var(--ink);
  padding: 1.5rem;
  max-width: 28rem;
  width: calc(100vw - 4rem);
  box-shadow: var(--shadow);
}
.redo-modal::backdrop {
  background: rgba(0, 0, 0, 0.55);
  backdrop-filter: blur(4px);
}
.redo-input {
  width: 100%;
  min-height: 80px;
  border: 1px solid var(--line-strong);
  border-radius: var(--radius-sm);
  background: var(--bg);
  color: var(--ink);
  font: inherit;
  padding: 0.5rem;
  resize: vertical;
}
.redo-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.6rem;
  margin-top: 1rem;
}
.redo-submit {
  background: var(--redo);
  color: #fff;
  border: none;
  border-radius: var(--radius-sm);
  min-height: 44px;
  padding: 0 1.2rem;
  font: inherit;
  font-weight: 600;
  cursor: pointer;
}
.redo-cancel {
  background: var(--bg-card);
  color: var(--ink);
  border: 1px solid var(--line-strong);
  border-radius: var(--radius-sm);
  min-height: 44px;
  padding: 0 1.2rem;
  font: inherit;
  cursor: pointer;
}
```

**Step 6 — Tests**

New test file: `test/redo.test.js`

Tests covering:
- `open(onConfirm, onCancel)` shows the modal dialog
- Empty comment text: submit button click does not call `onConfirm`
- Non-empty comment: submit calls `onConfirm(text)` and closes the dialog
- Cancel button calls `onCancel()` and closes the dialog

Extend `test/canvas.test.js`:
- DONE→DO drag opens the REDO modal (mock `mountRedoModal`)
- DONE→DOING drag opens the REDO modal
- DOING→DO drag does NOT open the REDO modal (only DONE origin triggers it)
- After REDO confirm, the card shows the redo badge

Extend `test/card.test.js`:
- Card with `item.redo === true` renders a badge with class `redo`
- Card with `item.redo === false` does not render a redo badge

**VALUE_HANDLERS required:** JS-AGENT
**Reviewers:** COVERAGE-REVIEWER, SECURITY-REVIEWER (user input stored via annotate)

---

### Item [31] — Commit-graph view

**Tier:** TERTIARY
**Priority status:** LOW
**Token budget estimate:** ~16k tokens
**Estimation basis:** Heuristic — SVG graph renderer in existing detail panel, click-to-expand behavior, scroll. Smallest of the four items. No Rust changes. No new files beyond extending `detail.js`.
**Depends on:** [28] must be complete (`detail.js` and the `commits` field in `item_json` must exist)
**Parallel-safe with:** [29], [30] (those items do not touch `detail.js`)

**Step 0 — EARS statements**
- WHEN an item detail panel is shown for an item with a non-empty `commits` array, the bottom section SHALL render a dot-and-line SVG graph, one dot per commit.
- WHEN a user clicks a commit dot, the panel SHALL display the full commit message (hash + body) in monospace below the dot.
- WHERE a commit message is long, the containing section SHALL scroll to reveal it fully.
- WHEN an item has no commits, the bottom section SHALL display "No commits yet."
- WHEN a second dot is clicked, the previously-expanded message SHALL collapse.

**Step 1 — Gherkin scenarios**
File: `test/features/commit-graph.feature`
Scenarios:
- Item with commits shows dot-and-line graph
- Clicking a dot expands the commit message
- Clicking a second dot collapses the first and expands the second
- Item with no commits shows placeholder
- Long commit message is scrollable

**Step 2 — Commit data shape**

The `commits` array in `item_json` (stubbed as `[]` in [28]) will carry objects of shape:
```json
{ "hash": "abc1234", "message": "feat: add the thing\n\nLonger body here." }
```

For the purposes of this cycle, the `commits` array remains `[]` (no Rust changes needed for [31] itself). The commit-graph renderer gracefully handles an empty array by showing the placeholder. The test fixture for [31] will add commits manually to the fixture item.

**Step 3 — Extend `detail.js`: commit-graph renderer**

Inside `detail.js`, in the `show()` function's ITEM mode path, replace the plain list renderer in the bottom section with:

`renderCommitGraph(commits, container)`:
- Creates an SVG element sized to `width: 100%; height: auto`
- Renders a vertical spine line from top to bottom of all dots
- For each commit: renders a `<circle>` dot (r=6) connected to the spine; a `<text>` showing the short hash (7 chars) to the right of the dot
- Each dot group is `role="button" tabindex="0"` with `aria-label="commit <hash>"`
- Click/Enter: expand/collapse a `<div>` below the SVG showing the full message in `font-family: var(--mono)` — this is an HTML div (not SVG) for proper text reflow and scrollability
- Only one message expanded at a time; clicking the active dot collapses it

CSS additions to `app.css`:
```css
.commit-graph-svg { display: block; width: 100%; }
.commit-dot { fill: var(--accent); stroke: var(--bg); stroke-width: 2; cursor: pointer; }
.commit-dot:hover, .commit-dot:focus-visible { fill: var(--doing); }
.commit-spine { stroke: var(--line-strong); stroke-width: 1.5; }
.commit-hash { font: 600 11px/1 var(--mono); fill: var(--ink-dim); }
.commit-message {
  display: none;
  padding: 0.6rem 0.4rem 0.6rem 1.6rem;
  font: 0.82rem/1.6 var(--mono);
  color: var(--ink-dim);
  white-space: pre-wrap;
  word-break: break-all;
  border-left: 2px solid var(--accent);
  margin: 0.25rem 0 0.5rem 0.8rem;
}
.commit-message.is-expanded { display: block; }
```

**Step 4 — Tests**

New test file: `test/commit-graph.test.js`

Tests covering:
- `renderCommitGraph` with empty array renders placeholder text
- `renderCommitGraph` with 3 commits renders 3 dots and the spine
- Clicking a dot expands the commit message div
- Clicking the same dot again collapses it
- Clicking a second dot collapses the first and expands the second
- Keyboard: Enter on a dot expands it

Extend `test/detail.test.js`:
- `show()` with item having commits calls through to the graph renderer and renders dots
- `show()` with item having no commits renders the placeholder

**VALUE_HANDLERS required:** JS-AGENT
**Reviewers:** COVERAGE-REVIEWER

---

## 5. PARALLEL GROUPING

### Dependency graph (verified acyclic)

```
[28] ────────┐
             ├──── [31] (needs [28])
[29] ───┐    │
        └────┘
[30] (needs [29])
```

Topological sort: [28], [29] (concurrent) → [30], [31] (concurrent after their respective prerequisites)

### PRIMARY Tier

**Round 1 (can run concurrently):**
- [28] — RHS detail panel (builds shared: `detail.js`, extended `item_json`)
- [29] — Drag-between-columns + WS live-update (builds shared: `api.postStatus`, WS subscription)

**Round 2 (after Round 1 completes):**
- [30] — REDO badge + modal (needs `api.postStatus` from [29])
- [31] — Commit-graph view (needs `detail.js` from [28])

[30] and [31] can run concurrently with each other after their respective prerequisites.

### No-conflict verification for Round 1

[28] and [29] may both touch `canvas.js` (wiring the panel-open click and the WS subscription). If run truly concurrently by two different agents writing to `canvas.js` simultaneously, they would conflict. The safe parallel execution path:
- [28] writes `detail.js` (new file — no conflict with [29])
- [28] extends `api.rs` (no conflict with [29])
- [29] writes `api.js` (adding `postStatus` — no conflict with [28])
- [29] extends `canvas.js` drag logic
- [28]'s wiring into `canvas.js` (card click → panel) is deferred to the integration step and can be done after [29] lands, OR both agents coordinate on separate named functions inside `canvas.js` that do not touch the same lines

**Recommendation:** Run [28] and [29] as concurrent agents but assign `canvas.js` modification exclusively to [29]. The [28] agent writes only `detail.js`, `api.rs`, `app.css` (detail panel CSS), and `test/detail.test.js`. The wiring of the panel open/close click into `canvas.js` is assigned to [30]'s canvas.js pass (or done as a final integration step after both [28] and [29] are merged). This eliminates the write conflict entirely.

Revised Round 1 file ownership:

| File | [28] | [29] |
|---|---|---|
| `src/api.rs` | extends `item_json` | no touch |
| `static/src/detail.js` | creates | no touch |
| `static/src/api.js` | no touch | adds `postStatus` |
| `static/src/canvas.js` | no touch | adds drag-column + WS |
| `static/app.css` | adds detail panel CSS | adds drop-glow CSS |
| `test/detail.test.js` | creates | no touch |
| `test/canvas.test.js` | no touch | extends |
| `test/api.test.js` | no touch | extends |
| `test/ws.test.js` | no touch | creates |
| `test/fixtures.js` | extends item shape | no touch |

The canvas wiring (card click → `detail.show()`) is done as the first step of [30], which starts after both [28] and [29] are merged. [30] can safely extend `canvas.js` at that point because it owns the only outstanding canvas.js task.

---

## 6. TEST STRATEGY

### Existing suite (do not break)
164 vitest tests across `api.test.js`, `canvas.test.js`, `card.test.js`, `comment.test.js`, `layout.test.js`, `masthead.test.js`, `model.test.js`, `progress.test.js`. All at 100% coverage. Every item in this cycle must leave the suite green at 100%.

### New test files

| File | Item | Scope |
|---|---|---|
| `test/detail.test.js` | [28] | Panel mount, show/hide, EPIC vs ITEM mode, placeholder text, close button |
| `test/ws.test.js` | [29] | WS URL construction, StatusPosted handling, reconnect refresh, disconnect |
| `test/redo.test.js` | [30] | Modal open/close, empty-comment guard, confirm path, cancel path |
| `test/commit-graph.test.js` | [31] | Dot rendering, expand/collapse, keyboard, empty state |

### Extended test files

| File | Items that extend it |
|---|---|
| `test/api.test.js` | [29] adds `postStatus` tests |
| `test/canvas.test.js` | [29] adds column-drop + drop-glow tests; [30] adds REDO modal trigger tests |
| `test/card.test.js` | [30] adds REDO badge tests |
| `test/fixtures.js` | [28] extends fixture item shape with `deps`, `annotations`, `commits`, `pr` |

### Rust integration tests

| File | Items that extend it |
|---|---|
| `src/http_surface_intest.rs` | [28] adds tests for extended `item_json` shape (deps, annotations, commits, pr fields) |
| `src/http_contract_intest.rs` | [28] adds contract tests verifying `GET /api/items` response shape |

### Coverage maintenance

The vitest config enforces 100% coverage of all lines, branches, functions, and statements in `src/**/*.js`. Every new function and branch added by items [28]–[31] must have a corresponding test. The plan decomposes each item so the tests are written (Step 2/3 per item) before the implementation is complete.

### Test environment notes

- jsdom is used; no real DOM layout geometry. The detail panel's scroll behaviour is not testable in jsdom — test structural presence and CSS class application instead.
- `<dialog>` with `showModal()` requires jsdom ≥ 20 (vitest uses jsdom 24+ via happy-dom or jsdom environment). Verify `dialog.showModal()` is available; if not, use a polyfill or mock in the redo tests.
- The WS tests (`test/ws.test.js`) mock `WebSocket` using `vi.stubGlobal('WebSocket', MockWebSocket)`.

---

## 7. DEPENDENCY MAP

```
[28] RHS detail panel
  └── blocks: [31] (commit-graph view uses detail.js)

[29] Drag-between-columns + WS
  └── blocks: [30] (REDO modal uses api.postStatus and canvas column-drop hook)

[30] REDO badge + modal
  └── requires: [29] complete

[31] Commit-graph view
  └── requires: [28] complete

[30] and [31] are safe to run concurrently with each other.
```

**No dependency cycles exist.**

---

## 8. TOKEN BUDGET SUMMARY

| Item | Est. tokens | Basis |
|---|---|---|
| [28] RHS detail panel | ~28k | Heuristic: new module + Rust extension + test coverage |
| [29] Drag-columns + WS | ~26k | Heuristic: canvas.js extension + WS wiring + new API method |
| [30] REDO badge + modal | ~18k | Heuristic: modal module + badge + canvas integration |
| [31] Commit-graph view | ~16k | Heuristic: SVG graph in existing panel + tests |
| **Total** | **~88k** | |

---

## 9. VALUE_HANDLER_POOL REQUIRED

| Agent | Items |
|---|---|
| RUST-AGENT | [28] (extend `item_json` in `api.rs`, integration tests) |
| JS-AGENT | [28], [29], [30], [31] (all frontend JS + tests) |
| CSS-AGENT (or JS-AGENT handles CSS) | [28] detail panel, [29] drop-glow, [30] modal + REDO badge, [31] commit-graph |

Note: If no dedicated CSS-AGENT is registered, JS-AGENT handles CSS changes as part of each item's implementation step.

---

## 10. MISSING HANDLERS

No handler gaps that would block this cycle. The JS-AGENT and RUST-AGENT cover all required work. A dedicated CSS-AGENT would be useful for isolated CSS-only changes but is not required.

**Flag for kaizen:** The CSS-only steps (token additions, new component rules) are handled by the JS-AGENT. If a CSS-AGENT were available, the CSS steps could be parallelised with the JS implementation steps, reducing round-trip cost.

---

## 11. SELF-IMPROVEMENT FLAGS

1. **`item_json` extensibility pattern:** The current `item_json` function takes only `&Item` and returns a minimal shape. Every cycle that needs new fields requires a handler to understand the full `api.rs` callsite context to avoid breaking MCP. Consider encapsulating the item-to-JSON transform behind a domain-level `ItemView` struct that carries computed fields (deps, annotations) so `item_json` remains a trivial serialisation call. Recommend as a KAIZEN item.

2. **PR and commit data are not in the domain model:** The ROADMAP refers to PR linkage (#10) and commit association, but the domain `Item` struct has no `pr_url`, `pr_title`, `pr_body`, `commits` fields. This cycle works around this gap with placeholders. A future KAIZEN item should define a `PrLinkage` and `CommitRef` type in `domain/model.rs` and the corresponding `PrLinked { id, pr_title, pr_url }` event in `domain/event.rs`.

3. **WS reconnect loop uses a fixed 2-second delay:** A production-quality reconnect would use exponential back-off with jitter. The 2-second fixed delay is acceptable for a solo builder but may cause visible lag. Flag for improvement once multiple concurrent users are a concern.

4. **`<dialog>` availability in jsdom:** The redo modal uses `HTMLDialogElement.showModal()`. If the test environment does not support this, the modal tests will fail at `dialog.showModal is not a function`. Verify and document the minimum jsdom version required; add a note to the vitest config.

---

## 12. RESUMPTION INSTRUCTIONS

A cold-start `lifecycle-orchestrator` resuming this plan needs:

1. **Branch:** `feature/epic-27-kanban-uplift` off `main`
2. **Baseline:** 164 vitest tests passing, 100% coverage; Rust tests passing
3. **Item execution order:**
   - Round 1 (concurrent): run [28] and [29] as separate agent tasks; [28] owns `api.rs` and `detail.js`; [29] owns `canvas.js` drag/WS and `api.js postStatus`
   - Round 2 (after Round 1 merged): run [30] and [31] as separate agent tasks; [30] owns `redo.js` + canvas.js REDO hook + card.js REDO badge; [31] owns commit-graph renderer extension in `detail.js`
4. **Coverage gate:** After each item, run `cd plugins/mission-control/flow-server/static && npm test -- --coverage` and verify all four thresholds remain at 100%.
5. **Rust gate:** After [28], run `cd plugins/mission-control/flow-server && cargo test` and verify all tests pass.
6. **Canvas wiring note:** The card-click → `detail.show()` wiring into `canvas.js` is deferred to [30]'s first step (Round 2) to avoid a write conflict between [28] and [29] agents. The [28] agent's scope ends at the `detail.js` module and the Rust extension; [30] wires the panel open into canvas.js.
7. **Fixture extension:** The [28] agent must extend `test/fixtures.js` with `deps`, `annotations`, `commits`, `pr` fields on fixture items. All subsequent test files (detail, ws, redo, commit-graph) import from this fixture.
8. **No new Rust routes are needed for [29], [30], [31].** The existing `POST /api/items/:id/status` (mapped to `post_status` in `api.rs`) and `POST /api/items/:id/annotate` (mapped to `annotate`) are already wired.
9. **CSS token availability:** `--redo`, `--redo-glow`, `--surface`, `--surface-2`, `--mono`, `--motion` are already in `app.css`. New CSS rules must use only existing tokens (no new custom property definitions unless strictly necessary).
10. **MCP surface:** `mcp.rs` uses `item_json` from `api.rs`. After the `item_json` signature change in [28], the MCP handler must be updated consistently. The [28] agent is responsible for this.
