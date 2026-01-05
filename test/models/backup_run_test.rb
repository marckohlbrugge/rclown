require "test_helper"

class BackupRunTest < ActiveSupport::TestCase
  setup do
    @run = backup_runs(:pending_run)
    @running_run = backup_runs(:running_run)
    @successful_run = backup_runs(:successful_run)
  end

  test "valid backup run" do
    assert @run.valid?
  end

  test "requires backup" do
    @run.backup = nil
    assert_not @run.valid?
  end

  test "default status is pending" do
    run = BackupRun.new(backup: backups(:daily_backup))
    assert_equal "pending", run.status
  end

  test "status enum values" do
    assert BackupRun.statuses.key?("pending")
    assert BackupRun.statuses.key?("running")
    assert BackupRun.statuses.key?("success")
    assert BackupRun.statuses.key?("failed")
    assert BackupRun.statuses.key?("cancelled")
    assert BackupRun.statuses.key?("skipped")
  end

  test "completed scope includes success, failed, cancelled" do
    completed = BackupRun.completed
    completed.each do |run|
      assert run.success? || run.failed? || run.cancelled?
    end
  end

  test "successful scope" do
    successful = BackupRun.successful
    successful.each { |run| assert run.success? }
  end

  test "duration returns nil when not started" do
    assert_nil @run.duration
  end

  test "duration calculates correctly for completed run" do
    duration = @successful_run.duration
    assert_not_nil duration
    assert duration > 0
  end

  test "formatted_duration for completed run" do
    formatted = @successful_run.formatted_duration
    assert_not_nil formatted
    assert formatted.include?("m") || formatted.include?("s")
  end

  # Loggable tests
  test "append_log adds to raw_log" do
    @run.append_log("First line\n")
    @run.append_log("Second line\n")
    assert_includes @run.raw_log, "First line"
    assert_includes @run.raw_log, "Second line"
  end

  test "has_log? returns true when log present" do
    run = BackupRun.create!(backup: backups(:daily_backup), status: :pending)
    run.append_log("Some log content")
    assert run.has_log?
  ensure
    run&.clear_log
    run&.destroy
  end

  test "has_log? returns false when log empty" do
    run = BackupRun.create!(backup: backups(:daily_backup), status: :pending)
    run.clear_log
    assert_not run.has_log?
  ensure
    run&.destroy
  end

  test "log_preview returns last N lines" do
    run = BackupRun.create!(backup: backups(:daily_backup), status: :pending)
    run.append_log((1..50).map { |i| "Line #{i}" }.join("\n"))
    preview = run.log_preview(lines: 5)
    assert_includes preview, "Line 50"
    assert_includes preview, "Line 46"
    assert_not_includes preview, "Line 1"
  ensure
    run&.clear_log
    run&.destroy
  end

  # ProcessManageable tests
  test "record_pid updates rclone_pid" do
    @run.record_pid(99999)
    assert_equal 99999, @run.reload.rclone_pid
  end

  test "process_running? returns false for non-existent pid" do
    @running_run.rclone_pid = 999999999
    assert_not @running_run.process_running?
  end
end
