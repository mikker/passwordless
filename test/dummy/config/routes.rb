Rails.application.routes.draw do
  mount(
    Passwordless::Engine,
    at: "/passwordless",
    defaults: { authenticatable: 'User' }
  )

  resources :users

  get '/secret', to: 'secrets#index'

  root to: 'users#index'
end
