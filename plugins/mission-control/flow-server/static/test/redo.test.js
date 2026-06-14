// redo.test.js — unit tests for the REDO modal (item [30])
//
// Covers: mount/open/close, empty-comment guard, confirm path, cancel path,
// Escape key, and ARIA attributes.
//
// jsdom note: HTMLDialogElement.showModal() is available in jsdom ≥ 20 (this
// project uses jsdom 24+ via vitest). If showModal is unavailable in a future
// environment, add a polyfill here.

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mountRedoModal } from '../src/redo.js'

let root
beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
  // HTMLDialogElement.showModal() is polyfilled globally in test/setup.js
})

describe('mountRedoModal', () => {
  it('appends a dialog element to root', () => {
    mountRedoModal(root)
    expect(root.querySelector('dialog')).toBeTruthy()
  })

  it('the dialog is not open initially', () => {
    mountRedoModal(root)
    const dialog = root.querySelector('dialog')
    expect(dialog.hasAttribute('open')).toBe(false)
  })

  it('open() shows the dialog', () => {
    const modal = mountRedoModal(root)
    modal.open(vi.fn(), vi.fn())
    const dialog = root.querySelector('dialog')
    expect(dialog.hasAttribute('open')).toBe(true)
  })

  it('dialog has role="dialog" and aria-modal="true"', () => {
    mountRedoModal(root)
    const dialog = root.querySelector('dialog')
    expect(dialog.getAttribute('role')).toBe('dialog')
    expect(dialog.getAttribute('aria-modal')).toBe('true')
  })

  it('dialog has aria-labelledby pointing to a heading inside it', () => {
    mountRedoModal(root)
    const dialog = root.querySelector('dialog')
    const labelId = dialog.getAttribute('aria-labelledby')
    expect(labelId).toBeTruthy()
    const heading = dialog.querySelector(`#${labelId}`)
    expect(heading).toBeTruthy()
    expect(heading.tagName.toLowerCase()).toMatch(/^h[1-6]$/)
  })

  it('open() clears the textarea on each call', () => {
    const modal = mountRedoModal(root)
    const dialog = root.querySelector('dialog')
    const textarea = dialog.querySelector('textarea')
    modal.open(vi.fn(), vi.fn())
    textarea.value = 'leftover text'
    modal.open(vi.fn(), vi.fn())
    expect(textarea.value).toBe('')
  })

  it('submit button is disabled when textarea is empty', () => {
    const modal = mountRedoModal(root)
    modal.open(vi.fn(), vi.fn())
    const dialog = root.querySelector('dialog')
    const submit = dialog.querySelector('.redo-submit')
    const textarea = dialog.querySelector('textarea')
    expect(textarea.value).toBe('')
    expect(submit.disabled).toBe(true)
  })

  it('submit button is disabled when textarea contains only whitespace', () => {
    const modal = mountRedoModal(root)
    modal.open(vi.fn(), vi.fn())
    const dialog = root.querySelector('dialog')
    const submit = dialog.querySelector('.redo-submit')
    const textarea = dialog.querySelector('textarea')
    textarea.value = '   \n  '
    textarea.dispatchEvent(new Event('input'))
    expect(submit.disabled).toBe(true)
  })

  it('submit button becomes enabled when textarea has non-empty text', () => {
    const modal = mountRedoModal(root)
    modal.open(vi.fn(), vi.fn())
    const dialog = root.querySelector('dialog')
    const submit = dialog.querySelector('.redo-submit')
    const textarea = dialog.querySelector('textarea')
    textarea.value = 'regression found'
    textarea.dispatchEvent(new Event('input'))
    expect(submit.disabled).toBe(false)
  })

  it('clicking submit calls onConfirm with the comment text and closes the dialog', () => {
    const onConfirm = vi.fn()
    const onCancel = vi.fn()
    const modal = mountRedoModal(root)
    modal.open(onConfirm, onCancel)
    const dialog = root.querySelector('dialog')
    const submit = dialog.querySelector('.redo-submit')
    const textarea = dialog.querySelector('textarea')
    textarea.value = 'deploy pipeline regression'
    textarea.dispatchEvent(new Event('input'))
    submit.click()
    expect(onConfirm).toHaveBeenCalledWith('deploy pipeline regression')
    expect(onCancel).not.toHaveBeenCalled()
    expect(dialog.hasAttribute('open')).toBe(false)
  })

  it('clicking submit when textarea is empty does NOT call onConfirm', () => {
    const onConfirm = vi.fn()
    const modal = mountRedoModal(root)
    modal.open(onConfirm, vi.fn())
    const dialog = root.querySelector('dialog')
    const submit = dialog.querySelector('.redo-submit')
    const textarea = dialog.querySelector('textarea')
    expect(textarea.value).toBe('')
    submit.click()
    expect(onConfirm).not.toHaveBeenCalled()
  })

  it('clicking Cancel calls onCancel and closes the dialog', () => {
    const onConfirm = vi.fn()
    const onCancel = vi.fn()
    const modal = mountRedoModal(root)
    modal.open(onConfirm, onCancel)
    const dialog = root.querySelector('dialog')
    const cancel = dialog.querySelector('.redo-cancel')
    cancel.click()
    expect(onCancel).toHaveBeenCalled()
    expect(onConfirm).not.toHaveBeenCalled()
    expect(dialog.hasAttribute('open')).toBe(false)
  })

  it('pressing Escape calls onCancel', () => {
    const onCancel = vi.fn()
    const modal = mountRedoModal(root)
    modal.open(vi.fn(), onCancel)
    const dialog = root.querySelector('dialog')
    // jsdom fires 'cancel' event on dialog when Escape is pressed
    dialog.dispatchEvent(new Event('cancel'))
    expect(onCancel).toHaveBeenCalled()
  })

  it('the dialog has a textarea and both buttons', () => {
    mountRedoModal(root)
    const dialog = root.querySelector('dialog')
    expect(dialog.querySelector('textarea')).toBeTruthy()
    expect(dialog.querySelector('.redo-submit')).toBeTruthy()
    expect(dialog.querySelector('.redo-cancel')).toBeTruthy()
  })

  it('submit guard: manually firing click when text is empty (after removing disabled) does NOT call onConfirm', () => {
    // Exercises the belt-and-suspenders `if (!text) return` guard at line 71,
    // in case the disabled attribute is bypassed (e.g. AT or programmatic click).
    const onConfirm = vi.fn()
    const modal = mountRedoModal(root)
    modal.open(onConfirm, vi.fn())
    const dialog = root.querySelector('dialog')
    const submit = dialog.querySelector('.redo-submit')
    const textarea = dialog.querySelector('textarea')
    // Force-remove disabled so the click fires the handler
    submit.removeAttribute('disabled')
    textarea.value = '' // still empty
    submit.click()
    expect(onConfirm).not.toHaveBeenCalled()
  })
})
