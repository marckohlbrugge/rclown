class NotifierDeliveryJob < ApplicationJob
  queue_as :notifications
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(notifier, backup_run)
    return unless notifier.enabled? && backup_run.failed?

    notifier.deliver(backup_run)
    notifier.update!(last_notified_at: Time.current, last_error: nil)
  rescue => e
    notifier.update!(last_failed_at: Time.current, last_error: e.message.truncate(500))
    raise
  end
end
