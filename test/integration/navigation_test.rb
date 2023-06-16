# frozen_string_literal: true

require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  fixtures :users

  test("failed access, sign in and redirect to protected resource") do
    alice = users(:alice)

    # Verify the user has no access to the /secret endpoint and
    # is instead redirected to homepage. Meanwhile access to /secret is
    # stored in the users session.
    get "/secret"
    assert_equal 302, status
    assert_equal "Not worthy!", flash["error"]
    follow_redirect!
    assert_equal 200, status
    assert_equal "/", path

    # Load login form
    get "/users/sign_in"
    assert_equal 200, status

    # Submit form
    post(
      "/users/sign_in",
      params: {
        passwordless: {email: alice.email}
      },

      headers: {"HTTP_USER_AGENT" => "Mosaic v.1"}
    )
    assert_equal 302, status
    assert flash["notice"].include?("If we found you in the system")

    # Expect session created for alice
    user_session = Passwordless::Session.find_by!(authenticatable: alice)
    assert_equal "Mosaic v.1", user_session.user_agent

    # Expect mail for alice
    assert_equal 1, ActionMailer::Base.deliveries.count
    email = ActionMailer::Base.deliveries.first
    assert_equal alice.email, email.to.first

    # Expect mail body to include session link
    token_sign_in_path = "/users/sign_in/#{user_session.token}"
    assert email.body.to_s.include?(token_sign_in_path)

    # Follow link, Expect redirect to /secret path which has been unsuccessfully
    # accessed in the beginning.
    get token_sign_in_path
    assert_equal 302, status
    follow_redirect!

    assert_equal 200, status
    assert_equal "/secret", path
    assert_equal "shhhh! secrets!", response.body
  end
end
