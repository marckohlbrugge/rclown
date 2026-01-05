module Backups
  class DryRunsController < ApplicationController
    include BackupScoped

    def create
      @run = @backup.execute(dry_run: true)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @backup, notice: "Dry run started." }
      end
    end
  end
end
