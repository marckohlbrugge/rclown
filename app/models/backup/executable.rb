module Backup::Executable
  extend ActiveSupport::Concern

  def execute(dry_run: false)
    return nil if running? && !dry_run

    runs.create!(
      dry_run: dry_run,
      source_rclone_path: source_rclone_path,
      destination_rclone_path: destination_rclone_path
    ).tap do |run|
      run.execute_later
    end
  end

  def running?
    runs.running.exists?
  end

  def last_run
    runs.completed.order(finished_at: :desc).first
  end

  def last_successful_run
    runs.successful.order(finished_at: :desc).first
  end
end
