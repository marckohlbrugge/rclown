class ScheduleBackupsJob < ApplicationJob
  queue_as :scheduler

  def perform
    cleanup_orphaned_runs

    Backup.enabled.find_each do |backup|
      next unless backup.due?
      next if backup.running?

      Rails.logger.info "Scheduling backup: #{backup.name}"
      backup.execute
    end
  end

  private
    def cleanup_orphaned_runs
      BackupRun.running.find_each do |run|
        next if run.process_running?

        Rails.logger.info "Cleaning up orphaned backup run ##{run.id}"
        run.append_log("\n\nBackup interrupted (process no longer running)")
        run.update!(status: :cancelled, finished_at: Time.current)
      end
    end
end
