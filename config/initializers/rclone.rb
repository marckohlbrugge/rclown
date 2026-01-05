# Verify rclone is installed at boot time
Rails.application.config.after_initialize do
  next if Rails.env.test?

  begin
    version_output = `rclone version 2>&1`
    if $?.success?
      version_line = version_output.lines.first&.strip
      Rails.logger.info "Rclone detected: #{version_line}"
    else
      raise "rclone command failed"
    end
  rescue Errno::ENOENT
    raise <<~ERROR
      rclone is not installed or not in PATH.

      Rclown requires rclone to perform backups. Please install it:
        - macOS: brew install rclone
        - Linux: https://rclone.org/install/

      Then restart the application.
    ERROR
  end
end
