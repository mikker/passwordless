# frozen_string_literal: true

require "test_helper"

module Passwordless
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    def create_session_for(user)
      Session.create!(
        authenticatable: user,
        remote_addr: "yes",
        user_agent: "James Bond"
      )
    end

    test "requesting a magic link as an existing user" do
      User.create email: "a@a"

      get "/users/sign_in"
      assert_equal 200, status

      post "/users/sign_in",
        params: {passwordless: {email: "A@a"}},
        headers: {'User-Agent': "an actual monkey"}
      assert_equal 200, status

      assert_equal 1, ActionMailer::Base.deliveries.size
    end

    test "magic link will send by custom method" do
      old_proc = Passwordless.after_session_save
      called = false
      Passwordless.after_session_save = ->(_) { called = true }

      User.create email: "a@a"

      post "/users/sign_in",
        params: {passwordless: {email: "A@a"}},
        headers: {'User-Agent': "an actual monkey"}
      assert_equal 200, status

      assert_equal true, called

      Passwordless.after_session_save = old_proc
    end

    test "requesting a magic link as an unknown user" do
      get "/users/sign_in"
      assert_equal 200, status

      post "/users/sign_in",
        params: {passwordless: {email: "invalidemail"}},
        headers: {'User-Agent': "an actual monkey"}
      assert_equal 200, status

      assert_equal 0, ActionMailer::Base.deliveries.size
    end

    test "requesting a magic link with overridden fetch method" do
      def User.fetch_resource_for_passwordless(email)
        User.find_or_create_by(email: email)
      end

      get "/users/sign_in"
      assert_equal 200, status

      post "/users/sign_in",
        params: {passwordless: {email: "overriden_email@example"}},
        headers: {'User-Agent': "an actual monkey"}
      assert_equal 200, status

      assert_equal 1, ActionMailer::Base.deliveries.size

      class << User
        remove_method :fetch_resource_for_passwordless
      end
    end

    test "signing in via a token" do
      user = User.create email: "a@a"
      session = create_session_for user

      get "/users/sign_in/#{session.token}"
      follow_redirect!

      assert_equal 200, status
      assert_equal "/", path
      assert_not_nil cookies[:user_id]
    end

    test "signing in via a token as STI model" do
      admin = Admin.create email: "a@a"
      session = create_session_for admin

      get "/users/sign_in/#{session.token}"
      follow_redirect!

      assert_equal 200, status
      assert_equal "/", path
      assert_not_nil cookies[:user_id]
    end

    test "signing in and redirecting back" do
      user = User.create! email: "a@a"

      get "/secret"
      assert_equal 302, status

      follow_redirect!
      assert_equal 200, status

      session = create_session_for user
      get "/users/sign_in/#{session.token}"
      follow_redirect!

      assert_equal 200, status
      assert_equal "/secret", path
    end

    test "disabling redirecting back after sign in" do
      default = Passwordless.redirect_back_after_sign_in
      Passwordless.redirect_back_after_sign_in = false

      user = User.create! email: "a@a"

      get "/secret"
      assert_equal 302, status

      follow_redirect!
      assert_equal 200, status

      session = create_session_for user
      get "/users/sign_in/#{session.token}"
      follow_redirect!

      assert_equal "/", path

      Passwordless.redirect_back_after_sign_in = default
    end

    test "trying to sign in with an unknown token" do
      assert_raise ActiveRecord::RecordNotFound do
        get "/users/sign_in/twin-hotdogs"
      end
    end

    test "signing out" do
      user = User.create email: "a@a"

      session = create_session_for user
      get "/users/sign_in/#{session.token}"
      assert_not_nil cookies[:user_id]

      get "/users/sign_out"
      follow_redirect!

      assert_equal 200, status
      assert_equal "/", path
      assert cookies[:user_id].blank?
    end

    test "trying to sign in with an timed out session" do
      user = User.create email: "a@a"
      session = create_session_for user
      session.update!(timeout_at: Time.current - 1.day)

      get "/users/sign_in/#{session.token}"
      follow_redirect!

      assert_match "Your session has expired", flash[:error]
      assert_nil cookies[:user_id]
      assert_equal 200, status
      assert_equal "/", path
    end
  end
end
