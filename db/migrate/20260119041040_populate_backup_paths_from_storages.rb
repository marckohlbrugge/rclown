class PopulateBackupPathsFromStorages < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE backups
      SET source_path = (SELECT prefix FROM storages WHERE storages.id = backups.source_storage_id),
          destination_path = (SELECT prefix FROM storages WHERE storages.id = backups.destination_storage_id)
    SQL
  end

  def down
    # No-op: we don't want to lose the path data if we rollback
  end
end
