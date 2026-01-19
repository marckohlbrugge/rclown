class AddRclonePathsToBackupRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :backup_runs, :source_rclone_path, :string
    add_column :backup_runs, :destination_rclone_path, :string
  end
end
