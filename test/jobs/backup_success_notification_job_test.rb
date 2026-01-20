require "test_helper"

class BackupSuccessNotificationJobTest < ActiveJob::TestCase
  test "enqueues notification jobs for successful backup run" do
    backup_run = backup_runs(:successful_run)

    # Enable success notifications for a notifier
    notifier = notifiers(:email_notifier)
    notifier.update!(notify_on_success: true)

    assert_enqueued_jobs Notifier.for_success.count, only: NotifierDeliveryJob do
      BackupSuccessNotificationJob.perform_now(backup_run)
    end
  end

  test "skips non-successful backup run" do
    backup_run = backup_runs(:failed_run)

    assert_no_enqueued_jobs only: NotifierDeliveryJob do
      BackupSuccessNotificationJob.perform_now(backup_run)
    end
  end

  test "does nothing when no notifiers have notify_on_success enabled" do
    backup_run = backup_runs(:successful_run)

    # Ensure no notifiers have success notifications enabled
    Notifier.update_all(notify_on_success: false)

    assert_no_enqueued_jobs only: NotifierDeliveryJob do
      BackupSuccessNotificationJob.perform_now(backup_run)
    end
  end
end
