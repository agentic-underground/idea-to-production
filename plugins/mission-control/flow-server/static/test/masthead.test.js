import { describe, it, expect, beforeEach, vi } from 'vitest'
import { screen, within, waitFor } from '@testing-library/dom'
import { mountMasthead } from '../src/masthead.js'

const items = (...statuses) => statuses.map((status, i) => ({ id: `i${i}`, title: `Item ${i}`, status }))

function makeApi(overrides = {}) {
  return {
    getEvents: vi.fn().mockResolvedValue([]),
    ...overrides
  }
}

let root
beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
})

describe('mountMasthead — progress bar', () => {
  it('renders a progressbar exposing the DONE percent to assistive tech', async () => {
    await mountMasthead(root, { items: items('done', 'do', 'do', 'do'), api: makeApi() })
    const bar = screen.getByRole('progressbar', { name: /progress/i })
    expect(bar.getAttribute('aria-valuenow')).toBe('25')
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('100')
  })

  it('reads 0 with no items done', async () => {
    await mountMasthead(root, { items: items('do', 'doing'), api: makeApi() })
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')
  })

  it('reads 100 when every item is done', async () => {
    await mountMasthead(root, { items: items('done', 'done'), api: makeApi() })
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('100')
  })

  it('the fill width tracks the DONE percent', async () => {
    const { masthead } = await mountMasthead(root, { items: items('done', 'do', 'do', 'do'), api: makeApi() })
    const fill = masthead.querySelector('.masthead-fill')
    expect(fill.style.width).toBe('25%')
  })

  it('shows a numeric percent label so completion is not conveyed by colour alone', async () => {
    const { masthead } = await mountMasthead(root, { items: items('done', 'done', 'do', 'do'), api: makeApi() })
    expect(masthead.textContent).toContain('50%')
  })
})

describe('mountMasthead — pac-man gauge', () => {
  it('renders a labelled pac-man gauge reflecting the DONE fraction', async () => {
    const { masthead } = await mountMasthead(root, { items: items('done', 'do'), api: makeApi() })
    const gauge = within(masthead).getByRole('img', { name: /completion/i })
    expect(gauge.getAttribute('data-percent')).toBe('50')
  })

  it('the gauge reads 100 and the "run & observe" state at full completion', async () => {
    const { masthead } = await mountMasthead(root, { items: items('done', 'done'), api: makeApi() })
    const gauge = within(masthead).getByRole('img', { name: /completion/i })
    expect(gauge.getAttribute('data-percent')).toBe('100')
    expect(masthead.getAttribute('data-complete')).toBe('true')
    expect(masthead.textContent.toLowerCase()).toMatch(/run.*observe/)
  })

  it('does not show the "run & observe" state below 100%', async () => {
    const { masthead } = await mountMasthead(root, { items: items('done', 'do'), api: makeApi() })
    expect(masthead.getAttribute('data-complete')).toBe('false')
    expect(masthead.textContent.toLowerCase()).not.toMatch(/run.*observe/)
  })

  it('an empty board is not complete (nothing to observe yet)', async () => {
    const { masthead } = await mountMasthead(root, { items: [], api: makeApi() })
    expect(masthead.getAttribute('data-complete')).toBe('false')
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')
  })
})

describe('mountMasthead — system-message feed', () => {
  it('renders sys_msg events newest-first, ignoring other event kinds', async () => {
    const api = makeApi({
      getEvents: vi.fn().mockResolvedValue([
        { kind: 'sys_msg', text: 'oldest' },
        { kind: 'token_spend', text: 'NOISE' },
        { kind: 'sys_msg', text: 'newest' }
      ])
    })
    await mountMasthead(root, { items: items('do'), api })
    const feed = await screen.findByRole('log', { name: /system messages/i })
    const entries = within(feed).getAllByRole('listitem')
    expect(entries.map((e) => e.textContent)).toEqual(['newest', 'oldest'])
    expect(feed.textContent).not.toContain('NOISE')
  })

  it('shows an empty-feed affordance when there are no system messages', async () => {
    const api = makeApi({ getEvents: vi.fn().mockResolvedValue([{ kind: 'token_spend', text: 'x' }]) })
    await mountMasthead(root, { items: items('do'), api })
    const feed = await screen.findByRole('log', { name: /system messages/i })
    expect(within(feed).queryAllByRole('listitem').length).toBe(0)
    expect(feed.textContent.toLowerCase()).toMatch(/no .*messages|nothing/i)
  })

  it('degrades gracefully to an empty feed when getEvents rejects (no crash)', async () => {
    const api = makeApi({ getEvents: vi.fn().mockRejectedValue(new Error('getEvents failed: 503')) })
    await mountMasthead(root, { items: items('do'), api })
    const feed = await screen.findByRole('log', { name: /system messages/i })
    expect(within(feed).queryAllByRole('listitem').length).toBe(0)
    // the rest of the masthead still rendered
    expect(screen.getByRole('progressbar')).toBeTruthy()
  })

  it('degrades gracefully when no api is supplied (empty feed)', async () => {
    await mountMasthead(root, { items: items('do') })
    const feed = await screen.findByRole('log', { name: /system messages/i })
    expect(within(feed).queryAllByRole('listitem').length).toBe(0)
  })

  it('refresh() re-reads items and events and updates the gauges + feed', async () => {
    const api = makeApi({
      getEvents: vi.fn()
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ kind: 'sys_msg', text: 'fresh news' }])
    })
    const handle = await mountMasthead(root, { items: items('do', 'do'), api })
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')

    await handle.refresh(items('done', 'do'))
    await waitFor(() => expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('50'))
    const feed = screen.getByRole('log', { name: /system messages/i })
    await waitFor(() => expect(within(feed).getByText('fresh news')).toBeTruthy())
  })
})
