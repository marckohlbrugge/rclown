class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.dig(:smtp, :from) || "rclown@example.com" }
  layout "mailer"
end
