module Backups
  class DryRunsController < ApplicationController
    include BackupScoped

    def create
      @backup.execute(dry_run: true)
      redirect_to @backup, notice: "Dry run started."
    end
  end
end
