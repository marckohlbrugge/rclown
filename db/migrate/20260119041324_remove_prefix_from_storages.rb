class RemovePrefixFromStorages < ActiveRecord::Migration[8.1]
  def change
    remove_index :storages, [ :provider_id, :bucket_name, :prefix ]
    add_index :storages, [ :provider_id, :bucket_name ], unique: true
    remove_column :storages, :prefix, :string
  end
end
