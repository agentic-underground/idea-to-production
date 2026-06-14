// api.js — the thin transport layer between the canvas and the flow-server.
// Bearer-token resolution/persistence and typed fetch wrappers for the REST
// verbs the canvas uses. Data flows down (responses) and intents flow up (the
// POST verbs); nothing here touches the DOM.
//
// @front-end
// element: flow-api-client
// intent: let the canvas read items and the event feed, and post governance intents
//         (WAIT/GO, per-job model override, draw a connection, annotate/rewrite a plan)
//         over the server's token-gated REST surface
// customer: solo-builder
// binding: one-way
// a11y: n/a (transport)
// privacy: token lives only in this browser's localStorage; never transmitted
//          except as the Authorization bearer the server itself issued
// improve?: "add an AbortController + retry/backoff once the WS delta stream lands
//            (roadmap #1 broadcasts deltas; this client currently pulls)"
// breadcrumbs: ["server returns typed {error,message} JSON on 4xx",
//               "validate_connection: 200 ⇒ ok, 409 cycle/broken_dep, 404 unknown"]

/** localStorage key for the persisted bearer token. */
export const TOKEN_KEY = 'flow.token'

/**
 * Resolve the bearer token: a non-empty `?token=` query value wins (and is
 * persisted); otherwise fall back to the stored value; otherwise the empty string.
 */
export function resolveToken(search) {
  const params = new URLSearchParams(search)
  const fromQuery = params.get('token')
  if (fromQuery) {
    saveToken(fromQuery)
    return fromQuery
  }
  return localStorage.getItem(TOKEN_KEY) ?? ''
}

/** Persist (or, given an empty value, clear) the bearer token. */
export function saveToken(token) {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token)
  } else {
    localStorage.removeItem(TOKEN_KEY)
  }
}

/** Build a token-bound API client. */
export function createApi(token) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`
  }

  const postJson = async (url, body) => {
    const res = await fetch(url, { method: 'POST', headers, body: JSON.stringify(body) })
    return res
  }

  return {
    /** GET the item array (throws on a non-ok response). */
    async getItems() {
      const res = await fetch('/api/items', { headers })
      if (!res.ok) throw new Error(`getItems failed: ${res.status}`)
      return res.json()
    },

    /** POST a WAIT/GO gate change (throws on a non-ok response). */
    async setGate(id, gate) {
      const res = await postJson(`/api/items/${id}/gate`, { gate })
      if (!res.ok) throw new Error(`setGate failed: ${res.status}`)
      return res.json()
    },

    /**
     * POST a per-job model assignment. `model` is an allowlisted model id to
     * override with, or `null` to clear the override (revert to the default).
     * Throws on a non-ok response (e.g. the server refuses an off-allowlist model).
     */
    async setModel(id, model) {
      const res = await postJson(`/api/items/${id}/model`, { model })
      if (!res.ok) throw new Error(`setModel failed: ${res.status}`)
      return res.json()
    },

    /**
     * POST a proposed connection for validation. Resolves {ok:true} on 200, or
     * {ok:false, error, message} on a typed rejection (cycle / broken_dep / unknown).
     */
    async validateConnection(from, to) {
      const res = await postJson('/api/connection/validate', { from, to })
      if (res.ok) return { ok: true }
      const body = await res.json()
      return { ok: false, error: body.error, message: body.message }
    },

    /**
     * POST a comment to be appended to the item's plan markdown as an annotation
     * (the Ctrl-Enter path of the comment/pause/annotate loop). Throws on a non-ok
     * response so the caller can surface the failure.
     */
    async annotate(id, text) {
      const res = await postJson(`/api/items/${id}/annotate`, { text })
      if (!res.ok) throw new Error(`annotate failed: ${res.status}`)
      return res.json()
    },

    /**
     * POST a comment to the carriage agent to re-draft the item. Resolves the
     * server's `{ draft }` (the new draft number) so the card's draft# badge can
     * advance. Throws on a non-ok response.
     */
    async rewrite(id, comment) {
      const res = await postJson(`/api/items/${id}/rewrite`, { comment })
      if (!res.ok) throw new Error(`rewrite failed: ${res.status}`)
      return res.json()
    },

    /**
     * POST a status change for an item (drag-to-column or REDO flow). Throws on a
     * non-ok response so the caller can rollback the optimistic update.
     */
    async postStatus(id, status) {
      const res = await postJson(`/api/items/${id}/status`, { status })
      if (!res.ok) throw new Error(`postStatus failed: ${res.status}`)
      return res.json()
    },

    /**
     * GET the orchestrator event array (the system-message feed source). Throws on
     * a non-ok response so the feed can degrade gracefully (empty feed, no crash).
     */
    async getEvents() {
      const res = await fetch('/api/events', { headers })
      if (!res.ok) throw new Error(`getEvents failed: ${res.status}`)
      return res.json()
    }
  }
}
