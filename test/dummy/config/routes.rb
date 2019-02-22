# frozen_string_literal: true

Rails.application.routes.draw do
  passwordless_for :users

  resources :users
  resources :registrations, only: %i[new create]

  get "/secret", to: "secrets#index"

  root to: "users#index"
end
