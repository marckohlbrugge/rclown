class BackupsController < ApplicationController
  before_action :set_backup, only: %i[show edit update destroy]

  def index
    @backups = Backup.includes(source_storage: :provider, destination_storage: :provider)
                     .order(created_at: :desc)
  end

  def show
    @runs = @backup.runs.order(created_at: :desc).limit(30)
  end

  def new
    @backup = Backup.new
  end

  def edit
  end

  def create
    @backup = Backup.new(backup_params)

    if @backup.save
      redirect_to @backup, notice: "Backup was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @backup.update(backup_params)
      redirect_to @backup, notice: "Backup was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @backup.destroy!
    redirect_to backups_path, notice: "Backup was successfully deleted.", status: :see_other
  end

  private
    def set_backup
      @backup = Backup.find(params[:id])
    end

    def backup_params
      params.require(:backup).permit(:name, :source_storage_id, :destination_storage_id, :source_path, :destination_path, :schedule, :enabled, :comparison_mode, :verify_enabled, :verify_tolerance_percent)
    end
end
