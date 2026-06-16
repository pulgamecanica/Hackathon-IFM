import { Controller } from "@hotwired/stimulus"

// Renders a live Leaflet/OpenStreetMap map of feedback by location.
// Leaflet is loaded from a CDN in the dashboard <head>, exposing global `L`.
//
// Markers are circles sized by feedback volume and colored by average
// sentiment. The controller polls the map_data endpoint so markers stay live
// as synthetic feedback streams in — no page reload.
export default class extends Controller {
  static values = {
    url: String,
    refreshInterval: { type: Number, default: 5000 }
  }

  connect() {
    this.markers = new Map()
    this.initMap()
    this.refresh()
    this.timer = setInterval(() => this.refresh(), this.refreshIntervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
    if (this.map) this.map.remove()
  }

  initMap() {
    this.map = L.map(this.element, { worldCopyJump: true, attributionControl: false })
      .setView([25, 5], 2)

    L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
      maxZoom: 19,
      subdomains: "abcd"
    }).addTo(this.map)
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
    const color = this.colorFor(loc.sentiment_label)
    const radius = 6 + Math.min(loc.feedback_count, 40) * 0.9
    const popup = `<strong>${loc.name}</strong><br>${loc.city || ""}<br>` +
      `${loc.feedback_count} feedback` +
      (loc.avg_sentiment != null ? `<br>sentiment ${loc.avg_sentiment.toFixed(2)}` : "")

    const existing = this.markers.get(loc.id)
    if (existing) {
      existing.setRadius(radius).setStyle({ fillColor: color, color })
      existing.getPopup().setContent(popup)
      return
    }

    const marker = L.circleMarker([loc.lat, loc.long], {
      radius, color, fillColor: color, fillOpacity: 0.6, weight: 2
    }).addTo(this.map).bindPopup(popup)

    this.markers.set(loc.id, marker)
  }

  colorFor(label) {
    return {
      positive: "#34d399",
      neutral: "#94a3b8",
      negative: "#fb7185",
      none: "#475569"
    }[label] || "#475569"
  }
}
