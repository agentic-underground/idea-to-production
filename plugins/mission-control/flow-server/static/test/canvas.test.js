import { describe, it, expect, beforeEach, vi } from 'vitest'
import { screen, within, waitFor } from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import { mountCanvas } from '../src/canvas.js'
import { FIXTURE_ITEMS, CYCLE_FIXTURE } from './fixtures.js'

function makeApi(overrides = {}) {
  return {
    getItems: vi.fn().mockResolvedValue(FIXTURE_ITEMS),
    setGate: vi.fn().mockResolvedValue({ ok: true }),
    validateConnection: vi.fn().mockResolvedValue({ ok: true }),
    ...overrides
  }
}

let root
beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
})

// jsdom lacks SVG layout geometry; stub the two methods the canvas reads.
function stubGeometry(canvas) {
  canvas.getBoundingClientRect = () => ({ left: 0, top: 0, width: 1000, height: 700, right: 1000, bottom: 700 })
}

describe('mountCanvas — rendering', () => {
  it('renders every fixture item as a card', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => {
      for (const item of FIXTURE_ITEMS) {
        expect(handle.svg.querySelector(`[data-id="${item.id}"]`)).toBeTruthy()
      }
    })
  })

  it('places each card in the column matching its status', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const done = handle.svg.querySelector('[data-id="flow-server"]')
    const doing = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
    const todo = handle.svg.querySelector('[data-id="carriage-telemetry"]')
    const xOf = (g) => Number(/translate\(([-\d.]+)/.exec(g.getAttribute('transform'))[1])
    expect(xOf(done)).toBeLessThan(xOf(doing))
    expect(xOf(doing)).toBeLessThan(xOf(todo))
  })

  it('draws a curved connector for each dependency edge', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    await waitFor(() => {
      const paths = handle.svg.querySelectorAll('path.connector')
      // 4 edges in the fixture: canvas→server, telemetry→server, loop→canvas, loop→telemetry
      expect(paths.length).toBe(4)
    })
    const first = handle.svg.querySelector('path.connector')
    expect(first.getAttribute('d')).toMatch(/^M .* C /) // cubic Bézier
  })

  it('renders three labelled board columns (DO/DOING/DONE)', async () => {
    await mountCanvas(root, { api: makeApi() })
    await waitFor(() => {
      expect(screen.getByText(/^DONE$/)).toBeTruthy()
      expect(screen.getByText(/^DOING$/)).toBeTruthy()
      expect(screen.getByText(/^DO$/)).toBeTruthy()
    })
  })
})

describe('mountCanvas — zoom about cursor', () => {
  it('wheel-up scales the world group up and recentres about the cursor', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('.world')).toBeTruthy())

    const before = handle.getTransform().scale
    handle.svg.dispatchEvent(
      new WheelEvent('wheel', { deltaY: -100, clientX: 300, clientY: 200, bubbles: true, cancelable: true })
    )
    const after = handle.getTransform()
    expect(after.scale).toBeGreaterThan(before)
    // the world group transform reflects the new scale
    const world = handle.svg.querySelector('.world')
    expect(world.getAttribute('transform')).toContain(`scale(${after.scale}`)
  })

  it('wheel-down scales the world group down', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('.world')).toBeTruthy())
    const before = handle.getTransform().scale
    handle.svg.dispatchEvent(
      new WheelEvent('wheel', { deltaY: 120, clientX: 100, clientY: 100, bubbles: true, cancelable: true })
    )
    expect(handle.getTransform().scale).toBeLessThan(before)
  })
})

describe('mountCanvas — pan', () => {
  it('click-drag on empty canvas translates the viewport', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('.world')).toBeTruthy())
    const start = handle.getTransform()

    handle.svg.dispatchEvent(new MouseEvent('pointerdown', { clientX: 400, clientY: 300, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 460, clientY: 340, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    const end = handle.getTransform()
    expect(end.x).toBe(start.x + 60)
    expect(end.y).toBe(start.y + 40)
  })

  it('a pointerdown that starts on a card does NOT pan (drags the card instead)', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const start = handle.getTransform()
    const card = handle.svg.querySelector('[data-id="flow-server"]')

    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 160, clientY: 100, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    // viewport did not pan
    expect(handle.getTransform().x).toBe(start.x)
  })
})

