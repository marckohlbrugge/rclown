class ProvidersController < ApplicationController
  before_action :set_provider, only: %i[show edit update destroy]

  def index
    @providers = Provider.order(created_at: :desc)
  end

  def show
  end

  def new
    @provider = Provider.new
  end

  def edit
  end

  def create
    @provider = Provider.new(provider_params)

    if @provider.save
      redirect_to @provider, notice: "Provider was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @provider.update(provider_params)
      redirect_to @provider, notice: "Provider was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @provider.destroy!
    redirect_to providers_path, notice: "Provider was successfully deleted.", status: :see_other
  end

  private
    def set_provider
      @provider = Provider.find(params[:id])
    end

    def provider_params
      params.require(:provider).permit(:name, :provider_type, :endpoint, :region, :access_key_id, :secret_access_key)
    end
end
