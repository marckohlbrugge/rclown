module Backups
  class CancellationsController < ApplicationController
    include BackupScoped

    def create
      @backup.cancel

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @backup, notice: "Backup cancelled." }
      end
    end
  end
end
