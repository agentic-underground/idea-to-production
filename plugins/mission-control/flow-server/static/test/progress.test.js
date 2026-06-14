import { describe, it, expect } from 'vitest'
import { doneFraction, donePercent, isComplete, sysMessages } from '../src/progress.js'

describe('doneFraction', () => {
  it('is 0 when no items are done', () => {
    expect(doneFraction([
      { status: 'do' }, { status: 'doing' }
    ])).toBe(0)
  })

  it('is the done/total fraction for a partial board', () => {
    expect(doneFraction([
      { status: 'done' }, { status: 'doing' }, { status: 'do' }, { status: 'done' }
    ])).toBe(0.5)
  })

  it('is 1 when every item is done', () => {
    expect(doneFraction([{ status: 'done' }, { status: 'done' }])).toBe(1)
  })

  it('is 0 for an empty board (no division by zero)', () => {
    expect(doneFraction([])).toBe(0)
  })
})

describe('donePercent', () => {
  it('rounds the fraction to a whole-number percent', () => {
    expect(donePercent([{ status: 'done' }, { status: 'do' }, { status: 'do' }])).toBe(33)
  })

  it('reads 100 when every item is done', () => {
    expect(donePercent([{ status: 'done' }])).toBe(100)
  })

  it('reads 0 for an empty board', () => {
    expect(donePercent([])).toBe(0)
  })
})

describe('isComplete', () => {
  it('is true only when every item is done', () => {
    expect(isComplete([{ status: 'done' }, { status: 'done' }])).toBe(true)
  })

  it('is false when any item is not done', () => {
    expect(isComplete([{ status: 'done' }, { status: 'doing' }])).toBe(false)
  })

  it('is false for an empty board (nothing to observe yet)', () => {
    expect(isComplete([])).toBe(false)
  })
})

describe('sysMessages', () => {
  it('keeps only kind==="sys_msg" events', () => {
    const events = [
      { kind: 'sys_msg', text: 'a' },
      { kind: 'token_spend', text: 'noise' },
      { kind: 'sys_msg', text: 'b' }
    ]
    expect(sysMessages(events).map((e) => e.text)).toEqual(['b', 'a'])
  })

  it('returns newest-first (reverses the append-only log order)', () => {
    const events = [
      { kind: 'sys_msg', text: 'oldest' },
      { kind: 'sys_msg', text: 'middle' },
      { kind: 'sys_msg', text: 'newest' }
    ]
    expect(sysMessages(events).map((e) => e.text)).toEqual(['newest', 'middle', 'oldest'])
  })

  it('returns an empty array for no events', () => {
    expect(sysMessages([])).toEqual([])
  })

  it('tolerates a non-array (degrades to empty)', () => {
    expect(sysMessages(undefined)).toEqual([])
    expect(sysMessages(null)).toEqual([])
  })
})
