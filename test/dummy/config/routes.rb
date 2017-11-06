Rails.application.routes.draw do
  passwordless_for :users
  passwordless_for :admins, at: '/'

  resources :users

  get '/secret', to: 'secrets#index'

  root to: 'users#index'
end
