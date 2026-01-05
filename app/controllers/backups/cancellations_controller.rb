module Backups
  class CancellationsController < ApplicationController
    include BackupScoped

    def create
      @backup.cancel
      redirect_to @backup, notice: "Backup cancelled."
    end
  end
end
