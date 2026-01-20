class NotifierDeliveryJob < ApplicationJob
  queue_as :notifications
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(notifier, backup_run, event_type = :failure)
    return unless notifier.enabled?
    return unless valid_event?(notifier, backup_run, event_type)

    notifier.deliver(backup_run, event_type)
    notifier.update!(last_notified_at: Time.current, last_error: nil)
  rescue => e
    notifier.update!(last_failed_at: Time.current, last_error: e.message.truncate(500))
    raise
  end

  private

  def valid_event?(notifier, backup_run, event_type)
    case event_type.to_sym
    when :failure
      backup_run.failed? && notifier.notify_on_failure?
    when :success
      backup_run.success? && notifier.notify_on_success?
    else
      false
    end
  end
end
