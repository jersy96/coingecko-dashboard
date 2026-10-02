import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

const ASSET_ID_PLACEHOLDER = "ASSET_ID"
const RATE_LIMITED_STATUS = 429
const RATE_LIMITED_MESSAGE = "CoinGecko is rate limiting this dashboard. The chart will load in a moment."

export default class extends Controller {
  static targets = ["priceColumn", "volatilityColumn", "conversionColumn", "marketCapColumn", "assetRow", "assetCell", "chartCanvas"]
  static values = { assets: Array, selectedAssetId: String, historyUrl: String }

  connect() {
    this.historyByAssetId = new Map()
    this.storeInitialHistory()

    this.chart = new Chart(this.chartCanvasTarget, {
      type: "line",
      data: this.buildChartData(this.selectedAssetIdValue),
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: false } }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  storeInitialHistory() {
    const selectedAsset = this.assetFor(this.selectedAssetIdValue)
    if (!selectedAsset) return

    this.historyByAssetId.set(selectedAsset.id, { labels: selectedAsset.labels, prices: selectedAsset.prices })
  }

  async selectAsset(event) {
    const assetId = event.currentTarget.dataset.marketFeedAssetIdParam
    this.selectedAssetIdValue = assetId
    this.highlightSelectedRow(assetId)

    const history = await this.historyFor(assetId)
    if (!history) return
    if (this.selectedAssetIdValue !== assetId) return

    this.chart.data = this.buildChartData(assetId)
    this.chart.update()
  }

  highlightSelectedRow(assetId) {
    this.assetRowTargets.forEach((row) => {
      row.classList.toggle("bg-slate-100", row.dataset.marketFeedAssetIdParam === assetId)
    })

    this.assetCellTargets.forEach((cell) => {
      const cellSelected = cell.closest("tr").dataset.marketFeedAssetIdParam === assetId
      cell.classList.toggle("bg-slate-100", cellSelected)
      cell.classList.toggle("bg-white", !cellSelected)
    })
  }

  async historyFor(assetId) {
    if (this.historyByAssetId.has(assetId)) return this.historyByAssetId.get(assetId)

    const response = await fetch(this.historyUrlFor(assetId), { headers: { Accept: "application/json" } })
    if (response.status === RATE_LIMITED_STATUS) {
      this.announce(RATE_LIMITED_MESSAGE)
      return null
    }
    if (!response.ok) return null

    const payload = await response.json()
    const history = this.buildHistory(payload.points)
    if (history.prices.length === 0) return history

    this.historyByAssetId.set(assetId, history)

    return history
  }

  announce(message) {
    document.querySelector("[data-market-feed-toast]")?.remove()

    const toast = document.createElement("div")
    toast.dataset.marketFeedToast = ""
    toast.dataset.controller = "toast"
    toast.className = "fixed bottom-6 right-6 z-50 flex max-w-sm items-start gap-3 rounded-md bg-slate-900 px-4 py-3 text-sm text-white shadow-lg"

    const text = document.createElement("p")
    text.className = "flex-1"
    text.textContent = message
    toast.appendChild(text)

    document.body.appendChild(toast)
  }

  historyUrlFor(assetId) {
    return this.historyUrlValue.replace(ASSET_ID_PLACEHOLDER, encodeURIComponent(assetId))
  }

  buildHistory(points) {
    return {
      prices: points.map((point) => point.price),
      labels: points.map((point, index) => {
        return index === points.length - 1 ? "Now" : this.formatLabel(point.recorded_at)
      })
    }
  }

  formatLabel(recordedAt) {
    return new Date(recordedAt).toLocaleDateString("en-US", { month: "short", day: "2-digit" })
  }

  toggleMetric(event) {
    const columnVisible = event.target.checked

    this.columnTargetsFor(event.target.dataset.marketFeedMetricParam).forEach((element) => {
      element.classList.toggle("hidden", !columnVisible)
    })
  }

  columnTargetsFor(metric) {
    if (metric === "volatility") return this.volatilityColumnTargets
    if (metric === "conversion") return this.conversionColumnTargets
    if (metric === "market-cap") return this.marketCapColumnTargets

    return this.priceColumnTargets
  }

  assetFor(assetId) {
    return this.assetsValue.find((candidate) => candidate.id === assetId)
  }

  buildChartData(assetId) {
    const asset = this.assetFor(assetId)
    const history = this.historyByAssetId.get(assetId) || { labels: [], prices: [] }

    return {
      labels: history.labels,
      datasets: [
        {
          label: `${asset?.name || assetId} price (USD)`,
          data: history.prices,
          borderColor: "#0f172a",
          backgroundColor: "rgba(15, 23, 42, 0.08)",
          tension: 0.3,
          fill: true
        }
      ]
    }
  }
}
