class Backup < ApplicationRecord
  include Executable, Schedulable, Enableable, Cancellable

  belongs_to :source_storage, class_name: "Storage"
  belongs_to :destination_storage, class_name: "Storage"

  has_many :runs, class_name: "BackupRun", dependent: :destroy

  validate :source_and_destination_differ

  before_validation :generate_name, if: -> { name.blank? && source_storage && destination_storage }

  private
    def generate_name
      self.name = "#{source_storage.name} → #{destination_storage.name}"
    end

    def source_and_destination_differ
      if source_storage_id.present? && source_storage_id == destination_storage_id
        errors.add(:destination_storage, "must be different from source")
      end
    end
end
