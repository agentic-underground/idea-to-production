import { describe, it, expect } from 'vitest'
import {
  COLUMNS,
  columnForStatus,
  groupByColumn,
  dependencyOrder,
  autoAlign,
  bezierPath,
  zoomAboutCursor
} from '../src/layout.js'
import { FIXTURE_ITEMS } from './fixtures.js'

describe('columnForStatus', () => {
  it('maps each status to its board column', () => {
    expect(columnForStatus('do')).toBe('do')
    expect(columnForStatus('doing')).toBe('doing')
    expect(columnForStatus('done')).toBe('done')
  })

  it('treats an unknown status as the DO column (safe default)', () => {
    expect(columnForStatus('mystery')).toBe('do')
  })
})

describe('groupByColumn', () => {
  it('places each fixture item in the correct DO/DOING/DONE column', () => {
    const grouped = groupByColumn(FIXTURE_ITEMS)
    expect(grouped.done.map((i) => i.id)).toEqual(['flow-server'])
    expect(grouped.doing.map((i) => i.id)).toEqual(['svg-flow-canvas'])
    expect(grouped.do.map((i) => i.id)).toEqual([
      'carriage-telemetry',
      'comment-rewrite-loop'
    ])
  })

  it('returns all three columns even when some are empty', () => {
    const grouped = groupByColumn([
      { id: 'x', status: 'done', deps: [] }
    ])
    expect(grouped.do).toEqual([])
    expect(grouped.doing).toEqual([])
    expect(grouped.done.map((i) => i.id)).toEqual(['x'])
    expect(Object.keys(grouped).sort()).toEqual([...COLUMNS].sort())
  })
})

describe('dependencyOrder', () => {
  it('orders items so every dependency precedes its dependents', () => {
    const order = dependencyOrder(FIXTURE_ITEMS).map((i) => i.id)
    expect(order.indexOf('flow-server')).toBeLessThan(order.indexOf('svg-flow-canvas'))
    expect(order.indexOf('flow-server')).toBeLessThan(order.indexOf('carriage-telemetry'))
    expect(order.indexOf('svg-flow-canvas')).toBeLessThan(
      order.indexOf('comment-rewrite-loop')
    )
    expect(order.indexOf('carriage-telemetry')).toBeLessThan(
      order.indexOf('comment-rewrite-loop')
    )
  })

  it('is stable for items with no dependencies (preserves input order)', () => {
    const items = [
      { id: 'a', deps: [] },
      { id: 'b', deps: [] },
      { id: 'c', deps: [] }
    ]
    expect(dependencyOrder(items).map((i) => i.id)).toEqual(['a', 'b', 'c'])
  })

  it('ignores a dependency on an item that is not present', () => {
    const items = [{ id: 'a', deps: ['ghost'] }]
    expect(dependencyOrder(items).map((i) => i.id)).toEqual(['a'])
  })

  it('treats an item with no deps field as having no dependencies', () => {
    const items = [{ id: 'a' }, { id: 'b' }] // deps undefined
    expect(dependencyOrder(items).map((i) => i.id)).toEqual(['a', 'b'])
  })

  it('does not hang on a cyclic input — emits every node once', () => {
    const items = [
      { id: 'a', deps: ['b'] },
      { id: 'b', deps: ['a'] }
    ]
    const order = dependencyOrder(items).map((i) => i.id).sort()
    expect(order).toEqual(['a', 'b'])
  })
})

describe('autoAlign', () => {
  it('assigns a position to every item, grouped by column and ranked by dependency', () => {
    const positions = autoAlign(FIXTURE_ITEMS)
    // every item gets an {x, y}
    for (const item of FIXTURE_ITEMS) {
      expect(positions[item.id]).toBeDefined()
      expect(typeof positions[item.id].x).toBe('number')
      expect(typeof positions[item.id].y).toBe('number')
    }
  })

  it('puts DONE left of DOING left of DO (column x ordering)', () => {
    const p = autoAlign(FIXTURE_ITEMS)
    expect(p['flow-server'].x).toBeLessThan(p['svg-flow-canvas'].x)
    expect(p['svg-flow-canvas'].x).toBeLessThan(p['carriage-telemetry'].x)
  })

  it('stacks two cards in the same column at different y', () => {
    const p = autoAlign(FIXTURE_ITEMS)
    expect(p['carriage-telemetry'].y).not.toBe(p['comment-rewrite-loop'].y)
    // same column ⇒ same x
    expect(p['carriage-telemetry'].x).toBe(p['comment-rewrite-loop'].x)
  })
})

describe('bezierPath', () => {
  it('builds a cubic Bézier between two anchor points', () => {
    const d = bezierPath({ x: 0, y: 0 }, { x: 100, y: 50 })
    expect(d).toMatch(/^M 0 0 C /)
    // a cubic path has the C command with three coordinate pairs
    expect(d).toContain('100 50')
    expect(d.match(/C/g)).toHaveLength(1)
  })

  it('bows the control points horizontally between the endpoints', () => {
    const d = bezierPath({ x: 0, y: 0 }, { x: 200, y: 0 })
    // first control point pulled right of the start, second left of the end
    expect(d).toContain('C 100 0 100 0 200 0')
  })
})

describe('zoomAboutCursor', () => {
  const base = { scale: 1, x: 0, y: 0 }

  it('keeps the cursor point fixed while scaling up', () => {
    const next = zoomAboutCursor(base, { cursorX: 50, cursorY: 50, factor: 2 })
    expect(next.scale).toBe(2)
    // world point under the cursor before and after must coincide
    const worldBeforeX = (50 - base.x) / base.scale
    const worldAfterX = (50 - next.x) / next.scale
    expect(worldAfterX).toBeCloseTo(worldBeforeX, 6)
  })

  it('clamps the scale to the configured min/max', () => {
    const tooBig = zoomAboutCursor(base, { cursorX: 0, cursorY: 0, factor: 1000 })
    expect(tooBig.scale).toBeLessThanOrEqual(4)
    const tooSmall = zoomAboutCursor(base, { cursorX: 0, cursorY: 0, factor: 0.0001 })
    expect(tooSmall.scale).toBeGreaterThanOrEqual(0.25)
  })

  it('leaves the transform untouched when a clamp absorbs the whole factor', () => {
    const maxed = { scale: 4, x: 10, y: 20 }
    const next = zoomAboutCursor(maxed, { cursorX: 5, cursorY: 5, factor: 2 })
    // already at max scale ⇒ no change to scale or translation
    expect(next).toEqual(maxed)
  })
})
