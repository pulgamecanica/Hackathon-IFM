import { Controller } from "@hotwired/stimulus"

// Renders a live Leaflet/OpenStreetMap map of feedback by location.
// Leaflet is loaded from a CDN in the dashboard <head>, exposing global `L`.
//
// Markers are circles sized by feedback volume and colored by average
// sentiment. The controller polls the map_data endpoint so markers stay live
// as synthetic feedback streams in — no page reload.
export default class extends Controller {
  static targets = ["canvas", "fullscreenIcon", "fullscreenLabel"]
  static values = {
    url: String,
    refreshInterval: { type: Number, default: 5000 }
  }

  connect() {
    this.markers = new Map()
    this.initMap()
    this.refresh()
    this.timer = setInterval(() => this.refresh(), this.refreshIntervalValue)
    this.onFullscreenChange = this.handleFullscreenChange.bind(this)
    document.addEventListener("fullscreenchange", this.onFullscreenChange)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("fullscreenchange", this.onFullscreenChange)
    if (this.map) this.map.remove()
  }

  initMap() {
    this.map = L.map(this.canvasTarget, { worldCopyJump: true, attributionControl: false })
      .setView([25, 5], 2)

    // Light, label-light base tiles. The .leaflet-tile-pane CSS rule grayscales
    // the tiles while leaving the colored sentiment markers untouched.
    L.tileLayer("https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png", {
      maxZoom: 19,
      subdomains: "abcd"
    }).addTo(this.map)
  }

  toggleFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      this.element.requestFullscreen()
    }
  }

  // Fill the screen in fullscreen, restore the fixed height when exiting, and
  // tell Leaflet to recompute its size so tiles fill the new viewport.
  handleFullscreenChange() {
    const active = document.fullscreenElement === this.element
    this.canvasTarget.classList.toggle("h-80", !active)
    this.canvasTarget.classList.toggle("h-screen", active)
    if (this.hasFullscreenIconTarget) this.fullscreenIconTarget.textContent = active ? "✕" : "⛶"
    if (this.hasFullscreenLabelTarget) this.fullscreenLabelTarget.textContent = active ? "Exit" : "Fullscreen"
    // Leaflet needs a tick after the layout change before invalidating size.
    setTimeout(() => this.map.invalidateSize(), 100)
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return
      const locations = await response.json()
      locations.forEach((loc) => this.upsertMarker(loc))
    } catch (e) {
      // Network blips are non-fatal — the next tick retries.
    }
  }

  upsertMarker(loc) {
    const style = this.styleFor(loc.sentiment_label)
    const radius = 5 + Math.min(loc.feedback_count, 40) * 0.85
    const popup = `<strong>${loc.name}</strong><br>${loc.city || ""}<br>` +
      `${loc.feedback_count} feedback` +
      (loc.avg_sentiment != null ? `<br>sentiment ${loc.avg_sentiment.toFixed(2)}` : "")

    const existing = this.markers.get(loc.id)
    if (existing) {
      existing.setRadius(radius).setStyle(style)
      existing.getPopup().setContent(popup)
      return
    }

    const marker = L.circleMarker([loc.lat, loc.long], { radius, ...style })
      .addTo(this.map).bindPopup(popup)

    this.markers.set(loc.id, marker)
  }

  // Jewel-tone sentiment markers — the only color on the grayscale map.
  styleFor(label) {
    return {
      positive: { color: "#065f46", fillColor: "#059669", fillOpacity: 0.9, weight: 1.5 },
      neutral:  { color: "#475569", fillColor: "#94a3b8", fillOpacity: 0.85, weight: 1.5 },
      negative: { color: "#9f1239", fillColor: "#e11d48", fillOpacity: 0.9, weight: 1.5 },
      none:     { color: "#a3a3a3", fillColor: "#ffffff", fillOpacity: 1, weight: 1 }
    }[label] || { color: "#a3a3a3", fillColor: "#ffffff", fillOpacity: 1, weight: 1 }
  }
}
