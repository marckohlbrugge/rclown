module Backups
  class EnablementsController < ApplicationController
    include BackupScoped

    def create
      @backup.enable

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@backup), partial: "backups/backup", locals: { backup: @backup }) }
        format.html { redirect_to @backup, notice: "Backup enabled." }
      end
    end

    def destroy
      @backup.disable

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@backup), partial: "backups/backup", locals: { backup: @backup }) }
        format.html { redirect_to @backup, notice: "Backup disabled." }
      end
    end
  end
end
