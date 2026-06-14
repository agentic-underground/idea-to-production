// ws.test.js — WebSocket subscription behaviour wired in canvas.js:
// URL construction, StatusPosted message handling, reconnect-on-close, disconnect.
//
// @front-end
// intent: pin every observable WS behaviour in isolation using a stubbed global
//         WebSocket and mocked timers so the canvas WS path is at 100% coverage
// customer: solo-builder (the governance UI's developer-as-operator)

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { waitFor } from '@testing-library/dom'
import { mountCanvas } from '../src/canvas.js'
import { FIXTURE_ITEMS } from './fixtures.js'

// ---------------------------------------------------------------------------
// MockWebSocket — a minimal stand-in for the browser WebSocket API.
// The test controls what the "server" sends and whether the socket closes.
// ---------------------------------------------------------------------------
class MockWebSocket {
  constructor(url) {
    this.url = url
    this.readyState = MockWebSocket.OPEN
    this.onmessage = null
    this.onclose = null
    this.onerror = null
    MockWebSocket.instances.push(this)
  }

  send(data) {
    this._sent = (this._sent ?? []).concat(data)
  }

  close() {
    this.readyState = MockWebSocket.CLOSED
    // Do NOT fire onclose here — the canvas sets ws.onclose = null before
    // calling close() in disconnect(), so we honour that by just flipping state.
  }

  /** Simulate an incoming server message. */
  receive(data) {
    this.onmessage?.({ data: typeof data === 'string' ? data : JSON.stringify(data) })
  }

  /** Simulate the connection closing (e.g. server drops). */
  simulateClose() {
    this.readyState = MockWebSocket.CLOSED
    this.onclose?.({ code: 1006 })
  }

  /** Simulate a socket-level error. */
  simulateError() {
    this.onerror?.({ type: 'error' })
  }
}
MockWebSocket.OPEN = 1
MockWebSocket.CLOSED = 3
MockWebSocket.instances = []

function makeApi(overrides = {}) {
  return {
    getItems: vi.fn().mockResolvedValue(FIXTURE_ITEMS),
    setGate: vi.fn().mockResolvedValue({ ok: true }),
    setModel: vi.fn().mockResolvedValue({ ok: true }),
    validateConnection: vi.fn().mockResolvedValue({ ok: true }),
    postStatus: vi.fn().mockResolvedValue({ ok: true }),
    ...overrides
  }
}

let root

beforeEach(() => {
  MockWebSocket.instances = []
  vi.stubGlobal('WebSocket', MockWebSocket)
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
  vi.useFakeTimers()
})

afterEach(() => {
  vi.unstubAllGlobals()
  vi.useRealTimers()
})

// ---------------------------------------------------------------------------
describe('WS — URL construction', () => {
  it('constructs ws:// URL when protocol is http:', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost:8080' })
    await mountCanvas(root, { api: makeApi(), token: 'tok-123' })
    expect(MockWebSocket.instances.length).toBeGreaterThan(0)
    expect(MockWebSocket.instances[0].url).toBe('ws://localhost:8080/ws?token=tok-123')
  })

  it('constructs wss:// URL when protocol is https:', async () => {
    vi.stubGlobal('location', { protocol: 'https:', host: 'app.example.com' })
    await mountCanvas(root, { api: makeApi(), token: 'secret' })
    expect(MockWebSocket.instances[0].url).toBe('wss://app.example.com/ws?token=secret')
  })

  it('does not open a WebSocket when no token is set', async () => {
    await mountCanvas(root, { api: makeApi(), token: '' })
    expect(MockWebSocket.instances.length).toBe(0)
  })
})

