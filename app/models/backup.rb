class Backup < ApplicationRecord
  include Executable, Schedulable, Enableable, Cancellable

  belongs_to :source_storage, class_name: "Storage"
  belongs_to :destination_storage, class_name: "Storage"

  has_many :runs, class_name: "BackupRun", dependent: :destroy

  def runs_by_day(days: 30)
    runs.where(dry_run: false, created_at: days.days.ago..).group_by { |r| r.created_at.to_date }
  end

  validate :source_and_destination_differ
  validate :source_storage_allows_source_usage
  validate :destination_storage_allows_destination_usage

  before_validation :generate_name, if: -> { name.blank? && source_storage && destination_storage }

  # Path methods for rclone commands
  def source_rclone_path(remote_name = "source")
    build_rclone_path(source_storage.bucket_name, source_path, remote_name)
  end

  def destination_rclone_path(remote_name = "destination")
    build_rclone_path(destination_storage.bucket_name, destination_path, remote_name)
  end

  # Full paths for display
  def source_full_path
    source_path.present? ? "#{source_storage.bucket_name}/#{source_path}" : source_storage.bucket_name
  end

  def destination_full_path
    destination_path.present? ? "#{destination_storage.bucket_name}/#{destination_path}" : destination_storage.bucket_name
  end

  private
    def build_rclone_path(bucket_name, path, remote_name)
      path.present? ? "#{remote_name}:#{bucket_name}/#{path}" : "#{remote_name}:#{bucket_name}"
    end

    def generate_name
      self.name = "#{source_storage.name} → #{destination_storage.name}"
    end

    def source_and_destination_differ
      if source_storage_id.present? && source_storage_id == destination_storage_id
        errors.add(:destination_storage, "must be different from source")
      end
    end

    def source_storage_allows_source_usage
      if source_storage.present? && !source_storage.available_as_source?
        errors.add(:source_storage, "is restricted to destination-only usage")
      end
    end

    def destination_storage_allows_destination_usage
      if destination_storage.present? && !destination_storage.available_as_destination?
        errors.add(:destination_storage, "is restricted to source-only usage")
      end
    end
end
