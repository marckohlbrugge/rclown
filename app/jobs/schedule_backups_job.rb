class ScheduleBackupsJob < ApplicationJob
  queue_as :scheduler

  def perform
    Backup.enabled.find_each do |backup|
      next unless backup.due?
      next if backup.running?

      Rails.logger.info "Scheduling backup: #{backup.name}"
      backup.execute
    end
  end
end
