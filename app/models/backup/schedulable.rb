module Backup::Schedulable
  extend ActiveSupport::Concern

  included do
    enum :schedule, { daily: "daily", weekly: "weekly" }

    scope :due, -> { enabled.where("last_run_at IS NULL OR last_run_at <= ?", 1.day.ago) }
  end

  def next_run_at
    return nil unless enabled?

    base_time = last_run_at || created_at

    case schedule
    when "daily"
      base_time + 1.day
    when "weekly"
      base_time + 1.week
    end
  end

  def due?
    return false unless enabled?
    return true if last_run_at.nil?

    case schedule
    when "daily"
      last_run_at <= 1.day.ago
    when "weekly"
      last_run_at <= 1.week.ago
    end
  end
end
