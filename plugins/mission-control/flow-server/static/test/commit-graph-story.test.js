// commit-graph-story.test.js — story-level tests for item [31].
// These tests drive the full user story from mounting the detail panel
// through clicking a commit dot and reading the full message.
// They correspond to the Gherkin scenarios in commit-graph.feature.
//
// Story: As a solo-builder, I want to see commits for an item displayed
// as a dot-and-line graph so I can inspect commit history without leaving
// the board view.

import { describe, it, expect, beforeEach } from 'vitest'
import { mountDetailPanel } from '../src/detail.js'
import { ITEM_WITH_COMMITS, ITEM_WITH_ANNOTATIONS } from './fixtures.js'

let root

beforeEach(() => {
  document.body.innerHTML = ''
  root = document.createElement('div')
  document.body.appendChild(root)
})

// ---------------------------------------------------------------------------
// Story: Item with commits — see dot-and-line graph
// ---------------------------------------------------------------------------

describe('Story: commit-graph view', () => {
  it('solo-builder opens detail for item with commits and sees dot-and-line graph', () => {
    // Given: the detail panel is mounted
    const { show } = mountDetailPanel(root)

    // When: I open the detail panel for an item with commits
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])

    // Then: the bottom section shows a commit graph list
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.querySelector('.commit-graph-list')).toBeTruthy()

    // And: there are as many dots as commits (ITEM_WITH_COMMITS has 2)
    const dots = bottom.querySelectorAll('.commit-dot')
    expect(dots.length).toBe(2)
  })

  it('solo-builder clicks a commit dot and reads the full commit message', () => {
    // Given: the detail panel is open for an item with commits
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])

    // When: I click the first commit dot
    const dot = root.querySelector('.commit-dot')
    dot.click()

    // Then: the commit-body becomes visible
    const body = root.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(true)

    // And: the full commit message is present (including the multi-line body)
    const pre = body.querySelector('pre')
    expect(pre.textContent).toContain('abc1234')
    expect(pre.textContent).toContain('feat: add the thing')
    expect(pre.textContent).toContain('Longer body here.')
  })

  it('solo-builder clicks the same dot again and the message collapses', () => {
    // Given: a commit dot is already expanded
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])
    const dot = root.querySelector('.commit-dot')
    dot.click()

    // When: I click the same dot again
    dot.click()

    // Then: the message is hidden
    const body = root.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(false)
  })

  it('solo-builder expands one commit and then another — first collapses', () => {
    // Given: the panel is open for an item with 2 commits
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])
    const dots = root.querySelectorAll('.commit-dot')
    const bodies = root.querySelectorAll('.commit-body')

    // When: I expand the first commit
    dots[0].click()
    expect(bodies[0].classList.contains('open')).toBe(true)

    // When: I click the second commit dot
    dots[1].click()

    // Then: the second commit expands
    expect(bodies[1].classList.contains('open')).toBe(true)

    // And: the first commit collapses automatically
    expect(bodies[0].classList.contains('open')).toBe(false)
  })

  it('solo-builder sees "No commits yet." when item has no commits', () => {
    // Given: the detail panel is mounted
    const { show } = mountDetailPanel(root)

    // When: I open the detail panel for an item with no commits
    show(ITEM_WITH_ANNOTATIONS, [ITEM_WITH_ANNOTATIONS])

    // Then: the placeholder is shown
    const bottom = root.querySelector('.detail-bottom')
    expect(bottom.textContent).toContain('No commits yet.')

    // And: no commit graph list is rendered
    expect(bottom.querySelector('.commit-graph-list')).toBeNull()
  })

  it('solo-builder uses keyboard to navigate and expand a commit', () => {
    // Given: the detail panel is open with commits
    const { show } = mountDetailPanel(root)
    show(ITEM_WITH_COMMITS, [ITEM_WITH_COMMITS])

    // When: I press Enter on the first dot
    const dot = root.querySelector('.commit-dot')
    dot.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }))

    // Then: the commit body expands
    const body = root.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(true)
  })
})
