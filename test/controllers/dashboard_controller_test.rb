require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get root_path
    assert_response :success
  end

  test "displays stats section" do
    get root_path
    assert_select "dt", text: "Total Backups"
    assert_select "dt", text: "Enabled"
    assert_select "dt", text: "Running"
    assert_select "dt", text: "Successful Today"
    assert_select "dt", text: "Failed Today"
  end

  test "displays backups section" do
    get root_path
    assert_select "h3", text: "Backups"
  end

  test "displays recent runs section" do
    get root_path
    assert_select "h3", text: "Recent Runs"
  end

  test "displays next scheduled runs section when enabled backups exist" do
    # Ensure we have an enabled backup
    backup = backups(:daily_backup)
    backup.update!(enabled: true, last_run_at: 1.hour.ago)

    get root_path
    assert_select "h3", text: "Next Scheduled Runs"
  end

  test "next scheduled runs shows backup names and times" do
    backup = backups(:daily_backup)
    backup.update!(enabled: true, last_run_at: 1.hour.ago)

    get root_path

    # Check that the scheduled run displays the backup info
    assert_select "p", text: /Daily backup/i
  end

  test "hides next scheduled runs when no enabled backups" do
    Backup.update_all(enabled: false)

    get root_path
    assert_select "h3", text: "Next Scheduled Runs", count: 0
  end
end
