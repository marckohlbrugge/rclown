module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private
    def authenticate
      authenticate_or_request_with_http_basic("Rclown") do |username, password|
        username == admin_username && password == admin_password
      end
    end

    def admin_username
      Rails.application.credentials.dig(:admin, :username) || ENV["ADMIN_USERNAME"] || "admin"
    end

    def admin_password
      Rails.application.credentials.dig(:admin, :password) || ENV["ADMIN_PASSWORD"]
    end
end
