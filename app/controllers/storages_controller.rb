class StoragesController < ApplicationController
  before_action :set_storage, only: %i[show edit update destroy]

  def index
    @storages = Storage.includes(:provider).order(created_at: :desc)
  end

  def show
  end

  def new
    @storage = Storage.new
    @storage.provider_id = params[:provider_id] if params[:provider_id]
  end

  def edit
  end

  def create
    @storage = Storage.new(storage_params)

    if @storage.save
      redirect_to @storage, notice: "Storage was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @storage.update(storage_params)
      redirect_to @storage, notice: "Storage was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @storage.in_use?
      redirect_to @storage, alert: "Cannot delete storage that is used by backups."
    else
      @storage.destroy!
      redirect_to storages_path, notice: "Storage was successfully deleted.", status: :see_other
    end
  end

  private
    def set_storage
      @storage = Storage.find(params[:id])
    end

    def storage_params
      params.require(:storage).permit(:provider_id, :bucket_name, :display_name, :usage_type)
    end
end
