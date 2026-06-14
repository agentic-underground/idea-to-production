// test/setup.js — global jsdom polyfills for the vitest suite.
//
// jsdom does not implement HTMLDialogElement.showModal() / close().
// Polyfill them so the REDO modal and any future <dialog>-based components
// work in the test environment without requiring a real browser.

if (typeof HTMLDialogElement !== 'undefined') {
  if (!HTMLDialogElement.prototype.showModal) {
    HTMLDialogElement.prototype.showModal = function () {
      this.setAttribute('open', '')
    }
  }
  if (!HTMLDialogElement.prototype.close) {
    HTMLDialogElement.prototype.close = function () {
      this.removeAttribute('open')
    }
  }
}
