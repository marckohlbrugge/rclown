module Backup::Cancellable
  extend ActiveSupport::Concern

  def cancel
    runs.running.find_each(&:cancel)
  end

  def cancellable?
    running?
  end
end
