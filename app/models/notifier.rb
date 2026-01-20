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
  scope :for_success, -> { enabled.where(notify_on_success: true) }
  scope :for_failure, -> { enabled.where(notify_on_failure: true) }

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

  def self.build(params)
    type = params[:type]
    klass = type.safe_constantize if NOTIFIER_TYPES.key?(type)
    klass ||= Notifier

    klass.new(params.permit(:name, :enabled)).tap do |notifier|
      notifier.config = klass.config_from_params(params)
    end
  end

  def self.config_from_params(_params)
    "{}"
  end

  def self.notify_failure(backup_run)
    for_failure.find_each do |notifier|
      NotifierDeliveryJob.perform_later(notifier, backup_run, :failure)
    end
  end

  def self.notify_success(backup_run)
    for_success.find_each do |notifier|
      NotifierDeliveryJob.perform_later(notifier, backup_run, :success)
    end
  end
end
