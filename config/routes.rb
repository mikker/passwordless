# frozen_string_literal: true

Passwordless::Engine.routes.draw do
  get "/sign_in", to: "sessions#new", as: :sign_in
  post "/sign_in", to: "sessions#create"
  get "/sign_in/:token", to: "sessions#show", as: :token_sign_in
  match "/sign_out", to: "sessions#destroy", via: %i[get delete], as: :sign_out
end
