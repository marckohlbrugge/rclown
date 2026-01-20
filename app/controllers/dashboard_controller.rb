class DashboardController < ApplicationController
  def show
    @backups = Backup.includes(:source_storage, :destination_storage).order(created_at: :desc).limit(10)
    @recent_runs = BackupRun.includes(backup: [ :source_storage, :destination_storage ])
                            .order(created_at: :desc)
                            .limit(10)
    @upcoming_backups = Backup.enabled
                              .includes(:source_storage, :destination_storage)
                              .select { |b| b.next_run_at.present? }
                              .sort_by(&:next_run_at)
                              .first(5)
    @stats = {
      total_backups: Backup.count,
      enabled_backups: Backup.enabled.count,
      running_backups: Backup.joins(:runs).merge(BackupRun.running).distinct.count,
      failed_today: BackupRun.failed.where(created_at: Date.current.all_day).count,
      successful_today: BackupRun.successful.where(created_at: Date.current.all_day).count
    }
  end
end
