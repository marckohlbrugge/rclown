class CreateStorages < ActiveRecord::Migration[8.1]
  def change
    create_table :storages do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :bucket_name, null: false
      t.string :prefix
      t.string :display_name

      t.timestamps
    end

    add_index :storages, [ :provider_id, :bucket_name, :prefix ], unique: true
  end
end
