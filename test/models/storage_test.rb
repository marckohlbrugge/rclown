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
    storage = storages(:shared_bucket)
    assert_equal "Daily Backups", storage.name
  end

  test "name returns bucket_name when display_name is blank" do
    assert_equal "my-source-bucket", @storage.name
  end

  test "rclone_path returns bucket path" do
    assert_equal "remote:my-source-bucket", @storage.rclone_path
  end

  test "rclone_path with custom remote name" do
    assert_equal "source:my-source-bucket", @storage.rclone_path("source")
  end

  test "uniqueness of bucket_name per provider" do
    duplicate = Storage.new(
      provider: @storage.provider,
      bucket_name: @storage.bucket_name
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:bucket_name], "already exists for this provider"
  end

  test "allows same bucket_name on different provider" do
    new_storage = Storage.new(
      provider: providers(:backblaze),
      bucket_name: @storage.bucket_name
    )
    assert new_storage.valid?
  end

  # Usage type tests
  test "available_as_source? returns true when usage_type is nil" do
    assert_nil @storage.usage_type
    assert @storage.available_as_source?
  end

  test "available_as_source? returns true when usage_type is source_only" do
    storage = storages(:source_only_storage)
    assert storage.available_as_source?
  end

  test "available_as_source? returns false when usage_type is destination_only" do
    storage = storages(:destination_only_storage)
    assert_not storage.available_as_source?
  end

  test "available_as_destination? returns true when usage_type is nil" do
    assert_nil @storage.usage_type
    assert @storage.available_as_destination?
  end

  test "available_as_destination? returns true when usage_type is destination_only" do
    storage = storages(:destination_only_storage)
    assert storage.available_as_destination?
  end

  test "available_as_destination? returns false when usage_type is source_only" do
    storage = storages(:source_only_storage)
    assert_not storage.available_as_destination?
  end

  test "available_as_source scope includes nil and source_only" do
    results = Storage.available_as_source
    assert_includes results, @storage
    assert_includes results, storages(:source_only_storage)
    assert_not_includes results, storages(:destination_only_storage)
  end

  test "available_as_destination scope includes nil and destination_only" do
    results = Storage.available_as_destination
    assert_includes results, @storage
    assert_includes results, storages(:destination_only_storage)
    assert_not_includes results, storages(:source_only_storage)
  end

  test "cannot change to destination_only when used as source in backup" do
    storage = storages(:source_bucket)
    storage.usage_type = :destination_only
    assert_not storage.valid?
    assert storage.errors[:usage_type].any? { |e| e.include?("used as a source") }
  end

  test "cannot change to source_only when used as destination in backup" do
    storage = storages(:destination_bucket)
    storage.usage_type = :source_only
    assert_not storage.valid?
    assert storage.errors[:usage_type].any? { |e| e.include?("used as a destination") }
  end

  test "can change usage_type when storage is not used in any backup" do
    storage = storages(:source_only_storage)
    storage.usage_type = :destination_only
    assert storage.valid?
  end
end
