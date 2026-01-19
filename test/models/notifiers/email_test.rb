require "test_helper"

module Notifiers
  class EmailTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test "valid email notifier" do
      notifier = notifiers(:email_notifier)
      assert notifier.valid?
    end

    test "recipients returns array from config" do
      notifier = notifiers(:email_notifier)
      assert_equal [ "admin@example.com", "ops@example.com" ], notifier.recipients
    end

    test "requires at least one recipient" do
      notifier = Notifiers::Email.new(name: "Test", config: '{"recipients":[]}')
      assert_not notifier.valid?
      assert_includes notifier.errors[:config], "must include at least one recipient email"
    end

    test "validates email format" do
      notifier = Notifiers::Email.new(name: "Test", config: '{"recipients":["invalid-email"]}')
      assert_not notifier.valid?
      assert_includes notifier.errors[:config], "contains invalid email addresses"
    end

    test "accepts valid email addresses" do
      notifier = Notifiers::Email.new(name: "Test", config: '{"recipients":["test@example.com"]}')
      assert notifier.valid?
    end

    test "deliver sends email to all recipients" do
      notifier = notifiers(:email_notifier)
      backup_run = backup_runs(:failed_run)

      assert_emails 2 do
        notifier.deliver(backup_run)
      end
    end

    test "test_delivery sends test email to all recipients" do
      notifier = notifiers(:email_notifier)

      assert_emails 2 do
        notifier.test_delivery
      end
    end
  end
end
