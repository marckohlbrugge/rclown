class Notifier < ApplicationRecord
  NOTIFIER_TYPES = {
    "Notifiers::Email" => "Email",
    "Notifiers::Slack" => "Slack",
    "Notifiers::Webhook" => "Webhook"
  }.freeze

  encrypts :config

  validates :name, presence: true
  validates :type, presence: true, inclusion: { in: NOTIFIER_TYPES.keys }

  scope :enabled, -> { where(enabled: true) }

  def self.notify_failure(backup_run)
    enabled.find_each do |notifier|
      NotifierDeliveryJob.perform_later(notifier, backup_run)
    end
  end

  def type_name
    NOTIFIER_TYPES[type]
  end

  def parsed_config
    return {} if config.blank?
    JSON.parse(config)
  rescue JSON::ParserError
    {}
  end

  def deliver(backup_run)
    raise NotImplementedError, "Subclasses must implement #deliver"
  end

  def test_delivery
    raise NotImplementedError, "Subclasses must implement #test_delivery"
  end
end
