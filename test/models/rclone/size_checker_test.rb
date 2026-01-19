require "test_helper"
require "minitest/mock"

class Rclone::SizeCheckerTest < ActiveSupport::TestCase
  setup do
    @storage = storages(:source_bucket)
    @config_file = Tempfile.new([ "rclone", ".conf" ])
    @config_file.write("[remote]\ntype = s3\n")
    @config_file.flush
  end

  teardown do
    @config_file.close
    @config_file.unlink
  end

  test "parses valid JSON response" do
    json_output = '{"count": 123, "bytes": 456789}'
    mock_status = MockStatus.new(true)

    Open3.stub :capture3, [ json_output, "", mock_status ] do
      checker = Rclone::SizeChecker.new(@storage, @config_file)
      result = checker.check

      assert_equal 123, result[:count]
      assert_equal 456789, result[:bytes]
    end
  end

  test "returns nil on command failure" do
    mock_status = MockStatus.new(false)

    Open3.stub :capture3, [ "", "error message", mock_status ] do
      checker = Rclone::SizeChecker.new(@storage, @config_file)
      result = checker.check

      assert_nil result
    end
  end

  test "returns nil on invalid JSON" do
    mock_status = MockStatus.new(true)

    Open3.stub :capture3, [ "not valid json", "", mock_status ] do
      checker = Rclone::SizeChecker.new(@storage, @config_file)
      result = checker.check

      assert_nil result
    end
  end

  test "uses correct remote name in command" do
    json_output = '{"count": 1, "bytes": 100}'
    mock_status = MockStatus.new(true)
    captured_command = nil

    capture_stub = lambda do |*command|
      captured_command = command
      [ json_output, "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      checker = Rclone::SizeChecker.new(@storage, @config_file, remote_name: "source")
      checker.check

      assert_includes captured_command, "source:my-source-bucket"
    end
  end

  test "builds correct command with config file" do
    json_output = '{"count": 1, "bytes": 100}'
    mock_status = MockStatus.new(true)
    captured_command = nil

    capture_stub = lambda do |*command|
      captured_command = command
      [ json_output, "", mock_status ]
    end

    Open3.stub :capture3, capture_stub do
      checker = Rclone::SizeChecker.new(@storage, @config_file)
      checker.check

      assert_equal "rclone", captured_command[0]
      assert_equal "size", captured_command[1]
      assert_includes captured_command, "--json"
      assert_includes captured_command, "--config"
      assert_includes captured_command, @config_file.path
    end
  end

  private
    MockStatus = Struct.new(:success) do
      def success?
        success
      end
    end
end
