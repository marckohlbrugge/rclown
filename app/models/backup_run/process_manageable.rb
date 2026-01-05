require "open3"

module BackupRun::ProcessManageable
  extend ActiveSupport::Concern

  def record_pid(pid)
    update_column(:rclone_pid, pid)
  end

  def cancel
    return unless running? && rclone_pid.present?

    begin
      Process.kill("TERM", rclone_pid)
      update!(
        status: :cancelled,
        finished_at: Time.current
      )
    rescue Errno::ESRCH
      # Process already terminated
      update!(
        status: :cancelled,
        finished_at: Time.current
      )
    rescue Errno::EPERM
      append_log("\nFailed to cancel: permission denied")
    end
  end

  def process_running?
    return false unless rclone_pid.present?

    begin
      Process.kill(0, rclone_pid)
      true
    rescue Errno::ESRCH, Errno::EPERM
      false
    end
  end

  def process_stats
    return nil unless process_running?

    begin
      output, _status = Open3.capture2("ps", "-p", rclone_pid.to_s, "-o", "%cpu,%mem")
      lines = output.strip.split("\n")
      return nil if lines.length < 2

      values = lines[1].split
      {
        cpu: values[0]&.to_f,
        memory: values[1]&.to_f
      }
    rescue
      nil
    end
  end
end
