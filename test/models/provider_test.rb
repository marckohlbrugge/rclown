require "test_helper"

class ProviderTest < ActiveSupport::TestCase
  setup do
    @provider = providers(:cloudflare)
  end

  test "valid provider" do
    assert @provider.valid?
  end

  test "requires name" do
    @provider.name = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:name], "can't be blank"
  end

  test "requires provider_type" do
    @provider.provider_type = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:provider_type], "can't be blank"
  end

  test "requires access_key_id" do
    @provider.access_key_id = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:access_key_id], "can't be blank"
  end

  test "requires secret_access_key" do
    @provider.secret_access_key = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:secret_access_key], "can't be blank"
  end

  test "cloudflare_r2 requires endpoint" do
    @provider.endpoint = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:endpoint], "can't be blank"
  end

  test "backblaze_b2 does not require endpoint" do
    provider = providers(:backblaze)
    provider.endpoint = nil
    assert provider.valid?
  end

  test "encrypts access_key_id when saved" do
    # Create a new provider to test encryption (fixtures store plain text)
    provider = Provider.create!(
      name: "Encryption Test",
      provider_type: :cloudflare_r2,
      endpoint: "https://test.r2.cloudflarestorage.com",
      access_key_id: "new_access_key",
      secret_access_key: "new_secret_key"
    )

    # The value should be readable
    assert_equal "new_access_key", provider.access_key_id

    # The raw stored value should be encrypted (different from plain text)
    raw_value = Provider.connection.select_value(
      "SELECT access_key_id FROM providers WHERE id = #{provider.id}"
    )
    assert_not_equal "new_access_key", raw_value
    assert raw_value.present?
  end

  test "encrypts secret_access_key when saved" do
    provider = Provider.create!(
      name: "Encryption Test 2",
      provider_type: :cloudflare_r2,
      endpoint: "https://test.r2.cloudflarestorage.com",
      access_key_id: "access_key_2",
      secret_access_key: "secret_value_to_encrypt"
    )

    assert_equal "secret_value_to_encrypt", provider.secret_access_key

    raw_value = Provider.connection.select_value(
      "SELECT secret_access_key FROM providers WHERE id = #{provider.id}"
    )
    assert_not_equal "secret_value_to_encrypt", raw_value
    assert raw_value.present?
  end

  test "provider_type_name returns human readable name" do
    assert_equal "Cloudflare R2", @provider.provider_type_name
    assert_equal "Backblaze B2", providers(:backblaze).provider_type_name
    assert_equal "Amazon S3", providers(:amazon).provider_type_name
  end

  test "generates cloudflare r2 rclone config" do
    config = @provider.rclone_config_section("source")
    assert_includes config, "[source]"
    assert_includes config, "type = s3"
    assert_includes config, "provider = Cloudflare"
    assert_includes config, "access_key_id = test_access_key_cf"
    assert_includes config, "secret_access_key = test_secret_key_cf"
    assert_includes config, "endpoint = https://test.r2.cloudflarestorage.com"
  end

  test "generates backblaze b2 rclone config" do
    config = providers(:backblaze).rclone_config_section("dest")
    assert_includes config, "[dest]"
    assert_includes config, "type = b2"
    assert_includes config, "account = test_access_key_b2"
    assert_includes config, "key = test_secret_key_b2"
  end

  test "generates amazon s3 rclone config" do
    config = providers(:amazon).rclone_config_section("remote")
    assert_includes config, "[remote]"
    assert_includes config, "type = s3"
    assert_includes config, "provider = AWS"
    assert_includes config, "access_key_id = test_access_key_aws"
    assert_includes config, "secret_access_key = test_secret_key_aws"
    assert_includes config, "region = us-east-1"
  end
end
