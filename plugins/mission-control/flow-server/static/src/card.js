// card.js — render ONE work item as an SVG rounded-rect card with badges and a
// keyboard-operable WAIT/GO toggle. Pure render-from-input + emit-intent-up: the
// card reads an item and a position, and calls onToggleGate(id, nextGate) when
// the human governs it. It mutates nothing it does not own.
//
// @front-end
// element: flow-card
// philosophy: recognition-over-recall (badges read at a glance)
// paradigm: dashboard-explorative
// intent: show a builder cost · state · model · draft for one item, and let them
//         pause/resume value-add down its path without opening it
// customer: solo-builder
// binding: one-way                # item in, gate-intent out
// render-trigger: items.changed
// modality: { touch: 1-tap, mouse: full, keyboard: full }
// style: operation                # badges + a lever, not a form
// a11y: wcag-2.1-aa               # role/name/value on the toggle; Enter/Space activate
// improve?: "expose a model-picker (roadmap #8) and error-catch/child-task badges
//            (roadmap #2 EARS) — the badge row is built to extend"
// breadcrumbs: ["gate 'go' ⇒ aria-pressed=false (not paused); 'wait' ⇒ true",
//               "onToggleGate is called with the OPPOSITE of the current gate"]

export const SVG_NS = 'http://www.w3.org/2000/svg'
export const CARD_TESTID = 'flow-card'
export const CARD_W = 240
export const CARD_H = 120

/** Shorten a marketplace model id to its family name for the badge. */
function shortModel(model) {
  const m = /claude-([a-z]+)/.exec(model ?? '')
  return m ? m[1] : (model ?? '')
}

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
 * Render an item as an SVG `<g>` translated to `pos`. Calls
 * `onToggleGate(id, nextGate)` when the WAIT/GO toggle is activated.
 */
export function renderCard(item, pos, { onToggleGate }) {
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
  g.appendChild(el('text', { x: 16, y: 30, class: 'card-title' }, item.title))

  // badge row
  g.appendChild(badge(16, 60, `${groupThousands(item.tokens)} tok`, 'tokens'))
  g.appendChild(badge(16, 82, item.status, 'status'))
  g.appendChild(badge(120, 82, shortModel(item.model), 'model'))
  if (item.draft) g.appendChild(badge(120, 60, `#${item.draft}`, 'draft'))

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
