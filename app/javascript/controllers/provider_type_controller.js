import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["endpoint", "region"]

  toggle() {
    // Fields are always visible, just updating hints could be done here if needed
  }
}
