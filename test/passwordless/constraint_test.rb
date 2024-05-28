# frozen_string_literal: true

require "test_helper"
require "passwordless/test_helpers"

module Passwordless
  class ConstraintTest < ActionDispatch::IntegrationTest
    fixtures :users

    test("restricts to users") do
      assert_raises(ActionController::RoutingError) do
        get "/constraint/only-user"
      end

      alice = users(:alice)
      passwordless_sign_in(alice)

      get "/constraint/only-user"
      assert_response :success
    end

    test("restricts with predicate") do
      alice = users(:alice)
      passwordless_sign_in(alice)

      assert_raises(ActionController::RoutingError) do
        get "/constraint/only-john"
      end

      john = users(:john)
      passwordless_sign_in(john)

      get "/constraint/only-john"
      assert_response :success
    end

    test("negative version") do
      get "/constraint/not-user"
      # redirect because not signed in but route is still matched
      assert_response :redirect
    end

    test("negative version with predicate") do
      passwordless_sign_in(users(:alice))
      assert_raises(ActionController::RoutingError) do
        get "/constraint/not-user"
      end

      get "/constraint/not-john"
      assert_response :success

      passwordless_sign_in(users(:john))
      assert_raises(ActionController::RoutingError) do
        get "/constraint/not-john"
      end
    end
  end
end
