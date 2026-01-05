class HealthController < ApplicationController
  def show
    @system_health = SystemHealth.new
    @running_backups = BackupRun.running.includes(:backup)
    @queue_stats = queue_stats
  end

  private
    def queue_stats
      {
        pending: SolidQueue::Job.where(finished_at: nil).count,
        scheduled: SolidQueue::ScheduledExecution.count,
        in_progress: SolidQueue::ClaimedExecution.count
      }
    rescue => e
      Rails.logger.error "Failed to get queue stats: #{e.message}"
      { pending: "N/A", scheduled: "N/A", in_progress: "N/A" }
    end
end
