class AddWorkerPidToBackupRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :backup_runs, :worker_pid, :integer
  end
end
