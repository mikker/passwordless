# frozen_string_literal: true

Rails.application.routes.draw do
  passwordless_for(:users)
  passwordless_for(:admins, controller: "admin/sessions")
  passwordless_for(:devs, as: :auth, at: "/")

  resources(:users)
  resources(:registrations, only: %i[new create])

  get("/secret", to: "secrets#index")
  get("/secret-alt", to: "secrets#index")

  root(to: "users#index")

  scope("/locale/:locale") do
    passwordless_for(:users, as: :locale_user)
  end

  constraints(Passwordless::Constraint.new(User)) do
    get("/constraint/only-user", to: "secrets#index")
  end

  is_john = -> (user) { user.email.include?("john") }

  constraints(Passwordless::Constraint.new(User, if: is_john)) do
    get("/constraint/only-john", to: "secrets#index")
  end

  constraints(Passwordless::ConstraintNot.new(User)) do
    get("/constraint/not-user", to: "secrets#index")
  end

  constraints(Passwordless::ConstraintNot.new(User, if: is_john)) do
    get("/constraint/not-john", to: "secrets#index")
  end
end
