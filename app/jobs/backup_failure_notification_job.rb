class BackupFailureNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(backup_run)
    return unless backup_run.failed?

    Notifier.notify_failure(backup_run)
  end
end
