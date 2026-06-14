// layout.js — the PURE canvas core. No DOM, no IO: column assignment,
// dependency-ordering, auto-align placement, Bézier connector geometry, and the
// zoom-about-cursor transform. Every function here is a coordinate the tests pin.
//
// @front-end
// element: flow-canvas-layout
// philosophy: instrument-panel (operation-style governance surface)
// paradigm: dashboard-explorative
// intent: turn a flat list of work items into a navigable dependency graph the
//         builder can comprehend at a glance and steer
// customer: solo-builder
// binding: one-way                # data in → geometry out; mutates nothing
// render-trigger: items.changed
// a11y: wcag-2.1-aa               # geometry only; the DOM layer carries roles/labels
// improve?: "swap the naive column-stack for an ELK/dagre DAG layout to minimise
//            edge crossings on large flows (see roadmap #2 implementation notes)"
// breadcrumbs: ["status ∈ {do,doing,done} from the server", "deps[] is ids this
//               item depends on", "DONE renders leftmost: value flows left→right"]

/** Board columns, left → right (value flows DONE → DOING → DO as work lands). */
export const COLUMNS = Object.freeze(['done', 'doing', 'do'])

/** Geometry constants (world units). */
export const CARD_W = 240
export const CARD_H = 120
export const COL_GAP = 120
export const ROW_GAP = 48
export const COL_X = { done: 40, doing: 40 + CARD_W + COL_GAP, do: 40 + 2 * (CARD_W + COL_GAP) }

export const ZOOM_MIN = 0.25
export const ZOOM_MAX = 4

/** Map a server status string to its board column (unknown ⇒ the DO column). */
export function columnForStatus(status) {
  if (status === 'doing') return 'doing'
  if (status === 'done') return 'done'
  return 'do'
}

/** Group items into {do, doing, done}, preserving input order within each. */
export function groupByColumn(items) {
  const grouped = { do: [], doing: [], done: [] }
  for (const item of items) {
    grouped[columnForStatus(item.status)].push(item)
  }
  return grouped
}

/**
 * Topologically order items so every present dependency precedes its dependents.
 * Stable for independent nodes (input order preserved); cycle-safe (each node is
 * emitted exactly once even if the input graph has a cycle).
 */
export function dependencyOrder(items) {
  const byId = new Map(items.map((i) => [i.id, i]))
  const visited = new Set()
  const out = []

  const visit = (item, stack) => {
    if (visited.has(item.id) || stack.has(item.id)) return
    stack.add(item.id)
    for (const depId of item.deps ?? []) {
      const dep = byId.get(depId)
      if (dep) visit(dep, stack)
    }
    stack.delete(item.id)
    visited.add(item.id)
    out.push(item)
  }

  for (const item of items) visit(item, new Set())
  return out
}

/**
 * Compute an {id: {x, y}} placement: items grouped by column (DONE left → DO
 * right) and, within a column, ranked by dependency order then stacked.
 */
export function autoAlign(items) {
  const ranked = dependencyOrder(items)
  const grouped = groupByColumn(ranked)
  const positions = {}
  for (const col of COLUMNS) {
    grouped[col].forEach((item, row) => {
      positions[item.id] = {
        x: COL_X[col],
        y: 40 + row * (CARD_H + ROW_GAP)
      }
    })
  }
  return positions
}

/**
 * A cubic Bézier path string from `a` to `b`, bowed horizontally: control points
 * sit at the horizontal midpoint, level with their own endpoint.
 */
export function bezierPath(a, b) {
  const midX = (a.x + b.x) / 2
  return `M ${a.x} ${a.y} C ${midX} ${a.y} ${midX} ${b.y} ${b.x} ${b.y}`
}

/**
 * Zoom a {scale, x, y} pan/zoom transform about a cursor point, keeping the world
 * point under the cursor fixed. Scale is clamped to [ZOOM_MIN, ZOOM_MAX]; when the
 * clamp absorbs the whole factor the transform is returned unchanged.
 */
export function zoomAboutCursor(transform, { cursorX, cursorY, factor }) {
  const nextScale = Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, transform.scale * factor))
  if (nextScale === transform.scale) return transform
  // world point under the cursor before the zoom
  const worldX = (cursorX - transform.x) / transform.scale
  const worldY = (cursorY - transform.y) / transform.scale
  // re-solve the translation so that world point lands back under the cursor
  return {
    scale: nextScale,
    x: cursorX - worldX * nextScale,
    y: cursorY - worldY * nextScale
  }
}
