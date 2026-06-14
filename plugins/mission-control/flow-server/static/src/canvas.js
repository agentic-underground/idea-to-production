// canvas.js — mount the interactive SVG flow-canvas: nested DO·DOING·DONE boards
// of rounded-rect cards joined by curved Bézier connectors, with wheel-zoom about
// the cursor, click-drag pan, card drag, auto-align, a WAIT/GO toggle per card,
// and connection-draw validation against the server. Data flows DOWN from the API
// into render; user intents flow UP through the API verbs.
//
// @front-end
// element: flow-canvas
// philosophy: instrument-panel · recognition-over-recall
// paradigm: dashboard-explorative
// intent: let a solo builder comprehend the whole value system as a live graph and
//         steer it — pause/resume paths, pick the model that runs each job, tidy the
//         layout, and reject any edit that would make the plan unbuildable
// customer: solo-builder
// binding: one-way                # API → render; toggle/model-pick/connect → API verbs
// render-trigger: items.changed
// modality: { touch: full, mouse: full, keyboard: full }
// style: operation
// a11y: wcag-2.1-aa               # cards are labelled groups; toggle is a real button;
//                                   errors land in an aria-live alert region
// improve?: "subscribe to the server's WS delta stream so the board live-updates
//            without re-fetch (roadmap #1); animate cross-column moves (roadmap #2 EARS)"
// breadcrumbs: ["world group holds the pan/zoom transform: translate(x y) scale(s)",
//               "a connector carries data-from/data-to so a card move can re-route it",
//               "tryConnect(from,to) ALWAYS validates server-side before committing"]

import {
  CARD_W,
  CARD_H,
  COLUMNS,
  COL_X,
  autoAlign,
  bezierPath,
  columnForStatus,
  zoomAboutCursor
} from './layout.js'
import { SVG_NS, renderCard } from './card.js'
import { MODEL_ALLOWLIST, modelLabel, resolveModel } from './model.js'

const COLUMN_LABELS = { do: 'DO', doing: 'DOING', done: 'DONE' }
const BOARD_TOP = 8
const BOARD_BOTTOM = 2000

/** Map a column name back to the server status string. */
const STATUS_FOR_COL = { done: 'done', doing: 'doing', do: 'do' }

/**
 * Given a world-coordinate x position, return the nearest column name.
 * Uses the centre of each column (COL_X[col] + CARD_W/2) as the reference
 * point — the column whose centre is closest wins.
 * Exported for direct unit-test coverage.
 */
export function detectColumn(worldX) {
  let nearest = COLUMNS[0]
  let minDist = Infinity
  for (const col of COLUMNS) {
    const centre = COL_X[col] + CARD_W / 2
    const dist = Math.abs(worldX - centre)
    if (dist < minDist) {
      minDist = dist
      nearest = col
    }
  }
  return nearest
}

function svgEl(name, attrs = {}, text) {
  const node = document.createElementNS(SVG_NS, name)
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v)
  if (text != null) node.textContent = text
  return node
}

/**
 * Mount the canvas into `root`. Returns a handle:
 *   { svg, getTransform(), tryConnect(from,to), refresh() }
 * If no token is set, renders a token prompt and does not fetch.
 */
