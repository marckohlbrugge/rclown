class NotifiersController < ApplicationController
  before_action :set_notifier, only: %i[show edit update destroy]

  def index
    @notifiers = Notifier.order(created_at: :desc)
  end

  def show
  end

  def new
    @notifier = Notifier.new
  end

  def edit
  end

  def create
    @notifier = Notifier.build(params[:notifier])

    if @notifier.save
      redirect_to notifier_path(@notifier), notice: "Notifier was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @notifier.assign_attributes(params[:notifier].permit(:name, :enabled))
    @notifier.config = @notifier.class.config_from_params(params[:notifier])

    if @notifier.save
      redirect_to notifier_path(@notifier), notice: "Notifier was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notifier.destroy!
    redirect_to notifiers_path, notice: "Notifier was successfully deleted.", status: :see_other
  end

  private

  def set_notifier
    @notifier = Notifier.find(params[:id])
  end
end
