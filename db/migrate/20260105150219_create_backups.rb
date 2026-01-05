class CreateBackups < ActiveRecord::Migration[8.1]
  def change
    create_table :backups do |t|
      t.string :name, null: false
      t.references :source_storage, null: false, foreign_key: { to_table: :storages }
      t.references :destination_storage, null: false, foreign_key: { to_table: :storages }
      t.string :schedule, null: false, default: "daily"
      t.boolean :enabled, null: false, default: true
      t.datetime :last_run_at

      t.timestamps
    end
  end
end
