require "open3"

class CleanupDeletedFilesJob < ApplicationJob
  queue_as :backups

  def perform
    Backup.enabled.find_each do |backup|
      cleanup_deleted_files(backup)
    end
  end

  private
    def cleanup_deleted_files(backup)
      config_file = generate_config(backup)
      deleted_path = backup.deleted_rclone_path("destination")

      delete_old_files(config_file, deleted_path, backup.retention_days)
      remove_empty_dirs(config_file, deleted_path)
    ensure
      cleanup_config(config_file)
    end

    def generate_config(backup)
      provider = backup.destination_storage.provider

      Tempfile.new([ "rclone", ".conf" ]).tap do |file|
        file.write(provider.rclone_config_section("destination"))
        file.flush
      end
    end

    def delete_old_files(config_file, path, retention_days)
      command = [
        "rclone", "delete",
        path,
        "--min-age", "#{retention_days}d",
        "--config", config_file.path
      ]

      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        Rails.logger.warn "[CleanupDeletedFilesJob] Failed to delete old files from #{path}: #{stderr}"
      end
    end

    def remove_empty_dirs(config_file, path)
      command = [
        "rclone", "rmdirs",
        path,
        "--leave-root",
        "--config", config_file.path
      ]

      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        Rails.logger.warn "[CleanupDeletedFilesJob] Failed to remove empty dirs from #{path}: #{stderr}"
      end
    end

    def cleanup_config(config_file)
      return unless config_file

      config_file.close
      config_file.unlink
    rescue => e
      Rails.logger.warn "[CleanupDeletedFilesJob] Failed to cleanup config: #{e.message}"
    end
end