// ---------------------------------------------------------------------------
describe('WS — StatusPosted message handling', () => {
  it('updates a card data-status when StatusPosted is received', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })

    await waitFor(() => expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]')).toBeTruthy())
    const ws = MockWebSocket.instances[0]
    ws.receive({ kind: 'status_posted', id: 'svg-flow-canvas', status: 'done' })

    await waitFor(() => {
      const card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
      expect(card.getAttribute('data-status')).toBe('done')
    })
    // No re-fetch
    expect(api.getItems).toHaveBeenCalledTimes(1)
  })

  it('ignores a StatusPosted message for an unknown id', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]')).toBeTruthy())
    const ws = MockWebSocket.instances[0]

    // Should not throw
    expect(() => ws.receive({ kind: 'status_posted', id: 'ghost-item', status: 'done' })).not.toThrow()
    // Other cards unaffected
    const card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
    expect(card.getAttribute('data-status')).toBe('doing')
  })

  it('ignores messages with an unrecognised kind', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const ws = MockWebSocket.instances[0]
    expect(() => ws.receive({ kind: 'gate_set', id: 'flow-server', gate: 'wait' })).not.toThrow()
    expect(api.getItems).toHaveBeenCalledTimes(1)
  })

  it('re-renders the card badge to the new status after StatusPosted', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(handle.svg.querySelector('[data-id="svg-flow-canvas"]')).toBeTruthy())
    const ws = MockWebSocket.instances[0]
    ws.receive({ kind: 'status_posted', id: 'svg-flow-canvas', status: 'done' })
    await waitFor(() => {
      const card = handle.svg.querySelector('[data-id="svg-flow-canvas"]')
      // The status badge text should now show the new status
      expect(card.textContent).toMatch(/done/i)
    })
  })
})

// ---------------------------------------------------------------------------
describe('WS — reconnect on close/error', () => {
  it('calls refresh() after 2000ms when the WS closes', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(MockWebSocket.instances.length).toBe(1))
    const ws = MockWebSocket.instances[0]

    const callsBefore = api.getItems.mock.calls.length
    ws.simulateClose()

    // Before the timeout, no re-fetch
    expect(api.getItems.mock.calls.length).toBe(callsBefore)
    // Advance 2000ms
    await vi.advanceTimersByTimeAsync(2000)
    // After 2s, a new getItems call is made
    expect(api.getItems.mock.calls.length).toBeGreaterThan(callsBefore)
  })

  it('calls refresh() after 2000ms when the WS errors', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(MockWebSocket.instances.length).toBe(1))
    const ws = MockWebSocket.instances[0]

    const callsBefore = api.getItems.mock.calls.length
    ws.simulateError()
    await vi.advanceTimersByTimeAsync(2000)
    expect(api.getItems.mock.calls.length).toBeGreaterThan(callsBefore)
  })
})

// ---------------------------------------------------------------------------
describe('WS — disconnect()', () => {
  it('handle.disconnect() closes the WebSocket', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(MockWebSocket.instances.length).toBe(1))
    const ws = MockWebSocket.instances[0]

    handle.disconnect()
    expect(ws.readyState).toBe(MockWebSocket.CLOSED)
  })

  it('disconnect() prevents the reconnect loop from firing', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(MockWebSocket.instances.length).toBe(1))
    const ws = MockWebSocket.instances[0]

    handle.disconnect()
    const callsBefore = api.getItems.mock.calls.length

    // Even if close fires after disconnect(), no reconnect happens
    ws.onclose?.({ code: 1000 })
    await vi.advanceTimersByTimeAsync(5000)
    expect(api.getItems.mock.calls.length).toBe(callsBefore)
  })

  it('disconnect() clears a pending reconnect timer', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(MockWebSocket.instances.length).toBe(1))
    const ws = MockWebSocket.instances[0]

    // Trigger the reconnect timer by simulating a close
    ws.simulateClose()
    // Timer is now pending — disconnect should cancel it
    const callsBefore = api.getItems.mock.calls.length
    handle.disconnect()
    // Advance past the 2s timer; getItems should NOT be called because the timer was cleared
    await vi.advanceTimersByTimeAsync(3000)
    expect(api.getItems.mock.calls.length).toBe(callsBefore)
  })
})

// ---------------------------------------------------------------------------
describe('WS — message JSON parse error is swallowed', () => {
  it('does not throw when a malformed (non-JSON) message is received', async () => {
    vi.stubGlobal('location', { protocol: 'http:', host: 'localhost' })
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const ws = MockWebSocket.instances[0]
    expect(() => ws.onmessage?.({ data: 'not-json!!!' })).not.toThrow()
  })
})
