import { Controller } from "@hotwired/stimulus"

// Drives the interactive dashboard filters. On each change it:
//  1. sets data-active-<group> on the controller root (CSS hides non-matching
//     cards instantly — covers cards streamed in live), and
//  2. updates the matching hidden field and submits the form, which reloads the
//     dashboard-body Turbo Frame so every panel re-renders server-filtered.
export default class extends Controller {
  static targets = ["chip", "form", "facet", "imagesToggle"]

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
    ["focus", "theme", "sentiment", "sku", "location"].forEach((group) => {
      this.element.dataset[this.datasetKey(group)] = "all"
      this.setField(group, "all")
    })
    this.chipTargets.forEach((chip) => chip.toggleAttribute("data-active", chip.hasAttribute("data-filter-default")))
    this.resetScopes()
    this.submit()
  }

  // A "shadowed" facet (Zone, Collection) narrows the selectors below it: only
  // the dependent chips tagged with the chosen value stay visible. Pure client-
  // side selection aid — it doesn't touch the server-applied filters.
  // NB: must NOT be named `scope` — that shadows Stimulus Controller's built-in
  // `scope` getter, which breaks this.element / this.targets for EVERY action.
  narrow(event) {
    const dimension = event.params.scope
    const facet = event.currentTarget
    this.facetTargets
      .filter((f) => f.dataset.filterScopeParam === dimension)
      .forEach((f) => f.toggleAttribute("data-active", f === facet))
    this.applyScopes()
  }

  // Recompute which dependent chips are visible. A chip stays visible only if it
  // satisfies EVERY active facet that applies to it (so Function + Collection
  // compose on the SKU list, while Zone independently narrows Locations).
  applyScopes() {
    const active = {} // dimension -> selected value (excluding "all")
    this.facetTargets.forEach((f) => {
      if (f.hasAttribute("data-active") && f.dataset.filterValueParam !== "all") {
        active[f.dataset.filterScopeParam] = f.dataset.filterValueParam
      }
    })
    const chips = this.element.querySelectorAll("[data-scope-zone], [data-scope-function], [data-scope-collection]")
    chips.forEach((chip) => {
      const hidden = Object.entries(active).some(([dim, val]) => {
        const own = chip.dataset["scope" + dim.charAt(0).toUpperCase() + dim.slice(1)]
        return own !== undefined && own !== val // dimension applies to this chip but doesn't match
      })
      chip.classList.toggle("hidden", hidden)
    })
  }

  // Reset facets to "All" and reveal every dependent chip.
  resetScopes() {
    this.facetTargets.forEach((facet) => facet.toggleAttribute("data-active", facet.dataset.filterValueParam === "all"))
    this.applyScopes()
  }

  // Open the product image tooltip north or south depending on room above the
  // chip (avoids clipping near the top of the page). CSS handles visibility.
  place(event) {
    const chip = event.currentTarget
    chip.dataset.place = chip.getBoundingClientRect().top > 220 ? "north" : "south"
  }

  // Global show/hide for product thumbnails (CSS keys off data-images).
  toggleImages() {
    const next = this.element.dataset.images === "off" ? "on" : "off"
    this.element.dataset.images = next
    if (this.hasImagesToggleTarget) this.imagesToggleTarget.textContent = next === "on" ? "Images: On" : "Images: Off"
  }

  // concierge:apply-filters — the chatbot detected filters in a question and is
  // driving the dashboard. Apply each provided dimension, then reload once.
  applyExternal(event) {
    const filters = event.detail?.filters || {}
    Object.entries(filters).forEach(([group, raw]) => {
      const value = raw === null || raw === undefined || raw === "" ? "all" : String(raw)
      this.element.dataset[this.datasetKey(group)] = value
      this.setField(group, value)
      this.chipTargets
        .filter((chip) => chip.dataset.filterGroupParam === group)
        .forEach((chip) => chip.toggleAttribute("data-active", chip.dataset.filterValueParam === value))
    })
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
