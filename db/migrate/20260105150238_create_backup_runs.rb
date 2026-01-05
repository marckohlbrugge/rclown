class CreateBackupRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :backup_runs do |t|
      t.references :backup, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :exit_code
      t.text :raw_log
      t.integer :rclone_pid
      t.boolean :dry_run, null: false, default: false

      t.timestamps
    end

    add_index :backup_runs, :status
    add_index :backup_runs, [ :backup_id, :status ]
  end
end
