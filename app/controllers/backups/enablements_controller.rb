module Backups
  class EnablementsController < ApplicationController
    include BackupScoped

    def create
      @backup.enable
      redirect_to @backup, notice: "Backup enabled."
    end

    def destroy
      @backup.disable
      redirect_to @backup, notice: "Backup disabled."
    end
  end
end
