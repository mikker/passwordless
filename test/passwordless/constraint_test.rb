# frozen_string_literal: true

require 'test_helper'
require 'passwordless/test_helpers'

module Passwordless
  class ConstraintTest < ActionDispatch::IntegrationTest
    fixtures :users

    test('#alice_has_no_access') do
      alice = users(:alice)
      passwordless_sign_in(alice)

      get '/secret-john'
      assert_response :not_found
    end

    test('#john_has_access') do
      john = users(:john)
      passwordless_sign_in(john)

      get '/secret-john'
      assert response.body.include?('shhhh! secrets!')
    end

    test('#anyone_logged_in_has_access') do
      alice = users(:alice)
      passwordless_sign_in(alice)

      get '/secret-noproc'
      assert response.body.include?('shhhh! secrets!')

      john = users(:john)
      passwordless_sign_in(john)

      get '/secret-noproc'
      assert response.body.include?('shhhh! secrets!')
    end

    test('#anyone_not_logged_in_has_access') do
      get '/secret-unauthenticated'
      assert response.body.include?('shhhh! secrets!')

      alice = users(:alice)
      passwordless_sign_in(alice)

      get '/secret-unauthenticated'
      assert_response :not_found
    end
  end
end
