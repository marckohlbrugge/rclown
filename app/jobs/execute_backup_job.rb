class ExecuteBackupJob < ApplicationJob
  include RcloneErrorHandling

  queue_as :backups

  def perform(backup_run)
    backup_run.execute
  end
end
