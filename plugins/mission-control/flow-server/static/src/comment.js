// comment.js — the comment / pause / annotate / rewrite loop for ONE item
// (roadmap #4). The moment the builder begins typing a comment the item PAUSES
// (setGate wait) and the panel highlights as paused; Ctrl-Enter unpauses
// (setGate go), appends the comment to the plan (annotate), and clears the input;
// a "Rewrite" button hands the comment to the carriage agent (rewrite) and bumps
// the draft# from the returned {draft}. Data flows DOWN (the item) into render;
// pause/draft state flows UP through onPaused/onDraft callbacks so the card can
// reflect it. The panel never mutates the item object it was handed.
//
// @front-end
// element: flow-comment-panel
// philosophy: human-in-the-loop — no value is spent while the builder is thinking
// paradigm: dashboard-explorative
// intent: let a solo builder tune any item — pause it the instant they start typing,
//         record their direction onto the plan with Ctrl-Enter, or hand it to the
//         agent for a full re-draft — without ever opening the item's document
// customer: solo-builder
// binding: one-way                # item in; pause-intent + draft-intent out
// render-trigger: items.changed
// modality: { touch: full, mouse: full, keyboard: full }
// style: operation
// a11y: wcag-2.1-aa               # labelled textbox; Rewrite is a real button; failures
//                                   land in an aria-live alert; Ctrl-Enter is the documented
//                                   commit (plain Enter stays a newline, never a surprise submit)
// improve?: "debounce the pause call and show a 'paused — composing' affordance; offer an
//            undo for an accidental annotate (the server keeps plan history)"
// breadcrumbs: ["pause fires ONCE on the empty→non-empty transition, never per keystroke",
//               "an already-WAIT item is not re-paused when typing begins",
//               "Ctrl-Enter on an empty comment is a no-op (no annotate, no unpause)",
//               "Rewrite reads the new draft# from the server's {draft}, never guesses"]

const ENTER = 'Enter'

/** Render the draft# badge text for a draft number (0 ⇒ no badge). */
function draftText(draft) {
  return draft ? `#${draft}` : ''
}

/**
 * Mount the comment panel for `item` into `root`. Returns a handle:
 *   { panel }
 * Callbacks (all optional): onPaused(bool) when the pause state flips,
 * onDraft(n) when a rewrite advances the draft number.
 */
export function mountCommentPanel(root, { item, api, onPaused, onDraft } = {}) {
  // Local working copy of the only mutable fields — never write back to `item`.
  let paused = item.gate === 'wait'
  let draft = item.draft ?? 0

  const panel = document.createElement('section')
  panel.className = `comment-panel ${paused ? 'is-paused' : ''}`.trim()
  panel.setAttribute('data-testid', `comment-panel-${item.id}`)
  panel.setAttribute('data-paused', paused ? 'true' : 'false')
  panel.setAttribute('aria-label', `Comment on ${item.title}`)

  // --- aria-live region for failures ---
  const alertBox = document.createElement('div')
  alertBox.setAttribute('role', 'alert')
  alertBox.setAttribute('aria-live', 'assertive')
  alertBox.className = 'flow-alert'
  alertBox.hidden = true
  const announce = (msg) => {
    alertBox.textContent = msg
    alertBox.hidden = !msg
  }

  // --- draft# badge ---
  const draftBadge = document.createElement('span')
  draftBadge.className = 'comment-draft'
  draftBadge.setAttribute('data-testid', `comment-draft-${item.id}`)
  draftBadge.textContent = draftText(draft)

  // --- comment textbox ---
  const labelId = `comment-label-${item.id}`
  const label = document.createElement('label')
  label.id = labelId
  label.className = 'comment-label'
  label.textContent = 'Comment'
  const box = document.createElement('textarea')
  box.className = 'comment-input'
  box.setAttribute('aria-labelledby', labelId)
  box.setAttribute('data-testid', `comment-input-${item.id}`)
  box.rows = 3

  // --- Rewrite button ---
  const rewriteBtn = document.createElement('button')
  rewriteBtn.type = 'button'
  rewriteBtn.className = 'comment-rewrite'
  rewriteBtn.textContent = 'Rewrite'

  // Set the pause state and reflect it on the panel + up via onPaused. Callers
  // only invoke this on a genuine transition (the input listener guards on !paused;
  // Ctrl-Enter only unpauses a paused panel), so there is no redundant-call guard.
  const setPaused = (next) => {
    paused = next
    panel.classList.toggle('is-paused', paused)
    panel.setAttribute('data-paused', paused ? 'true' : 'false')
    onPaused?.(paused)
  }

  const setDraft = (n) => {
    draft = n
    draftBadge.textContent = draftText(draft)
    onDraft?.(n)
  }

  // Pause-on-type: fire once, on the empty→non-empty transition. The input
  // listener is the only caller and already guards on !paused, so this pauses
  // exactly once. Keep the panel usable even if the gate call fails.
  const pauseOnType = async () => {
    setPaused(true)
    try {
      await api.setGate(item.id, 'wait')
      announce('')
    } catch (err) {
      announce(`Could not pause ${item.id}: ${err.message}`)
    }
  }

  box.addEventListener('input', () => {
    if (box.value.length > 0 && !paused) pauseOnType()
  })

  // Ctrl-Enter: unpause + annotate + clear. Plain Enter stays a newline.
  box.addEventListener('keydown', async (e) => {
    if (e.key !== ENTER || !(e.ctrlKey || e.metaKey)) return
    e.preventDefault()
    const text = box.value.trim()
    if (!text) return
    try {
      await api.setGate(item.id, 'go')
      await api.annotate(item.id, text)
      box.value = ''
      setPaused(false)
      announce('')
    } catch (err) {
      announce(`Could not annotate ${item.id}: ${err.message}`)
    }
  })

  rewriteBtn.addEventListener('click', async () => {
    const text = box.value.trim()
    if (!text) return
    try {
      const res = await api.rewrite(item.id, text)
      setDraft(res.draft)
      announce('')
    } catch (err) {
      announce(`Could not rewrite ${item.id}: ${err.message}`)
    }
  })

  const controls = document.createElement('div')
  controls.className = 'comment-controls'
  controls.append(draftBadge, rewriteBtn)

  panel.append(alertBox, label, box, controls)
  root.appendChild(panel)

  return { panel }
}
