require 'test_helper'

module Passwordless
  class SessionsTest < ActionDispatch::IntegrationTest
    test "requesting a magic link as an existing user" do
      user = User.create email: 'a@a'

      get "/passwordless/sign_in"
      assert_equal 200, status

      post "/passwordless/sign_in", {
        params: { passwordless: { email: user.email } },
        headers: { 'User-Agent': 'an actual monkey' }
      }
      assert_equal 200, status

      assert_equal 1, ActionMailer::Base.deliveries.size
    end

    test "requesting a magic link as an unknown user" do
      get "/passwordless/sign_in"
      assert_equal 200, status

      post "/passwordless/sign_in", {
        params: { passwordless: { email: 'something_em@ilish' } },
        headers: { 'User-Agent': 'an actual monkey' }
      }
      assert_equal 200, status

      assert_equal 0, ActionMailer::Base.deliveries.size
    end

    test "signing in via a token" do
      user = User.create email: 'a@a'
      session = Session.create!(
        authenticatable: user,
        remote_addr: 'yes',
        user_agent: 'James Bond'
      )

      get "/passwordless/sign_in/#{session.token}"
      follow_redirect!

      assert_equal 200, status
      assert_equal "/", path
      refute_nil cookies[:user_id]
    end

    test "trying to sign in with an unknown token" do
      assert_raise ActiveRecord::RecordNotFound do
        get "/passwordless/sign_in/twin-hotdogs"
      end
    end

    test "signin out" do
      user = User.create email: 'a@a'
      session = Session.create!(
        authenticatable: user,
        remote_addr: 'yes',
        user_agent: 'James Bond'
      )

      get "/passwordless/sign_in/#{session.token}"
      refute_nil cookies[:user_id]

      get '/passwordless/sign_out'
      follow_redirect!

      assert_equal 200, status
      assert_equal "/", path
      assert cookies[:user_id].blank?
    end
  end
end
