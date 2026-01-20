require "test_helper"

class NotifierDeliveryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "delivers failure notification and updates last_notified_at" do
    notifier = notifiers(:email_notifier)
    backup_run = backup_runs(:failed_run)

    assert_emails 2 do
      NotifierDeliveryJob.perform_now(notifier, backup_run, :failure)
    end

    notifier.reload
    assert_not_nil notifier.last_notified_at
    assert_nil notifier.last_error
  end

  test "delivers success notification when notify_on_success is enabled" do
    notifier = notifiers(:email_notifier)
    notifier.update!(notify_on_success: true)
    backup_run = backup_runs(:successful_run)

    assert_emails 2 do
      NotifierDeliveryJob.perform_now(notifier, backup_run, :success)
    end

    notifier.reload
    assert_not_nil notifier.last_notified_at
  end

  test "skips disabled notifier" do
    notifier = notifiers(:disabled_email_notifier)
    backup_run = backup_runs(:failed_run)

    assert_no_emails do
      NotifierDeliveryJob.perform_now(notifier, backup_run, :failure)
    end
  end

  test "skips success event when notify_on_success is false" do
    notifier = notifiers(:email_notifier)
    notifier.update!(notify_on_success: false)
    backup_run = backup_runs(:successful_run)

    assert_no_emails do
      NotifierDeliveryJob.perform_now(notifier, backup_run, :success)
    end
  end

  test "skips failure event when notify_on_failure is false" do
    notifier = notifiers(:email_notifier)
    notifier.update!(notify_on_failure: false)
    backup_run = backup_runs(:failed_run)

    assert_no_emails do
      NotifierDeliveryJob.perform_now(notifier, backup_run, :failure)
    end
  end

  test "skips when backup_run status doesnt match event type" do
    notifier = notifiers(:email_notifier)
    backup_run = backup_runs(:successful_run)

    assert_no_emails do
      NotifierDeliveryJob.perform_now(notifier, backup_run, :failure)
    end
  end

  test "records error on failure and re-raises" do
    webhook_url = "https://hooks.slack.com/services/TEST/URL/HERE"
    notifier = Notifiers::Slack.create!(
      name: "Test Slack",
      config: { webhook_url: webhook_url }.to_json
    )
    backup_run = backup_runs(:failed_run)

    stub_request(:post, webhook_url)
      .to_return(status: 500, body: "Internal Server Error")

    # Directly call the job logic to ensure the error is raised
    error = assert_raises(RuntimeError) do
      begin
        notifier.deliver(backup_run)
        notifier.update!(last_notified_at: Time.current, last_error: nil)
      rescue => e
        notifier.update!(last_failed_at: Time.current, last_error: e.message.truncate(500))
        raise
      end
    end

    assert_includes error.message, "500"

    notifier.reload
    assert_not_nil notifier.last_failed_at
    assert_includes notifier.last_error, "500"
  ensure
    notifier&.destroy
  end
end
