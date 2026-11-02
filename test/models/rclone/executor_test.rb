require "test_helper"

class Rclone::ExecutorTest < ActiveSupport::TestCase
  test "excludes .deleted when syncing to the bucket root" do
    command = build_command(backups(:daily_backup))

    assert_equal "/.deleted/**", command[command.index("--exclude") + 1]
  end

  test "does not exclude .deleted when syncing to a destination path" do
    command = build_command(backups(:weekly_backup))

    assert_not_includes command, "--exclude"
  end

  private
    def build_command(backup)
      run = backup.runs.build(dry_run: true)
      config_file = Tempfile.new([ "rclone", ".conf" ])
      Rclone::Executor.new(run).send(:build_command, config_file)
    ensure
      config_file&.close!
    end
end
