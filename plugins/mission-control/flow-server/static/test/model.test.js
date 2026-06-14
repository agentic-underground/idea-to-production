import { describe, it, expect } from 'vitest'
import {
  MODEL_ALLOWLIST,
  DEFAULT_ALLOWLIST,
  modelLabel,
  shortModel,
  isAllowed,
  resolveModel
} from '../src/model.js'

describe('MODEL_ALLOWLIST', () => {
  it('is the four marketplace model ids in cost→capability order', () => {
    expect(MODEL_ALLOWLIST).toEqual([
      'claude-haiku-4-5',
      'claude-sonnet-4-6',
      'claude-opus-4-8',
      'claude-fable-5'
    ])
  })

  it('DEFAULT_ALLOWLIST is the same canonical set (the configurable default)', () => {
    expect(DEFAULT_ALLOWLIST).toEqual(MODEL_ALLOWLIST)
  })

  it('is frozen so a caller cannot mutate the shared allowlist', () => {
    expect(Object.isFrozen(MODEL_ALLOWLIST)).toBe(true)
  })
})

describe('shortModel', () => {
  it('reduces a claude- id to its family name', () => {
    expect(shortModel('claude-opus-4-8')).toBe('opus')
    expect(shortModel('claude-haiku-4-5')).toBe('haiku')
    expect(shortModel('claude-fable-5')).toBe('fable')
  })

  it('returns a non-claude id unchanged', () => {
    expect(shortModel('gpt-x')).toBe('gpt-x')
  })

  it('returns the empty string for a missing model', () => {
    expect(shortModel(undefined)).toBe('')
    expect(shortModel(null)).toBe('')
  })
})

describe('modelLabel', () => {
  it('title-cases the family name with its version for the picker', () => {
    expect(modelLabel('claude-haiku-4-5')).toBe('Haiku 4.5')
    expect(modelLabel('claude-sonnet-4-6')).toBe('Sonnet 4.6')
    expect(modelLabel('claude-opus-4-8')).toBe('Opus 4.8')
    expect(modelLabel('claude-fable-5')).toBe('Fable 5')
  })

  it('falls back to the raw id when it is not a recognised claude- id', () => {
    expect(modelLabel('gpt-x')).toBe('gpt-x')
  })
})

describe('isAllowed', () => {
  it('accepts a model that is in the allowlist', () => {
    expect(isAllowed('claude-opus-4-8')).toBe(true)
  })

  it('rejects a model that is not in the allowlist', () => {
    expect(isAllowed('claude-evil-9')).toBe(false)
  })

  it('rejects null / undefined', () => {
    expect(isAllowed(null)).toBe(false)
    expect(isAllowed(undefined)).toBe(false)
  })

  it('honours a custom (narrowed) allowlist when one is supplied', () => {
    expect(isAllowed('claude-fable-5', ['claude-haiku-4-5'])).toBe(false)
    expect(isAllowed('claude-haiku-4-5', ['claude-haiku-4-5'])).toBe(true)
  })
})

describe('resolveModel', () => {
  it('treats model as the default when defaultModel is absent (no override)', () => {
    const r = resolveModel({ model: 'claude-sonnet-4-6' })
    expect(r).toEqual({ model: 'claude-sonnet-4-6', default: 'claude-sonnet-4-6', isOverride: false })
  })

  it('reports no override when model equals defaultModel', () => {
    const r = resolveModel({ model: 'claude-sonnet-4-6', defaultModel: 'claude-sonnet-4-6' })
    expect(r.isOverride).toBe(false)
    expect(r.model).toBe('claude-sonnet-4-6')
    expect(r.default).toBe('claude-sonnet-4-6')
  })

  it('reports an override when model differs from defaultModel', () => {
    const r = resolveModel({ model: 'claude-opus-4-8', defaultModel: 'claude-sonnet-4-6' })
    expect(r.isOverride).toBe(true)
    expect(r.model).toBe('claude-opus-4-8')
    expect(r.default).toBe('claude-sonnet-4-6')
  })

  it('treats a missing model as the empty string and not an override', () => {
    const r = resolveModel({})
    expect(r).toEqual({ model: '', default: '', isOverride: false })
  })
})
