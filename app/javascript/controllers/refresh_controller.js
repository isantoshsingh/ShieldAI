/**
 * Stimulus Refresh Controller
 * Automatically reloads a Turbo Frame at a configurable interval.
 *
 * Usage:
 *   data-controller="refresh"
 *   data-refresh-url-value="/path/to/reload"
 *   data-refresh-interval-value="60000"
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url:      String,
    interval: { type: Number, default: 60000 }
  }

  connect() {
    this.startRefresh()
  }

  disconnect() {
    this.stopRefresh()
  }

  startRefresh() {
    this.timer = setInterval(() => this.reload(), this.intervalValue)
  }

  stopRefresh() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  async reload() {
    const frame = this.element
    if (!frame || !this.urlValue) return

    try {
      // Turbo Frame auto-reloads when src is set
      if (frame.tagName === 'TURBO-FRAME') {
        frame.src = this.urlValue
        await frame.loaded
      }
    } catch {
      // Silently ignore reload errors (e.g. user navigated away)
    }
  }
}
