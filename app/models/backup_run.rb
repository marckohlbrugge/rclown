class BackupRun < ApplicationRecord
  include ProcessManageable, Loggable

  TIMEOUT = 12.hours

  belongs_to :backup, touch: true
  broadcasts_refreshes_to :backup

  enum :status, {
    pending: "pending",
    running: "running",
    success: "success",
    failed: "failed",
    cancelled: "cancelled",
    skipped: "skipped"
  }, default: :pending

  scope :completed, -> { where(status: [ :success, :failed, :cancelled ]) }
  scope :successful, -> { where(status: :success) }
  scope :recent, -> { order(created_at: :desc).limit(30) }

  def completed?
    success? || failed? || cancelled?
  end

  after_create :update_backup_last_run_at

  def execute
    running!
    update!(started_at: Time.current, worker_pid: Process.pid)
    clear_log

    result = Rclone::Executor.new(self).run

    record_result(result)
  rescue => e
    record_failure(e)
  end

  def execute_later
    ExecuteBackupJob.perform_later(self)
  end

  def duration
    return nil unless started_at

    end_time = finished_at || Time.current
    end_time - started_at
  end

  def formatted_duration
    return nil unless duration

    hours = (duration / 3600).floor
    minutes = ((duration % 3600) / 60).floor
    seconds = (duration % 60).floor

    if hours > 0
      "#{hours}h #{minutes}m #{seconds}s"
    elsif minutes > 0
      "#{minutes}m #{seconds}s"
    else
      "#{seconds}s"
    end
  end

  def notify_failure
    return unless failed?
    BackupFailureNotificationJob.perform_later(self)
  end

  def notify_success
    return unless success?
    BackupSuccessNotificationJob.perform_later(self)
  end

  private
    def record_result(result)
      update!(
        status: result[:success] ? :success : :failed,
        exit_code: result[:exit_code],
        finished_at: Time.current
      )

      if result[:success]
        notify_success
      else
        notify_failure
      end
    end

    def record_failure(error)
      append_log("\n\nRuby Error: #{error.class}: #{error.message}\n#{error.backtrace&.first(10)&.join("\n")}")
      update!(
        status: :failed,
        exit_code: -1,
        finished_at: Time.current
      )

      notify_failure
    end

    def update_backup_last_run_at
      backup.update_column(:last_run_at, Time.current) unless dry_run?
    end
end
