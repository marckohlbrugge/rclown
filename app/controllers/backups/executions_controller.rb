module Backups
  class ExecutionsController < ApplicationController
    include BackupScoped

    def create
      if @backup.execute
        redirect_to @backup, notice: "Backup started."
      else
        redirect_to @backup, alert: "Backup is already running."
      end
    end
  end
end
