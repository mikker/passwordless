# frozen_string_literal: true

require "test_helper"

module Passwordless
  class PasswordlessForTest < ActionDispatch::IntegrationTest
    test "map sign in for user" do
      assert_routes(
        {method: :get, path: "/users/sign_in"},
        controller: "passwordless/sessions",
        action: "new",
        authenticatable: "user"
      )
      assert_routes(
        {method: :post, path: "/users/sign_in", params: {
          passwordless: {email: "a@a"},
        },},
        controller: "passwordless/sessions",
        action: "create",
        authenticatable: "user"
      )
      assert_routes(
        {method: :delete, path: "/users/sign_out"},
        controller: "passwordless/sessions",
        action: "destroy",
        authenticatable: "user"
      )
      assert_raises ActiveRecord::RecordNotFound do
        assert_routes(
          {method: :get, path: "/users/sign_in/abc123"},
          controller: "passwordless/sessions",
          action: "show",
          params: {token: "abc123"},
          authenticatable: "user"
        )
      end
    end

    private

    def assert_routes(expected, parameters)
      process expected[:method], expected[:path], params: expected[:params]
      assert_equal parameters, request.path_parameters
    end
  end
end