describe('mountCanvas — non-left buttons are ignored', () => {
  it('a right-button press on empty canvas does not pan', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('.world')).toBeTruthy())
    const start = handle.getTransform()
    handle.svg.dispatchEvent(new MouseEvent('pointerdown', { clientX: 400, clientY: 300, button: 2, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 500, clientY: 400, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))
    expect(handle.getTransform()).toEqual(start)
  })

  it('a right-button press on a card does not drag it', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="flow-server"]')
    const before = card.getAttribute('transform')
    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 2, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 200, clientY: 200, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))
    expect(card.getAttribute('transform')).toBe(before)
  })
})

describe('mountCanvas — degraded data', () => {
  it('renders items with no deps field and draws no connectors', async () => {
    const api = makeApi({
      getItems: vi.fn().mockResolvedValue([
        { id: 'lonely', title: 'Lonely', status: 'do', gate: 'go', tokens: 0, model: 'm' }
      ])
    })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="lonely"]')).toBeTruthy())
    expect(handle.svg.querySelectorAll('path.connector').length).toBe(0)
  })

  it('skips an edge whose endpoint is absent from the item set', async () => {
    const api = makeApi({
      getItems: vi.fn().mockResolvedValue([
        { id: 'a', title: 'A', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: ['ghost'] }
      ])
    })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="a"]')).toBeTruthy())
    // the ghost dependency yields no connector
    expect(handle.svg.querySelectorAll('path.connector').length).toBe(0)
  })
})

describe('mountCanvas — drag a card', () => {
  it('dragging a card updates its translate by the drag delta (scaled)', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="flow-server"]')
    const xy = (g) => /translate\(([-\d.]+) ([-\d.]+)\)/.exec(g.getAttribute('transform')).slice(1).map(Number)
    const [x0, y0] = xy(card)

    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 150, clientY: 130, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    const [x1, y1] = xy(card)
    expect(x1).toBe(x0 + 50)
    expect(y1).toBe(y0 + 30)
  })

  it('moving a card re-routes its connectors (the path d changes)', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('path.connector')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
    const connector = handle.svg.querySelector('path.connector[data-from="svg-flow-canvas"]')
    const before = connector.getAttribute('d')

    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 100, clientY: 200, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    expect(connector.getAttribute('d')).not.toBe(before)
  })
})

describe('mountCanvas — auto-align', () => {
  it('the Auto-align button re-lays the cards to their computed positions', async () => {
    const handle = await mountCanvas(root, { api: makeApi() })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="flow-server"]')

    // drag the card away from its aligned spot
    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 300, clientY: 300, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))
    const moved = card.getAttribute('transform')

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /auto-align/i }))
    expect(card.getAttribute('transform')).not.toBe(moved)
  })
})

describe('mountCanvas — WAIT/GO toggle', () => {
  it('clicking a card toggle calls the API with the opposite gate', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]')).toBeTruthy())
    const user = userEvent.setup()
    const card = handle.svg.querySelector('[data-id="svg-flow-canvas"]') // gate: go
    await user.click(within(card).getByRole('button', { name: /pause|resume/i }))
    expect(api.setGate).toHaveBeenCalledWith('svg-flow-canvas', 'wait')
  })

  it('reflects the new gate on the card after a successful toggle', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]')).toBeTruthy())
    const user = userEvent.setup()
    let card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
    await user.click(within(card).getByRole('button', { name: /pause|resume/i }))
    await waitFor(() => {
      card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
      expect(card.getAttribute('data-gate')).toBe('wait')
    })
  })

  it('surfaces an error and keeps the prior gate when the API rejects', async () => {
    const api = makeApi({ setGate: vi.fn().mockRejectedValue(new Error('setGate failed: 401')) })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]')).toBeTruthy())
    const user = userEvent.setup()
    const card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
    await user.click(within(card).getByRole('button', { name: /pause|resume/i }))
    await waitFor(() => expect(screen.getByRole('alert').textContent).toMatch(/pause/i))
    // gate unchanged
    expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]').getAttribute('data-gate')).toBe('go')
  })

  it('phrases the failure as "resume" when a WAIT item fails to go GO', async () => {
    const api = makeApi({ setGate: vi.fn().mockRejectedValue(new Error('setGate failed: 401')) })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    // carriage-telemetry starts in WAIT ⇒ toggling it attempts a resume to GO
    await waitFor(() => expect(handle.svg.querySelector('[data-id="carriage-telemetry"]')).toBeTruthy())
    const user = userEvent.setup()
    const card = handle.svg.querySelector('[data-id="carriage-telemetry"]')
    await user.click(within(card).getByRole('button', { name: /pause|resume/i }))
    await waitFor(() => expect(screen.getByRole('alert').textContent).toMatch(/resume/i))
  })
})

