// commit-graph.js — dot-and-line commit graph renderer for item [31].
// Renders a git-style vertical dot list into a container element.
// Each dot is clickable/keyboard-navigable and expands the full commit message.
//
// @front-end
// element: commit-graph
// philosophy: recognition-over-recall
// paradigm: dashboard-explorative
// intent: let a solo builder scan commit history for any roadmap item at a glance
//         and expand individual commits to read the full message
// customer: solo-builder
// binding: one-way (commit data in, interaction out via DOM events)
// a11y: wcag-2.1-aa — role=button, tabindex=0, aria-expanded, keyboard Enter/Space

const MAX_SUMMARY_LEN = 60

/**
 * Render a git-style dot-and-line commit graph into `container`.
 *
 * @param {HTMLElement} container - the element to render into (cleared on call)
 * @param {Array<{hash: string, message: string}>} commits - newest-first
 */
export function renderCommitGraph(container, commits) {
  // Clear previous content
  container.innerHTML = ''

  if (!commits || commits.length === 0) {
    const placeholder = document.createElement('p')
    placeholder.className = 'detail-placeholder'
    placeholder.textContent = 'No commits yet.'
    container.appendChild(placeholder)
    return
  }

  const list = document.createElement('ul')
  list.className = 'commit-graph-list'

  // Track the currently expanded dot so we can collapse it when another opens.
  let activeDot = null
  let activeBody = null

  for (const commit of commits) {
    const li = document.createElement('li')

    // --- dot (the clickable circle) ----------------------------------------
    const dot = document.createElement('span')
    dot.className = 'commit-dot'
    dot.setAttribute('role', 'button')
    dot.setAttribute('tabindex', '0')
    dot.setAttribute('aria-expanded', 'false')
    dot.setAttribute('aria-label', `commit ${commit.hash || ''}`)

    // --- short hash --------------------------------------------------------
    const hashEl = document.createElement('span')
    hashEl.className = 'commit-hash'
    const shortHash = commit.hash ? commit.hash.slice(0, 7) : ''
    hashEl.textContent = shortHash

    // --- summary (first line, max 60 chars + ellipsis) ---------------------
    const summaryEl = document.createElement('span')
    summaryEl.className = 'commit-summary'
    const firstLine = commit.message ? commit.message.split('\n')[0] : ''
    summaryEl.textContent =
      firstLine.length > MAX_SUMMARY_LEN
        ? firstLine.slice(0, MAX_SUMMARY_LEN) + '...'
        : firstLine

    // --- disclosure body ---------------------------------------------------
    const bodyDiv = document.createElement('div')
    bodyDiv.className = 'commit-body'

    const pre = document.createElement('pre')
    // Full hash + full message in monospace
    pre.textContent = (commit.hash || '') + '\n' + (commit.message || '')
    bodyDiv.appendChild(pre)

    // --- toggle logic -------------------------------------------------------
    function toggle() {
      const isOpen = bodyDiv.classList.contains('open')

      // Collapse any currently-active entry (single-expand behaviour)
      if (activeBody && activeBody !== bodyDiv) {
        activeBody.classList.remove('open')
        activeDot.setAttribute('aria-expanded', 'false')
      }

      if (isOpen) {
        // Close this one
        bodyDiv.classList.remove('open')
        dot.setAttribute('aria-expanded', 'false')
        activeDot = null
        activeBody = null
      } else {
        // Open this one
        bodyDiv.classList.add('open')
        dot.setAttribute('aria-expanded', 'true')
        activeDot = dot
        activeBody = bodyDiv
      }
    }

    dot.addEventListener('click', toggle)
    dot.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        toggle()
      }
    })

    // Assemble: dot + hash + summary on one row, body below
    const row = document.createElement('div')
    row.className = 'commit-row'
    row.appendChild(dot)
    row.appendChild(hashEl)
    row.appendChild(summaryEl)

    li.appendChild(row)
    li.appendChild(bodyDiv)
    list.appendChild(li)
  }

  container.appendChild(list)
}
