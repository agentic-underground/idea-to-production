import { describe, it, expect, beforeEach, vi } from 'vitest'
import { within } from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import { SVG_NS, renderCard, CARD_TESTID } from '../src/card.js'
import { FIXTURE_ITEMS } from './fixtures.js'

const item = FIXTURE_ITEMS[1] // svg-flow-canvas: doing, go, sonnet, draft 1

let svg
beforeEach(() => {
  document.body.innerHTML = ''
  svg = document.createElementNS(SVG_NS, 'svg')
  document.body.appendChild(svg)
})

describe('renderCard', () => {
  it('renders a rounded-rect card group at the given position', () => {
    const g = renderCard(item, { x: 10, y: 20 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    expect(g.namespaceURI).toBe(SVG_NS)
    expect(g.getAttribute('transform')).toBe('translate(10 20)')
    const rect = g.querySelector('rect')
    expect(rect.getAttribute('rx')).toBeTruthy() // rounded
  })

  it('labels the card group for assistive tech with the item title and state', () => {
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    expect(g.getAttribute('role')).toBe('group')
    const label = g.getAttribute('aria-label')
    expect(label).toContain('SVG flow-canvas')
    expect(label.toLowerCase()).toContain('doing')
  })

  it('carries a data-id matching the item for runtime introspection', () => {
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    expect(g.getAttribute('data-id')).toBe('svg-flow-canvas')
    expect(g.getAttribute('data-testid')).toBe(`${CARD_TESTID}-svg-flow-canvas`)
  })

  it('shows badges for token cost, status, model and draft#', () => {
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    const text = g.textContent
    expect(text).toContain('42,000') // token cost, grouped
    expect(text.toLowerCase()).toContain('doing') // status badge
    expect(text).toContain('sonnet') // model (short name)
    expect(text).toContain('#1') // draft number
  })

  it('renders a WAIT/GO toggle as a button reading the current gate', () => {
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    const toggle = within(g).getByRole('button', { name: /go|wait/i })
    // item is GO ⇒ the toggle offers to switch to WAIT, current state announced
    expect(toggle.getAttribute('aria-pressed')).toBe('false') // not paused
  })

  it('a WAIT item announces the paused state on the toggle and card', () => {
    const waitItem = FIXTURE_ITEMS[2] // carriage-telemetry: wait
    const g = renderCard(waitItem, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    expect(g.getAttribute('data-gate')).toBe('wait')
    const toggle = within(g).getByRole('button', { name: /go|wait/i })
    expect(toggle.getAttribute('aria-pressed')).toBe('true') // paused
  })

  it('invokes onToggleGate with the OPPOSITE gate when the toggle is clicked', async () => {
    const user = userEvent.setup()
    const onToggleGate = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate }) // item is GO
    svg.appendChild(g)
    const toggle = within(g).getByRole('button', { name: /go|wait/i })
    await user.click(toggle)
    expect(onToggleGate).toHaveBeenCalledWith('svg-flow-canvas', 'wait')
  })

  it('toggles from WAIT back to GO', async () => {
    const user = userEvent.setup()
    const onToggleGate = vi.fn()
    const waitItem = FIXTURE_ITEMS[2]
    const g = renderCard(waitItem, { x: 0, y: 0 }, { onToggleGate })
    svg.appendChild(g)
    await user.click(within(g).getByRole('button', { name: /go|wait/i }))
    expect(onToggleGate).toHaveBeenCalledWith('carriage-telemetry', 'go')
  })

  it('the toggle is keyboard-operable (Enter activates it)', async () => {
    const user = userEvent.setup()
    const onToggleGate = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate })
    svg.appendChild(g)
    const toggle = within(g).getByRole('button', { name: /go|wait/i })
    toggle.focus()
    await user.keyboard('{Enter}')
    expect(onToggleGate).toHaveBeenCalledWith('svg-flow-canvas', 'wait')
  })

  it('omits the draft badge when the item has no draft number', () => {
    const noDraft = { ...item, draft: 0 }
    const g = renderCard(noDraft, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    expect(g.textContent).not.toContain('#')
  })

  it('falls back to the raw model string when it is not a claude- id', () => {
    const odd = { ...item, model: 'gpt-x' }
    const g = renderCard(odd, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    expect(g.textContent).toContain('gpt-x')
  })

  it('renders an empty model badge when the model is missing', () => {
    const noModel = { ...item, model: undefined }
    const g = renderCard(noModel, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    const badge = g.querySelector('[data-badge="model"]')
    expect(badge.textContent).toBe('')
  })
})

describe('renderCard — model badge / picker', () => {
  it('exposes the model badge as a button with a picker affordance', () => {
    // svg-flow-canvas: model sonnet, no defaultModel ⇒ default
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel: vi.fn() })
    svg.appendChild(g)
    const picker = within(g).getByRole('button', { name: /model/i })
    expect(picker.getAttribute('aria-haspopup')).toBe('listbox')
    expect(picker.getAttribute('data-testid')).toBe(`model-picker-${item.id}`)
  })

  it('marks a model that equals the default as "default"', () => {
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel: vi.fn() })
    svg.appendChild(g)
    const picker = g.querySelector(`[data-testid="model-picker-${item.id}"]`)
    expect(picker.getAttribute('data-override')).toBe('false')
    expect(picker.getAttribute('aria-label').toLowerCase()).toContain('default')
    expect(picker.getAttribute('aria-label').toLowerCase()).toContain('sonnet')
    // a visible default/override marker glyph reads on the card
    expect(g.textContent.toLowerCase()).toContain('default')
  })

  it('marks a model that differs from the default as an "override"', () => {
    const overridden = { ...item, model: 'claude-opus-4-8', defaultModel: 'claude-sonnet-4-6' }
    const g = renderCard(overridden, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel: vi.fn() })
    svg.appendChild(g)
    const picker = g.querySelector(`[data-testid="model-picker-${overridden.id}"]`)
    expect(picker.getAttribute('data-override')).toBe('true')
    expect(picker.getAttribute('aria-label').toLowerCase()).toContain('override')
    expect(picker.getAttribute('aria-label').toLowerCase()).toContain('opus')
    expect(g.textContent.toLowerCase()).toContain('override')
  })

  it('shows the resolved (override) model name in the badge, not the default', () => {
    const overridden = { ...item, model: 'claude-opus-4-8', defaultModel: 'claude-sonnet-4-6' }
    const g = renderCard(overridden, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel: vi.fn() })
    expect(g.textContent).toContain('opus')
  })

  it('emits onPickModel with the item id when the badge is clicked', async () => {
    const user = userEvent.setup()
    const onPickModel = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel })
    svg.appendChild(g)
    await user.click(within(g).getByRole('button', { name: /model/i }))
    expect(onPickModel).toHaveBeenCalledWith(item.id)
  })

  it('the model badge is keyboard-operable (Enter opens the picker)', async () => {
    const user = userEvent.setup()
    const onPickModel = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel })
    svg.appendChild(g)
    const picker = within(g).getByRole('button', { name: /model/i })
    picker.focus()
    await user.keyboard('{Enter}')
    expect(onPickModel).toHaveBeenCalledWith(item.id)
  })

  it('a non-activating key on the model badge emits no intent', async () => {
    const user = userEvent.setup()
    const onPickModel = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel })
    svg.appendChild(g)
    const picker = within(g).getByRole('button', { name: /model/i })
    picker.focus()
    await user.keyboard('{Escape}')
    expect(onPickModel).not.toHaveBeenCalled()
  })

  it('opening the model picker does not start a card drag / pan', async () => {
    const onPickModel = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn(), onPickModel })
    svg.appendChild(g)
    const picker = g.querySelector(`[data-testid="model-picker-${item.id}"]`)
    // pointerdown on the picker must be inside .model-picker so canvas drag-guard skips it
    expect(picker.closest('.model-picker')).toBe(picker)
  })

  it('renders without a model picker handler (toggle-only callers still work)', () => {
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    // the badge falls back to an inert text label when no onPickModel is supplied
    expect(g.querySelector('[data-badge="model"]')).toBeTruthy()
    expect(g.querySelector(`[data-testid="model-picker-${item.id}"]`)).toBeNull()
  })

  it('ignores a non-activating key on the toggle (no intent emitted)', async () => {
    const user = userEvent.setup()
    const onToggleGate = vi.fn()
    const g = renderCard(item, { x: 0, y: 0 }, { onToggleGate })
    svg.appendChild(g)
    const toggle = within(g).getByRole('button', { name: /go|wait/i })
    toggle.focus()
    await user.keyboard('{Escape}')
    expect(onToggleGate).not.toHaveBeenCalled()
  })
})

