import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "emailFields", "slackFields", "webhookFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selectedRadio = this.radioTargets.find(radio => radio.checked)
    const selectedType = selectedRadio?.value

    this.hideAllFields()

    if (selectedType === "Notifiers::Email" && this.hasEmailFieldsTarget) {
      this.emailFieldsTarget.classList.remove("hidden")
    } else if (selectedType === "Notifiers::Slack" && this.hasSlackFieldsTarget) {
      this.slackFieldsTarget.classList.remove("hidden")
    } else if (selectedType === "Notifiers::Webhook" && this.hasWebhookFieldsTarget) {
      this.webhookFieldsTarget.classList.remove("hidden")
    }
  }

  hideAllFields() {
    if (this.hasEmailFieldsTarget) this.emailFieldsTarget.classList.add("hidden")
    if (this.hasSlackFieldsTarget) this.slackFieldsTarget.classList.add("hidden")
    if (this.hasWebhookFieldsTarget) this.webhookFieldsTarget.classList.add("hidden")
  }
}
