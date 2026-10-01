import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["apply"]

  connect() {
    this.dirtyPickers = new Set()
    this.refreshApply()
  }

  pickerChanged(event) {
    const { picker, dirty, selectedCount } = event.detail

    if (dirty) {
      this.dirtyPickers.add(picker)
    } else {
      this.dirtyPickers.delete(picker)
    }

    this.selectedCounts = { ...this.selectedCounts, [picker]: selectedCount }
    this.refreshApply()
  }

  refreshApply() {
    this.applyTarget.disabled = this.dirtyPickers.size === 0
  }
}
