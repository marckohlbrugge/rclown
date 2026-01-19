require "test_helper"

class BackupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @backup = backups(:daily_backup)
    @source_storage = storages(:source_bucket)
    @destination_storage = storages(:destination_bucket)
  end

  test "should create backup with paths" do
    assert_difference("Backup.count") do
      post backups_url, params: {
        backup: {
          source_storage_id: @source_storage.id,
          destination_storage_id: @destination_storage.id,
          source_path: "data/exports",
          destination_path: "backups/daily",
          schedule: "daily",
          enabled: true
        }
      }
    end

    backup = Backup.last
    assert_equal "data/exports", backup.source_path
    assert_equal "backups/daily", backup.destination_path
    assert_redirected_to backup_url(backup)
  end

  test "should update backup with paths" do
    patch backup_url(@backup), params: {
      backup: {
        source_path: "new/source/path",
        destination_path: "new/dest/path"
      }
    }

    @backup.reload
    assert_equal "new/source/path", @backup.source_path
    assert_equal "new/dest/path", @backup.destination_path
    assert_redirected_to backup_url(@backup)
  end

  test "should clear paths when set to empty" do
    @backup.update!(source_path: "existing/path", destination_path: "other/path")

    patch backup_url(@backup), params: {
      backup: {
        source_path: "",
        destination_path: ""
      }
    }

    @backup.reload
    assert_equal "", @backup.source_path
    assert_equal "", @backup.destination_path
  end
end
