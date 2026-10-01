import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "chips", "hiddenFields"]
  static values = { selected: Array, supported: Array }

  connect() {
    this.appliedSelection = this.selectionSignature()
    this.renderChips()
  }

  openResults() {
    this.resultsTarget.classList.remove("hidden")
    this.renderResults()
  }

  closeResults() {
    this.resultsTarget.classList.add("hidden")
  }

  filter() {
    this.renderResults()
  }

  matchingCurrencies() {
    const query = this.queryTarget.value.trim().toLowerCase()
    if (query.length === 0) return this.supportedValue

    return this.supportedValue.filter((currency) => currency.includes(query))
  }

  renderResults() {
    this.resultsTarget.innerHTML = ""

    this.matchingCurrencies().forEach((currency) => {
      const option = document.createElement("li")
      option.className = "cursor-pointer px-3 py-2 text-sm uppercase text-slate-700 hover:bg-slate-100"
      option.textContent = currency
      option.dataset.currency = currency
      option.dataset.action = "mousedown->currency-picker#toggleCurrency"
      this.resultsTarget.appendChild(option)
    })
  }

  toggleCurrency(event) {
    event.preventDefault()
    const currency = event.currentTarget.dataset.currency

    if (this.selectedValue.includes(currency)) {
      this.selectedValue = this.selectedValue.filter((candidate) => candidate !== currency)
    } else {
      this.selectedValue = [...this.selectedValue, currency]
    }

    this.renderChips()
  }

  removeChip(event) {
    this.selectedValue = this.selectedValue.filter((candidate) => candidate !== event.currentTarget.dataset.currency)
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

    this.selectedValue.forEach((currency) => {
      this.chipsTarget.appendChild(this.buildChip(currency))
      this.hiddenFieldsTarget.appendChild(this.buildHiddenField(currency))
    })

    this.dispatch("changed", {
      detail: {
        picker: "currencies",
        dirty: this.selectionSignature() !== this.appliedSelection,
        selectedCount: this.selectedValue.length
      },
      prefix: "picker"
    })
  }

  buildChip(currency) {
    const chip = document.createElement("span")
    chip.className = "flex items-center gap-2 rounded-full bg-slate-900 py-1 pl-3 pr-2 text-xs font-medium text-white"
    chip.appendChild(this.buildChipLabel(currency))
    chip.appendChild(this.buildChipRemoveButton(currency))
    return chip
  }

  buildChipLabel(currency) {
    const label = document.createElement("button")
    label.type = "button"
    label.className = "cursor-pointer"
    label.title = "Copy code"
    label.textContent = currency.toUpperCase()
    label.dataset.action = "click->currency-picker#copyLabel"
    return label
  }

  buildChipRemoveButton(currency) {
    const removeButton = document.createElement("button")
    removeButton.type = "button"
    removeButton.className = "rounded-full px-1 leading-none text-slate-300 transition hover:bg-slate-700 hover:text-white"
    removeButton.textContent = "×"
    removeButton.title = "Remove"
    removeButton.setAttribute("aria-label", "Remove")
    removeButton.dataset.currency = currency
    removeButton.dataset.action = "click->currency-picker#removeChip"
    return removeButton
  }

  buildHiddenField(currency) {
    const field = document.createElement("input")
    field.type = "hidden"
    field.name = "currencies[]"
    field.value = currency
    return field
  }

  selectionSignature() {
    return [...this.selectedValue].sort().join(",")
  }
}
