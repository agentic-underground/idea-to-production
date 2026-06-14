// commit-graph.test.js — unit tests for the dot-and-line commit graph renderer (item [31]).
// Tests run against jsdom. No layout geometry is available — we test structural
// presence, CSS class toggling, aria attributes, and text content.
//
// @front-end
// element: commit-graph
// philosophy: recognition-over-recall
// intent: verify every Gherkin scenario from commit-graph.feature

import { describe, it, expect, beforeEach } from 'vitest'
import { renderCommitGraph } from '../src/commit-graph.js'

let container

beforeEach(() => {
  document.body.innerHTML = ''
  container = document.createElement('div')
  document.body.appendChild(container)
})

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

describe('renderCommitGraph — empty commits', () => {
  it('renders "No commits yet." placeholder when commits is empty', () => {
    renderCommitGraph(container, [])
    expect(container.textContent).toContain('No commits yet.')
  })

  it('does not render a commit-graph-list when commits is empty', () => {
    renderCommitGraph(container, [])
    expect(container.querySelector('.commit-graph-list')).toBeNull()
  })

  it('does not throw when called with empty array', () => {
    expect(() => renderCommitGraph(container, [])).not.toThrow()
  })
})

// ---------------------------------------------------------------------------
// List structure with commits
// ---------------------------------------------------------------------------

describe('renderCommitGraph — list structure', () => {
  it('renders a .commit-graph-list when commits are present', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: first' }
    ])
    expect(container.querySelector('.commit-graph-list')).toBeTruthy()
  })

  it('renders the correct number of list items', () => {
    renderCommitGraph(container, [
      { hash: 'aaa0001', message: 'commit 1' },
      { hash: 'bbb0002', message: 'commit 2' },
      { hash: 'ccc0003', message: 'commit 3' }
    ])
    const items = container.querySelectorAll('.commit-graph-list li')
    expect(items.length).toBe(3)
  })

  it('renders 5 list items for 5 commits', () => {
    const commits = Array.from({ length: 5 }, (_, i) => ({
      hash: `hash${String(i).padStart(4, '0')}`,
      message: `commit ${i}`
    }))
    renderCommitGraph(container, commits)
    expect(container.querySelectorAll('.commit-graph-list li').length).toBe(5)
  })

  it('renders a .commit-dot in each list item', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' },
      { hash: 'def5678', message: 'fix: thing' }
    ])
    const dots = container.querySelectorAll('.commit-dot')
    expect(dots.length).toBe(2)
  })
})

// ---------------------------------------------------------------------------
// Short hash and summary
// ---------------------------------------------------------------------------

describe('renderCommitGraph — short hash and summary', () => {
  it('shows the first 7 chars of the hash in .commit-hash', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234abcdef', message: 'feat: thing' }
    ])
    const hashEl = container.querySelector('.commit-hash')
    expect(hashEl).toBeTruthy()
    expect(hashEl.textContent).toBe('abc1234')
  })

  it('shows the first line of the message as the summary', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: first line\n\nSecond paragraph.' }
    ])
    const summary = container.querySelector('.commit-summary')
    expect(summary).toBeTruthy()
    expect(summary.textContent).toContain('feat: first line')
    expect(summary.textContent).not.toContain('Second paragraph')
  })

  it('truncates summary to 60 chars with ellipsis when first line is long', () => {
    const longLine = 'a'.repeat(80)
    renderCommitGraph(container, [
      { hash: 'abc1234', message: longLine }
    ])
    const summary = container.querySelector('.commit-summary')
    expect(summary.textContent.length).toBeLessThanOrEqual(64) // 60 + '...' + some tolerance
    expect(summary.textContent).toContain('...')
  })

  it('does not add ellipsis when summary is 60 chars or less', () => {
    const shortLine = 'a'.repeat(60)
    renderCommitGraph(container, [
      { hash: 'abc1234', message: shortLine }
    ])
    const summary = container.querySelector('.commit-summary')
    expect(summary.textContent).not.toContain('...')
  })
})

// ---------------------------------------------------------------------------
// Expand / collapse on click
// ---------------------------------------------------------------------------

describe('renderCommitGraph — click to expand/collapse', () => {
  it('commit-body is hidden by default', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing\n\nBody here.' }
    ])
    const body = container.querySelector('.commit-body')
    expect(body).toBeTruthy()
    expect(body.classList.contains('open')).toBe(false)
  })

  it('clicking a dot reveals the commit-body (adds class "open")', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing\n\nBody here.' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    const body = container.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(true)
  })

  it('clicking the same dot again hides the commit-body (removes class "open")', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    dot.click()
    const body = container.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(false)
  })

  it('commit-body contains the full hash in a <pre>', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234abcdef', message: 'feat: thing\n\nFull body here.' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    const pre = container.querySelector('.commit-body pre')
    expect(pre).toBeTruthy()
    expect(pre.textContent).toContain('abc1234abcdef')
  })

  it('commit-body contains the full message body in a <pre>', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: first line\n\nThis is a full body with\nmultiple lines.' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    const pre = container.querySelector('.commit-body pre')
    expect(pre.textContent).toContain('This is a full body with')
    expect(pre.textContent).toContain('multiple lines.')
  })

  it('long commit message is fully preserved in the commit-body pre', () => {
    const longBody = 'x'.repeat(500)
    renderCommitGraph(container, [
      { hash: 'abc1234', message: `feat: short\n\n${longBody}` }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    const pre = container.querySelector('.commit-body pre')
    expect(pre.textContent).toContain(longBody)
    expect(pre.textContent.length).toBeGreaterThanOrEqual(500)
  })
})

