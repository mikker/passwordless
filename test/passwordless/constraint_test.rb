# frozen_string_literal: true

require "test_helper"
require "passwordless/test_helpers"

module Passwordless
  class ConstraintTest < ActionDispatch::IntegrationTest
    fixtures :users

    test("#alice_has_no_access") do
      alice = users(:alice)
      passwordless_sign_in(alice)

      get "/secret-john"
      assert_response :not_found
    end

    test("#john_has_access") do
      john = users(:john)
      passwordless_sign_in(john)

      get "/secret-john"
      assert response.body.include?("shhhh! secrets!")
    end
  end
end
