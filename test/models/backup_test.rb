require "test_helper"

class BackupTest < ActiveSupport::TestCase
  setup do
    @backup = backups(:daily_backup)
  end

  test "valid backup" do
    assert @backup.valid?
  end

  test "auto-generates name when blank" do
    @backup.name = nil
    @backup.valid?
    assert_not_nil @backup.name
    assert_includes @backup.name, @backup.source_storage.name
    assert_includes @backup.name, @backup.destination_storage.name
  end

  test "requires source_storage" do
    @backup.source_storage = nil
    assert_not @backup.valid?
  end

  test "requires destination_storage" do
    @backup.destination_storage = nil
    assert_not @backup.valid?
  end

  test "source and destination must differ" do
    @backup.destination_storage = @backup.source_storage
    assert_not @backup.valid?
    assert_includes @backup.errors[:destination_storage], "must be different from source"
  end

  # Schedulable tests
  test "schedule enum values" do
    assert Backup.schedules.key?("daily")
    assert Backup.schedules.key?("weekly")
  end

  test "due? returns true when never run" do
    @backup.last_run_at = nil
    assert @backup.due?
  end

  test "due? returns true when last run is old enough" do
    @backup.schedule = :daily
    @backup.last_run_at = 2.days.ago
    assert @backup.due?
  end

  test "due? returns false when recently run" do
    @backup.schedule = :daily
    @backup.last_run_at = 1.hour.ago
    assert_not @backup.due?
  end

  test "due? returns false when disabled" do
    @backup.enabled = false
    @backup.last_run_at = nil
    assert_not @backup.due?
  end

  # Enableable tests
  test "enabled scope" do
    enabled_count = Backup.enabled.count
    assert enabled_count > 0
    Backup.enabled.each { |b| assert b.enabled? }
  end

  test "enable sets enabled to true" do
    backup = backups(:disabled_backup)
    backup.enable
    assert backup.enabled?
  end

  test "disable sets enabled to false" do
    @backup.disable
    assert_not @backup.enabled?
  end

  # Executable tests
  test "running? returns true when there are running runs" do
    assert @backup.running?
  end

  test "running? returns false when no running runs" do
    backup = backups(:weekly_backup)
    assert_not backup.running?
  end

  test "last_run returns most recent completed run" do
    last = @backup.last_run
    assert_not_nil last
    assert last.completed?
  end
end
