// model.js — the PURE per-job model-selection core. No DOM, no IO: the allowlist
// of marketplace models, label/short-name helpers, an allowlist guard, and the
// resolver that derives {model, default, isOverride} from a fetched item. These
// are the coordinates the model badge + picker are wired to; unit-tested directly.
//
// @front-end
// element: flow-model-core
// philosophy: recognition-over-recall (the resolved model + its default read at a glance)
// paradigm: dashboard-explorative
// intent: turn a fetched item's model fields into a glanceable "what model runs this,
//         and is that the default or my override" answer, and gate any change to the
//         configured allowlist so an off-menu model can never be chosen
// customer: solo-builder
// binding: one-way                # item in → {model,default,isOverride} out; mutates nothing
// render-trigger: items.changed
// a11y: wcag-2.1-aa               # pure data; the DOM layer carries roles/labels
// improve?: "let a project narrow the allowlist from server config (the picker already
//            accepts a custom list) — promote the family→version map when a 2nd surface needs it"
// breadcrumbs: ["resolved model = item.model; default = item.defaultModel ?? item.model",
//               "isOverride ⇔ a defaultModel is present AND differs from model",
//               "isAllowed(model, list=ALLOWLIST) is the single off-menu guard"]

/** The configurable default allowlist — marketplace model ids, cost→capability order. */
export const MODEL_ALLOWLIST = Object.freeze([
  'claude-haiku-4-5',
  'claude-sonnet-4-6',
  'claude-opus-4-8',
  'claude-fable-5'
])

/** Alias for the canonical default set (a project may pass its own narrowed list). */
export const DEFAULT_ALLOWLIST = MODEL_ALLOWLIST

/** family → display version, for the picker label (e.g. haiku ⇒ "Haiku 4.5"). */
const FAMILY_VERSION = {
  haiku: '4.5',
  sonnet: '4.6',
  opus: '4.8',
  fable: '5'
}

/** Shorten a marketplace model id to its family name (claude-opus-4-8 ⇒ "opus"). */
export function shortModel(model) {
  const m = /claude-([a-z]+)/.exec(model ?? '')
  return m ? m[1] : (model ?? '')
}

/** A human label for the picker: title-cased family + version (claude-opus-4-8 ⇒ "Opus 4.8"). */
export function modelLabel(model) {
  const family = shortModel(model)
  const version = FAMILY_VERSION[family]
  if (!version) return model
  return `${family[0].toUpperCase()}${family.slice(1)} ${version}`
}

/** True iff `model` is a member of `allowlist` (the off-menu guard). */
export function isAllowed(model, allowlist = MODEL_ALLOWLIST) {
  return allowlist.includes(model)
}

/**
 * Resolve an item's model assignment. The default is `defaultModel` when present,
 * else `model` itself (a server that does not yet expose a default ⇒ no override).
 * Returns { model, default, isOverride }.
 */
export function resolveModel(item) {
  const model = item.model ?? ''
  const def = item.defaultModel ?? model
  return { model, default: def, isOverride: model !== def }
}
