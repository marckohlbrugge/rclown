require "test_helper"

class StorageTest < ActiveSupport::TestCase
  setup do
    @storage = storages(:source_bucket)
  end

  test "valid storage" do
    assert @storage.valid?
  end

  test "requires bucket_name" do
    @storage.bucket_name = nil
    assert_not @storage.valid?
    assert_includes @storage.errors[:bucket_name], "can't be blank"
  end

  test "requires provider" do
    @storage.provider = nil
    assert_not @storage.valid?
    assert_includes @storage.errors[:provider], "must exist"
  end

  test "name returns display_name when present" do
    storage = storages(:with_prefix)
    assert_equal "Daily Backups", storage.name
  end

  test "name returns bucket_name when display_name is blank" do
    assert_equal "my-source-bucket", @storage.name
  end

  test "full_path without prefix" do
    assert_equal "my-source-bucket", @storage.full_path
  end

  test "full_path with prefix" do
    storage = storages(:with_prefix)
    assert_equal "shared-bucket/backups/daily", storage.full_path
  end

  test "rclone_path without prefix" do
    assert_equal "remote:my-source-bucket", @storage.rclone_path
  end

  test "rclone_path with prefix" do
    storage = storages(:with_prefix)
    assert_equal "remote:shared-bucket/backups/daily", storage.rclone_path
  end

  test "rclone_path with custom remote name" do
    assert_equal "source:my-source-bucket", @storage.rclone_path("source")
  end

  test "uniqueness of bucket_name and prefix per provider" do
    duplicate = Storage.new(
      provider: @storage.provider,
      bucket_name: @storage.bucket_name,
      prefix: @storage.prefix
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:bucket_name], "with this prefix already exists for this provider"
  end

  test "allows same bucket_name with different prefix" do
    new_storage = Storage.new(
      provider: @storage.provider,
      bucket_name: @storage.bucket_name,
      prefix: "different-prefix"
    )
    assert new_storage.valid?
  end

  test "allows same bucket_name on different provider" do
    new_storage = Storage.new(
      provider: providers(:backblaze),
      bucket_name: @storage.bucket_name
    )
    assert new_storage.valid?
  end
end
