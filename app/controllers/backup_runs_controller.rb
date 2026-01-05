class BackupRunsController < ApplicationController
  def show
    @run = BackupRun.find(params[:id])
    @backup = @run.backup
  end
end
