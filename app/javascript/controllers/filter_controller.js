import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item", "empty"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()

    let visibleCount = 0
    this.itemTargets.forEach(item => {
      const text = item.dataset.filterText?.toLowerCase() || ""
      const matches = query === "" || text.includes(query)
      item.classList.toggle("hidden", !matches)
      if (matches) visibleCount++
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }
}
