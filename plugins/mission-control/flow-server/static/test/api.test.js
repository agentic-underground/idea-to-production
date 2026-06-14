import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import {
  TOKEN_KEY,
  resolveToken,
  saveToken,
  createApi
} from '../src/api.js'

beforeEach(() => {
  localStorage.clear()
})

describe('resolveToken', () => {
  it('prefers the ?token= query param and persists it', () => {
    const t = resolveToken('?token=abc123')
    expect(t).toBe('abc123')
    expect(localStorage.getItem(TOKEN_KEY)).toBe('abc123')
  })

  it('falls back to localStorage when no query token is present', () => {
    localStorage.setItem(TOKEN_KEY, 'stored-tok')
    expect(resolveToken('')).toBe('stored-tok')
  })

  it('returns the empty string when neither source has a token', () => {
    expect(resolveToken('?other=1')).toBe('')
  })

  it('ignores an empty query token value and keeps the stored one', () => {
    localStorage.setItem(TOKEN_KEY, 'stored-tok')
    expect(resolveToken('?token=')).toBe('stored-tok')
  })
})

describe('saveToken', () => {
  it('writes the token to localStorage', () => {
    saveToken('xyz')
    expect(localStorage.getItem(TOKEN_KEY)).toBe('xyz')
  })

  it('clears the stored token when given an empty value', () => {
    localStorage.setItem(TOKEN_KEY, 'old')
    saveToken('')
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
  })
})

describe('createApi', () => {
  let fetchMock
  beforeEach(() => {
    fetchMock = vi.fn()
    vi.stubGlobal('fetch', fetchMock)
  })
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  const ok = (body) => ({
    ok: true,
    status: 200,
    json: async () => body
  })
  const fail = (status, body) => ({
    ok: false,
    status,
    json: async () => body
  })

  it('getItems GETs /api/items with the bearer token and returns the array', async () => {
    fetchMock.mockResolvedValue(ok([{ id: 'a' }]))
    const api = createApi('tok')
    const items = await api.getItems()
    expect(items).toEqual([{ id: 'a' }])
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/items')
    expect(opts.headers.Authorization).toBe('Bearer tok')
  })

  it('setGate POSTs the gate body to the item gate endpoint', async () => {
    fetchMock.mockResolvedValue(ok({ ok: true }))
    const api = createApi('tok')
    await api.setGate('svg-flow-canvas', 'wait')
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/items/svg-flow-canvas/gate')
    expect(opts.method).toBe('POST')
    expect(JSON.parse(opts.body)).toEqual({ gate: 'wait' })
    expect(opts.headers['Content-Type']).toBe('application/json')
  })

  it('validateConnection POSTs {from,to} and resolves ok:true on 200', async () => {
    fetchMock.mockResolvedValue(ok({ ok: true }))
    const api = createApi('tok')
    const res = await api.validateConnection('a', 'b')
    expect(res).toEqual({ ok: true })
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/connection/validate')
    expect(JSON.parse(opts.body)).toEqual({ from: 'a', to: 'b' })
  })

  it('validateConnection resolves {ok:false, reason} on a typed error response', async () => {
    fetchMock.mockResolvedValue(
      fail(409, { error: 'cycle', message: 'a → b → a forms a cycle' })
    )
    const api = createApi('tok')
    const res = await api.validateConnection('a', 'b')
    expect(res.ok).toBe(false)
    expect(res.error).toBe('cycle')
    expect(res.message).toMatch(/cycle/)
  })

  it('setModel POSTs the model body to the item model endpoint', async () => {
    fetchMock.mockResolvedValue(ok({ ok: true }))
    const api = createApi('tok')
    await api.setModel('svg-flow-canvas', 'claude-opus-4-8')
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/items/svg-flow-canvas/model')
    expect(opts.method).toBe('POST')
    expect(JSON.parse(opts.body)).toEqual({ model: 'claude-opus-4-8' })
    expect(opts.headers.Authorization).toBe('Bearer tok')
  })

  it('setModel sends model:null to clear an override (revert to default)', async () => {
    fetchMock.mockResolvedValue(ok({ ok: true }))
    const api = createApi('tok')
    await api.setModel('svg-flow-canvas', null)
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/items/svg-flow-canvas/model')
    expect(JSON.parse(opts.body)).toEqual({ model: null })
  })

  it('setModel rejects (throws) on a non-ok response so callers can surface it', async () => {
    fetchMock.mockResolvedValue(fail(409, { error: 'not_allowed' }))
    const api = createApi('tok')
    await expect(api.setModel('a', 'claude-evil-9')).rejects.toThrow(/409/)
  })

  it('setGate rejects (throws) on a non-ok response so callers can surface it', async () => {
    fetchMock.mockResolvedValue(fail(401, { error: 'unauthorized' }))
    const api = createApi('bad')
    await expect(api.setGate('a', 'go')).rejects.toThrow(/401/)
  })

  it('getItems rejects (throws) on a non-ok response', async () => {
    fetchMock.mockResolvedValue(fail(401, { error: 'unauthorized' }))
    const api = createApi('bad')
    await expect(api.getItems()).rejects.toThrow(/401/)
  })

  it('annotate POSTs the comment text to the item annotate endpoint', async () => {
    fetchMock.mockResolvedValue(ok({ ok: true }))
    const api = createApi('tok')
    await api.annotate('svg-flow-canvas', 'ship the picker first')
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/items/svg-flow-canvas/annotate')
    expect(opts.method).toBe('POST')
    expect(JSON.parse(opts.body)).toEqual({ text: 'ship the picker first' })
    expect(opts.headers.Authorization).toBe('Bearer tok')
  })

  it('annotate rejects (throws) on a non-ok response so callers can surface it', async () => {
    fetchMock.mockResolvedValue(fail(401, { error: 'unauthorized' }))
    const api = createApi('bad')
    await expect(api.annotate('a', 'note')).rejects.toThrow(/401/)
  })

  it('rewrite POSTs the comment and returns the new {draft} number', async () => {
    fetchMock.mockResolvedValue(ok({ draft: 4 }))
    const api = createApi('tok')
    const res = await api.rewrite('svg-flow-canvas', 'redo the whole plan')
    expect(res).toEqual({ draft: 4 })
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/items/svg-flow-canvas/rewrite')
    expect(opts.method).toBe('POST')
    expect(JSON.parse(opts.body)).toEqual({ comment: 'redo the whole plan' })
  })

  it('rewrite rejects (throws) on a non-ok response so callers can surface it', async () => {
    fetchMock.mockResolvedValue(fail(500, { error: 'agent_unavailable' }))
    const api = createApi('bad')
    await expect(api.rewrite('a', 'note')).rejects.toThrow(/500/)
  })

  it('getEvents GETs /api/events with the bearer token and returns the array', async () => {
    fetchMock.mockResolvedValue(ok([{ kind: 'sys_msg', text: 'hello' }]))
    const api = createApi('tok')
    const events = await api.getEvents()
    expect(events).toEqual([{ kind: 'sys_msg', text: 'hello' }])
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/events')
    expect(opts.headers.Authorization).toBe('Bearer tok')
  })

  it('getEvents rejects (throws) on a non-ok response so the feed can degrade', async () => {
    fetchMock.mockResolvedValue(fail(503, { error: 'unavailable' }))
    const api = createApi('bad')
    await expect(api.getEvents()).rejects.toThrow(/503/)
  })
})
