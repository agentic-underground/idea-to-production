// app.js — the browser bootstrap shim for the SVG flow-canvas. Resolves the
// bearer token (from ?token= or localStorage), wires the token form, mounts the
// canvas against the live flow-server, and re-mounts when the token is supplied.
// This file is the thin wiring proven at the STORY layer (Playwright); the logic
// it composes — layout, card, canvas, api — is unit-covered to 100%.
//
// @front-end
// element: flow-app
// intent: get the builder onto the live governance canvas with the least friction,
//         persisting their token so the board is one click away next time
// customer: solo-builder
// binding: one-way
// privacy: token is kept only in this browser; never sent anywhere but as the
//          Authorization bearer to the local flow-server that issued it
// improve?: "open the WS delta stream here and call handle.refresh() on each delta
//            so the board live-updates (roadmap #1/#6)"

import { resolveToken, saveToken, TOKEN_KEY } from './src/api.js'
import { createApi } from './src/api.js'
import { mountCanvas } from './src/canvas.js'

function mountTokenForm(root, onToken) {
  root.innerHTML = ''
  const form = document.createElement('form')
  form.className = 'token-form'
  form.innerHTML = `
    <h1>Flow canvas</h1>
    <p>Paste the flow-server bearer token to connect to the live board.</p>
    <label>Bearer token
      <input type="password" name="token" autocomplete="off" required />
    </label>
    <button type="submit">Connect</button>
  `
  form.addEventListener('submit', (e) => {
    e.preventDefault()
    const token = form.elements.token.value.trim()
    if (!token) return
    saveToken(token)
    onToken(token)
  })
  root.appendChild(form)
  form.elements.token.focus()
}

async function boot() {
  const root = document.getElementById('app')
  const token = resolveToken(window.location.search)

  // strip ?token= from the URL bar so the secret is not left in history/sharing
  if (token && window.location.search.includes('token=')) {
    const url = new URL(window.location.href)
    url.searchParams.delete('token')
    window.history.replaceState({}, '', url)
  }

  if (!token) {
    mountTokenForm(root, () => boot())
    return
  }

  const api = createApi(token)
  try {
    await mountCanvas(root, { api, token })
  } catch (err) {
    // a bad/expired token (401) drops the builder back to the token form
    if (/401|403/.test(String(err.message))) {
      localStorage.removeItem(TOKEN_KEY)
      mountTokenForm(root, () => boot())
      return
    }
    const note = document.createElement('div')
    note.setAttribute('role', 'alert')
    note.className = 'flow-alert'
    note.textContent = `Could not load the board: ${err.message}`
    root.appendChild(note)
  }
}

if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot)
  } else {
    boot()
  }
}

export { boot, mountTokenForm }
