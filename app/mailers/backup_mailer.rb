class BackupMailer < ApplicationMailer
  def failure(backup_run)
    @backup_run = backup_run
    @backup = backup_run.backup

    mail(
      to: notification_email,
      subject: "[Rclown] Backup Failed: #{@backup.name}"
    )
  end

  private
    def notification_email
      Rails.application.credentials.notification_email || ENV["NOTIFICATION_EMAIL"]
    end
end
