require "open3"
require "timeout"

class Rclone::Executor
  attr_reader :backup_run

  TIMEOUT = BackupRun::TIMEOUT

  def initialize(backup_run)
    @backup_run = backup_run
  end

  def run
    config_file = generate_config
    execute_rclone(config_file)
  ensure
    cleanup_config(config_file)
  end

  private
    def backup
      backup_run.backup
    end

    def generate_config
      Rclone::ConfigGenerator.new(backup).generate
    end

    def execute_rclone(config_file)
      command = build_command(config_file)
      backup_run.append_log("Running: #{command.join(' ')}\n\n")

      exit_code = nil

      Timeout.timeout(TIMEOUT.to_i) do
        Open3.popen2e(*command) do |stdin, stdout_stderr, wait_thr|
          stdin.close

          backup_run.record_pid(wait_thr.pid)

          stdout_stderr.each_line do |line|
            backup_run.append_log(line)
          end

          exit_code = wait_thr.value.exitstatus
        end
      end

      { success: exit_code == 0, exit_code: exit_code }
    rescue Timeout::Error
      backup_run.append_log("\n\nERROR: Backup timed out after #{TIMEOUT.inspect}")
      kill_process
      { success: false, exit_code: -2 }
    end

    def build_command(config_file)
      source_path = backup.source_storage.rclone_path("source")
      dest_path = backup.destination_storage.rclone_path("destination")

      cmd = [
        "rclone",
        backup_run.dry_run? ? "sync" : "sync",
        source_path,
        dest_path,
        "--config", config_file.path,
        "--stats", "30s",
        "--stats-one-line",
        "--log-level", "NOTICE",
        "--disable", "ServerSideAcrossConfigs"
      ]

      cmd << "--dry-run" if backup_run.dry_run?

      cmd
    end

    def kill_process
      return unless backup_run.rclone_pid

      begin
        Process.kill("TERM", backup_run.rclone_pid)
        sleep 2
        Process.kill("KILL", backup_run.rclone_pid) if backup_run.process_running?
      rescue Errno::ESRCH, Errno::EPERM
        # Process already terminated or we don't have permission
      end
    end

    def cleanup_config(config_file)
      return unless config_file

      config_file.close
      config_file.unlink
    rescue => e
      Rails.logger.warn "Failed to cleanup rclone config: #{e.message}"
    end
end
