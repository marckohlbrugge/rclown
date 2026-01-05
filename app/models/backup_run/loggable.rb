module BackupRun::Loggable
  extend ActiveSupport::Concern

  def append_log(text)
    return if text.blank?

    current_log = raw_log || ""
    update_column(:raw_log, current_log + text)
  end

  def clear_log
    update_column(:raw_log, nil)
  end

  def log_lines
    raw_log&.lines || []
  end

  def log_preview(lines: 20)
    log_lines.last(lines).join
  end

  def has_log?
    raw_log.present?
  end
end
