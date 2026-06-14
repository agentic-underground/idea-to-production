import { describe, it, expect, beforeEach, vi } from 'vitest'
import { screen, within, waitFor } from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import { mountCommentPanel } from '../src/comment.js'
import { FIXTURE_ITEMS } from './fixtures.js'

// comment-rewrite-loop fixture: status do, gate go, opus, draft 0
const item = () => ({ ...FIXTURE_ITEMS[3] })

function makeApi(overrides = {}) {
  return {
    setGate: vi.fn().mockResolvedValue({ ok: true }),
    annotate: vi.fn().mockResolvedValue({ ok: true }),
    rewrite: vi.fn().mockResolvedValue({ draft: 1 }),
    ...overrides
  }
}

let root
beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
})

describe('mountCommentPanel — structure', () => {
  it('renders an accessible, labelled comment textbox for the item', () => {
    mountCommentPanel(root, { item: item(), api: makeApi() })
    const box = screen.getByRole('textbox', { name: /comment/i })
    expect(box).toBeTruthy()
    expect(box.tagName).toBe('TEXTAREA')
  })

  it('renders a Rewrite button', () => {
    mountCommentPanel(root, { item: item(), api: makeApi() })
    expect(screen.getByRole('button', { name: /rewrite/i })).toBeTruthy()
  })

  it('starts un-paused (not highlighted) before any typing', () => {
    const { panel } = mountCommentPanel(root, { item: item(), api: makeApi() })
    expect(panel.getAttribute('data-paused')).toBe('false')
    expect(panel.classList.contains('is-paused')).toBe(false)
  })

  it('shows no draft badge for an item with no draft field at all', () => {
    const noDraft = { ...item() }
    delete noDraft.draft
    const { panel } = mountCommentPanel(root, { item: noDraft, api: makeApi() })
    expect(within(panel).queryByText(/^#/)).toBeNull()
  })
})

describe('mountCommentPanel — typing pauses the item', () => {
  it('pausing on first keystroke calls setGate(id,"wait") and highlights as paused', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    const id = item().id
    const { panel } = mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('n')
    await waitFor(() => expect(api.setGate).toHaveBeenCalledWith(id, 'wait'))
    expect(panel.getAttribute('data-paused')).toBe('true')
    expect(panel.classList.contains('is-paused')).toBe(true)
  })

  it('does not re-pause on every subsequent keystroke (pauses once)', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('hello')
    await waitFor(() => expect(api.setGate).toHaveBeenCalledTimes(1))
    expect(api.setGate).toHaveBeenCalledWith(item().id, 'wait')
  })

  it('emits onPaused(true) up so the card can reflect the pause', async () => {
    const user = userEvent.setup()
    const onPaused = vi.fn()
    mountCommentPanel(root, { item: item(), api: makeApi(), onPaused })
    await user.click(screen.getByRole('textbox', { name: /comment/i }))
    await user.keyboard('x')
    await waitFor(() => expect(onPaused).toHaveBeenCalledWith(true))
  })

  it('an item already paused (gate wait) does not re-call setGate when typing begins', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    const paused = { ...item(), gate: 'wait' }
    const { panel } = mountCommentPanel(root, { item: paused, api })
    // already paused ⇒ panel reads paused from the start
    expect(panel.getAttribute('data-paused')).toBe('true')
    await user.click(screen.getByRole('textbox', { name: /comment/i }))
    await user.keyboard('y')
    // typing should NOT redundantly pause an already-paused item
    expect(api.setGate).not.toHaveBeenCalled()
  })

  it('surfaces an error and stays usable if the pause call fails', async () => {
    const user = userEvent.setup()
    const api = makeApi({ setGate: vi.fn().mockRejectedValue(new Error('setGate failed: 401')) })
    mountCommentPanel(root, { item: item(), api })
    await user.click(screen.getByRole('textbox', { name: /comment/i }))
    await user.keyboard('z')
    await waitFor(() => expect(screen.getByRole('alert').textContent).toMatch(/pause/i))
  })
})

