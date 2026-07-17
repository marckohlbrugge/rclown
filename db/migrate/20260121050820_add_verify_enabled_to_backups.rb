class AddVerifyEnabledToBackups < ActiveRecord::Migration[8.1]
  def change
    add_column :backups, :verify_enabled, :boolean, default: true, null: false
  end
end
