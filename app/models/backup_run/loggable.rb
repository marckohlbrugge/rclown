module BackupRun::Loggable
  extend ActiveSupport::Concern

  LOG_DIR = Rails.root.join("storage", "logs", "backup_runs")
  BROADCAST_DEBOUNCE = 2.seconds

  included do
    after_destroy :clear_log
  end

  def log_file_path
    LOG_DIR.join("#{id}.log")
  end

  def append_log(text)
    return if text.blank?

    ensure_log_directory
    File.open(log_file_path, "a") { |f| f.write(text) }
    broadcast_log_update
  end

  def clear_log
    FileUtils.rm_f(log_file_path)
  end

  def raw_log
    return nil unless log_file_path.exist?

    File.read(log_file_path)
  end

  def log_lines
    raw_log&.lines || []
  end

  def log_preview(lines: 20)
    log_lines.last(lines).join
  end

  def has_log?
    log_file_path.exist? && log_file_path.size > 0
  end

  private
    def ensure_log_directory
      FileUtils.mkdir_p(LOG_DIR) unless LOG_DIR.exist?
    end

    def broadcast_log_update
      cache_key = "backup_run_log_broadcast:#{id}"

      # Debounce: only broadcast if we haven't recently
      return if Rails.cache.exist?(cache_key)

      Rails.cache.write(cache_key, true, expires_in: BROADCAST_DEBOUNCE)
      broadcast_refresh_later_to(backup)
    end
end