// ---------------------------------------------------------------------------
// Keyboard interaction
// ---------------------------------------------------------------------------

describe('renderCommitGraph — keyboard interaction', () => {
  it('dot has tabindex="0" for keyboard focus', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    expect(dot.getAttribute('tabindex')).toBe('0')
  })

  it('dot has role="button"', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    expect(dot.getAttribute('role')).toBe('button')
  })

  it('pressing Enter on a dot expands the commit-body', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }))
    const body = container.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(true)
  })

  it('pressing Space on a dot expands the commit-body', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true }))
    const body = container.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(true)
  })

  it('pressing other keys on a dot does not toggle the commit-body', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true }))
    const body = container.querySelector('.commit-body')
    expect(body.classList.contains('open')).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// aria-expanded
// ---------------------------------------------------------------------------

describe('renderCommitGraph — aria-expanded', () => {
  it('dot has aria-expanded="false" initially', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    expect(dot.getAttribute('aria-expanded')).toBe('false')
  })

  it('dot has aria-expanded="true" after click', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    expect(dot.getAttribute('aria-expanded')).toBe('true')
  })

  it('dot has aria-expanded="false" after second click', () => {
    renderCommitGraph(container, [
      { hash: 'abc1234', message: 'feat: thing' }
    ])
    const dot = container.querySelector('.commit-dot')
    dot.click()
    dot.click()
    expect(dot.getAttribute('aria-expanded')).toBe('false')
  })
})

// ---------------------------------------------------------------------------
// Multiple commits — independence of expand/collapse
// ---------------------------------------------------------------------------

describe('renderCommitGraph — multiple commits', () => {
  it('each commit has its own dot and commit-body', () => {
    renderCommitGraph(container, [
      { hash: 'aaa0001', message: 'commit A' },
      { hash: 'bbb0002', message: 'commit B' }
    ])
    const dots = container.querySelectorAll('.commit-dot')
    const bodies = container.querySelectorAll('.commit-body')
    expect(dots.length).toBe(2)
    expect(bodies.length).toBe(2)
  })

  it('clicking dot 1 opens body 1 and dot 2 body stays closed', () => {
    renderCommitGraph(container, [
      { hash: 'aaa0001', message: 'commit A' },
      { hash: 'bbb0002', message: 'commit B' }
    ])
    const dots = container.querySelectorAll('.commit-dot')
    const bodies = container.querySelectorAll('.commit-body')
    dots[0].click()
    expect(bodies[0].classList.contains('open')).toBe(true)
    expect(bodies[1].classList.contains('open')).toBe(false)
  })

  it('clicking dot 2 while dot 1 is open collapses dot 1', () => {
    renderCommitGraph(container, [
      { hash: 'aaa0001', message: 'commit A' },
      { hash: 'bbb0002', message: 'commit B' }
    ])
    const dots = container.querySelectorAll('.commit-dot')
    const bodies = container.querySelectorAll('.commit-body')
    dots[0].click()
    dots[1].click()
    expect(bodies[0].classList.contains('open')).toBe(false)
    expect(bodies[1].classList.contains('open')).toBe(true)
  })

  it('each commit-body pre contains only its own commit message', () => {
    renderCommitGraph(container, [
      { hash: 'aaa0001', message: 'MESSAGE_A' },
      { hash: 'bbb0002', message: 'MESSAGE_B' }
    ])
    const dots = container.querySelectorAll('.commit-dot')
    const bodies = container.querySelectorAll('.commit-body')
    dots[0].click()
    expect(bodies[0].querySelector('pre').textContent).toContain('MESSAGE_A')
    expect(bodies[0].querySelector('pre').textContent).not.toContain('MESSAGE_B')
  })
})

// ---------------------------------------------------------------------------
// Defensive / edge cases
// ---------------------------------------------------------------------------

describe('renderCommitGraph — defensive paths', () => {
  it('commit with no hash does not throw and renders empty hash', () => {
    expect(() =>
      renderCommitGraph(container, [{ hash: undefined, message: 'some message' }])
    ).not.toThrow()
  })

  it('commit with no message does not throw and renders empty summary', () => {
    expect(() =>
      renderCommitGraph(container, [{ hash: 'abc1234', message: undefined }])
    ).not.toThrow()
  })

  it('commit with hash shorter than 7 chars displays full hash', () => {
    renderCommitGraph(container, [{ hash: 'abc', message: 'short hash' }])
    const hashEl = container.querySelector('.commit-hash')
    expect(hashEl.textContent).toBe('abc')
  })
})
