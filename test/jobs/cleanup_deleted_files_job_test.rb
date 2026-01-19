require "test_helper"
require "minitest/mock"

class CleanupDeletedFilesJobTest < ActiveSupport::TestCase
  setup do
    @backup = backups(:daily_backup)
    @job = CleanupDeletedFilesJob.new
  end

  test "iterates over enabled backups" do
    mock_status = MockStatus.new(true)
    call_count = 0

    capture_stub = lambda do |*command|
      call_count += 1
      [ "", "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      @job.perform
    end

    # Each backup should have delete + rmdirs = 2 calls per enabled backup
    enabled_count = Backup.enabled.count
    assert_equal enabled_count * 2, call_count
  end

  test "calls rclone delete with correct min-age" do
    mock_status = MockStatus.new(true)
    captured_commands = []

    capture_stub = lambda do |*command|
      captured_commands << command
      [ "", "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      @job.perform
    end

    # Find the delete command for our daily_backup fixture
    delete_command = captured_commands.find do |cmd|
      cmd[1] == "delete" && cmd[2].include?(@backup.destination_storage.bucket_name)
    end
    assert_not_nil delete_command

    min_age_index = delete_command.index("--min-age")
    assert_not_nil min_age_index
    assert_equal "#{@backup.retention_days}d", delete_command[min_age_index + 1]
  end

  test "calls rclone rmdirs with leave-root flag" do
    mock_status = MockStatus.new(true)
    captured_commands = []

    capture_stub = lambda do |*command|
      captured_commands << command
      [ "", "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      @job.perform
    end

    rmdirs_command = captured_commands.find { |cmd| cmd[1] == "rmdirs" }
    assert_not_nil rmdirs_command
    assert_includes rmdirs_command, "--leave-root"
  end

  test "targets .deleted path with backup ID" do
    mock_status = MockStatus.new(true)
    captured_commands = []

    capture_stub = lambda do |*command|
      captured_commands << command
      [ "", "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      @job.perform
    end

    # Find the delete command for our daily_backup fixture
    delete_command = captured_commands.find do |cmd|
      cmd[1] == "delete" && cmd[2].include?("backup-#{@backup.id}")
    end
    deleted_path = delete_command[2]

    # .deleted includes backup ID: bucket/.deleted/backup-123
    assert_match %r{/\.deleted/backup-#{@backup.id}}, deleted_path
    assert_includes deleted_path, @backup.destination_storage.bucket_name
  end

  test "skips disabled backups" do
    mock_status = MockStatus.new(true)
    captured_commands = []

    capture_stub = lambda do |*command|
      captured_commands << command
      [ "", "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      @job.perform
    end

    disabled_backup = backups(:disabled_backup)
    paths = captured_commands.map { |cmd| cmd[2] }

    # Disabled backup's path should not appear
    assert_not paths.any? { |p| p.include?(disabled_backup.destination_storage.bucket_name) && p.include?(disabled_backup.destination_path.to_s) }
  end

  private
    MockStatus = Struct.new(:success) do
      def success?
        success
      end
    end
end
