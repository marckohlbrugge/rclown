require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # format_bytes tests
  test "format_bytes returns dash for nil" do
    assert_equal "—", format_bytes(nil)
  end

  test "format_bytes formats gigabytes" do
    assert_equal "1.50 GB", format_bytes(1_500_000_000)
  end

  test "format_bytes formats megabytes" do
    assert_equal "1.50 MB", format_bytes(1_500_000)
  end

  test "format_bytes formats kilobytes" do
    assert_equal "1.50 KB", format_bytes(1_500)
  end

  test "format_bytes formats bytes" do
    assert_equal "500 B", format_bytes(500)
  end

  # format_duration tests
  test "format_duration returns dash for nil" do
    assert_equal "—", format_duration(nil)
  end

  test "format_duration formats hours and minutes" do
    assert_equal "2h 30m", format_duration(9000)
  end

  test "format_duration formats minutes and seconds" do
    assert_equal "5m 30s", format_duration(330)
  end

  test "format_duration formats seconds only" do
    assert_equal "45s", format_duration(45)
  end
end
