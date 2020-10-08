# frozen_string_literal: true

Rails.application.routes.draw do
  passwordless_for(:users)
  passwordless_for(:admins)

  resources(:users)
  resources(:registrations, only: %i[new create])

  get("/secret", to: "secrets#index")
  get("/secret-alt", to: "secrets#index")
  get("/deprecated_secret", to: "deprecated_secrets#index")
  post("/deprecated_fake_login", to: "deprecated_secrets#fake_login")

  root(to: "users#index")
end
