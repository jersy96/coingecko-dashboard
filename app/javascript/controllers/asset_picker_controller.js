import { Controller } from "@hotwired/stimulus"
import { applyChipOverflow, observeChipOverflow } from "controllers/chip_overflow"

const TOP_ENTRIES_DELAY = 500
const SEARCH_DELAY = 2000

export default class extends Controller {
  static targets = ["query", "results", "chips", "chipsPanel", "hiddenFields", "expandToggle"]
  static values = { selected: Array, labels: Object, url: String, expanded: Boolean }

  connect() {
    this.topEntries = null
    this.appliedSelection = this.selectionSignature()
    this.renderChips()
    this.overflowObserver = observeChipOverflow(this.chipsTarget, () => this.refreshChipOverflow())
  }

  disconnect() {
    clearTimeout(this.pendingRequest)
    this.overflowObserver.disconnect()
  }

  openResults() {
    this.resultsTarget.classList.remove("hidden")

    if (this.queryTarget.value.length > 0) return

    this.showTopEntries()
  }

  showTopEntries() {
    if (this.topEntries) {
      clearTimeout(this.pendingRequest)
      this.renderResults(this.topEntries)
      return
    }

    this.renderLoading()
    this.schedule(TOP_ENTRIES_DELAY, () => this.fetchTopEntries())
  }

  closeResults() {
    clearTimeout(this.pendingRequest)
    this.resultsTarget.classList.add("hidden")
  }

  search() {
    const query = this.queryTarget.value

    if (query.length === 0) {
      this.showTopEntries()
      return
    }

    this.renderLoading()
    this.schedule(SEARCH_DELAY, () => this.fetchEntries(query))
  }

  schedule(delay, request) {
    clearTimeout(this.pendingRequest)
    this.pendingRequest = setTimeout(request, delay)
  }

  async fetchTopEntries() {
    const entries = await this.requestEntries("")
    if (!entries) return

    this.topEntries = entries
    this.renderResults(entries)
  }

  async fetchEntries(query) {
    const entries = await this.requestEntries(query)
    if (!entries) return

    this.renderResults(entries)
  }

  async requestEntries(query) {
    const response = await fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })

    if (!response.ok) {
      this.resultsTarget.innerHTML = '<li class="px-3 py-2 text-sm text-slate-400">No se pudo cargar el catálogo</li>'
      return null
    }

    const payload = await response.json()
    return payload.entries
  }

  renderLoading() {
    this.resultsTarget.innerHTML = '<li class="px-3 py-2 text-sm text-slate-400">Loading…</li>'
  }

  renderResults(entries) {
    this.resultsTarget.innerHTML = ""

    entries.forEach((entry) => {
      const option = document.createElement("li")
      option.className = "cursor-pointer px-3 py-2 text-sm text-slate-700 hover:bg-slate-100"
      option.textContent = entry.label
      option.dataset.assetId = entry.id
      option.dataset.action = "mousedown->asset-picker#toggleEntry"
      this.labelsValue = { ...this.labelsValue, [entry.id]: entry.label }
      this.resultsTarget.appendChild(option)
    })
  }

  toggleEntry(event) {
    event.preventDefault()
    const assetId = event.currentTarget.dataset.assetId

    if (this.selectedValue.includes(assetId)) {
      this.selectedValue = this.selectedValue.filter((candidate) => candidate !== assetId)
    } else {
      this.selectedValue = [...this.selectedValue, assetId]
    }

    this.renderChips()
  }

  removeChip(event) {
    this.selectedValue = this.selectedValue.filter((candidate) => candidate !== event.currentTarget.dataset.assetId)
    this.renderChips()
  }

  async copyLabel(event) {
    const labelElement = event.currentTarget
    const label = labelElement.textContent

    await navigator.clipboard.writeText(label)

    labelElement.textContent = "✓ Copied"
    setTimeout(() => { labelElement.textContent = label }, 1500)
  }

  renderChips() {
    this.chipsTarget.innerHTML = ""
    this.hiddenFieldsTarget.innerHTML = ""

    this.selectedValue.forEach((assetId) => {
      this.chipsTarget.appendChild(this.buildChip(assetId))
      this.hiddenFieldsTarget.appendChild(this.buildHiddenField(assetId))
    })

    this.refreshChipOverflow()

    this.dispatch("changed", {
      detail: {
        picker: "assets",
        dirty: this.selectionSignature() !== this.appliedSelection,
        selectedCount: this.selectedValue.length
      },
      prefix: "picker"
    })
  }

  toggleExpanded() {
    this.expandedValue = !this.expandedValue
    this.refreshChipOverflow()
  }

  refreshChipOverflow() {
    applyChipOverflow(this.chipsPanelTarget, this.chipsTarget, this.expandToggleTarget, this.expandedValue)
  }

  selectionSignature() {
    return [...this.selectedValue].sort().join(",")
  }

  buildChip(assetId) {
    const chip = document.createElement("span")
    chip.className = "flex items-center gap-2 rounded-full bg-slate-900 py-1 pl-3 pr-2 text-xs font-medium text-white"
    chip.appendChild(this.buildChipLabel(assetId))
    chip.appendChild(this.buildChipRemoveButton(assetId))
    return chip
  }

  buildChipLabel(assetId) {
    const label = document.createElement("button")
    label.type = "button"
    label.className = "cursor-pointer"
    label.title = "Copy name"
    label.textContent = this.labelsValue[assetId] || assetId
    label.dataset.action = "click->asset-picker#copyLabel"
    return label
  }

  buildChipRemoveButton(assetId) {
    const removeButton = document.createElement("button")
    removeButton.type = "button"
    removeButton.className = "rounded-full px-1 leading-none text-slate-300 transition hover:bg-slate-700 hover:text-white"
    removeButton.textContent = "×"
    removeButton.title = "Remove"
    removeButton.setAttribute("aria-label", "Remove")
    removeButton.dataset.assetId = assetId
    removeButton.dataset.action = "click->asset-picker#removeChip"
    return removeButton
  }

  buildHiddenField(assetId) {
    const field = document.createElement("input")
    field.type = "hidden"
    field.name = "asset_ids[]"
    field.value = assetId
    return field
  }
}
