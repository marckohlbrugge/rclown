class ConsolidateDuplicateStorages < ActiveRecord::Migration[8.1]
  def up
    # Find groups of storages with same provider_id and bucket_name
    duplicates = execute(<<~SQL).to_a
      SELECT provider_id, bucket_name
      FROM storages
      GROUP BY provider_id, bucket_name
      HAVING COUNT(*) > 1
    SQL

    duplicates.each do |row|
      provider_id = row["provider_id"]
      bucket_name = row["bucket_name"]

      # Get all storages for this provider/bucket, preferring ones without prefix
      storages = execute(<<~SQL).to_a
        SELECT id, prefix
        FROM storages
        WHERE provider_id = #{provider_id} AND bucket_name = #{quote(bucket_name)}
        ORDER BY CASE WHEN prefix IS NULL OR prefix = '' THEN 0 ELSE 1 END, id
      SQL

      # First one is canonical (no prefix preferred, otherwise first by id)
      canonical_id = storages.first["id"]
      duplicate_ids = storages[1..].map { |s| s["id"] }

      # Update backups to point to canonical storage
      duplicate_ids.each do |dup_id|
        execute("UPDATE backups SET source_storage_id = #{canonical_id} WHERE source_storage_id = #{dup_id}")
        execute("UPDATE backups SET destination_storage_id = #{canonical_id} WHERE destination_storage_id = #{dup_id}")
      end

      # Delete duplicates
      execute("DELETE FROM storages WHERE id IN (#{duplicate_ids.join(',')})")
    end
  end

  def down
    # Cannot reverse this migration - data has been consolidated
    raise ActiveRecord::IrreversibleMigration
  end
end
