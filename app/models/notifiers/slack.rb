module Notifiers
  class Slack < Notifier
    validate :validate_webhook_url

    def self.config_from_params(params)
      { webhook_url: params[:webhook_url] }.to_json
    end

    def webhook_url
      parsed_config["webhook_url"]
    end

    def deliver(backup_run)
      post_message(failure_message(backup_run))
    end

    def test_delivery
      post_message(test_message)
    end

    private

    def validate_webhook_url
      if webhook_url.blank?
        errors.add(:config, "must include a Slack webhook URL")
      elsif !webhook_url.start_with?("https://hooks.slack.com/")
        errors.add(:config, "must be a valid Slack webhook URL")
      end
    end

    def post_message(payload)
      uri = URI(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Slack webhook failed: #{response.code} #{response.body}"
      end
    end

    def failure_message(backup_run)
      backup = backup_run.backup

      {
        text: "Backup Failed: #{backup.name}",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "Backup Failed",
              emoji: true
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Backup:*\n#{backup.name}"
              },
              {
                type: "mrkdwn",
                text: "*Status:*\nFailed"
              },
              {
                type: "mrkdwn",
                text: "*Duration:*\n#{backup_run.formatted_duration || 'N/A'}"
              },
              {
                type: "mrkdwn",
                text: "*Exit Code:*\n#{backup_run.exit_code || 'N/A'}"
              }
            ]
          }
        ]
      }
    end

    def test_message
      {
        text: "Rclown Test Notification",
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "This is a test notification from *Rclown* backup system. If you received this, your Slack integration is working correctly."
            }
          }
        ]
      }
    end
  end
end
