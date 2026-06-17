import { Controller } from "@hotwired/stimulus"

// Floating Concierge chatbot. Toggles a chat panel; on send it syncs the active
// dashboard filters into the request, optimistically renders the user's message
// plus a typing indicator, then the server streams the reply back. If the reply
// carries detected filters (data-applied-filters), it dispatches an event the
// dashboard filter controller listens for, so the chat can drive the dashboard.
export default class extends Controller {
  static targets = ["panel", "messages", "input", "form", "userTemplate", "typingTemplate", "launcherIcon"]

  connect() {
    this.observer = new MutationObserver((mutations) => this.onMutations(mutations))
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  toggle() {
    const open = this.panelTarget.classList.toggle("hidden") === false
    if (this.hasLauncherIconTarget) this.launcherIconTarget.textContent = open ? "−" : "✦"
    if (open) {
      this.scrollToBottom()
      this.inputTarget.focus()
    }
  }

  // turbo:submit-start — scope to the live dashboard filters, then optimistically
  // show the user's bubble and a typing indicator.
  sending() {
    const text = this.inputTarget.value.trim()
    if (!text) return

    this.syncFilters()

    const bubble = this.userTemplateTarget.content.cloneNode(true)
    bubble.querySelector("[data-message-body]").textContent = text
    this.messagesTarget.appendChild(bubble)

    document.getElementById("concierge-typing")?.remove()
    this.messagesTarget.appendChild(this.typingTemplateTarget.content.cloneNode(true))

    this.inputTarget.value = ""
    this.scrollToBottom()
  }

  // Copy the dashboard's currently-applied filters into our hidden fields so the
  // answer stays scoped to whatever is on screen.
  syncFilters() {
    const filterForm = document.querySelector('[data-filter-target="form"]')
    if (!filterForm) return
    ;["focus", "theme", "sentiment", "sku", "location"].forEach((name) => {
      const src = filterForm.querySelector(`[name="${name}"]`)
      const dst = this.formTarget.querySelector(`[name="${name}"]`)
      if (src && dst) dst.value = src.value
    })
  }

  onMutations(mutations) {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.ELEMENT_NODE && node.hasAttribute("data-applied-filters")) {
          this.applyToDashboard(node)
        }
      }
    }
    this.scrollToBottom()
  }

  // Push filters the question implied onto the dashboard (consumed once).
  applyToDashboard(node) {
    const raw = node.getAttribute("data-applied-filters")
    node.removeAttribute("data-applied-filters")
    let filters
    try { filters = JSON.parse(raw) } catch { return }
    if (filters && Object.keys(filters).length) {
      window.dispatchEvent(new CustomEvent("concierge:apply-filters", { detail: { filters } }))
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
