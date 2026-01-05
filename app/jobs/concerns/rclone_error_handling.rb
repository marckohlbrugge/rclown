module RcloneErrorHandling
  extend ActiveSupport::Concern

  included do
    # Retry on transient system errors
    retry_on Errno::ENOENT, wait: :polynomially_longer, attempts: 3
    retry_on Errno::ECONNREFUSED, wait: :polynomially_longer, attempts: 3

    # Don't retry on permanent failures - let them fail
    # The BackupRun will be marked as failed
  end
end
