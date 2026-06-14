// masthead.js — the top-of-screen governance masthead (roadmap #6): a progress
// bar + a pac-man completion gauge whose fill is the fraction of items that are
// DONE, and a system-message feed (a mini-blog of orchestrator updates, newest
// first). At 100% the masthead reads complete and surfaces the "run & observe"
// state. Data flows DOWN (items + the event log) into render; the masthead emits
// nothing — it is a pure view. It degrades gracefully when the event endpoint
// errors (empty feed, no crash) and when no api is wired at all.
//
// @front-end
// element: flow-masthead
// philosophy: instrument-panel — completion is glanceable and motivating
// paradigm: dashboard-explorative
// intent: tell a solo builder, at a glance and from the top of the screen, how close
//         the project is to "done / run & observe", and let them read what the value
//         system has been doing — without leaving the board
// customer: solo-builder
// binding: one-way                # items/events in → bar + gauge + feed out; emits nothing
// render-trigger: items.changed
// modality: { touch: read, mouse: read, keyboard: read }   # a glanceable status surface
// style: operation
// a11y: wcag-2.1-aa               # the bar is a role=progressbar with valuenow/min/max; the
//                                   gauge is a labelled role=img; the feed is a role=log; the
//                                   percent is shown as text (never colour alone)
// improve?: "subscribe to the WS delta stream and prepend new sys_msgs live (roadmap #1/#6)
//            instead of re-fetching on refresh(); animate the pac-man mouth as it fills"
// breadcrumbs: ["fill width + gauge data-percent come from progress.donePercent(items)",
//               "data-complete='true' ⇔ progress.isComplete(items) (≥1 item, all done)",
//               "the feed reads progress.sysMessages(events) — newest-first, sys_msg only",
//               "a failed/absent getEvents ⇒ empty feed, the bar/gauge still render"]

import { donePercent, isComplete, sysMessages } from './progress.js'

const SVG_NS = 'http://www.w3.org/2000/svg'

/**
 * Render the pac-man gauge: a disc with a wedge "mouth" whose openness narrows as
 * completion rises (a full disc at 100%). Labelled role=img, carrying data-percent.
 */
function renderPacman(percent) {
  const svg = document.createElementNS(SVG_NS, 'svg')
  svg.setAttribute('class', 'masthead-pacman')
  svg.setAttribute('viewBox', '0 0 32 32')
  svg.setAttribute('role', 'img')
  svg.setAttribute('aria-label', `Completion: ${percent}%`)
  svg.setAttribute('data-percent', String(percent))
  svg.setAttribute('width', '32')
  svg.setAttribute('height', '32')

  // The mouth half-angle goes from ~40° (open, 0%) to 0° (closed, 100%).
  const half = ((100 - percent) / 100) * 40 // degrees
  const r = 15
  const cx = 16
  const cy = 16
  const rad = (deg) => (deg * Math.PI) / 180
  const upper = { x: cx + r * Math.cos(rad(-half)), y: cy + r * Math.sin(rad(-half)) }
  const lower = { x: cx + r * Math.cos(rad(half)), y: cy + r * Math.sin(rad(half)) }
  // large-arc sweeps the disc minus the mouth wedge
  const path = document.createElementNS(SVG_NS, 'path')
  path.setAttribute('class', 'pacman-body')
  path.setAttribute('d', `M ${cx} ${cy} L ${upper.x.toFixed(2)} ${upper.y.toFixed(2)} A ${r} ${r} 0 1 1 ${lower.x.toFixed(2)} ${lower.y.toFixed(2)} Z`)
  svg.appendChild(path)
  return svg
}

/**
 * Mount the masthead into `root`. Returns a handle:
 *   { masthead, refresh(nextItems?) }
 * `refresh` re-derives the gauges from `nextItems` (or the current items) and
 * re-reads the event feed from the api.
 */
export async function mountMasthead(root, { items = [], api } = {}) {
  let current = items

  const masthead = document.createElement('header')
  masthead.className = 'flow-masthead'
  masthead.setAttribute('data-testid', 'flow-masthead')

  // --- progress bar (with a text percent + the pac-man gauge) ---
  const barWrap = document.createElement('div')
  barWrap.className = 'masthead-bar'
  const bar = document.createElement('div')
  bar.setAttribute('role', 'progressbar')
  bar.setAttribute('aria-label', 'Roadmap progress')
  bar.setAttribute('aria-valuemin', '0')
  bar.setAttribute('aria-valuemax', '100')
  const fill = document.createElement('div')
  fill.className = 'masthead-fill'
  bar.appendChild(fill)
  barWrap.appendChild(bar)

  const percentLabel = document.createElement('span')
  percentLabel.className = 'masthead-percent'

  const completeLabel = document.createElement('span')
  completeLabel.className = 'masthead-complete'

  let gaugeSlot = document.createElement('span')
  gaugeSlot.className = 'masthead-gauge'

  const status = document.createElement('div')
  status.className = 'masthead-status'
  status.append(gaugeSlot, percentLabel, completeLabel)

  // --- system-message feed ---
  const feed = document.createElement('ul')
  feed.setAttribute('role', 'log')
  feed.setAttribute('aria-label', 'System messages')
  feed.setAttribute('aria-live', 'polite')
  feed.className = 'masthead-feed'
  const feedEmpty = document.createElement('li')
  feedEmpty.className = 'masthead-feed-empty'
  // presentation role: it is an affordance, not a message entry, so it must not
  // be counted among the feed's listitems.
  feedEmpty.setAttribute('role', 'presentation')
  feedEmpty.textContent = 'No system messages yet.'

  masthead.append(barWrap, status, feed)
  root.appendChild(masthead)

  const renderGauges = () => {
    const pct = donePercent(current)
    const complete = isComplete(current)
    bar.setAttribute('aria-valuenow', String(pct))
    fill.style.width = `${pct}%`
    percentLabel.textContent = `${pct}%`
    masthead.setAttribute('data-complete', complete ? 'true' : 'false')
    completeLabel.textContent = complete ? 'Run & observe' : ''
    const gauge = renderPacman(pct)
    gaugeSlot.replaceWith(gauge)
    gauge.classList.add('masthead-gauge')
    gaugeSlot = gauge
  }

  const renderFeed = (events) => {
    const msgs = sysMessages(events)
    feed.innerHTML = ''
    if (!msgs.length) {
      feed.appendChild(feedEmpty)
      return
    }
    for (const msg of msgs) {
      const li = document.createElement('li')
      li.className = 'masthead-feed-item'
      li.textContent = msg.text
      feed.appendChild(li)
    }
  }

  const loadFeed = async () => {
    if (!api) {
      renderFeed([])
      return
    }
    try {
      renderFeed(await api.getEvents())
    } catch {
      // degrade gracefully — an empty feed, the rest of the masthead intact
      renderFeed([])
    }
  }

  const refresh = async (nextItems) => {
    if (nextItems) current = nextItems
    renderGauges()
    await loadFeed()
  }

  await refresh()

  return { masthead, refresh }
}
