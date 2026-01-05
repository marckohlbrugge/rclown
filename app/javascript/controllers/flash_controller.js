import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  dismiss() {
    this.element.remove()
  }

  connect() {
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
      setTimeout(() => this.dismiss(), 300)
    }, 5000)
  }
}
