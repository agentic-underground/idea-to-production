import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./test/setup.js'],
    include: ['test/**/*.test.js'],
    coverage: {
      provider: 'v8',
      include: ['src/**/*.js'],
      // app.js is the browser bootstrap shim (DOMContentLoaded wiring against a
      // live server); it is exercised at the STORY layer via Playwright, not in
      // jsdom. The logic it wires (layout, card, canvas, api) is covered here.
      exclude: ['src/app.js'],
      thresholds: {
        lines: 100,
        branches: 100,
        functions: 100,
        statements: 100
      }
    }
  }
})
