class AddUsageTypeToStorages < ActiveRecord::Migration[8.1]
  def change
    add_column :storages, :usage_type, :integer
  end
end
