Rails.application.configure do
  config.mission_control.jobs.http_basic_auth_enabled = true
  config.mission_control.jobs.http_basic_auth_user = ENV["HTTP_AUTH_USERNAME"]
  config.mission_control.jobs.http_basic_auth_password = ENV["HTTP_AUTH_PASSWORD"]
end
