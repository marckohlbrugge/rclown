require "net/http"

module Notifiers
  class Webhook < Notifier
    validate :validate_url

    def url
      parsed_config["url"]
    end

    def headers
      parsed_config["headers"] || {}
    end

    def include_logs?
      parsed_config["include_logs"] == true
    end

    def deliver(backup_run, event_type = :failure)
      payload = event_type.to_sym == :success ? success_payload(backup_run) : failure_payload(backup_run)
      post_payload(payload)
    end

    def test_delivery
      post_payload(test_payload)
    end

    def self.config_from_params(params)
      {
        url: params[:url],
        headers: parse_headers(params[:headers]),
        include_logs: params[:include_logs] == "1"
      }.to_json
    end

    def self.parse_headers(headers_string)
      return {} if headers_string.blank?

      headers_string.split("\n").each_with_object({}) do |line, hash|
        key, value = line.split(":", 2).map(&:strip)
        hash[key] = value if key.present? && value.present?
      end
    end

    private

    def validate_url
      if url.blank?
        errors.add(:config, "must include a webhook URL")
      elsif !url.start_with?("https://")
        errors.add(:config, "must be a valid HTTPS URL")
      end
    end

    def post_payload(payload)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.path.presence || "/")
      request["Content-Type"] = "application/json"
      headers.each { |key, value| request[key] = value }
      request.body = payload.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Webhook failed: #{response.code} #{response.body.truncate(200)}"
      end
    end

    def failure_payload(backup_run)
      backup = backup_run.backup

      payload = {
        event: "backup.failed",
        timestamp: Time.current.iso8601,
        backup: {
          id: backup.id,
          name: backup.name
        },
        run: {
          id: backup_run.id,
          status: backup_run.status,
          exit_code: backup_run.exit_code,
          started_at: backup_run.started_at&.iso8601,
          finished_at: backup_run.finished_at&.iso8601,
          duration_seconds: backup_run.duration&.round
        }
      }

      if include_logs? && backup_run.has_log?
        payload[:run][:log_preview] = backup_run.log_preview(lines: 50)
      end

      payload
    end

    def success_payload(backup_run)
      backup = backup_run.backup

      {
        event: "backup.success",
        timestamp: Time.current.iso8601,
        backup: {
          id: backup.id,
          name: backup.name
        },
        run: {
          id: backup_run.id,
          status: backup_run.status,
          started_at: backup_run.started_at&.iso8601,
          finished_at: backup_run.finished_at&.iso8601,
          duration_seconds: backup_run.duration&.round,
          source_bytes: backup_run.source_bytes,
          source_count: backup_run.source_count
        }
      }
    end

    def test_payload
      {
        event: "notification.test",
        timestamp: Time.current.iso8601,
        message: "Test notification from Rclown backup system"
      }
    end
  end
end
