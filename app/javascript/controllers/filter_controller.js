import { Controller } from "@hotwired/stimulus"

// Category / sentiment filter. Sets data-active-<group> on the region wrapper;
// the actual show/hide is done in CSS, so live-streamed cards filter for free.
export default class extends Controller {
  static targets = ["region", "chip"]

  apply(event) {
    const { group, value } = event.params
    const region = this.hasRegionTarget ? this.regionTarget : this.element
    region.dataset[this.datasetKey(group)] = value

    this.chipTargets
      .filter((chip) => chip.dataset.filterGroupParam === group)
      .forEach((chip) => chip.toggleAttribute("data-active", chip === event.currentTarget))
  }

  // Clear every group back to "all" and restore default-active chips.
  reset() {
    const region = this.hasRegionTarget ? this.regionTarget : this.element
    ;["focus", "theme", "sentiment"].forEach((group) => {
      region.dataset[this.datasetKey(group)] = "all"
    })
    this.chipTargets.forEach((chip) => {
      chip.toggleAttribute("data-active", chip.hasAttribute("data-filter-default"))
    })
  }

  // "focus" -> "activeFocus" (renders as data-active-focus)
  datasetKey(group) {
    return "active" + group.charAt(0).toUpperCase() + group.slice(1)
  }
}
