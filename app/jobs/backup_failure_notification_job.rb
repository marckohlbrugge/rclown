class BackupFailureNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(backup_run)
    return unless backup_run.failed?

    BackupMailer.failure(backup_run).deliver_now
  end
end
