// progress.js — the PURE completion + feed core for the masthead (roadmap #6).
// No DOM, no IO: derive the DONE fraction of the roadmap, whether it is complete
// ("run & observe"), and the newest-first system-message stream from the event
// log. These are the coordinates the masthead bar, pac-man gauge, and feed wire
// to; unit-tested directly.
//
// @front-end
// element: flow-progress-core
// philosophy: recognition-over-recall — "how close are we to done" read at a glance
// paradigm: dashboard-explorative
// intent: turn the item list + event log into the three numbers/lists the masthead
//         renders — the DONE fraction (bar + gauge fill), the complete flag (the
//         "run & observe" signal), and the newest-first system-message feed
// customer: solo-builder
// binding: one-way                # items/events in → fraction/flag/list out; mutates nothing
// render-trigger: items.changed
// a11y: wcag-2.1-aa               # pure data; the DOM layer carries roles/labels
// improve?: "weight the fraction by token cost or item size once #3 telemetry lands,
//            so the bar reflects effort done, not just item count"
// breadcrumbs: ["fraction = done / total; an empty board is 0 (not NaN, never complete)",
//               "isComplete is true ONLY when every item is done AND there is ≥1 item",
//               "sysMessages keeps kind==='sys_msg' and returns newest-first (reverses log order)"]

const isDone = (item) => item.status === 'done'

/** The fraction (0..1) of items whose status is "done". Empty board ⇒ 0. */
export function doneFraction(items) {
  if (!items.length) return 0
  return items.filter(isDone).length / items.length
}

/** The DONE fraction as a whole-number percent (0..100). */
export function donePercent(items) {
  return Math.round(doneFraction(items) * 100)
}

/** True iff there is at least one item and every item is done. */
export function isComplete(items) {
  return items.length > 0 && items.every(isDone)
}

/**
 * The system-message feed: keep only `kind === "sys_msg"` events and return them
 * newest-first (the event log is append-only / oldest-first). Degrades to an empty
 * array for a non-array input so a failed fetch never crashes the feed.
 */
export function sysMessages(events) {
  if (!Array.isArray(events)) return []
  return events.filter((e) => e.kind === 'sys_msg').reverse()
}
