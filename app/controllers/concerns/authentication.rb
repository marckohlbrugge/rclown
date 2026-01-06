module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private

  def authenticate
    return unless http_auth_configured?

    authenticate_or_request_with_http_basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, http_auth_username) &
        ActiveSupport::SecurityUtils.secure_compare(password, http_auth_password)
    end
  end

  def http_auth_configured?
    http_auth_username.present? && http_auth_password.present?
  end

  def http_auth_username
    ENV["HTTP_AUTH_USERNAME"]
  end

  def http_auth_password
    ENV["HTTP_AUTH_PASSWORD"]
  end
end
