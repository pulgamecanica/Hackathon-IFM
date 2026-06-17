import { Controller } from "@hotwired/stimulus"

// Drives the LUMA Concierge chat: on send it optimistically shows the user's
// message and a typing indicator, then the server streams the bot reply back
// (and removes the indicator). Keeps the log scrolled to the newest message.
export default class extends Controller {
  static targets = ["messages", "input", "userTemplate", "typingTemplate"]

  connect() {
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true })
    this.scrollToBottom()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  // turbo:submit-start — render the user's bubble + typing dots immediately.
  sending() {
    const text = this.inputTarget.value.trim()
    if (!text) return

    const bubble = this.userTemplateTarget.content.cloneNode(true)
    bubble.querySelector("[data-message-body]").textContent = text
    this.messagesTarget.appendChild(bubble)

    document.getElementById("typing")?.remove()
    this.messagesTarget.appendChild(this.typingTemplateTarget.content.cloneNode(true))

    this.inputTarget.value = ""
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
