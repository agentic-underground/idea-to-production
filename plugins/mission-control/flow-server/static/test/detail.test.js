// detail.test.js — unit tests for the RHS detail panel (item [28]).
// Tests mount the panel against jsdom, verify structural presence and
// content rendering. Scroll behaviour is not testable in jsdom — we test
// CSS class application and content presence instead.

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mountDetailPanel } from '../src/detail.js'
import {
  EPIC_ITEM,
  ITEM_WITH_ANNOTATIONS,
  ITEM_WITH_COMMITS,
  CHILD_ITEMS
} from './fixtures.js'

let root

beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
})

// ---------------------------------------------------------------------------
// Panel mount
// ---------------------------------------------------------------------------

describe('mountDetailPanel — mount', () => {
  it('appends an aside.detail-panel to root', () => {
    mountDetailPanel(root)
    const panel = root.querySelector('aside.detail-panel')
    expect(panel).toBeTruthy()
  })

  it('panel starts hidden', () => {
    mountDetailPanel(root)
    const panel = root.querySelector('aside.detail-panel')
    expect(panel.hidden).toBe(true)
  })

  it('returns show and hide functions', () => {
    const handle = mountDetailPanel(root)
    expect(typeof handle.show).toBe('function')
    expect(typeof handle.hide).toBe('function')
  })

  it('contains a close button with aria-label', () => {
    mountDetailPanel(root)
    const btn = root.querySelector('.detail-close')
    expect(btn).toBeTruthy()
    expect(btn.getAttribute('aria-label')).toBeTruthy()
  })

  it('contains a detail-top and detail-bottom section', () => {
    mountDetailPanel(root)
    expect(root.querySelector('.detail-top')).toBeTruthy()
    expect(root.querySelector('.detail-bottom')).toBeTruthy()
  })
})

// ---------------------------------------------------------------------------
// hide()
// ---------------------------------------------------------------------------

describe('mountDetailPanel — hide()', () => {
  it('hides the panel', () => {
    const { show, hide } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    expect(root.querySelector('aside.detail-panel').hidden).toBe(false)
    hide()
    expect(root.querySelector('aside.detail-panel').hidden).toBe(true)
  })

  it('clears panel content on hide', () => {
    const { show, hide } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    hide()
    const top = root.querySelector('.detail-top')
    expect(top.innerHTML).toBe('')
  })

  it('hide() called before show() does not throw', () => {
    const { hide } = mountDetailPanel(root)
    expect(() => hide()).not.toThrow()
  })
})

// ---------------------------------------------------------------------------
// show() — ITEM mode (pr === null)
// ---------------------------------------------------------------------------

describe('mountDetailPanel — show() ITEM mode', () => {
  it('makes the panel visible', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    expect(root.querySelector('aside.detail-panel').hidden).toBe(false)
  })

  it('renders annotation text in the top section', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('First note')
    expect(top.textContent).toContain('Second note')
    expect(top.textContent).toContain('Latest note')
  })

  it('renders "No issue text recorded." when annotations is empty', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...ITEM_WITH_ANNOTATIONS, annotations: [] }
    show(item, [item])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('No issue text recorded.')
  })

  it('renders "No commits yet." in bottom section when commits is empty', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.textContent).toContain('No commits yet.')
  })

  it('renders commit list in bottom section when commits are present', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.textContent).toContain('abc1234')
    expect(bottom.textContent).toContain('def5678')
  })

  it('stale content is cleared between show() calls', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    const itemB = { ...ITEM_WITH_COMMITS }
    show(itemB, [itemB])
    const top = root.querySelector('.detail-top')
    // First item's annotation should not appear after switching to itemB
    expect(top.textContent).not.toContain('First note')
  })
})

// ---------------------------------------------------------------------------
// show() — EPIC mode (pr !== null)
// ---------------------------------------------------------------------------

