class RemoveRawLogFromBackupRuns < ActiveRecord::Migration[8.1]
  def change
    remove_column :backup_runs, :raw_log, :text
  end
end
