class BackupSuccessNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(backup_run)
    return unless backup_run.success?

    Notifier.notify_success(backup_run)
  end
end
