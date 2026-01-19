class AddRetentionDaysToBackups < ActiveRecord::Migration[8.1]
  def change
    add_column :backups, :retention_days, :integer, default: 30, null: false
  end
end
