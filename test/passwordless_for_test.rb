# frozen_string_literal: true

require "test_helper"

module Passwordless
  class PasswordlessForTest < ActionDispatch::IntegrationTest
    test("map sign in for user") do
      assert_recognizes(
        {controller: "passwordless/sessions", action: "new", authenticatable: "user"},
        {method: :get, path: "/users/sign_in"},
        {authenticatable: "user"}
      )

      assert_recognizes(
        {controller: "passwordless/sessions", action: "create", authenticatable: "user"},
        {method: :post, path: "/users/sign_in", params: {passwordless: {email: "a@a"}}},
        {authenticatable: "user"}
      )

      assert_recognizes(
        {controller: "passwordless/sessions", action: "show", authenticatable: "user", token: "abc123"},
        {method: :get, path: "/users/sign_in/abc123", params: {token: "abc123"}},
        {authenticatable: "user"}
      )

      assert_recognizes(
        {controller: "passwordless/sessions", action: "destroy", authenticatable: "user"},
        {method: :delete, path: "/users/sign_out"},
        {authenticatable: "user"}
      )
    end
  end
end
