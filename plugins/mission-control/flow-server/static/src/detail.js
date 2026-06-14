// detail.js — the RHS detail panel for item [28].
// Renders item details (PR info for EPICs, annotations + commits for items)
// in an <aside> panel beside the SVG canvas.
//
// @front-end
// element: detail-panel
// philosophy: recognition-over-recall
// paradigm: dashboard-explorative
// intent: let a solo builder inspect issue text, PR linkage, and commit history
//         for any card without leaving the board view
// customer: solo-builder
// binding: one-way (item data in, close intent out)
// a11y: wcag-2.1-aa — aside with aria-label, aria-expanded, close button ≥44px
// improve?: "extend show() bottom section to a dot-and-line SVG commit graph
//            when [31] (commit-graph view) is implemented"

/**
 * Mount the detail panel into `root`.
 * Returns { show(item, allItems), hide() }.
 *
 * Panel structure:
 *   <aside class="detail-panel" hidden aria-label="Item detail" aria-expanded="false">
 *     <button class="detail-close" aria-label="Close detail">×</button>
 *     <section class="detail-top" aria-label="Primary content"></section>
 *     <section class="detail-bottom" aria-label="Secondary content"></section>
 *   </aside>
 */
export function mountDetailPanel(root) {
  const aside = document.createElement('aside')
  aside.className = 'detail-panel'
  aside.setAttribute('aria-label', 'Item detail')
  aside.setAttribute('aria-expanded', 'false')
  aside.hidden = true

  const closeBtn = document.createElement('button')
  closeBtn.className = 'detail-close'
  closeBtn.setAttribute('aria-label', 'Close detail')
  closeBtn.type = 'button'
  closeBtn.textContent = '×'

  const topSection = document.createElement('section')
  topSection.className = 'detail-top'
  topSection.setAttribute('aria-label', 'Primary content')

  const bottomSection = document.createElement('section')
  bottomSection.className = 'detail-bottom'
  bottomSection.setAttribute('aria-label', 'Secondary content')

  aside.appendChild(closeBtn)
  aside.appendChild(topSection)
  aside.appendChild(bottomSection)
  root.appendChild(aside)

  // --- hide ---------------------------------------------------------------

  function hide() {
    topSection.innerHTML = ''
    bottomSection.innerHTML = ''
    aside.hidden = true
    aside.setAttribute('aria-expanded', 'false')
  }

  closeBtn.addEventListener('click', hide)

  // --- show ---------------------------------------------------------------

  /**
   * Show the detail panel for `item`. `allItems` is the full item list, used
   * to resolve dep titles for EPIC mode.
   *
   * Mode detection:
   *   EPIC mode — item.pr is not null (has PR linkage)
   *   ITEM mode — item.pr is null (the common case in this cycle)
   */
  function show(item, allItems) {
    // Clear stale content first so no cross-item bleed.
    topSection.innerHTML = ''
    bottomSection.innerHTML = ''

    if (item.pr !== null && item.pr !== undefined) {
      renderEpicTop(item, topSection)
      renderEpicBottom(item, allItems, bottomSection)
    } else {
      renderItemTop(item, topSection)
      renderItemBottom(item, bottomSection)
    }

    aside.hidden = false
    aside.setAttribute('aria-expanded', 'true')
  }

  // --- EPIC mode renderers ------------------------------------------------

  function renderEpicTop(item, container) {
    const pr = item.pr

    // PR title
    const titleEl = document.createElement('h2')
    titleEl.className = 'detail-pr-title'
    titleEl.textContent = pr.title || 'Untitled PR'
    container.appendChild(titleEl)

    // PR body
    if (pr.body) {
      const bodyEl = document.createElement('p')
      bodyEl.className = 'detail-pr-body'
      bodyEl.textContent = pr.body
      container.appendChild(bodyEl)
    }

    // Label chips
    if (pr.labels && pr.labels.length > 0) {
      const labelsRow = document.createElement('div')
      labelsRow.className = 'detail-chips-row detail-labels-row'
      for (const label of pr.labels) {
        const chip = document.createElement('span')
        chip.className = 'detail-label'
        chip.textContent = label
        labelsRow.appendChild(chip)
      }
      container.appendChild(labelsRow)
    }

    // Assignee chips
    if (pr.assignees && pr.assignees.length > 0) {
      const assigneesRow = document.createElement('div')
      assigneesRow.className = 'detail-chips-row detail-assignees-row'
      for (const assignee of pr.assignees) {
        const chip = document.createElement('span')
        chip.className = 'detail-assignee'
        chip.textContent = assignee
        assigneesRow.appendChild(chip)
      }
      container.appendChild(assigneesRow)
    }
  }

  function renderEpicBottom(item, allItems, container) {
    const deps = item.deps || []
    const count = deps.length

    const countEl = document.createElement('p')
    countEl.className = 'detail-dep-count'
    countEl.textContent = `${count} item${count !== 1 ? 's' : ''}`
    container.appendChild(countEl)

    if (count > 0) {
      const list = document.createElement('ul')
      list.className = 'detail-dep-list'
      const itemsById = new Map((allItems || []).map((i) => [i.id, i]))
      for (const depId of deps) {
        const li = document.createElement('li')
        li.className = 'detail-dep-item'
        const depItem = itemsById.get(depId)
        li.textContent = depItem ? depItem.title : depId
        list.appendChild(li)
      }
      container.appendChild(list)
    }
  }

  // --- ITEM mode renderers ------------------------------------------------

  function renderItemTop(item, container) {
    const annotations = item.annotations || []

    if (annotations.length === 0) {
      const placeholder = document.createElement('p')
      placeholder.className = 'detail-placeholder'
      placeholder.textContent = 'No issue text recorded.'
      container.appendChild(placeholder)
      return
    }

    for (const text of annotations) {
      const p = document.createElement('p')
      p.className = 'detail-annotation'
      p.textContent = text
      container.appendChild(p)
    }
  }

  function renderItemBottom(item, container) {
    const commits = item.commits || []

    if (commits.length === 0) {
      const placeholder = document.createElement('p')
      placeholder.className = 'detail-placeholder'
      placeholder.textContent = 'No commits yet.'
      container.appendChild(placeholder)
      return
    }

    const list = document.createElement('ul')
    list.className = 'detail-commit-list'
    for (const commit of commits) {
      const li = document.createElement('li')
      li.className = 'detail-commit-item'
      const hash = document.createElement('code')
      hash.className = 'detail-commit-hash'
      hash.textContent = commit.hash ? commit.hash.slice(0, 7) : ''
      const msg = document.createElement('span')
      msg.className = 'detail-commit-msg'
      msg.textContent = commit.message ? commit.message.split('\n')[0] : ''
      li.appendChild(hash)
      li.appendChild(msg)
      list.appendChild(li)
    }
    container.appendChild(list)
  }

  return { show, hide }
}