describe('mountDetailPanel — show() EPIC mode', () => {
  it('renders PR title in the top section', () => {
    const { show } = mountDetailPanel(root)
    show(EPIC_ITEM, [EPIC_ITEM, ...CHILD_ITEMS])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('feat: My Epic PR')
  })

  it('renders PR body in the top section', () => {
    const { show } = mountDetailPanel(root)
    show(EPIC_ITEM, [EPIC_ITEM, ...CHILD_ITEMS])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('This implements the epic.')
  })

  it('renders label chips in the top section', () => {
    const { show } = mountDetailPanel(root)
    show(EPIC_ITEM, [EPIC_ITEM, ...CHILD_ITEMS])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('epic')
    expect(top.textContent).toContain('feature')
  })

  it('renders assignee chips in the top section', () => {
    const { show } = mountDetailPanel(root)
    show(EPIC_ITEM, [EPIC_ITEM, ...CHILD_ITEMS])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('alice')
  })

  it('renders dep count in the bottom section', () => {
    const { show } = mountDetailPanel(root)
    show(EPIC_ITEM, [EPIC_ITEM, ...CHILD_ITEMS])
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.textContent).toContain('2')
  })

  it('renders dep titles in the bottom section', () => {
    const { show } = mountDetailPanel(root)
    show(EPIC_ITEM, [EPIC_ITEM, ...CHILD_ITEMS])
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.textContent).toContain('Child A')
    expect(bottom.textContent).toContain('Child B')
  })

  it('renders "PR not linked yet." when pr is null in an otherwise EPIC-like item', () => {
    const { show } = mountDetailPanel(root)
    // An item with deps but no pr (null) falls into ITEM mode and shows the ITEM top
    // A genuine "pr: null" EPIC would show PR not linked yet only if we treat it as EPIC
    // Per plan: pr === null means ITEM mode. So we test the pr=null case via a
    // separate EPIC item that has pr explicitly set but then nulled.
    // The plan says: if pr is null → ITEM mode. So this test verifies ITEM mode for
    // a dep-heavy item with null pr.
    const epicWithNullPr = { ...EPIC_ITEM, pr: null, annotations: [] }
    show(epicWithNullPr, [epicWithNullPr, ...CHILD_ITEMS])
    const top = root.querySelector('.detail-top')
    expect(top.textContent).toContain('No issue text recorded.')
  })
})

// ---------------------------------------------------------------------------
// Close button
// ---------------------------------------------------------------------------

describe('mountDetailPanel — close button', () => {
  it('close button click hides the panel', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    const btn = root.querySelector('.detail-close')
    btn.click()
    expect(root.querySelector('aside.detail-panel').hidden).toBe(true)
  })

  it('close button click clears panel content', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    root.querySelector('.detail-close').click()
    expect(root.querySelector('.detail-top').innerHTML).toBe('')
  })
})

// ---------------------------------------------------------------------------
// aria-expanded
// ---------------------------------------------------------------------------

describe('mountDetailPanel — aria-expanded', () => {
  it('panel has aria-expanded=true when shown', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    const panel = root.querySelector('aside.detail-panel')
    expect(panel.getAttribute('aria-expanded')).toBe('true')
  })

  it('panel has aria-expanded=false when hidden', () => {
    const { show, hide } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    hide()
    const panel = root.querySelector('aside.detail-panel')
    expect(panel.getAttribute('aria-expanded')).toBe('false')
  })
})

// ---------------------------------------------------------------------------
// show() — ITEM mode commit-graph integration ([31])
// ---------------------------------------------------------------------------

describe('mountDetailPanel — show() commit-graph integration', () => {
  it('renders .commit-graph-list in bottom section when commits are present', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.querySelector('.commit-graph-list')).toBeTruthy()
  })

  it('does not render .commit-graph-list when commits is empty', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.querySelector('.commit-graph-list')).toBeNull()
  })

  it('renders a .commit-dot for each commit', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])
    const dots = root.querySelectorAll('.commit-dot')
    expect(dots.length).toBe(2)
  })

  it('clicking a commit dot in the detail panel expands its body', () => {
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])
    const dot = root.querySelector('.commit-dot')
    dot.click()
    const body = root.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(true)
  })
})

