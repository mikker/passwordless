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

      post("/users/sign_in", params: {passwordless_session: {email: "a@a"}})
      assert_equal 302, status

      assert_equal 1, ActionMailer::Base.deliveries.size

      follow_redirect!
      assert_equal "/users/sign_in/#{Session.last!.id}", path
    end

    test("POST /:passwordless_for/sign_in -> SUCCESS / malformed email") do
      create_user(email: "a_XYZ@a")

      post("/users/sign_in", params: {passwordless_session: {email: "     a_xyZ@a "}})
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
          params: {passwordless_session: {email: "A@a"}}
        )
      end

      assert_equal true, called
    end

    test("POST /:passwordless_for/sign_in -> SUCCESS / custom User.fetch_resource_for_passwordless method") do
      def User.fetch_resource_for_passwordless(email)
        User.find_by(email: "heres the trick")
      end

      User.create!(email: "heres the trick")

      post("/users/sign_in", params: {passwordless_session: {email: "something else"}})

      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal "heres the trick", ActionMailer::Base.deliveries.last.to
    ensure
      class << User
        remove_method :fetch_resource_for_passwordless
      end
    end

    test("POST /:passwordless_for/sign_in -> ERROR") do
      post("/users/sign_in", params: {passwordless_session: {email: "A@a"}})

      assert_equal 422, status
      assert_equal "/users/sign_in", path
      assert_equal 0, ActionMailer::Base.deliveries.size

      assert_template "passwordless/sessions/new"
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

      patch("/users/sign_in/#{passwordless_session.id}", params: {passwordless_session: {token: "hi"}})

      assert_equal 302, status

      follow_redirect!
      assert_equal 200, status
      assert_equal "/", path

      assert_equal pwless_session(User), Session.last!.id
    end

    test("PATCH /:passwordless_for/sign_in/:id -> ERROR") do
      passwordless_session = create_pwless_session(token: "hi")

      patch("/users/sign_in/#{passwordless_session.id}", params: {passwordless_session: {token: "no"}})

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
          params: {passwordless_session: {token: "hi"}}
        )
      end

      assert_equal 302, status

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
        params: {passwordless_session: {token: "hi"}}
      )

      assert_equal 302, status

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
      assert session[Helpers.session_key(user.class)].blank?
    end

    #   # test("signing in via a token") do
    #   #   user = User.create(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal "/", path
    #   #   assert_not_nil session[Helpers.session_key(user.class)]
    #   # end
    #   #
    #   # test("reset session id when signing in via a token") do
    #   #   user = User.create(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   old_session_id = @request.session_options[:id].to_s
    #   #
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   new_session_id = @request.session_options[:id].to_s
    #   #
    #   #   assert_not_equal old_session_id, new_session_id
    #   # end
    #   #
    #   # test("signing in via a token as STI model") do
    #   #   admin = Admin.create(email: "a@a")
    #   #   passwordless_session = create_session_for(admin)
    #   #
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal "/", path
    #   #   assert_not_nil session[Helpers.session_key(admin.class)]
    #   # end
    #   #
    #   # test("signing in and redirecting back") do
    #   #   user = User.create!(email: "a@a")
    #   #
    #   #   get "/secret"
    #   #   assert_equal 302, status
    #   #
    #   #   follow_redirect!
    #   #   assert_equal 200, status
    #   #
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal "/secret", path
    #   #   assert_nil session[Helpers.redirect_session_key(User)]
    #   # end
    #   #
    #   # test("signing in and redirecting via query parameter") do
    #   #   Passwordless.restrict_token_reuse = false
    #   #   user = User.create!(email: "a@a")
    #   #
    #   #   get "/secret"
    #   #   assert_equal 302, status
    #   #
    #   #   follow_redirect!
    #   #   assert_equal 200, status
    #   #
    #   #   # Test without domain
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}?destination_path=/secret-alt"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal "/secret-alt", path
    #   #
    #   #   # Text complete url
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}?destination_path=http://www.example.com/secret-alt"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal "/secret-alt", path
    #   # end
    #   #
    #   # test("signing in and redirecting via insecure query parameter") do
    #   #   user = User.create!(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}?destination_path=http://insecure.example.org/secret-alt"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal Passwordless.success_redirect_path, path
    #   # end
    #   #
    #   # test("signing in and redirecting with redirect_to options") do
    #   #   Passwordless.redirect_to_response_options = {notice: "hello!"}
    #   #
    #   #   user = User.create!(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal "hello!", flash[:notice]
    #   #   assert_equal 200, status
    #   #   assert_equal Passwordless.success_redirect_path, path
    #   # end
    #   #
    #   # test("disabling redirecting back after sign in") do
    #   #   default = Passwordless.redirect_back_after_sign_in
    #   #   Passwordless.redirect_back_after_sign_in = false
    #   #
    #   #   user = User.create!(email: "a@a")
    #   #
    #   #   get "/secret"
    #   #   assert_equal 302, status
    #   #
    #   #   follow_redirect!
    #   #   assert_equal 200, status
    #   #
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   follow_redirect!
    #   #
    #   #   assert_equal "/", path
    #   #
    #   #   Passwordless.redirect_back_after_sign_in = default
    #   # end
    #   #
    #   # test("trying to sign in with an unknown token") do
    #   #   assert_raise(ActiveRecord::RecordNotFound) do
    #   #     get "/users/sign_in/twin-hotdogs"
    #   #   end
    #   # end
    #   #
    #   # test("reset session id when signing out") do
    #   #   user = User.create(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #
    #   #   old_session_id = @request.session_options[:id].to_s
    #   #   get "/users/sign_out"
    #   #   new_session_id = @request.session_options[:id].to_s
    #   #
    #   #   assert_not_equal old_session_id, new_session_id
    #   # end
    #   #
    #   # test("signing out with redirect_to options") do
    #   #   Passwordless.redirect_to_response_options = {notice: "bye!"}
    #   #
    #   #   user = User.create(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   assert_not_nil session[Helpers.session_key(user.class)]
    #   #
    #   #   get "/users/sign_out"
    #   #
    #   #   follow_redirect!
    #   #
    #   #   assert_equal "bye!", flash[:notice]
    #   #   assert_equal 200, status
    #   #   assert_equal "/", path
    #   #   assert session[Helpers.session_key(user.class)].blank?
    #   # end
    #   #
    #   # test("trying to sign in with an timed out session") do
    #   #   user = User.create(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #   passwordless_session.update!(timeout_at: Time.current - 1.day)
    #   #
    #   #   get "/users/sign_in/#{passwordless_session.token}"
    #   #   follow_redirect!
    #   #
    #   #   assert_match "Your session has expired", flash[:error]
    #   #   assert_nil session[Helpers.session_key(user.class)]
    #   #   assert_equal 200, status
    #   #   assert_equal "/", path
    #   # end
    #   #
    #   # test("responding to HEAD requests") do
    #   #   user = User.create(email: "a@a")
    #   #   passwordless_session = create_session_for(user)
    #   #
    #   #   token_path = "/users/sign_in/#{passwordless_session.token}"
    #   #   head token_path
    #   #
    #   #   assert_equal 200, status
    #   #   assert_equal token_path, path
    #   #   assert_nil session[Helpers.session_key(user.class)]
    #   # end

    class Helpers
      extend Passwordless::ControllerHelpers
    end

    def pwless_session(cls)
      session[Helpers.session_key(cls)]
    end
  end
end
