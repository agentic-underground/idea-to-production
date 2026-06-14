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
    deps: []
  },
  {
    id: 'svg-flow-canvas',
    title: 'SVG flow-canvas',
    status: 'doing',
    gate: 'go',
    tokens: 42000,
    model: 'claude-sonnet-4-6',
    draft: 1,
    deps: ['flow-server']
  },
  {
    id: 'carriage-telemetry',
    title: 'Carriage agent + token telemetry',
    status: 'do',
    gate: 'wait',
    tokens: 0,
    model: 'claude-sonnet-4-6',
    draft: 0,
    deps: ['flow-server']
  },
  {
    id: 'comment-rewrite-loop',
    title: 'Comment / pause / annotate / rewrite loop',
    status: 'do',
    gate: 'go',
    tokens: 0,
    model: 'claude-opus-4-8',
    draft: 0,
    deps: ['svg-flow-canvas', 'carriage-telemetry']
  }
]

/** A two-node fixture where adding b→a would close the a→b cycle. */
export const CYCLE_FIXTURE = [
  { id: 'a', title: 'A', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: [] },
  { id: 'b', title: 'B', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: ['a'] }
]
