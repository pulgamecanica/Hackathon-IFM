import { Controller } from "@hotwired/stimulus"

// Drives the interactive dashboard filters. On each change it:
//  1. sets data-active-<group> on the controller root (CSS hides non-matching
//     cards instantly — covers cards streamed in live), and
//  2. updates the matching hidden field and submits the form, which reloads the
//     dashboard-body Turbo Frame so every panel re-renders server-filtered.
export default class extends Controller {
  static targets = ["chip", "form"]

  apply(event) {
    const { group, value } = event.params
    this.element.dataset[this.datasetKey(group)] = value
    this.setField(group, value)
    this.chipTargets
      .filter((chip) => chip.dataset.filterGroupParam === group)
      .forEach((chip) => chip.toggleAttribute("data-active", chip === event.currentTarget))
    this.submit()
  }

  reset() {
    ["focus", "theme", "sentiment", "sku"].forEach((group) => {
      this.element.dataset[this.datasetKey(group)] = "all"
      this.setField(group, "all")
    })
    this.chipTargets.forEach((chip) => chip.toggleAttribute("data-active", chip.hasAttribute("data-filter-default")))
    this.submit()
  }

  setField(group, value) {
    const field = this.formTarget.querySelector(`[name="${group}"]`)
    if (field) field.value = value === "all" ? "" : value
  }

  submit() {
    this.formTarget.requestSubmit()
  }

  // "focus" -> "activeFocus" (renders as data-active-focus)
  datasetKey(group) {
    return "active" + group.charAt(0).toUpperCase() + group.slice(1)
  }
}
