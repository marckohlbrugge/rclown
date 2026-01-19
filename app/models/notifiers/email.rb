module Notifiers
  class Email < Notifier
    validate :validate_recipients

    def recipients
      parsed_config["recipients"] || []
    end

    def deliver(backup_run)
      recipients.each do |recipient|
        BackupMailer.failure(backup_run, recipient: recipient).deliver_now
      end
    end

    def test_delivery
      recipients.each do |recipient|
        BackupMailer.test_notification(recipient: recipient).deliver_now
      end
    end

    private

    def validate_recipients
      if recipients.empty?
        errors.add(:config, "must include at least one recipient email")
      elsif recipients.any? { |r| !r.match?(URI::MailTo::EMAIL_REGEXP) }
        errors.add(:config, "contains invalid email addresses")
      end
    end
  end
end