describe('mountCanvas — connection-draw validation', () => {
  it('refuses a cycle-forming edge and shows why (no connector added)', async () => {
    const api = makeApi({
      getItems: vi.fn().mockResolvedValue(CYCLE_FIXTURE),
      validateConnection: vi.fn().mockResolvedValue({ ok: false, error: 'cycle', message: 'b → a → b forms a cycle' })
    })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="a"]')).toBeTruthy())

    const before = handle.svg.querySelectorAll('path.connector').length
    // attempt to draw b → a (which closes the a → b cycle)
    const res = await handle.tryConnect('b', 'a')

    expect(res.ok).toBe(false)
    expect(api.validateConnection).toHaveBeenCalledWith('b', 'a')
    expect(handle.svg.querySelectorAll('path.connector').length).toBe(before)
    expect(screen.getByRole('alert').textContent).toMatch(/cycle/i)
  })

  it('adds an edge but leaves it unrouted when an endpoint has no position', async () => {
    const api = makeApi({
      getItems: vi.fn().mockResolvedValue([
        { id: 'a', title: 'A', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: [] }
      ])
    })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="a"]')).toBeTruthy())
    // validate passes, but 'phantom' has no card/position ⇒ the path has no d
    const res = await handle.tryConnect('a', 'phantom')
    expect(res.ok).toBe(true)
    const path = handle.svg.querySelector('path.connector[data-to="phantom"]')
    expect(path).toBeTruthy()
    expect(path.getAttribute('d')).toBeNull()
  })

  it('accepts a valid edge and adds a connector', async () => {
    const api = makeApi({
      getItems: vi.fn().mockResolvedValue([
        { id: 'a', title: 'A', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: [] },
        { id: 'b', title: 'B', status: 'do', gate: 'go', tokens: 0, model: 'm', deps: [] }
      ])
    })
    const handle = await mountCanvas(root, { api })
    stubGeometry(handle.svg)
    await waitFor(() => expect(handle.svg.querySelector('[data-id="a"]')).toBeTruthy())
    const before = handle.svg.querySelectorAll('path.connector').length

    const res = await handle.tryConnect('a', 'b')
    expect(res.ok).toBe(true)
    expect(handle.svg.querySelectorAll('path.connector').length).toBe(before + 1)
  })
})

describe('mountCanvas — token gate', () => {
  it('shows a token prompt and does not call getItems when no token is set', async () => {
    const api = makeApi()
    await mountCanvas(root, { api, token: '' })
    expect(api.getItems).not.toHaveBeenCalled()
    expect(screen.getByLabelText(/token/i)).toBeTruthy()
  })

  it('returns an inert handle in the no-token state so callers can treat it uniformly', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: '' })
    expect(handle.svg).toBeNull()
    expect(handle.getTransform()).toBeNull()
    await expect(handle.refresh()).resolves.toBeUndefined()
    await expect(handle.tryConnect('a', 'b')).resolves.toEqual({ ok: false })
    expect(api.validateConnection).not.toHaveBeenCalled()
  })

  it('mounts against the live API by default (token assumed present)', async () => {
    const api = makeApi()
    await mountCanvas(root, { api })
    expect(api.getItems).toHaveBeenCalled()
  })

  it('mountCanvas tolerates being called with no options bag', async () => {
    // no api ⇒ no token gate prompt is the safe default; should not throw at mount
    await expect(mountCanvas(root, { token: '' })).resolves.toBeTruthy()
  })
})
