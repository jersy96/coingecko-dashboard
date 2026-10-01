import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static targets = ["priceColumn", "volatilityColumn", "conversionColumn", "marketCapColumn", "assetRow", "assetCell", "chartCanvas"]
  static values = { assets: Array, selectedAssetId: String }

  connect() {
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

  selectAsset(event) {
    const assetId = event.currentTarget.dataset.marketFeedAssetIdParam
    this.selectedAssetIdValue = assetId
    this.chart.data = this.buildChartData(assetId)
    this.chart.update()

    this.assetRowTargets.forEach((row) => {
      row.classList.toggle("bg-slate-100", row.dataset.marketFeedAssetIdParam === assetId)
    })

    this.assetCellTargets.forEach((cell) => {
      const cellSelected = cell.closest("tr").dataset.marketFeedAssetIdParam === assetId
      cell.classList.toggle("bg-slate-100", cellSelected)
      cell.classList.toggle("bg-white", !cellSelected)
    })
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

  buildChartData(assetId) {
    const asset = this.assetsValue.find((candidate) => candidate.id === assetId)

    return {
      labels: asset.labels,
      datasets: [
        {
          label: `${asset.name} price (USD)`,
          data: asset.prices,
          borderColor: "#0f172a",
          backgroundColor: "rgba(15, 23, 42, 0.08)",
          tension: 0.3,
          fill: true
        }
      ]
    }
  }
}