describe('renderCard — REDO badge (item [30])', () => {
  it('renders a REDO badge when item.redo is true', () => {
    const redoItem = { ...item, redo: true }
    const g = renderCard(redoItem, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    const redoBadge = g.querySelector('[data-badge="redo"]')
    expect(redoBadge).toBeTruthy()
    expect(redoBadge.textContent).toBe('REDO')
  })

  it('the REDO badge has class "badge redo"', () => {
    const redoItem = { ...item, redo: true }
    const g = renderCard(redoItem, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    const redoBadge = g.querySelector('[data-badge="redo"]')
    expect(redoBadge.classList.contains('badge')).toBe(true)
    expect(redoBadge.classList.contains('redo')).toBe(true)
  })

  it('does NOT render a REDO badge when item.redo is false', () => {
    const noRedo = { ...item, redo: false }
    const g = renderCard(noRedo, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    expect(g.querySelector('[data-badge="redo"]')).toBeNull()
  })

  it('does NOT render a REDO badge when item.redo is undefined', () => {
    const noRedo = { ...item }
    delete noRedo.redo
    const g = renderCard(noRedo, { x: 0, y: 0 }, { onToggleGate: vi.fn() })
    svg.appendChild(g)
    expect(g.querySelector('[data-badge="redo"]')).toBeNull()
  })
})
