# frozen_string_literal: true

require "test_helper"

class DeprecatedSecretsControllerTest < ActionDispatch::IntegrationTest
  def create_session_for(user)
    Passwordless::Session.create!(
      authenticatable: user,
      remote_addr: "yes",
      user_agent: "James Bond"
    )
  end

  def login(passwordless_session)
    post "/deprecated_fake_login", params: {
      authenticatable_type: passwordless_session.authenticatable_type,
      authenticatable_id: passwordless_session.authenticatable_id,
    }
  end

  test "authenticate_by_cookies" do
    user = User.create(email: "foo@example.com")
    passwordless_session = create_session_for(user)
    login(passwordless_session)
    refute cookies["user_id"].blank?

    get "/deprecated_secret", headers: {"User-Agent" => "Thing"}
    assert_equal 200, status

    # Session has been upgraded
    assert cookies["user_id"].blank?
  end
end
