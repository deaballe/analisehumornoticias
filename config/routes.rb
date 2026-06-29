Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount Sidekiq::Web => "/sidekiq" unless Rails.env.test?

  root "dashboard#index"
  resources :keywords, only: [ :show ]
end
