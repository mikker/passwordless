# frozen_string_literal: true

require "test_helper"

module Passwordless
  class PasswordlessForTest < ActionDispatch::IntegrationTest
    test("map sign in for user") do
      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "new",
          authenticatable: "user",
          resource: "users"
        },
        {method: :get, path: "/users/sign_in"},
        {authenticatable: "user", resource: "users"}
      )

      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "create",
          authenticatable: "user",
          resource: "users"
        },
        {method: :post, path: "/users/sign_in", params: {passwordless: {email: "a@a"}}},
        {authenticatable: "user", resource: "users"}
      )

      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "show",
          authenticatable: "user",
          resource: "users",
          token: "abc123"
        },
        {method: :get, path: "/users/sign_in/abc123", params: {token: "abc123"}},
        {authenticatable: "user", resource: "users"}
      )

      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "destroy",
          authenticatable: "user",
          resource: "users"
        },
        {method: :delete, path: "/users/sign_out"},
        {authenticatable: "user", resource: "users"}
      )
    end

    test("map sign in for admin") do
      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "new",
          authenticatable: "admin",
          resource: "admins"
        },
        {method: :get, path: "/admins/sign_in"},
        {authenticatable: "admin", resource: "admins"}
      )

      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "create",
          authenticatable: "admin",
          resource: "admins"
        },
        {method: :post, path: "/admins/sign_in", params: {passwordless: {email: "a@a"}}},
        {authenticatable: "admin", resource: "admins"}
      )

      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "show",
          authenticatable: "admin",
          resource: "admins",
          token: "abc123"
        },
        {method: :get, path: "/admins/sign_in/abc123", params: {token: "abc123"}},
        {authenticatable: "admin", resource: "admins"}
      )

      assert_recognizes(
        {
          controller: "passwordless/sessions",
          action: "destroy",
          authenticatable: "admin",
          resource: "admins"
        },
        {method: :delete, path: "/admins/sign_out"},
        {authenticatable: "admin", resource: "admins"}
      )
    end
  end
end