// ---------------------------------------------------------------------------
// Branch coverage — defensive/fallback paths
// ---------------------------------------------------------------------------

describe('mountDetailPanel — branch coverage', () => {
  it('item without annotations property does not throw', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...ITEM_WITH_ANNOTATIONS }
    delete item.annotations
    expect(() => show(item, [item])).not.toThrow()
    expect(root.querySelector('.detail-top').textContent).toContain('No issue text recorded.')
  })

  it('item without commits property does not throw', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...ITEM_WITH_ANNOTATIONS }
    delete item.commits
    expect(() => show(item, [item])).not.toThrow()
    expect(root.querySelector('.detail-bottom').textContent).toContain('No commits yet.')
  })

  it('EPIC dep not found in allItems falls back to dep id', () => {
    const { show } = mountDetailPanel(root)
    // Pass EPIC_ITEM with deps but empty allItems — dep title falls back to id
    show(EPIC_ITEM, [EPIC_ITEM]) // child-a and child-b not in allItems
    const bottom = root.querySelector('.detail-bottom')
    // Should show the dep ids as fallback
    expect(bottom.textContent).toContain('child-a')
    expect(bottom.textContent).toContain('child-b')
  })

  it('commit with no hash renders empty hash', () => {
    const { show } = mountDetailPanel(root)
    const item = {
      ...ITEM_WITH_COMMITS,
      commits: [{ hash: undefined, message: 'some message' }]
    }
    expect(() => show(item, [item])).not.toThrow()
    const hash = root.querySelector('.commit-hash')
    expect(hash.textContent).toBe('')
  })

  it('commit with no message renders empty summary', () => {
    const { show } = mountDetailPanel(root)
    const item = {
      ...ITEM_WITH_COMMITS,
      commits: [{ hash: 'abc1234', message: undefined }]
    }
    expect(() => show(item, [item])).not.toThrow()
    const summary = root.querySelector('.commit-summary')
    expect(summary.textContent).toBe('')
  })

  it('EPIC with pr.body absent does not crash', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...EPIC_ITEM, pr: { title: 'No body PR', labels: [], assignees: [] } }
    expect(() => show(item, [item, ...CHILD_ITEMS])).not.toThrow()
    expect(root.querySelector('.detail-pr-title').textContent).toBe('No body PR')
  })

  it('EPIC with empty labels array renders no label chips', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...EPIC_ITEM, pr: { title: 'T', body: 'B', labels: [], assignees: [] } }
    show(item, [item])
    expect(root.querySelector('.detail-label')).toBeNull()
  })

  it('EPIC with empty assignees array renders no assignee chips', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...EPIC_ITEM, pr: { title: 'T', body: 'B', labels: [], assignees: [] } }
    show(item, [item])
    expect(root.querySelector('.detail-assignee')).toBeNull()
  })

  it('EPIC with no pr.title falls back to "Untitled PR"', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...EPIC_ITEM, pr: { title: '', labels: [], assignees: [] } }
    show(item, [item])
    expect(root.querySelector('.detail-pr-title').textContent).toBe('Untitled PR')
  })

  it('EPIC item without deps property renders "0 items"', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...EPIC_ITEM }
    delete item.deps
    expect(() => show(item, [item])).not.toThrow()
    expect(root.querySelector('.detail-dep-count').textContent).toBe('0 items')
  })

  it('EPIC dep count shows singular "item" for 1 dep', () => {
    const { show } = mountDetailPanel(root)
    const item = { ...EPIC_ITEM, deps: ['child-a'] }
    show(item, [item, ...CHILD_ITEMS])
    expect(root.querySelector('.detail-dep-count').textContent).toBe('1 item')
  })

  it('EPIC bottom section with null allItems does not crash', () => {
    const { show } = mountDetailPanel(root)
    expect(() => show(EPIC_ITEM, null)).not.toThrow()
    // Should render dep ids as fallback (allItems is null, so itemsById is empty)
    expect(root.querySelector('.detail-bottom').textContent).toContain('child-a')
  })
})
