class AddSizeToBackupRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :backup_runs, :source_count, :integer
    add_column :backup_runs, :source_bytes, :integer
  end
end
