require "test_helper"

module Notifiers
  class SlackTest < ActiveSupport::TestCase
    test "valid slack notifier" do
      notifier = notifiers(:slack_notifier)
      assert notifier.valid?
    end

    test "webhook_url returns url from config" do
      notifier = notifiers(:slack_notifier)
      assert_equal "https://hooks.slack.com/services/T00/B00/XXX", notifier.webhook_url
    end

    test "requires webhook_url" do
      notifier = Notifiers::Slack.new(name: "Test", config: "{}")
      assert_not notifier.valid?
      assert_includes notifier.errors[:config], "must include a Slack webhook URL"
    end

    test "validates webhook_url format" do
      notifier = Notifiers::Slack.new(name: "Test", config: '{"webhook_url":"https://invalid.com"}')
      assert_not notifier.valid?
      assert_includes notifier.errors[:config], "must be a valid Slack webhook URL"
    end

    test "accepts valid slack webhook URL" do
      notifier = Notifiers::Slack.new(name: "Test", config: '{"webhook_url":"https://hooks.slack.com/services/XXX"}')
      assert notifier.valid?
    end

    test "deliver posts to slack webhook" do
      notifier = notifiers(:slack_notifier)
      backup_run = backup_runs(:failed_run)

      stub_request(:post, notifier.webhook_url)
        .to_return(status: 200, body: "ok")

      notifier.deliver(backup_run)

      assert_requested(:post, notifier.webhook_url) do |req|
        body = JSON.parse(req.body)
        body["text"].include?("Backup Failed")
      end
    end

    test "test_delivery posts test message to slack" do
      notifier = notifiers(:slack_notifier)

      stub_request(:post, notifier.webhook_url)
        .to_return(status: 200, body: "ok")

      notifier.test_delivery

      assert_requested(:post, notifier.webhook_url) do |req|
        body = JSON.parse(req.body)
        body["text"].include?("Test")
      end
    end

    test "deliver raises on non-success response" do
      notifier = notifiers(:slack_notifier)
      backup_run = backup_runs(:failed_run)

      stub_request(:post, notifier.webhook_url)
        .to_return(status: 500, body: "error")

      assert_raises(RuntimeError) do
        notifier.deliver(backup_run)
      end
    end
  end
end
