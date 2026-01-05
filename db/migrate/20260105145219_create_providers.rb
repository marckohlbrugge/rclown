class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.string :endpoint
      t.string :region
      t.string :access_key_id, null: false
      t.string :secret_access_key, null: false

      t.timestamps
    end
  end
end
