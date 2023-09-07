require "test_helper"

module Passwordless
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    def create_user(attrs = {})
      attrs.reverse_merge!(email: next_email)
      User.create!(attrs)
    end

    def create_pwless_session(attrs = {})
      attrs[:authenticatable] = create_user unless attrs.key?(:authenticatable)
      Session.create!(attrs)
    end

    test("GET /:passwordless_for/sign_in") do
      get "/users/sign_in"

      assert_equal 200, status
      assert_template "passwordless/sessions/new"
    end

    test("POST /:passwordless_for/sign_in -> SUCCESS") do
      create_user(email: "a@a")

      post("/users/sign_in", params: {passwordless: {email: "a@a"}})
      assert_equal 302, status

      assert_equal 1, ActionMailer::Base.deliveries.size

      follow_redirect!
      assert_equal "/users/sign_in/#{Session.last!.id}", path
    end

    test("POST /:passwordless_for/sign_in -> SUCCESS / malformed email") do
      create_user(email: "a_XYZ@a")

      post("/users/sign_in", params: {passwordless: {email: "     a_xyZ@a "}})
      assert_equal 302, status

      assert_equal 1, ActionMailer::Base.deliveries.size

      follow_redirect!
      assert_equal "/users/sign_in/#{Session.last!.id}", path
    end

    test("POST /:passwordless_for/sign_in -> SUCCESS / custom delivery method") do
      called = false

      touch = lambda do |session, req|
        assert_equal(Session, session.class)
        assert_equal(ActionDispatch::Request, req.class)

        called = true
      end

      User.create email: "a@a"

      with_config(after_session_save: touch) do
        post(
          "/users/sign_in",
          params: {passwordless: {email: "A@a"}}
        )
      end

      assert_equal true, called
    end

    test("POST /:passwordless_for/sign_in -> SUCCESS / custom User.fetch_resource_for_passwordless method") do
      def User.fetch_resource_for_passwordless(email)
        User.find_by(email: "heres the trick")
      end

      User.create!(email: "heres the trick")

      post("/users/sign_in", params: {passwordless: {email: "something else"}})

      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal "heres the trick", ActionMailer::Base.deliveries.last.to
    ensure
      class << User
        remove_method :fetch_resource_for_passwordless
      end
    end

    test("POST /:passwordless_for/sign_in -> ERROR / not found") do
      post("/users/sign_in", params: {passwordless: {email: "A@a"}})

      assert_equal 404, status
      assert_equal "/users/sign_in", path
      assert_equal 0, ActionMailer::Base.deliveries.size

      assert_template "passwordless/sessions/new"
      assert_match "We couldn't find a user with that email address", flash[:error]
    end

    test("POST /:passwordless_for/sign_in -> ERROR / other error") do
      create_user(email: "a@a")

      with_config(expires_at: lambda { nil }) do
        post("/users/sign_in", params: {passwordless: {email: "a@a"}})
      end

      assert_equal 422, status
      assert_equal "/users/sign_in", path
      assert_equal 0, ActionMailer::Base.deliveries.size

      assert_template "passwordless/sessions/new"
      assert_match "An error occured", flash[:error]
    end

    test("GET /:passwordless_for/sign_in/:id") do
      passwordless_session = create_pwless_session

      get("/users/sign_in/#{passwordless_session.id}")

      assert_equal 200, status
      assert_equal "/users/sign_in/#{passwordless_session.to_param}", path
      assert_template "passwordless/sessions/show"
    end

    test("PATCH /:passwordless_for/sign_in/:id -> SUCCESS") do
      passwordless_session = create_pwless_session(token: "hi")

      patch("/users/sign_in/#{passwordless_session.id}", params: {passwordless: {token: "hi"}})

      assert_equal 303, status

      follow_redirect!
      assert_equal 200, status
      assert_equal "/", path

      assert_equal pwless_session(User), Session.last!.id
    end

    test("PATCH /:passwordless_for/sign_in/:id -> ERROR") do
      passwordless_session = create_pwless_session(token: "hi")

      patch("/users/sign_in/#{passwordless_session.id}", params: {passwordless: {token: "no"}})

      assert_equal 403, status
      assert_equal "/users/sign_in/#{passwordless_session.to_param}", path
      assert_template "passwordless/sessions/show"

      assert_nil pwless_session(User)
    end

    test("PATCH /:passwordless_for/sign_in/:id -> ERROR / token already claimed") do
      passwordless_session = create_pwless_session(token: "hi")
      passwordless_session.claim!

      with_config(restrict_token_reuse: true) do
        patch(
          "/users/sign_in/#{passwordless_session.id}",
          params: {passwordless: {token: "hi"}}
        )
      end

      assert_equal 303, status

      follow_redirect!
      assert_equal 200, status
      assert_equal "/", path
      assert_match "This link has already been used, try requesting the link again", flash[:error]

      assert_nil pwless_session(User)
    end

    test("PATCH /:passwordless_for/sign_in/:id -> ERROR / session is timed out") do
      passwordless_session = create_pwless_session(token: "hi")
      passwordless_session.update!(timeout_at: Time.current - 1.day)

      patch(
        "/users/sign_in/#{passwordless_session.id}",
        params: {passwordless: {token: "hi"}}
      )

      assert_equal 303, status

      follow_redirect!
      assert_equal 200, status
      assert_equal "/", path
      assert_match "Your session has expired", flash[:error]

      assert_nil pwless_session(User)
    end

    test("DELETE /:passwordless_for/sign_out") do
      user = User.create(email: "a@a")
      passwordless_session = create_pwless_session(authenticatable: user, token: "hi")

      get "/users/sign_in/#{passwordless_session.id}/#{passwordless_session.token}"
      assert_not_nil pwless_session(User)

      get "/users/sign_out"
      follow_redirect!

      assert_equal 200, status
      assert_equal "/", path
      assert pwless_session(User).blank?
    end

    class Helpers
      extend Passwordless::ControllerHelpers
    end

    def pwless_session(cls)
      session[Helpers.session_key(cls)]
    end
  end
end
