Rails.application.routes.draw do
  root "dashboard#show"

  resource :dashboard, only: :show, controller: "dashboard"

  resources :providers do
    scope module: :providers do
      resource :connection_test, only: :create
      resources :buckets, only: [ :index, :create ]
    end
  end

  resources :storages

  resources :backups do
    scope module: :backups do
      resource :execution, only: :create
      resource :cancellation, only: :create
      resource :enablement, only: [ :create, :destroy ]
      resource :dry_run, only: :create
      resources :runs, only: [ :index, :show ]
    end
  end

  resource :health, only: :show, controller: "health"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
