class AddComparisonModeToBackups < ActiveRecord::Migration[8.1]
  def change
    add_column :backups, :comparison_mode, :integer, default: 0, null: false
  end
end
