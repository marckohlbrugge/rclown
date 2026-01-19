class AddPathsToBackups < ActiveRecord::Migration[8.1]
  def change
    add_column :backups, :source_path, :string
    add_column :backups, :destination_path, :string
  end
end
