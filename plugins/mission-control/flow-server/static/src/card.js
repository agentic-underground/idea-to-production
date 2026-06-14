// card.js — render ONE work item as an SVG rounded-rect card with badges and a
// keyboard-operable WAIT/GO toggle. Pure render-from-input + emit-intent-up: the
// card reads an item and a position, and calls onToggleGate(id, nextGate) when
// the human governs it. It mutates nothing it does not own.
//
// @front-end
// element: flow-card
// philosophy: recognition-over-recall (badges read at a glance)
// paradigm: dashboard-explorative
// intent: show a builder cost · state · model · draft for one item, let them
//         pause/resume value-add down its path, and pick the model that runs it —
//         all without opening it
// customer: solo-builder
// binding: one-way                # item in, gate-intent + model-pick-intent out
// render-trigger: items.changed
// modality: { touch: 1-tap, mouse: full, keyboard: full }
// style: operation                # badges + a lever + a picker, not a form
// a11y: wcag-2.1-aa               # role/name/value on the toggle; the model badge is a
//                                   button (aria-haspopup=listbox); Enter/Space activate both
// improve?: "add error-catch/child-task badges (roadmap #2 EARS) — the badge row is built to extend"
// breadcrumbs: ["gate 'go' ⇒ aria-pressed=false (not paused); 'wait' ⇒ true",
//               "onToggleGate is called with the OPPOSITE of the current gate",
//               "model badge carries data-override; default ⇔ model == defaultModel (or no defaultModel)",
//               "onPickModel(id) only fires when a handler is wired (else the badge is inert text)"]

import { shortModel, modelLabel, resolveModel } from './model.js'

export const SVG_NS = 'http://www.w3.org/2000/svg'
export const CARD_TESTID = 'flow-card'
export const CARD_W = 240
export const CARD_H = 120

/** Group an integer with thousands separators (locale-independent). */
function groupThousands(n) {
  return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

function el(name, attrs = {}, text) {
  const node = document.createElementNS(SVG_NS, name)
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v)
  if (text != null) node.textContent = text
  return node
}

/** Render one badge `<text>` at (x, y); returns the node. */
function badge(x, y, label, cls) {
  return el('text', { x, y, class: `badge ${cls}`, 'data-badge': cls }, label)
}

/**
 * Render the model badge. Shows the resolved (override-or-default) model short
 * name plus a "default"/"override" marker. When `onPickModel` is supplied the
 * badge is a button (role=button, aria-haspopup=listbox, Enter/Space + click);
 * otherwise it is an inert `<text>` label (backwards-compatible).
 */
function renderModelBadge(item, onPickModel) {
  const { model, default: def, isOverride } = resolveModel(item)
  const marker = isOverride ? 'override' : 'default'

  if (!onPickModel) {
    return badge(120, 82, shortModel(model), 'model')
  }

  const ariaLabel = isOverride
    ? `Model: ${modelLabel(model)} (override of default ${modelLabel(def)}) — change`
    : `Model: ${modelLabel(model)} (default) — change`

  const picker = el('g', {
    role: 'button',
    tabindex: '0',
    'aria-haspopup': 'listbox',
    'aria-label': ariaLabel,
    class: 'model-picker',
    'data-override': isOverride ? 'true' : 'false',
    'data-testid': `model-picker-${item.id}`,
    transform: 'translate(120 70)'
  })
  // a generous transparent hit target (>= the badge text it wraps)
  picker.appendChild(el('rect', { x: -2, y: -12, width: 112, height: 28, rx: 6, ry: 6, class: 'model-hit' }))
  picker.appendChild(badge(0, 0, shortModel(model), 'model'))
  picker.appendChild(badge(0, 13, marker, `model-marker model-${marker}`))

  const open = (e) => {
    e.preventDefault()
    e.stopPropagation()
    onPickModel(item.id)
  }
  picker.addEventListener('click', open)
  picker.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') open(e)
  })
  return picker
}

/**
 * Render an item as an SVG `<g>` translated to `pos`. Calls
 * `onToggleGate(id, nextGate)` when the WAIT/GO toggle is activated, and
 * `onPickModel(id)` when the model badge is activated (if a handler is given).
 */
export function renderCard(item, pos, { onToggleGate, onPickModel } = {}) {
  const paused = item.gate === 'wait'

  const g = el('g', {
    transform: `translate(${pos.x} ${pos.y})`,
    class: `card ${paused ? 'is-paused' : ''}`.trim(),
    role: 'group',
    'aria-label': `${item.title} — ${item.status}${paused ? ', paused' : ''}`,
    'data-id': item.id,
    'data-gate': item.gate,
    'data-status': item.status,
    'data-testid': `${CARD_TESTID}-${item.id}`,
    tabindex: '0'
  })

  g.appendChild(el('rect', { width: CARD_W, height: CARD_H, rx: 14, ry: 14, class: 'card-bg' }))
  // glowing left accent bar — recoloured by the card's status in app.css (DO/DOING/DONE)
  g.appendChild(el('rect', { x: 1, y: 14, width: 5, height: CARD_H - 28, rx: 2.5, ry: 2.5, class: 'card-accent' }))
  g.appendChild(el('text', { x: 16, y: 30, class: 'card-title' }, item.title))

  // badge row
  g.appendChild(badge(16, 60, `${groupThousands(item.tokens)} tok`, 'tokens'))
  g.appendChild(badge(16, 82, item.status, 'status'))
  if (item.draft) g.appendChild(badge(120, 60, `#${item.draft}`, 'draft'))

  // model badge — a keyboard-operable picker affordance when a handler is given,
  // an inert label otherwise. Marks default vs override so cost↔capability reads.
  g.appendChild(renderModelBadge(item, onPickModel))

  // WAIT/GO toggle — an SVG button-role group, keyboard operable.
  const nextGate = paused ? 'go' : 'wait'
  const toggle = el('g', {
    role: 'button',
    tabindex: '0',
    'aria-pressed': paused ? 'true' : 'false',
    'aria-label': paused ? 'Paused — resume (GO)' : 'Running — pause (WAIT)',
    class: 'gate-toggle',
    'data-testid': `gate-toggle-${item.id}`,
    transform: `translate(${CARD_W - 76} ${CARD_H - 38})`
  })
  toggle.appendChild(el('rect', { width: 60, height: 26, rx: 13, ry: 13, class: 'gate-bg' }))
  toggle.appendChild(el('text', { x: 30, y: 18, 'text-anchor': 'middle', class: 'gate-label' }, paused ? 'WAIT' : 'GO'))

  const fire = (e) => {
    e.preventDefault()
    e.stopPropagation()
    onToggleGate(item.id, nextGate)
  }
  toggle.addEventListener('click', fire)
  toggle.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') fire(e)
  })

  g.appendChild(toggle)
  return g
}
