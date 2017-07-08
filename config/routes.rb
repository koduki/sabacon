require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  root :to => 'submissions#index'
  mount Sidekiq::Web => '/sidekiq'

  resources :problems, only: [:index]
  resources :submissions
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
