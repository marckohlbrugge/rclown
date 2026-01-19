class Storage < ApplicationRecord
  belongs_to :provider

  has_many :source_backups, class_name: "Backup", foreign_key: :source_storage_id, dependent: :restrict_with_error
  has_many :destination_backups, class_name: "Backup", foreign_key: :destination_storage_id, dependent: :restrict_with_error

  enum :usage_type, { source_only: 0, destination_only: 1 }, prefix: true

  validates :bucket_name, presence: true
  validate :usage_type_compatible_with_existing_backups, if: :usage_type_changed?

  scope :available_as_source, -> { where(usage_type: [ nil, :source_only ]) }
  scope :available_as_destination, -> { where(usage_type: [ nil, :destination_only ]) }

  def available_as_source?
    usage_type.nil? || usage_type_source_only?
  end

  def available_as_destination?
    usage_type.nil? || usage_type_destination_only?
  end
  validates :bucket_name, uniqueness: { scope: :provider_id, message: "already exists for this provider" }

  def name
    display_name.presence || bucket_name
  end

  def rclone_path(remote_name = "remote")
    "#{remote_name}:#{bucket_name}"
  end

  def backups
    Backup.where(source_storage_id: id).or(Backup.where(destination_storage_id: id))
  end

  def in_use?
    backups.exists?
  end

  private
    def usage_type_compatible_with_existing_backups
      if usage_type_destination_only? && source_backups.exists?
        errors.add(:usage_type, "cannot be changed to destination-only while this storage is used as a source in existing backups. Please update or remove those backups first.")
      end

      if usage_type_source_only? && destination_backups.exists?
        errors.add(:usage_type, "cannot be changed to source-only while this storage is used as a destination in existing backups. Please update or remove those backups first.")
      end
    end
end
