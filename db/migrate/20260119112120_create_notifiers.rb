class CreateNotifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :notifiers do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.boolean :enabled, default: true
      t.text :config
      t.datetime :last_notified_at
      t.datetime :last_failed_at
      t.string :last_error

      t.timestamps
    end
  end
end