describe('mountCommentPanel — Ctrl-Enter annotates + unpauses + clears', () => {
  it('Ctrl-Enter calls setGate(id,"go"), annotate(id,text), and clears the input', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    const id = item().id
    const { panel } = mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('do the picker first')
    await user.keyboard('{Control>}{Enter}{/Control}')
    await waitFor(() => expect(api.annotate).toHaveBeenCalledWith(id, 'do the picker first'))
    expect(api.setGate).toHaveBeenCalledWith(id, 'go')
    expect(box.value).toBe('')
    await waitFor(() => expect(panel.getAttribute('data-paused')).toBe('false'))
  })

  it('emits onPaused(false) up when Ctrl-Enter unpauses', async () => {
    const user = userEvent.setup()
    const onPaused = vi.fn()
    mountCommentPanel(root, { item: item(), api: makeApi(), onPaused })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('note{Control>}{Enter}{/Control}')
    await waitFor(() => expect(onPaused).toHaveBeenLastCalledWith(false))
  })

  it('Ctrl-Enter with an empty comment does nothing (no annotate, no unpause)', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    box.focus()
    await user.keyboard('{Control>}{Enter}{/Control}')
    expect(api.annotate).not.toHaveBeenCalled()
    expect(api.setGate).not.toHaveBeenCalled()
  })

  it('a plain Enter (no Ctrl) does not annotate — it is a newline in the comment', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('line one{Enter}line two')
    expect(api.annotate).not.toHaveBeenCalled()
    expect(box.value).toContain('line one')
  })

  it('surfaces an error and keeps the comment if annotate fails', async () => {
    const user = userEvent.setup()
    const api = makeApi({ annotate: vi.fn().mockRejectedValue(new Error('annotate failed: 500')) })
    mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('keep me{Control>}{Enter}{/Control}')
    await waitFor(() => expect(screen.getByRole('alert').textContent).toMatch(/annotat/i))
    // the comment is preserved so the builder can retry
    expect(box.value).toBe('keep me')
  })
})

describe('mountCommentPanel — Rewrite bumps the draft badge', () => {
  it('clicking Rewrite calls rewrite(id, comment) and bumps the draft# from the returned {draft}', async () => {
    const user = userEvent.setup()
    const id = item().id
    const api = makeApi({ rewrite: vi.fn().mockResolvedValue({ draft: 3 }) })
    const { panel } = mountCommentPanel(root, { item: item(), api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('redraft entirely')
    await user.click(screen.getByRole('button', { name: /rewrite/i }))
    await waitFor(() => expect(api.rewrite).toHaveBeenCalledWith(id, 'redraft entirely'))
    await waitFor(() => {
      const badge = within(panel).getByText(/#3/)
      expect(badge).toBeTruthy()
    })
  })

  it('emits onDraft with the new draft number so the card badge can advance', async () => {
    const user = userEvent.setup()
    const onDraft = vi.fn()
    const api = makeApi({ rewrite: vi.fn().mockResolvedValue({ draft: 5 }) })
    mountCommentPanel(root, { item: item(), api, onDraft })
    await user.click(screen.getByRole('textbox', { name: /comment/i }))
    await user.keyboard('go')
    await user.click(screen.getByRole('button', { name: /rewrite/i }))
    await waitFor(() => expect(onDraft).toHaveBeenCalledWith(5))
  })

  it('Rewrite with an empty comment does nothing', async () => {
    const user = userEvent.setup()
    const api = makeApi()
    mountCommentPanel(root, { item: item(), api })
    await user.click(screen.getByRole('button', { name: /rewrite/i }))
    expect(api.rewrite).not.toHaveBeenCalled()
  })

  it('surfaces an error and does not bump the draft if rewrite fails', async () => {
    const user = userEvent.setup()
    const api = makeApi({ rewrite: vi.fn().mockRejectedValue(new Error('rewrite failed: 500')) })
    const { panel } = mountCommentPanel(root, { item: item(), api })
    await user.click(screen.getByRole('textbox', { name: /comment/i }))
    await user.keyboard('boom')
    await user.click(screen.getByRole('button', { name: /rewrite/i }))
    await waitFor(() => expect(screen.getByRole('alert').textContent).toMatch(/rewrite/i))
    // draft badge unchanged (the fixture starts at draft 0 ⇒ no badge shown)
    expect(within(panel).queryByText(/^#/)).toBeNull()
  })

  it('shows the existing draft# badge for an item that already has drafts', () => {
    const drafted = { ...item(), draft: 2 }
    const { panel } = mountCommentPanel(root, { item: drafted, api: makeApi() })
    expect(within(panel).getByText(/#2/)).toBeTruthy()
  })

  it('never mutates the fetched item object (one-way binding) across a full loop', async () => {
    const user = userEvent.setup()
    const passed = { ...item(), gate: 'go', draft: 0 }
    const api = makeApi({ rewrite: vi.fn().mockResolvedValue({ draft: 7 }) })
    mountCommentPanel(root, { item: passed, api })
    const box = screen.getByRole('textbox', { name: /comment/i })
    await user.click(box)
    await user.keyboard('tune it') // pauses
    await user.click(screen.getByRole('button', { name: /rewrite/i })) // bumps draft to 7
    await waitFor(() => expect(api.rewrite).toHaveBeenCalled())
    // the source object is untouched: gate still go, draft still 0
    expect(passed.gate).toBe('go')
    expect(passed.draft).toBe(0)
  })
})
