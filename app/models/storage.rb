class Storage < ApplicationRecord
  belongs_to :provider

  has_many :source_backups, class_name: "Backup", foreign_key: :source_storage_id, dependent: :restrict_with_error
  has_many :destination_backups, class_name: "Backup", foreign_key: :destination_storage_id, dependent: :restrict_with_error

  validates :bucket_name, presence: true
  validates :bucket_name, uniqueness: { scope: [ :provider_id, :prefix ], message: "with this prefix already exists for this provider" }

  def name
    display_name.presence || bucket_name
  end

  def full_path
    prefix.present? ? "#{bucket_name}/#{prefix}" : bucket_name
  end

  def rclone_path(remote_name = "remote")
    prefix.present? ? "#{remote_name}:#{bucket_name}/#{prefix}" : "#{remote_name}:#{bucket_name}"
  end

  def backups
    Backup.where(source_storage_id: id).or(Backup.where(destination_storage_id: id))
  end

  def in_use?
    backups.exists?
  end
end
