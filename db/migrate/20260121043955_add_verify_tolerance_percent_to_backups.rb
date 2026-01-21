class AddVerifyTolerancePercentToBackups < ActiveRecord::Migration[8.1]
  def change
    add_column :backups, :verify_tolerance_percent, :decimal, default: 0.1, null: false
  end
end
