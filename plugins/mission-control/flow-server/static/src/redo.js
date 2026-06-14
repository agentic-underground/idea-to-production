// redo.js — the REDO comment modal for backward (DONE→DO/DOING) moves.
// Exports mountRedoModal(root) → { open(onConfirm, onCancel) }.
//
// @front-end
// element: redo-modal
// philosophy: instrument-panel
// intent: require a "why" comment before any backward move commits, surfacing
//         the cost of regression and creating an auditable record via annotate
// customer: solo-builder
// binding: one-way     # open() receives callbacks; never touches canvas state
// modality: { mouse: full, keyboard: full }
// style: operation
// a11y: wcag-2.1-aa — uses native <dialog> for focus-trap + backdrop;
//         aria-labelledby on the heading; submit gated on non-empty comment
// breadcrumbs: ["<dialog>.showModal() gives native focus trap + ::backdrop",
//               "cancel event fires when Escape is pressed inside <dialog>",
//               "onConfirm(text) is called by the canvas to annotate + postStatus",
//               "onCancel() is called by the canvas to snap the card back"]

/**
 * Mount the REDO comment modal into `root`. Returns a controller:
 *   { open(onConfirm, onCancel) }
 *
 * open(onConfirm, onCancel):
 *   Shows the modal. Clears the textarea. Enables submit only when the
 *   textarea has non-empty (non-whitespace) text.
 *   - onConfirm(comment: string) — called with the trimmed comment text on submit
 *   - onCancel()                 — called on Cancel button click or Escape key
 */
export function mountRedoModal(root) {
  const HEADING_ID = 'redo-modal-title'

  const dialog = document.createElement('dialog')
  dialog.className = 'redo-modal'
  dialog.setAttribute('role', 'dialog')
  dialog.setAttribute('aria-modal', 'true')
  dialog.setAttribute('aria-labelledby', HEADING_ID)

  dialog.innerHTML = `
    <h2 id="${HEADING_ID}" class="redo-title">Why are you moving this back?</h2>
    <p class="redo-subtitle">A backward move requires a "why" comment before it commits.</p>
    <textarea
      class="redo-input"
      rows="4"
      placeholder="Explain the regression or change of plan…"
      aria-label="Reason for backward move"
    ></textarea>
    <div class="redo-actions">
      <button class="redo-cancel" type="button">Cancel</button>
      <button class="redo-submit" type="button" disabled>Submit</button>
    </div>
  `

  root.appendChild(dialog)

  const textarea = dialog.querySelector('.redo-input')
  const submitBtn = dialog.querySelector('.redo-submit')
  const cancelBtn = dialog.querySelector('.redo-cancel')

  // Keep active callbacks so event listeners always see the latest open() args.
  let activeConfirm = null
  let activeCancel = null

  // Enable/disable submit based on non-whitespace content.
  textarea.addEventListener('input', () => {
    submitBtn.disabled = textarea.value.trim() === ''
  })

  submitBtn.addEventListener('click', () => {
    const text = textarea.value.trim()
    if (!text) return // guard: should be disabled, but belt-and-suspenders
    dialog.close()
    if (activeConfirm) activeConfirm(text)
  })

  cancelBtn.addEventListener('click', () => {
    dialog.close()
    if (activeCancel) activeCancel()
  })

  // The native <dialog> fires a 'cancel' event when Escape is pressed.
  dialog.addEventListener('cancel', () => {
    if (activeCancel) activeCancel()
  })

  return {
    /**
     * Show the modal and register this invocation's callbacks.
     * Clears the textarea and resets the submit button to disabled.
     */
    open(onConfirm, onCancel) {
      activeConfirm = onConfirm
      activeCancel = onCancel
      textarea.value = ''
      submitBtn.disabled = true
      dialog.showModal()
    }
  }
}
