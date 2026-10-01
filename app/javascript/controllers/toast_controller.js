import { Controller } from "@hotwired/stimulus"

const VISIBLE_MILLISECONDS = 5000

export default class extends Controller {
  connect() {
    this.dismissTimeout = setTimeout(() => this.dismiss(), VISIBLE_MILLISECONDS)
  }

  disconnect() {
    clearTimeout(this.dismissTimeout)
  }

  dismiss() {
    this.element.remove()
  }
}
