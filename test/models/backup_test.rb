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

  # Storage usage type compatibility tests
  test "rejects destination-only storage as source" do
    backup = Backup.new(
      source_storage: storages(:destination_only_storage),
      destination_storage: storages(:source_bucket),
      schedule: :daily
    )
    assert_not backup.valid?
    assert_includes backup.errors[:source_storage], "is restricted to destination-only usage"
  end

  test "rejects source-only storage as destination" do
    backup = Backup.new(
      source_storage: storages(:destination_bucket),
      destination_storage: storages(:source_only_storage),
      schedule: :daily
    )
    assert_not backup.valid?
    assert_includes backup.errors[:destination_storage], "is restricted to source-only usage"
  end

  test "accepts source-only storage as source" do
    backup = Backup.new(
      source_storage: storages(:source_only_storage),
      destination_storage: storages(:destination_only_storage),
      schedule: :daily
    )
    assert backup.valid?
  end

  test "accepts destination-only storage as destination" do
    backup = Backup.new(
      source_storage: storages(:source_bucket),
      destination_storage: storages(:destination_only_storage),
      schedule: :daily
    )
    assert backup.valid?
  end

  test "accepts storage with no usage restriction as source or destination" do
    backup = Backup.new(
      source_storage: storages(:source_bucket),
      destination_storage: storages(:destination_bucket),
      schedule: :daily
    )
    assert backup.valid?
  end

  # Path method tests
  test "source_rclone_path without path" do
    assert_equal "source:my-source-bucket", @backup.source_rclone_path("source")
  end

  test "source_rclone_path with path" do
    @backup.source_path = "data/exports"
    assert_equal "source:my-source-bucket/data/exports", @backup.source_rclone_path("source")
  end

  test "destination_rclone_path without path" do
    assert_equal "dest:my-backup-bucket", @backup.destination_rclone_path("dest")
  end

  test "destination_rclone_path with path" do
    @backup.destination_path = "backups/daily"
    assert_equal "dest:my-backup-bucket/backups/daily", @backup.destination_rclone_path("dest")
  end

  test "source_full_path without path" do
    assert_equal "my-source-bucket", @backup.source_full_path
  end

  test "source_full_path with path" do
    @backup.source_path = "data/exports"
    assert_equal "my-source-bucket/data/exports", @backup.source_full_path
  end

  test "destination_full_path without path" do
    assert_equal "my-backup-bucket", @backup.destination_full_path
  end

  test "destination_full_path with path" do
    @backup.destination_path = "backups/daily"
    assert_equal "my-backup-bucket/backups/daily", @backup.destination_full_path
  end

  # Deleted path tests (for --backup-dir)
  test "deleted_rclone_path without destination_path" do
    assert_equal "dest:my-backup-bucket/.deleted/backups/#{@backup.id}/#{Date.current.iso8601}", @backup.deleted_rclone_path("dest")
  end

  test "deleted_rclone_path with destination_path" do
    @backup.destination_path = "backups/daily"
    assert_equal "dest:my-backup-bucket/.deleted/backups/#{@backup.id}/#{Date.current.iso8601}/backups/daily", @backup.deleted_rclone_path("dest")
  end

  test "deleted_rclone_path with custom date" do
    date = Date.new(2025, 6, 15)
    assert_equal "dest:my-backup-bucket/.deleted/backups/#{@backup.id}/2025-06-15", @backup.deleted_rclone_path("dest", date: date)
  end

  test "deleted_rclone_base_path for cleanup" do
    assert_equal "dest:my-backup-bucket/.deleted/backups/#{@backup.id}", @backup.deleted_rclone_base_path("dest")
  end

  # Retention days tests
  test "retention_days defaults to 30" do
    backup = Backup.new(
      source_storage: storages(:source_bucket),
      destination_storage: storages(:destination_bucket),
      schedule: :daily
    )
    assert_equal 30, backup.retention_days
  end

  test "retention_days can be set to custom value" do
    @backup.retention_days = 90
    assert @backup.valid?
    assert_equal 90, @backup.retention_days
  end

  # Chart data tests
  test "chart_data returns empty array when no successful runs" do
    backup = backups(:weekly_backup)
    backup.runs.destroy_all
    assert_equal [], backup.chart_data
  end

  test "chart_data returns data for successful non-dry runs" do
    backup = backups(:weekly_backup)
    backup.runs.destroy_all

    # Create successful runs with data
    run1 = backup.runs.create!(
      status: :success,
      dry_run: false,
      started_at: 2.days.ago,
      finished_at: 2.days.ago + 5.minutes,
      source_bytes: 1000
    )
    run2 = backup.runs.create!(
      status: :success,
      dry_run: false,
      started_at: 1.day.ago,
      finished_at: 1.day.ago + 10.minutes,
      source_bytes: 2000
    )

    data = backup.chart_data
    assert_equal 2, data.size
    assert_equal 1000, data.first[:size_bytes]
    assert_equal 2000, data.last[:size_bytes]
  end

  test "chart_data excludes dry runs" do
    backup = backups(:weekly_backup)
    backup.runs.destroy_all

    backup.runs.create!(
      status: :success,
      dry_run: true,
      started_at: 1.day.ago,
      finished_at: 1.day.ago + 5.minutes,
      source_bytes: 1000
    )

    assert_equal [], backup.chart_data
  end

  test "chart_data excludes failed runs" do
    backup = backups(:weekly_backup)
    backup.runs.destroy_all

    backup.runs.create!(
      status: :failed,
      dry_run: false,
      started_at: 1.day.ago,
      finished_at: 1.day.ago + 5.minutes,
      source_bytes: 1000
    )

    assert_equal [], backup.chart_data
  end

  test "chart_stats returns nil when no data" do
    backup = backups(:weekly_backup)
    backup.runs.destroy_all
    assert_nil backup.chart_stats
  end

  test "chart_stats calculates correct statistics" do
    backup = backups(:weekly_backup)
    backup.runs.destroy_all

    backup.runs.create!(
      status: :success,
      dry_run: false,
      started_at: 3.days.ago,
      finished_at: 3.days.ago + 60.seconds,
      source_bytes: 1000
    )
    backup.runs.create!(
      status: :success,
      dry_run: false,
      started_at: 2.days.ago,
      finished_at: 2.days.ago + 120.seconds,
      source_bytes: 3000
    )
    backup.runs.create!(
      status: :success,
      dry_run: false,
      started_at: 1.day.ago,
      finished_at: 1.day.ago + 180.seconds,
      source_bytes: 2000
    )

    stats = backup.chart_stats

    # Size stats
    assert_equal 2000, stats[:size][:latest]
    assert_equal 1000, stats[:size][:min]
    assert_equal 3000, stats[:size][:max]
    assert_equal 2000, stats[:size][:avg]

    # Duration stats
    assert_equal 180, stats[:duration][:latest]
    assert_equal 60, stats[:duration][:min]
    assert_equal 180, stats[:duration][:max]
    assert_equal 120, stats[:duration][:avg]
  end
end
