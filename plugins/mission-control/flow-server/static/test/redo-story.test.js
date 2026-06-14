// redo-story.test.js — story-level interaction tests for item [30]
//
// These tests drive the COMPLETE user story at the DOM level (jsdom), simulating
// the experience of a solo builder encountering a backward drag:
//   1. Drag a DONE card backward (to DO or DOING)
//   2. See the REDO modal appear
//   3. Type a reason and submit → card gets REDO badge, APIs called
//   4. Or cancel → card returns to DONE, no API calls
//   5. Moving a REDO-badged card forward clears the badge
//
// These tests use the full canvas + redo module integration, not mocks of redo.js.
// They satisfy the STORY_PROVEN gate.

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { waitFor } from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import { mountCanvas } from '../src/canvas.js'
import { FIXTURE_ITEMS } from './fixtures.js'

function makeApi(overrides = {}) {
  return {
    getItems: vi.fn().mockResolvedValue(FIXTURE_ITEMS),
    setGate: vi.fn().mockResolvedValue({ ok: true }),
    setModel: vi.fn().mockResolvedValue({ ok: true }),
    validateConnection: vi.fn().mockResolvedValue({ ok: true }),
    postStatus: vi.fn().mockResolvedValue({ ok: true }),
    annotate: vi.fn().mockResolvedValue({ ok: true }),
    ...overrides
  }
}

let root
beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
})

function stubGeometry(canvas) {
  canvas.getBoundingClientRect = () => ({ left: 0, top: 0, width: 1000, height: 700, right: 1000, bottom: 700 })
}

// ─── Story 1: Solo builder moves a done card backward, provides a reason ───

describe('Story: backward drag from DONE → DO requires and accepts a comment', () => {
  it('builder drags done card to DO, types a reason, submits — card shows REDO badge', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    stubGeometry(handle.svg)

    // Setup: confirm the card starts in "done"
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="flow-server"]')
    expect(card.getAttribute('data-status')).toBe('done')

    // ACT 1: drag the done card far right into the DO column
    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 820, clientY: 100, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    // ASSERT 1: the REDO modal must appear, no status change yet
    const dialog = await waitFor(() => {
      const d = document.querySelector('dialog[open]')
      expect(d).toBeTruthy()
      return d
    })
    expect(api.postStatus).not.toHaveBeenCalled()
    expect(api.annotate).not.toHaveBeenCalled()

    // ASSERT 1b: submit button disabled (empty comment)
    const submit = dialog.querySelector('.redo-submit')
    expect(submit.disabled).toBe(true)

    // ACT 2: type the reason
    const user = userEvent.setup()
    const textarea = dialog.querySelector('textarea')
    await user.type(textarea, 'Regression found: pipeline step 3 fails on node 16')

    // ASSERT 2: submit now enabled
    expect(submit.disabled).toBe(false)

    // ACT 3: submit
    submit.click()

    // ASSERT 3: API calls made correctly
    await waitFor(() => {
      expect(api.annotate).toHaveBeenCalledWith('flow-server', 'Regression found: pipeline step 3 fails on node 16')
      expect(api.postStatus).toHaveBeenCalledWith('flow-server', 'do')
    })

    // ASSERT 4: dialog closed
    await waitFor(() => {
      expect(document.querySelector('dialog[open]')).toBeNull()
    })

    // ASSERT 5: card now shows the coral REDO badge
    await waitFor(() => {
      const updatedCard = handle.svg.querySelector('[data-id="flow-server"]')
      expect(updatedCard.querySelector('[data-badge="redo"]')).toBeTruthy()
      expect(updatedCard.getAttribute('data-status')).toBe('do')
    })
  })
})

// ─── Story 2: Builder changes their mind and cancels the backward move ─────

describe('Story: builder cancels the REDO modal — card returns to DONE', () => {
  it('builder drags done card to DOING, then cancels — card snaps back to DONE', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    stubGeometry(handle.svg)

    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="flow-server"]')

    // Drag done → doing (+360px)
    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 460, clientY: 100, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    const dialog = await waitFor(() => {
      const d = document.querySelector('dialog[open]')
      expect(d).toBeTruthy()
      return d
    })

    // Cancel the modal
    dialog.querySelector('.redo-cancel').click()

    // Dialog closes
    await waitFor(() => expect(document.querySelector('dialog[open]')).toBeNull())

    // No API calls
    expect(api.postStatus).not.toHaveBeenCalled()
    expect(api.annotate).not.toHaveBeenCalled()

    // Card stays at done
    await waitFor(() => {
      const updatedCard = handle.svg.querySelector('[data-id="flow-server"]')
      expect(updatedCard.getAttribute('data-status')).toBe('done')
    })
  })
})

// ─── Story 3: REDO badge cleared when card moves forward again ────────────

describe('Story: REDO badge is cleared when the builder completes the card again', () => {
  it('after a successful backward move, dragging the card to DONE removes the badge', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    stubGeometry(handle.svg)

    // First: perform the full backward move to get the REDO badge
    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    let card = handle.svg.querySelector('[data-id="flow-server"]')

    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 820, clientY: 100, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    const dialog = await waitFor(() => {
      const d = document.querySelector('dialog[open]')
      expect(d).toBeTruthy()
      return d
    })
    const textarea = dialog.querySelector('textarea')
    textarea.value = 'found a bug'
    textarea.dispatchEvent(new Event('input'))
    dialog.querySelector('.redo-submit').click()

    // Wait for REDO badge to appear
    await waitFor(() => {
      card = handle.svg.querySelector('[data-id="flow-server"]')
      expect(card.querySelector('[data-badge="redo"]')).toBeTruthy()
    })
    // Card is now in 'do' with redo badge

    // Second: drag it back to DONE (forward move from do → done: -720px)
    card = handle.svg.querySelector('[data-id="flow-server"]')
    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 820, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 100, clientY: 100, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    // postStatus called for done
    await waitFor(() => expect(api.postStatus).toHaveBeenCalledWith('flow-server', 'done'))

    // REDO badge gone
    await waitFor(() => {
      card = handle.svg.querySelector('[data-id="flow-server"]')
      expect(card.querySelector('[data-badge="redo"]')).toBeNull()
      expect(card.getAttribute('data-status')).toBe('done')
    })
  })
})

// ─── Story 4: Escape key is an alternative to Cancel ──────────────────────

describe('Story: Escape key acts as Cancel in the REDO modal', () => {
  it('pressing Escape in the REDO modal reverts the card to DONE', async () => {
    const api = makeApi()
    const handle = await mountCanvas(root, { api, token: 'tok' })
    stubGeometry(handle.svg)

    await waitFor(() => expect(handle.svg.querySelector('[data-id="flow-server"]')).toBeTruthy())
    const card = handle.svg.querySelector('[data-id="flow-server"]')

    card.dispatchEvent(new MouseEvent('pointerdown', { clientX: 100, clientY: 100, button: 0, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointermove', { clientX: 820, clientY: 100, bubbles: true }))
    window.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }))

    const dialog = await waitFor(() => {
      const d = document.querySelector('dialog[open]')
      expect(d).toBeTruthy()
      return d
    })

    // Simulate Escape via the native dialog 'cancel' event
    dialog.dispatchEvent(new Event('cancel'))

    // Card status unchanged
    await waitFor(() => {
      const updatedCard = handle.svg.querySelector('[data-id="flow-server"]')
      expect(updatedCard.getAttribute('data-status')).toBe('done')
    })
    expect(api.postStatus).not.toHaveBeenCalled()
  })
})
