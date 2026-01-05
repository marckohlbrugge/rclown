module Backups
  class RunsController < ApplicationController
    include BackupScoped

    def index
      @runs = @backup.runs.order(created_at: :desc).page(params[:page])
    end

    def show
      @run = @backup.runs.find(params[:id])
    end
  end
end
