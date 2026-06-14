// Fixture flow — mirrors the shape the flow-server's `GET /api/items` returns
// (id · title · status · gate · tokens · model), extended with an optional
// `deps` array (ids this item depends on) so the canvas can draw connectors
// without a live server. The ids and dependency edges below are the EPIC #0
// dependency tree from mission-control's ROADMAP.md.
//
// @front-end
// intent: give the canvas-logic tests a deterministic, server-shaped graph
// customer: solo-builder (the governance UI's developer-as-operator)

export const FIXTURE_ITEMS = [
  {
    id: 'flow-server',
    title: 'Flow server (HTTP + WS + MCP)',
    status: 'done',
    gate: 'go',
    tokens: 250000,
    model: 'claude-opus-4-8',
    draft: 6,
    deps: [],
    annotations: ['Initial architecture note', 'Revised API shape'],
    commits: [],
    pr: null
  },
  {
    id: 'svg-flow-canvas',
    title: 'SVG flow-canvas',
    status: 'doing',
    gate: 'go',
    tokens: 42000,
    model: 'claude-sonnet-4-6',
    draft: 1,
    deps: ['flow-server'],
    annotations: [],
    commits: [],
    pr: null
  },
  {
    id: 'carriage-telemetry',
    title: 'Carriage agent + token telemetry',
    status: 'do',
    gate: 'wait',
    tokens: 0,
    model: 'claude-sonnet-4-6',
    draft: 0,
    deps: ['flow-server'],
    annotations: ['Waiting on telemetry design'],
    commits: [],
    pr: null
  },
  {
    id: 'comment-rewrite-loop',
    title: 'Comment / pause / annotate / rewrite loop',
    status: 'do',
    gate: 'go',
    tokens: 0,
    model: 'claude-opus-4-8',
    draft: 0,
    deps: ['svg-flow-canvas', 'carriage-telemetry'],
    annotations: [],
    commits: [],
    pr: null
  }
]

/** A two-node fixture where adding b→a would close the a→b cycle. */
export const CYCLE_FIXTURE = [
  { id: 'a', title: 'A', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: [], annotations: [], commits: [], pr: null },
  { id: 'b', title: 'B', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: ['a'], annotations: [], commits: [], pr: null }
]

/** A fixture item simulating an EPIC with a linked PR. */
export const EPIC_ITEM = {
  id: 'my-epic',
  title: 'My Epic',
  status: 'doing',
  gate: 'go',
  tokens: 0,
  model: 'claude-sonnet-4-6',
  draft: 0,
  deps: ['child-a', 'child-b'],
  annotations: [],
  commits: [],
  pr: { title: 'feat: My Epic PR', body: 'This implements the epic.', labels: ['epic', 'feature'], assignees: ['alice'] }
}

/** A fixture item for ITEM mode: has annotations and no commits. */
export const ITEM_WITH_ANNOTATIONS = {
  id: 'annotated-item',
  title: 'Annotated Item',
  status: 'do',
  gate: 'go',
  tokens: 0,
  model: 'claude-sonnet-4-6',
  draft: 0,
  deps: [],
  annotations: ['First note', 'Second note', 'Latest note'],
  commits: [],
  pr: null
}

/** A fixture item with commits but no annotations. */
export const ITEM_WITH_COMMITS = {
  id: 'committed-item',
  title: 'Committed Item',
  status: 'done',
  gate: 'go',
  tokens: 0,
  model: 'claude-sonnet-4-6',
  draft: 0,
  deps: [],
  annotations: [],
  commits: [
    { hash: 'abc1234', message: 'feat: add the thing\n\nLonger body here.' },
    { hash: 'def5678', message: 'fix: correct the thing' }
  ],
  pr: null
}

/** Child items referenced by EPIC_ITEM deps. */
export const CHILD_ITEMS = [
  { id: 'child-a', title: 'Child A', status: 'do', gate: 'go', tokens: 0, model: 'claude-sonnet-4-6', draft: 0, deps: [], annotations: [], commits: [], pr: null },
  { id: 'child-b', title: 'Child B', status: 'doing', gate: 'go', tokens: 0, model: 'claude-sonnet-4-6', draft: 0, deps: [], annotations: [], commits: [], pr: null }
]
