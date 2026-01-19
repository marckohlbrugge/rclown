require "test_helper"

module Notifiers
  class WebhookTest < ActiveSupport::TestCase
    test "valid webhook notifier" do
      notifier = notifiers(:webhook_notifier)
      assert notifier.valid?
    end

    test "url returns url from config" do
      notifier = notifiers(:webhook_notifier)
      assert_equal "https://api.example.com/webhooks/backup", notifier.url
    end

    test "headers returns headers from config" do
      notifier = notifiers(:webhook_notifier)
      assert_equal({ "Authorization" => "Bearer token" }, notifier.headers)
    end

    test "include_logs? returns true when configured" do
      notifier = notifiers(:webhook_notifier)
      assert notifier.include_logs?
    end

    test "include_logs? returns false when not configured" do
      notifier = notifiers(:webhook_notifier_no_logs)
      assert_not notifier.include_logs?
    end

    test "requires url" do
      notifier = Notifiers::Webhook.new(name: "Test", config: "{}")
      assert_not notifier.valid?
      assert_includes notifier.errors[:config], "must include a webhook URL"
    end

    test "validates https url" do
      notifier = Notifiers::Webhook.new(name: "Test", config: '{"url":"http://insecure.com"}')
      assert_not notifier.valid?
      assert_includes notifier.errors[:config], "must be a valid HTTPS URL"
    end

    test "accepts valid https url" do
      notifier = Notifiers::Webhook.new(name: "Test", config: '{"url":"https://secure.com"}')
      assert notifier.valid?
    end

    test "deliver posts to webhook with headers" do
      notifier = notifiers(:webhook_notifier)
      backup_run = backup_runs(:failed_run)

      stub_request(:post, notifier.url)
        .with(headers: { "Authorization" => "Bearer token" })
        .to_return(status: 200, body: "ok")

      notifier.deliver(backup_run)

      assert_requested(:post, notifier.url) do |req|
        body = JSON.parse(req.body)
        body["event"] == "backup.failed" && body["backup"]["name"].present?
      end
    end

    test "deliver includes logs when configured" do
      notifier = notifiers(:webhook_notifier)
      backup_run = backup_runs(:failed_run)
      backup_run.append_log("Test log content")

      stub_request(:post, notifier.url).to_return(status: 200, body: "ok")

      notifier.deliver(backup_run)

      assert_requested(:post, notifier.url) do |req|
        body = JSON.parse(req.body)
        body["run"]["log_preview"].present?
      end
    ensure
      backup_run.clear_log
    end

    test "deliver excludes logs when not configured" do
      notifier = notifiers(:webhook_notifier_no_logs)
      backup_run = backup_runs(:failed_run)
      backup_run.append_log("Test log content")

      stub_request(:post, notifier.url).to_return(status: 200, body: "ok")

      notifier.deliver(backup_run)

      assert_requested(:post, notifier.url) do |req|
        body = JSON.parse(req.body)
        body["run"]["log_preview"].nil?
      end
    ensure
      backup_run.clear_log
    end

    test "test_delivery posts test message" do
      notifier = notifiers(:webhook_notifier)

      stub_request(:post, notifier.url).to_return(status: 200, body: "ok")

      notifier.test_delivery

      assert_requested(:post, notifier.url) do |req|
        body = JSON.parse(req.body)
        body["event"] == "notification.test"
      end
    end

    test "deliver raises on non-success response" do
      notifier = notifiers(:webhook_notifier)
      backup_run = backup_runs(:failed_run)

      stub_request(:post, notifier.url).to_return(status: 500, body: "error")

      assert_raises(RuntimeError) do
        notifier.deliver(backup_run)
      end
    end
  end
end