export async function mountCanvas(root, { api, token = 'present' } = {}) {
  root.innerHTML = ''

  // --- error / status live region (shared) ---
  const alertBox = document.createElement('div')
  alertBox.setAttribute('role', 'alert')
  alertBox.setAttribute('aria-live', 'assertive')
  alertBox.className = 'flow-alert'
  alertBox.hidden = true
  root.appendChild(alertBox)

  const announce = (msg) => {
    alertBox.textContent = msg
    alertBox.hidden = !msg
  }

  // --- no-token gate: prompt, do not fetch ---
  if (!token) {
    const label = document.createElement('label')
    label.textContent = 'Bearer token'
    const input = document.createElement('input')
    input.type = 'password'
    input.name = 'token'
    label.appendChild(input)
    root.appendChild(label)
    return { svg: null, getTransform: () => null, tryConnect: async () => ({ ok: false }), refresh: async () => {} }
  }

  // --- toolbar ---
  const toolbar = document.createElement('div')
  toolbar.className = 'flow-toolbar'
  const alignBtn = document.createElement('button')
  alignBtn.type = 'button'
  alignBtn.textContent = 'Auto-align'
  toolbar.appendChild(alignBtn)
  root.appendChild(toolbar)

  // --- svg scaffold: <svg><g.world><g.boards/><g.edges/><g.cards/></g></svg> ---
  const svg = svgEl('svg', { class: 'flow-canvas', width: '100%', height: '100%', role: 'application', 'aria-label': 'Flow canvas' })
  const world = svgEl('g', { class: 'world' })
  const boardsLayer = svgEl('g', { class: 'boards' })
  const edgesLayer = svgEl('g', { class: 'edges' })
  const cardsLayer = svgEl('g', { class: 'cards' })
  world.append(boardsLayer, edgesLayer, cardsLayer)
  svg.appendChild(world)
  root.appendChild(svg)

  // --- state ---
  let transform = { scale: 1, x: 0, y: 0 }
  let items = []
  const positions = {} // id → {x, y}
  const cardEls = {} // id → <g>
  const edges = [] // {from, to, path}

  const applyTransform = () => {
    world.setAttribute('transform', `translate(${transform.x} ${transform.y}) scale(${transform.scale})`)
  }
  applyTransform()

  // anchor points for a connector: from-card left-centre → to-card right-centre.
  const anchorFrom = (id) => ({ x: positions[id].x, y: positions[id].y + CARD_H / 2 })
  const anchorTo = (id) => ({ x: positions[id].x + CARD_W, y: positions[id].y + CARD_H / 2 })

  const routeEdge = (edge) => {
    if (!positions[edge.from] || !positions[edge.to]) return
    edge.path.setAttribute('d', bezierPath(anchorFrom(edge.from), anchorTo(edge.to)))
  }

  const addEdge = (from, to) => {
    const path = svgEl('path', { class: 'connector', fill: 'none', 'data-from': from, 'data-to': to })
    const edge = { from, to, path }
    edges.push(edge)
    edgesLayer.appendChild(path)
    routeEdge(edge)
    return edge
  }

  const rerouteEdgesFor = (id) => {
    for (const edge of edges) {
      if (edge.from === id || edge.to === id) routeEdge(edge)
    }
  }

  // --- WAIT/GO toggle handler: optimistic-with-rollback through the API ---
  const onToggleGate = async (id, nextGate) => {
    const item = items.find((i) => i.id === id)
    const prev = item.gate
    try {
      await api.setGate(id, nextGate)
      item.gate = nextGate
      rerenderCard(id)
      announce('')
    } catch (err) {
      item.gate = prev
      announce(`Could not ${nextGate === 'wait' ? 'pause' : 'resume'} ${id}: ${err.message}`)
    }
  }

  // --- model picker: an accessible listbox popup over the canvas. Only one open
  // at a time; choosing an allowlisted model overrides, "Use default" clears it.
  let pickerEl = null
  const closePicker = () => {
    if (pickerEl) {
      pickerEl.remove()
      pickerEl = null
    }
  }

  // Apply a chosen model: `model` is an allowlisted id to override with, or null
  // to clear the override. No-ops when the choice is already the resolved model.
  const applyModel = async (id, model) => {
    const item = items.find((i) => i.id === id)
    const resolved = resolveModel(item)
    closePicker()
    // choosing the model already in effect (or "default" when already default) is a no-op
    if (model === null ? !resolved.isOverride : model === resolved.model) return
    const prevModel = item.model
    try {
      await api.setModel(id, model)
      // Pin the default on the working copy so override-vs-default stays decidable
      // even when the server has not (yet) exposed a separate defaultModel field.
      item.defaultModel = resolved.default
      item.model = model === null ? resolved.default : model
      rerenderCard(id)
      announce('')
    } catch (err) {
      item.model = prevModel
      announce(`Could not change the model for ${id}: ${err.message}`)
    }
  }

  const onPickModel = (id) => {
    closePicker()
    const item = items.find((i) => i.id === id)
    const resolved = resolveModel(item)

    const listbox = document.createElement('ul')
    listbox.setAttribute('role', 'listbox')
    listbox.setAttribute('aria-label', `Choose model for ${item.title}`)
    listbox.className = 'model-listbox'
    listbox.tabIndex = -1

    const choices = [
      ...MODEL_ALLOWLIST.map((m) => ({ label: modelLabel(m), model: m, selected: m === resolved.model })),
      { label: 'Use default', model: null, selected: false }
    ]

    const optionEls = choices.map((choice) => {
      const li = document.createElement('li')
      li.setAttribute('role', 'option')
      li.setAttribute('aria-selected', choice.selected ? 'true' : 'false')
      li.tabIndex = -1
      li.className = 'model-option'
      li.textContent = choice.label
      li.addEventListener('click', () => applyModel(id, choice.model))
      listbox.appendChild(li)
      return li
    })

    // keyboard: arrows move a roving focus (wrapping), Enter chooses, Escape closes.
    let active = Math.max(0, choices.findIndex((c) => c.selected))
    const focusActive = () => optionEls[active].focus()
    listbox.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        active = (active + 1) % optionEls.length
        focusActive()
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        active = (active - 1 + optionEls.length) % optionEls.length
        focusActive()
      } else if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        applyModel(id, choices[active].model)
      } else if (e.key === 'Escape') {
        e.preventDefault()
        closePicker()
      }
    })

    root.appendChild(listbox)
    pickerEl = listbox
    focusActive()
  }

  const placeCard = (id) => {
    cardEls[id].setAttribute('transform', `translate(${positions[id].x} ${positions[id].y})`)
  }

  const rerenderCard = (id) => {
    const item = items.find((i) => i.id === id)
    const fresh = renderCard(item, positions[id], { onToggleGate, onPickModel })
    wireCardDrag(fresh, id)
    cardEls[id].replaceWith(fresh)
    cardEls[id] = fresh
  }

  // --- board columns (drawn behind the cards) ---
  const drawBoards = () => {
    boardsLayer.innerHTML = ''
    for (const col of COLUMNS) {
      const x = COL_X[col] - 16
      const colG = svgEl('g', { class: `board board-${col}`, 'data-col': col })
      colG.appendChild(svgEl('rect', {
        x, y: BOARD_TOP, width: CARD_W + 32, height: BOARD_BOTTOM, rx: 16, ry: 16, class: 'board-bg'
      }))
      colG.appendChild(svgEl('text', { x: x + 16, y: BOARD_TOP + 28, class: 'board-label' }, COLUMN_LABELS[col]))
      boardsLayer.appendChild(colG)
    }
  }

  // --- helpers: column <g> elements and drop-glow class management ---
  const getColEl = (col) => boardsLayer.querySelector(`.board-${col}`)

  const setDropGlow = (targetCol, sourceCol) => {
    for (const col of COLUMNS) {
      const el = getColEl(col)
      if (col === targetCol && col !== sourceCol) {
        el.classList.add('board--drop-active')
      } else {
        el.classList.remove('board--drop-active')
      }
    }
  }

  const clearDropGlow = () => {
    for (const col of COLUMNS) {
      getColEl(col).classList.remove('board--drop-active')
    }
  }

  // --- card dragging (and distinguishing card-drag from canvas-pan) ---
  function wireCardDrag(cardEl, id) {
    cardEl.addEventListener('pointerdown', (e) => {
      if (e.button !== 0) return
      // a pointerdown that originates on the gate toggle or model picker must not start a drag
      if (e.target.closest && e.target.closest('.gate-toggle, .model-picker')) return
      e.stopPropagation() // do NOT let the canvas pan
      const startX = e.clientX
      const startY = e.clientY
      const origin = { ...positions[id] }
      const item = items.find((i) => i.id === id)
      const sourceCol = columnForStatus(item.status)

      const onMove = (m) => {
        positions[id] = {
          x: origin.x + (m.clientX - startX) / transform.scale,
          y: origin.y + (m.clientY - startY) / transform.scale
        }
        placeCard(id)
        rerouteEdgesFor(id)
        // Drop-zone glow: show which column the card is hovering over
        const targetCol = detectColumn(positions[id].x)
        setDropGlow(targetCol, sourceCol)
      }

      const onUp = async () => {
        window.removeEventListener('pointermove', onMove)
        window.removeEventListener('pointerup', onUp)
        clearDropGlow()

        // Column-drop: detect where the card landed and post status if changed
        const targetCol = detectColumn(positions[id].x)
        if (targetCol === sourceCol) return

        const newStatus = STATUS_FOR_COL[targetCol]
        const prevStatus = item.status

        // Optimistic update: change status + re-render immediately
        item.status = newStatus
        rerenderCard(id)
        // Snap to the target column
        const aligned = autoAlign(items)
        positions[id] = aligned[id]
        placeCard(id)
        rerouteEdgesFor(id)

        try {
          await api.postStatus(id, newStatus)
          announce('')
        } catch (err) {
          // Rollback on failure
          item.status = prevStatus
          rerenderCard(id)
          const rolledBack = autoAlign(items)
          positions[id] = rolledBack[id]
          placeCard(id)
          rerouteEdgesFor(id)
          announce(`Could not move ${id}: ${err.message}`)
        }
      }
      window.addEventListener('pointermove', onMove)
      window.addEventListener('pointerup', onUp)
    })
  }

  // --- canvas pan (only when the pointerdown reaches empty canvas) ---
  svg.addEventListener('pointerdown', (e) => {
    if (e.button !== 0) return
    const startX = e.clientX
    const startY = e.clientY
    const origin = { x: transform.x, y: transform.y }
    const onMove = (m) => {
      transform = { ...transform, x: origin.x + (m.clientX - startX), y: origin.y + (m.clientY - startY) }
      applyTransform()
    }
    const onUp = () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', onUp)
    }
    window.addEventListener('pointermove', onMove)
    window.addEventListener('pointerup', onUp)
  })

  // --- wheel zoom about the cursor ---
  svg.addEventListener('wheel', (e) => {
    e.preventDefault()
    const rect = svg.getBoundingClientRect()
    const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1
    transform = zoomAboutCursor(transform, {
      cursorX: e.clientX - rect.left,
      cursorY: e.clientY - rect.top,
      factor
    })
    applyTransform()
  }, { passive: false })

  // --- auto-align ---
  alignBtn.addEventListener('click', () => {
    const aligned = autoAlign(items)
    for (const id of Object.keys(aligned)) {
      positions[id] = aligned[id]
      placeCard(id)
    }
    for (const edge of edges) routeEdge(edge)
  })

  // --- render the full board from the current item list ---
  const render = () => {
    drawBoards()
    edgesLayer.innerHTML = ''
    cardsLayer.innerHTML = ''
    edges.length = 0
    Object.assign(positions, autoAlign(items))

    for (const item of items) {
      const g = renderCard(item, positions[item.id], { onToggleGate, onPickModel })
      wireCardDrag(g, item.id)
      cardEls[item.id] = g
      cardsLayer.appendChild(g)
    }
    // dependency edges from each item's deps[] (refresh() guarantees deps is an array)
    for (const item of items) {
      for (const dep of item.deps) {
        if (positions[dep]) addEdge(item.id, dep)
      }
    }
  }

  // --- connection-draw: ALWAYS validate server-side before committing ---
  const tryConnect = async (from, to) => {
    const res = await api.validateConnection(from, to)
    if (!res.ok) {
      announce(`Connection refused (${res.error}): ${res.message}`)
      return res
    }
    addEdge(from, to)
    announce('')
    return res
  }

  const refresh = async () => {
    // Clone on ingest: the canvas owns its working copy of each item (it mutates
    // gate on a successful toggle) and must never write back into the objects the
    // API handed it — one-way binding means data flows down, not back up.
    const fetched = await api.getItems()
    items = fetched.map((i) => ({ ...i, deps: [...(i.deps ?? [])] }))
    render()
  }

  // --- updateItemStatus: update one item's status in the working copy + re-render ---
  const updateItemStatus = (id, status) => {
    const item = items.find((i) => i.id === id)
    if (!item) return
    item.status = status
    rerenderCard(id)
    // Snap the card to its new column
    const aligned = autoAlign(items)
    positions[id] = aligned[id]
    placeCard(id)
    rerouteEdgesFor(id)
  }

  // --- WebSocket subscription: live status updates ---
  let ws = null
  let reconnectTimer = null

  const openWs = () => {
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:'
    const wsUrl = `${proto}//${location.host}/ws?token=${token}`
    ws = new WebSocket(wsUrl)

    ws.onmessage = (e) => {
      let msg
      try { msg = JSON.parse(e.data) } catch { return }
      if (msg.kind === 'status_posted') {
        updateItemStatus(msg.id, msg.status)
      }
      // Other kinds: no-op (future extensibility)
    }

    const scheduleReconnect = () => {
      reconnectTimer = setTimeout(() => {
        reconnectTimer = null
        refresh()
      }, 2000)
    }

    ws.onclose = scheduleReconnect
    ws.onerror = scheduleReconnect
  }

  openWs()

  await refresh()

  return {
    svg,
    getTransform: () => transform,
    tryConnect,
    refresh,
    getItems: () => items,
    updateItemStatus,
    disconnect: () => {
      if (ws) {
        ws.onclose = null
        ws.onerror = null
        ws.close()
      }
      if (reconnectTimer != null) {
        clearTimeout(reconnectTimer)
        reconnectTimer = null
      }
    }
  }
}
