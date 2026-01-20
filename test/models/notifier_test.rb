require "test_helper"

class NotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "valid notifier" do
    notifier = notifiers(:email_notifier)
    assert notifier.valid?
  end

  test "requires name" do
    notifier = Notifiers::Email.new(config: '{"recipients":["test@example.com"]}')
    assert_not notifier.valid?
    assert_includes notifier.errors[:name], "can't be blank"
  end

  test "type validation rejects invalid types" do
    # Test that the NOTIFIER_TYPES constant doesn't include invalid types
    assert_not_includes Notifier::NOTIFIER_TYPES.keys, "InvalidType"
    # Valid types should be included
    assert_includes Notifier::NOTIFIER_TYPES.keys, "Notifiers::Email"
    assert_includes Notifier::NOTIFIER_TYPES.keys, "Notifiers::Slack"
    assert_includes Notifier::NOTIFIER_TYPES.keys, "Notifiers::Webhook"
  end

  test "enabled scope returns only enabled notifiers" do
    enabled = Notifier.enabled
    enabled.each do |notifier|
      assert notifier.enabled?
    end
  end

  test "type_name returns human-readable type name" do
    assert_equal "Email", notifiers(:email_notifier).type_name
    assert_equal "Slack", notifiers(:slack_notifier).type_name
    assert_equal "Webhook", notifiers(:webhook_notifier).type_name
  end

  test "parsed_config returns empty hash for blank config" do
    notifier = Notifiers::Email.new(name: "Test", config: nil)
    assert_equal({}, notifier.parsed_config)
  end

  test "parsed_config returns empty hash for invalid JSON" do
    notifier = Notifiers::Email.new(name: "Test", config: "invalid json")
    assert_equal({}, notifier.parsed_config)
  end

  test "notify_failure enqueues jobs for notifiers with notify_on_failure enabled" do
    backup_run = backup_runs(:failed_run)

    assert_enqueued_jobs Notifier.for_failure.count, only: NotifierDeliveryJob do
      Notifier.notify_failure(backup_run)
    end
  end

  test "notify_success enqueues jobs for notifiers with notify_on_success enabled" do
    backup_run = backup_runs(:successful_run)

    # Enable success notifications for one notifier
    notifier = notifiers(:email_notifier)
    notifier.update!(notify_on_success: true)

    assert_enqueued_jobs Notifier.for_success.count, only: NotifierDeliveryJob do
      Notifier.notify_success(backup_run)
    end
  end

  test "for_failure scope returns enabled notifiers with notify_on_failure" do
    Notifier.for_failure.each do |notifier|
      assert notifier.enabled?
      assert notifier.notify_on_failure?
    end
  end

  test "for_success scope returns enabled notifiers with notify_on_success" do
    notifier = notifiers(:email_notifier)
    notifier.update!(notify_on_success: true)

    Notifier.for_success.each do |n|
      assert n.enabled?
      assert n.notify_on_success?
    end
  end

  test "notify_on_failure defaults to true" do
    notifier = Notifiers::Email.new(name: "Test", config: '{"recipients":["test@example.com"]}')
    assert notifier.notify_on_failure?
  end

  test "notify_on_success defaults to false" do
    notifier = Notifiers::Email.new(name: "Test", config: '{"recipients":["test@example.com"]}')
    assert_not notifier.notify_on_success?
  end
end
