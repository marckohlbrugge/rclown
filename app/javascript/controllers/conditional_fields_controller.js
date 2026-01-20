import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "fields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selectedValue = this.radioTargets.find(radio => radio.checked)?.value

    this.fieldsTargets.forEach(el => {
      el.classList.toggle("hidden", el.dataset.value !== selectedValue)
    })
  }
}
