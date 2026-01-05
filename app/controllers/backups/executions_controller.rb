module Backups
  class ExecutionsController < ApplicationController
    include BackupScoped

    def create
      @run = @backup.execute

      if @run
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to @backup, notice: "Backup started." }
        end
      else
        redirect_to @backup, alert: "Backup is already running."
      end
    end
  end
end
