module Notifiers
  class Email < Notifier
    validate :validate_recipients

    def recipients
      parsed_config["recipients"] || []
    end

    def deliver(backup_run, event_type = :failure)
      recipients.each do |recipient|
        case event_type.to_sym
        when :success
          BackupMailer.success(backup_run, recipient: recipient).deliver_now
        else
          BackupMailer.failure(backup_run, recipient: recipient).deliver_now
        end
      end
    end

    def test_delivery
      recipients.each do |recipient|
        BackupMailer.test_notification(recipient: recipient).deliver_now
      end
    end

    def self.config_from_params(params)
      recipients = params[:recipients].to_s.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      { recipients: recipients }.to_json
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
