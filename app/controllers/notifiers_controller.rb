class NotifiersController < ApplicationController
  before_action :set_notifier, only: %i[show edit update destroy]

  def index
    @notifiers = Notifier.order(created_at: :desc)
  end

  def show
  end

  def new
    @notifier = Notifier.new
  end

  def edit
  end

  def create
    @notifier = build_notifier

    if @notifier.save
      redirect_to @notifier, notice: "Notifier was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @notifier.assign_attributes(notifier_params)
    @notifier.config = build_config

    if @notifier.save
      redirect_to @notifier, notice: "Notifier was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notifier.destroy!
    redirect_to notifiers_path, notice: "Notifier was successfully deleted.", status: :see_other
  end

  private

  def set_notifier
    @notifier = Notifier.find(params[:id])
  end

  def notifier_params
    params.require(:notifier).permit(:name, :enabled)
  end

  def build_notifier
    type = params[:notifier][:type]
    klass = type.safe_constantize if Notifier::NOTIFIER_TYPES.key?(type)
    klass ||= Notifier

    notifier = klass.new(notifier_params)
    notifier.config = build_config
    notifier
  end

  def build_config
    case params[:notifier][:type]
    when "Notifiers::Email"
      recipients = params[:notifier][:recipients].to_s.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      { recipients: recipients }.to_json
    when "Notifiers::Slack"
      { webhook_url: params[:notifier][:webhook_url] }.to_json
    when "Notifiers::Webhook"
      headers = parse_headers(params[:notifier][:headers])
      {
        url: params[:notifier][:url],
        headers: headers,
        include_logs: params[:notifier][:include_logs] == "1"
      }.to_json
    else
      "{}"
    end
  end

  def parse_headers(headers_string)
    return {} if headers_string.blank?

    headers_string.split("\n").each_with_object({}) do |line, hash|
      key, value = line.split(":", 2).map(&:strip)
      hash[key] = value if key.present? && value.present?
    end
  end
end
