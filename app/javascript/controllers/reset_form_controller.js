import { Controller } from "@hotwired/stimulus"

// Resets the form after a successful Turbo submission (used by the chat box so
// the question input clears once the answer streams back).
export default class extends Controller {
  reset(event) {
    if (event.detail?.success !== false) this.element.reset()
  }
}
