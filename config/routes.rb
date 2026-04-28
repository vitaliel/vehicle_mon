Rails.application.routes.draw do
  devise_for :users

  resources :vehicles do
    resources :service_log_entries, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :reminder_thresholds
    member do
      patch :update_mileage
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#index"
end
