require "open3"
require "timeout"

class Rclone::Executor
  class StorageUsageError < StandardError; end

  attr_reader :backup_run

  TIMEOUT = BackupRun::TIMEOUT

  def initialize(backup_run)
    @backup_run = backup_run
  end

  def run
    validate_storage_usage!
    @config_file = generate_config
    result = execute_rclone(@config_file)

    if result[:success] && !backup_run.dry_run?
      result = verify_backup(result)
    end

    result
  ensure
    cleanup_config(@config_file)
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

    def verify_backup(result)
      backup_run.append_log("\n")

      source_size = Rclone::SizeChecker.new(@config_file, rclone_path: backup.source_rclone_path("source")).check
      if source_size
        backup_run.append_log("[VERIFY] Source: #{source_size[:count]} objects, #{format_bytes(source_size[:bytes])}\n")
      else
        backup_run.append_log("[VERIFY] Source: failed to get size\n")
        return result
      end

      dest_size = Rclone::SizeChecker.new(@config_file, rclone_path: backup.destination_rclone_path("destination"), excludes: ".deleted/**").check
      if dest_size
        backup_run.append_log("[VERIFY] Destination: #{dest_size[:count]} objects, #{format_bytes(dest_size[:bytes])}\n")
      else
        backup_run.append_log("[VERIFY] Destination: failed to get size\n")
        return result
      end

      if source_size[:count] == dest_size[:count] && source_size[:bytes] == dest_size[:bytes]
        backup_run.append_log("[VERIFY] OK - counts and sizes match\n")
        result
      else
        backup_run.append_log("[VERIFY] MISMATCH - source and destination differ\n")
        { success: false, exit_code: result[:exit_code] }
      end
    end

    def format_bytes(bytes)
      if bytes >= 1_000_000_000
        format("%.1f GB", bytes / 1_000_000_000.0)
      elsif bytes >= 1_000_000
        format("%.1f MB", bytes / 1_000_000.0)
      elsif bytes >= 1_000
        format("%.1f KB", bytes / 1_000.0)
      else
        "#{bytes} B"
      end
    end

    def build_command(config_file)
      source_path = backup.source_rclone_path("source")
      dest_path = backup.destination_rclone_path("destination")
      deleted_path = backup.deleted_rclone_path("destination")

      cmd = [
        "rclone",
        "sync",
        source_path,
        dest_path,
        "--backup-dir", deleted_path,
        "--suffix", "-#{Date.current.iso8601}",
        "--config", config_file.path,
        "--stats", "30s",
        "--stats-one-line",
        "--log-level", "NOTICE",
        "--disable", "ServerSideAcrossConfigs"
      ]

      cmd += upload_cutoff_flags
      cmd << "--dry-run" if backup_run.dry_run?

      cmd
    end

    def upload_cutoff_flags
      case backup.destination_storage.provider.provider_type
      when "cloudflare_r2", "amazon_s3"
        [ "--s3-upload-cutoff", "0" ]
      when "backblaze_b2"
        [ "--b2-upload-cutoff", "0" ]
      else
        []
      end
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

    def validate_storage_usage!
      source = backup.source_storage
      destination = backup.destination_storage

      unless source.available_as_source?
        raise StorageUsageError, "Source storage '#{source.name}' is restricted to destination-only usage"
      end

      unless destination.available_as_destination?
        raise StorageUsageError, "Destination storage '#{destination.name}' is restricted to source-only usage"
      end
    end
end
