class BackupMailer < ApplicationMailer
  def failure(backup_run, recipient: nil)
    @backup_run = backup_run
    @backup = backup_run.backup

    mail(
      to: recipient || default_notification_email,
      subject: "[Rclown] Backup Failed: #{@backup.name}"
    )
  end

  def success(backup_run, recipient: nil)
    @backup_run = backup_run
    @backup = backup_run.backup

    mail(
      to: recipient || default_notification_email,
      subject: "[Rclown] Backup Successful: #{@backup.name}"
    )
  end

  def test_notification(recipient:)
    mail(
      to: recipient,
      subject: "[Rclown] Test Notification"
    )
  end

  private
    def default_notification_email
      Rails.application.credentials.notification_email || ENV["NOTIFICATION_EMAIL"]
    end
end
